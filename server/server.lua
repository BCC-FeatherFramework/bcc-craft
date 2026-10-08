local activeCrafting = {}

-- Recipes are read from the server's own config. The client names a location
-- and an item; everything else (materials, amounts, XP, duration, jobs) comes
-- from CraftingLocations here, so a modified client cannot change a recipe.
local function FindRecipe(locationId, itemName)
	if type(itemName) ~= "string" then return nil end
	for _, location in ipairs(CraftingLocations) do
		if locationId == nil or locationId == "unknown" or location.locationId == locationId then
			for _, category in ipairs(location.categories) do
				for _, item in ipairs(category.items) do
					if item.itemName == itemName then
						return item, location
					end
				end
			end
		end
	end
	return nil
end

local function IsWeapon(itemName)
	return string.sub(itemName:lower(), 1, string.len("weapon_")) == "weapon_"
end

-- Validates a crafting request and returns the recipe, amount and character.
local function ResolveRequest(params, source)
	local requested = type(params) == "table" and params.item
	if type(requested) ~= "table" then return nil end
	local recipe = FindRecipe(params.locationId, requested.itemName)
	if not recipe then
		devPrint("[ERROR] Unknown recipe:", tostring(requested.itemName), "at", tostring(params.locationId))
		return nil
	end
	local amount = math.floor(tonumber(requested.itemAmount) or 1)
	local maxAmount = IsWeapon(recipe.itemName) and (Config.WeaponsLimit or 1) or 100
	if amount < 1 or amount > maxAmount then return nil end
	local Character = CraftCharacters.Get(source)
	if not Character then return nil end
	return recipe, amount, Character
end

-- Shared checks for CanCraft and AttemptCraft. Notifies the player on failure.
local function CheckRequirements(source, item, inputAmount, Character)
	-- Check job requirements
	if item.requiredJobs and #item.requiredJobs > 0 then
		devPrint("Checking job requirements for: " .. item.itemLabel)
		if not CraftJobs.MeetsRecipe(Character.charIdentifier, item.requiredJobs) then
			devPrint("Player does not meet the job requirements for: " .. item.itemLabel)
			NotifyClient(source, _U("InvalidJobForCrafting") .. item.itemLabel, 5000, "error")
			return false
		end
	end

	-- Check Needed Item (tools that must be held)
	if item.neededItems and #item.neededItems > 0 then
		for _, neededItem in pairs(item.neededItems) do
			if CraftInventory.Count(source, neededItem.itemName) < 1 then
				devPrint(_U("MissingNeededItem") .. neededItem.itemLabel)
				NotifyClient(source, _U("MissingNeededItem") .. neededItem.itemLabel .. ".", 4000, "error")
				return false
			end
		end
	end

	-- Check if player has required items (consumed materials scale with the amount)
	for _, reqItem in pairs(item.requiredItems) do
		local required = reqItem.removeItem and reqItem.itemCount * inputAmount or reqItem.itemCount
		local count = CraftInventory.Count(source, reqItem.itemName)
		devPrint(_U("PlayerHas") .. count .. _U("Of") .. reqItem.itemName .. _U("Requires") .. required .. ")")
		if count < required then
			NotifyClient(source, _U("MissingMaterials") .. item.itemLabel .. ".", 4000, "error")
			return false
		end
	end

	-- Optional playtime requirement through bcc-userlog
	if Config.useBccUserlog and UserLogAPI and (item.requiredPlaytimeMinutes or 0) > 0 then
		local identifier = GetPlayerIdentifierByType(source, "steam")
		local playerData = identifier and UserLogAPI:GetUserBySteamID(identifier)
		local playtime = playerData and playerData.players_playTime
		local requiredMinutes = item.requiredPlaytimeMinutes
		if playtime and playtime < requiredMinutes then
			local requiredHours = math.floor(requiredMinutes / 60)
			NotifyClient(source, "You need at least " .. requiredHours .. " hours of playtime (" .. requiredMinutes .. " minutes) to craft this item.", 5000, "error")
			return false
		end
	end
	return true
end

-- Register the RPC for attempting to craft an item
FeatherRPC:Register("bcc-crafting:AttemptCraft", function(params, cb, source)
	local item, inputAmount, Character = ResolveRequest(params, source)
	if not item then
		devPrint("[ERROR] Invalid crafting attempt from source: " .. tostring(source))
		return cb(false)
	end

	local playerId = Character.charIdentifier
	local itemConfigAmount = item.itemAmount * inputAmount

	if not CheckRequirements(source, item, inputAmount, Character) then
		return cb(false)
	end

	-- Check player's crafting level
	GetPlayerCraftingData(playerId, function(xp, level)
		if level < item.requiredLevel then
			NotifyClient(source, _U("RequiredLevel") .. item.requiredLevel .. ".", 4000, "error")
			return cb(false)
		end

		local totalDuration = item.duration * inputAmount
		if not IsWeapon(item.itemName) then
			-- Regular item limit check for non-weapon items
			local definition = CraftInventory.Definition(item.itemName)
			local itemLimit = definition and tonumber(definition.max_quantity)
			if not definition then
				NotifyClient(source, "Item data not found for item: " .. item.itemLabel, 4000, "error")
				return cb(false)
			end
			if itemLimit and itemLimit > 0 and itemConfigAmount > itemLimit then
				NotifyClient(source, _U("CannotCraftOverLimit") .. item.itemLabel, 4000, "error")
				return cb(false)
			end
		elseif not CraftWeapons.DefinitionId(item.itemName) then
			NotifyClient(source, _U("FailedToAddWeapon"), 4000, "error")
			return cb(false)
		end

		-- Remove required items from inventory, or wear the tools
		for _, reqItem in pairs(item.requiredItems) do
			if reqItem.removeItem then
				local requiredItemCount = reqItem.itemCount * inputAmount
				local removed = CraftInventory.Remove(source, reqItem.itemName, requiredItemCount)
				if not removed.ok then
					devPrint("[ERROR] Failed to remove item: " .. tostring(reqItem.itemName) .. " " .. tostring(removed.code))
					NotifyClient(source, _U("RemoveItemFailed", reqItem.itemLabel), 4000, "error")
					return cb(false)
				end
			else
				local outcome, problem = CraftInventory.WearTool(playerId, reqItem.itemName,
					reqItem.useDurability, reqItem.maxDurability)
				if not outcome then
					devPrint("[ERROR] Tool wear failed: " .. tostring(reqItem.itemName) .. " " .. tostring(problem))
					NotifyClient(source, "Item not found: " .. reqItem.itemLabel, 4000, "error")
					return cb(false)
				elseif outcome == "broken" then
					NotifyClient(source, "Your crafting tool has broken", 4000, "error")
				end
			end
		end

		-- Expected completion: animated recipes finished while the player waited.
		local timestamp = item.playAnimation and (os.time() - totalDuration) or os.time()

		local insertOk, insertId = pcall(DB.insert,
			"INSERT INTO bcc_crafting_log (charidentifier, itemName, itemLabel, itemAmount, requiredItems, status, duration, rewardXP, timestamp, locationId) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
			playerId, item.itemName, item.itemLabel, itemConfigAmount, json.encode(item.requiredItems),
			"in_progress", totalDuration, item.rewardXP, timestamp, params.locationId
		)
		if insertOk and insertId then
			activeCrafting[source] = { craftingId = insertId, startTime = os.time(), duration = totalDuration }
			local started = {}
			for key, value in pairs(item) do started[key] = value end
			started.itemAmount = inputAmount
			started.craftingId = insertId
			FeatherRPC:Notify("bcc-crafting:StartCrafting", { item = started }, source)
			Discord:sendMessage("Player ID: " .. playerId .. " started crafting " .. tostring(item.itemLabel)
				.. ". Amount: " .. tostring(itemConfigAmount) .. ". Total Duration: " .. tostring(totalDuration) .. "s")
			cb(true)
		else
			NotifyClient(source, _U("CraftingAttemptFailed"), 4000, "error")
			cb(false)
		end
	end)
end)

-- Register the RPC for checking if a player can craft an item
FeatherRPC:Register("bcc-crafting:CanCraft", function(params, cb, source)
	local item, inputAmount, Character = ResolveRequest(params, source)
	if not item then return cb(false) end
	if not CheckRequirements(source, item, inputAmount, Character) then return cb(false) end

	-- Level check
	GetPlayerCraftingData(Character.charIdentifier, function(xp, level)
		if level < item.requiredLevel then
			NotifyClient(source, _U("RequiredLevel") .. item.requiredLevel, 4000, "error")
			return cb(false)
		end
		cb(true) -- Passed all checks
	end)
end)

-- Server-side function to retrieve ongoing crafting items and remaining times
RegisterNetEvent("bcc-crafting:getOngoingCrafting", function()
	local _source = source
	local Character = CraftCharacters.Get(_source)
	if not Character then return end
	local queryOk, result = pcall(DB.query,
		"SELECT * FROM bcc_crafting_log WHERE charidentifier = ? AND status = 'in_progress'",
		Character.charIdentifier
	)
	local ongoingCraftingList = {}
	if queryOk and result and #result > 0 then
		for _, craftingLog in ipairs(result) do
			local remainingTime = craftingLog.duration - (os.time() - craftingLog.timestamp)
			if remainingTime <= 0 then
				DB.exec("UPDATE bcc_crafting_log SET status = 'completed', completed_at = NOW() WHERE id = ?", craftingLog.id)
				remainingTime = 0
			end
			table.insert(ongoingCraftingList, { craftingLog = craftingLog, remainingTime = remainingTime })
		end
	end
	TriggerClientEvent("bcc-crafting:sendOngoingCraftingList", _source, ongoingCraftingList)
end)

-- Register the RPC for getting completed crafting items
FeatherRPC:Register("bcc-crafting:GetCompletedCrafting", function(_, cb, source)
	local Character = CraftCharacters.Get(source)
	if not Character then return cb(false) end

	local queryOk, completedResult = pcall(DB.query,
		"SELECT * FROM bcc_crafting_log WHERE charidentifier = ? AND status = 'completed'",
		Character.charIdentifier
	)
	if queryOk and completedResult and #completedResult > 0 then
		cb(completedResult)
	else
		cb(false)
	end
end)

local function AwardXP(source, playerId, totalXP)
	AddPlayerCraftingXP(playerId, totalXP, function(newLevel)
		if newLevel then
			devPrint("[DEBUG] Player leveled up to: " .. newLevel)
			TriggerClientEvent("bcc-crafting:levelUp", source, newLevel)
		end
	end)
end

-- Register the callback for collecting crafted items. The client names the log;
-- the server loads it and only accepts the player's own completed entries.
FeatherRPC:Register("bcc-crafting:collectCraftedItem", function(params, cb, source)
	local requestedLog = type(params) == "table" and params.craftingLog
	local logId = type(requestedLog) == "table" and tonumber(requestedLog.id)
	local Character = CraftCharacters.Get(source)
	if not logId or not Character then return cb(false) end

	local rows = DB.query("SELECT * FROM bcc_crafting_log WHERE id = ? AND charidentifier = ? AND status = 'completed'",
		logId, Character.charIdentifier)
	local craftingLog = rows and rows[1]
	if not craftingLog then return cb(false) end

	if not Config.allowGlobalCollection then
		local playerLocation = params.locationId
		local itemLocation = craftingLog.locationId
		-- If itemLocation is NULL or "unknown", allow collection from anywhere
		if itemLocation ~= nil and itemLocation ~= "unknown" and itemLocation ~= playerLocation then
			NotifyClient(source, _U("WrongCollectionLocation"), 4000, "error")
			return cb(false)
		end
	end

	local playerId = Character.charIdentifier
	local firstname, lastname = Character.firstname, Character.lastname
	local itemName = craftingLog.itemName
	local itemLabel = craftingLog.itemLabel
	local rewardXP = craftingLog.rewardXP
	local amountToAdd = craftingLog.itemAmount

	if IsWeapon(itemName) then
		if CraftInventory.WeaponCount(playerId) >= Config.maxWeaponsAllowed then
			NotifyClient(source, _U("CannotCarryMoreWeapons"), 4000, "error")
			return cb(false)
		end

		local issued = CraftWeapons.Issue(source, Character, itemName, craftingLog.id)
		if not issued.ok then
			devPrint("[ERROR] Weapon issue failed: " .. tostring(issued.code) .. " " .. tostring(issued.message))
			NotifyClient(source, _U("FailedToAddWeapon"), 4000, "error")
			return cb(false)
		end
		DB.exec("DELETE FROM bcc_crafting_log WHERE id = ?", craftingLog.id)
		NotifyClient(source, _U("CollectedWeapon") .. itemLabel, 4000, "success")
		AwardXP(source, playerId, rewardXP)
		Discord:sendMessage(string.format(
			"**Crafting Completion**\n\n**Player:** %s %s (ID: %s)\n**Crafted Weapon:** %s\n**XP Gained:** %d XP\n**Weapon Collected Successfully**",
			firstname, lastname, playerId, itemLabel, rewardXP))
		return cb(true)
	end

	-- Regular items: give as many as fit now; the rest stays to collect later.
	if not CraftInventory.Definition(itemName) then
		NotifyClient(source, "Item data not found for item: " .. itemLabel, 4000, "error")
		return cb(false)
	end
	local addableAmount = math.min(amountToAdd, getAvailableSpace(source, itemName))
	local partialAmount = CraftInventory.CarryableAmount(source, itemName, addableAmount)
	if partialAmount <= 0 then
		NotifyClient(source, _U("NotEnoughSpace") .. amountToAdd .. "x " .. itemLabel .. ".", 4000, "error")
		return cb(false)
	end

	local granted = CraftInventory.Grant(source, itemName, partialAmount)
	if not granted.ok then
		devPrint("[ERROR] Grant failed: " .. tostring(granted.code))
		NotifyClient(source, _U("NotEnoughSpace") .. amountToAdd .. "x " .. itemLabel .. ".", 4000, "error")
		return cb(false)
	end

	local remainingAmount = amountToAdd - partialAmount
	if remainingAmount > 0 then
		DB.exec("UPDATE bcc_crafting_log SET itemAmount = ? WHERE id = ?", remainingAmount, craftingLog.id)
		NotifyClient(source, _U("CollectedPartially") .. partialAmount .. "x " .. itemLabel .. ".", 4000, "success")
	else
		DB.exec("DELETE FROM bcc_crafting_log WHERE id = ?", craftingLog.id)
		NotifyClient(source, _U("CollectedCraftedItem") .. partialAmount .. "x " .. itemLabel .. ".", 4000, "success")
	end

	local totalXP = rewardXP * partialAmount
	AwardXP(source, playerId, totalXP)
	Discord:sendMessage(string.format(
		"**Crafting Completion**\n\n**Player:** %s %s (ID: %s)\n**Crafted Item:** %s x%d\n**XP Gained:** %d XP\n**Item Collected Successfully**",
		firstname, lastname, playerId, itemLabel, partialAmount, totalXP))
	cb(true)
end)

-- Function to get available space for an item in player's inventory
function getAvailableSpace(source, itemName)
	local itemData = CraftInventory.Definition(itemName)
	if not itemData then
		devPrint("[ERROR] Item data not found for item: " .. itemName)
		return 0
	end
	local itemLimit = tonumber(itemData.max_quantity)
	if not itemLimit or itemLimit <= 0 then return math.huge end
	return math.max(itemLimit - CraftInventory.Count(source, itemName), 0)
end

-- Register the RPC for getting crafting data
FeatherRPC:Register("bcc-crafting:GetCraftingData", function(params, cb, recSource)
	local char = CraftCharacters.Get(recSource)
	if not char then return cb(false) end

	local playerId = char.charIdentifier
	local queryOk, result = pcall(DB.query,
		"SELECT currentXP, currentLevel FROM bcc_craft_progress WHERE charidentifier = ?", playerId)
	if not queryOk or not result or #result == 0 then
		pcall(DB.exec, "INSERT INTO bcc_craft_progress (charidentifier, currentXP, currentLevel) VALUES (?, 0, 1)", playerId)
		return cb({
			level = 1,
			xpToNextLevel = Config.LevelThresholds[1].xpPerLevel,
			categories = params.categories or {},
		})
	end

	local currentXP = result[1].currentXP
	local level = result[1].currentLevel
	local xpForNextLevel = 0
	for _, threshold in ipairs(Config.LevelThresholds) do
		if level >= threshold.minLevel and level <= threshold.maxLevel then
			xpForNextLevel = threshold.xpPerLevel
			break
		end
	end
	if xpForNextLevel == 0 then return cb(false) end

	local xpToNextLevel = xpForNextLevel - (currentXP % xpForNextLevel)
	return cb({
		level = level,
		xpToNextLevel = math.max(0, xpToNextLevel),
		categories = params.categories or {},
	})
end)

-- Function to add player crafting XP
function AddPlayerCraftingXP(playerId, amount, callback)
	devPrint("Adding XP for player:" .. playerId .. " Amount:" .. amount)

	GetPlayerCraftingData(playerId, function(xp, lastLevel)
		xp = xp + amount
		local newLevel, remainingXP = CalculateIncrementalLevel(xp, lastLevel)
		pcall(DB.exec,
			"UPDATE bcc_craft_progress SET currentXP = ?, currentLevel = ?, lastLevel = ? WHERE charidentifier = ?",
			remainingXP, newLevel, newLevel, playerId
		)
		if newLevel > lastLevel then
			callback(newLevel)
		else
			callback(nil)
		end
	end)
end

-- Function to get player crafting data (XP and level)
function GetPlayerCraftingData(playerId, callback)
	local ok, result = pcall(DB.query,
		"SELECT currentXP, currentLevel FROM bcc_craft_progress WHERE charidentifier = ?", playerId)
	if ok and result and #result > 0 then
		callback(result[1].currentXP, result[1].currentLevel)
	else
		pcall(DB.insert, "INSERT INTO bcc_craft_progress (charidentifier, currentXP, currentLevel) VALUES (?, 0, 1)", playerId)
		callback(0, 1)
	end
end

-- Calculate the player's level and remaining XP based on dynamic LevelThresholds
function CalculateLevelFromXP(xp)
	local level = 1
	local remainingXP = xp

	for _, threshold in ipairs(Config.LevelThresholds) do
		local xpForRange = (threshold.maxLevel - threshold.minLevel + 1) * threshold.xpPerLevel
		if remainingXP >= xpForRange then
			remainingXP = remainingXP - xpForRange
			level = threshold.maxLevel + 1
		else
			level = threshold.minLevel + math.floor(remainingXP / threshold.xpPerLevel)
			remainingXP = remainingXP % threshold.xpPerLevel
			break
		end
	end

	return level, remainingXP
end

-- Calculate the incremental level and remaining XP
function CalculateIncrementalLevel(xp, lastLevel)
	local level = lastLevel
	local remainingXP = xp

	for _, threshold in ipairs(Config.LevelThresholds) do
		if level >= threshold.minLevel and level <= threshold.maxLevel then
			local xpPerLevel = threshold.xpPerLevel
			while remainingXP >= xpPerLevel do
				remainingXP = remainingXP - xpPerLevel
				level = level + 1
				if level > threshold.maxLevel then
					break
				end
			end
			if remainingXP < xpPerLevel then
				break
			end
		end
	end

	return level, remainingXP
end

-- Register usable items for crafting books (once feather-inventory is ready)
local function RegisterCraftBooks()
	for _, location in ipairs(CraftingLocations) do
		-- Register book for the whole location
		if location.craftbookCategory and location.craftbookCategory ~= "" then
			local registered = CraftInventory.RegisterUsable(location.craftbookCategory, function(_, src)
				CraftInventory.Close(src)
				FeatherRPC:Notify("bcc-crafting:craftbook:useLocation", {
					locationLabel = location.blip.label or "Crafting",
					locationId = location.locationId,
					categories = location.categories
				}, src)
				return { ok = true }
			end)
			if not registered.ok then print("[bcc-craft] book registration failed: " .. location.craftbookCategory) end
		end

		-- Register individual category books as fallback
		for _, category in ipairs(location.categories) do
			category.locationId = location.locationId
			local craftBookItem = category.craftBookItem
			if craftBookItem and craftBookItem ~= "" then
				local registered = CraftInventory.RegisterUsable(craftBookItem, function(_, src)
					CraftInventory.Close(src)
					FeatherRPC:Notify("bcc-crafting:craftbook:use", category, src)
					return { ok = true }
				end)
				if not registered.ok then print("[bcc-craft] book registration failed: " .. craftBookItem) end
			end
		end
	end
end

CreateThread(function()
	local ready = Craft.Call('feather-inventory', 'AwaitReady', 30000)
	if not ready.ok then return print("[bcc-craft] feather-inventory is not ready; craft books are not usable.") end
	RegisterCraftBooks()
end)

AddEventHandler("onResourceStart", function(resource)
	if resource == "feather-inventory" then
		CreateThread(function()
			Craft.Call('feather-inventory', 'AwaitReady', 30000)
			RegisterCraftBooks()
		end)
	end
end)

-- Register the RPC for getting item limit
FeatherRPC:Register("bcc-crafting:getItemLimit", function(params, cb, source)
	local itemName = params.itemName
	if type(itemName) ~= "string" or itemName == "" then return cb("N/A") end
	local definition = CraftInventory.Definition(itemName)
	local limit = definition and tonumber(definition.max_quantity)
	if limit and limit > 0 then cb(limit) else cb("N/A") end
end)

-- Register the RPC for getting weapon limit
FeatherRPC:Register("bcc-crafting:getWeaponLimit", function(params, cb, source)
	local Character = CraftCharacters.Get(source)
	if not Character then return cb(false) end
	cb(CraftInventory.WeaponCount(Character.charIdentifier) < Config.maxWeaponsAllowed)
end)

FeatherRPC:Register('bcc-crafting:GetMaxCraftAmount', function(params, cb, source)
	local requested = type(params) == "table" and params.item
	local item = type(requested) == "table" and FindRecipe(params.locationId, requested.itemName)
	if not item or not CraftCharacters.Get(source) then return cb(0) end

	local maxCraftable = math.huge
	for _, reqItem in ipairs(item.requiredItems) do
		local has = CraftInventory.Count(source, reqItem.itemName)
		if reqItem.removeItem then
			if reqItem.itemCount > 0 then
				maxCraftable = math.min(maxCraftable, math.floor(has / reqItem.itemCount))
			end
		elseif has <= 0 then
			maxCraftable = 0 -- No tool = cannot craft at all
			break
		end
	end
	if maxCraftable == math.huge then maxCraftable = 0 end
	cb(maxCraftable)
end)

-- Function to update crafting status
function updateCraftingStatus(craftingId, status)
	local completedAt = status == "completed" and os.date("%Y-%m-%d %H:%M:%S") or nil
	DB.exec("UPDATE bcc_crafting_log SET status = ?, completed_at = ? WHERE id = ?", status, completedAt, craftingId)
end

-- Function to get itemAmount from CraftingLocations based on itemName
function getConfigItemAmount(itemName)
	local item = FindRecipe(nil, itemName)
	if item then return item.itemAmount end
	devPrint("[ERROR] Item not found in CraftingLocations: " .. tostring(itemName))
	return nil
end

-- Craft books: only books configured on a location or category can be given,
-- and their price comes from that config.
FeatherRPC:Register("bcc-crafting:giveBook", function(data, cb, source)
	local itemName = type(data) == "table" and data.item
	if type(itemName) ~= "string" then return cb(false) end

	local found, priceEnabled, goldCost, moneyCost, itemLabel = false, false, 0, 0, itemName
	for _, location in ipairs(CraftingLocations) do
		if location.craftbookCategory == itemName then
			found, itemLabel = true, location.blip and location.blip.label or itemName
			priceEnabled = location.craftbookprice == true
			goldCost, moneyCost = location.craftbookpricegold, location.craftbookpricemoney
			break
		end
		for _, category in ipairs(location.categories) do
			if category.craftBookItem == itemName then
				found, itemLabel = true, category.label or itemName
				priceEnabled = category.craftbookprice == true
				goldCost, moneyCost = category.craftbookpricegold, category.craftbookpricemoney
				break
			end
		end
		if found then break end
	end
	if not found then return cb(false) end
	if type(data.label) == "string" and #data.label <= 100 then itemLabel = data.label end
	local amount = 1

	if priceEnabled and (not goldCost or not moneyCost) then
		NotifyClient(source, _U("priceForCraftBookNotSet"), 5000, "error")
		return cb(false)
	end

	local char = CraftCharacters.Get(source)
	if not char then return cb(false) end

	if CraftInventory.CarryableAmount(source, itemName, amount) < amount then
		NotifyClient(source, _U("notEnoughSpaceForBook", itemLabel), 4000, "error")
		return cb(false)
	end

	-- Character XP requirements (craftbookpricexp) have no Feather source yet and are not checked.
	if priceEnabled then
		local paid = CraftEconomy.Pay(char, moneyCost, goldCost, itemName)
		if not paid.ok then
			if paid.code == "insufficient_funds" then
				NotifyClient(source, _U("notEnoughMoneyGoldForBook", moneyCost, goldCost, itemLabel), 5000, "error")
			else
				NotifyClient(source, _U("CraftingAttemptFailed"), 5000, "error")
			end
			return cb(false)
		end
	end

	local granted = CraftInventory.Grant(source, itemName, amount)
	if not granted.ok then
		print(("[bcc-craft] book %s paid but not granted to %s: %s"):format(itemName, char.charIdentifier, tostring(granted.code)))
		NotifyClient(source, _U("notEnoughSpaceForBook", itemLabel), 4000, "error")
		return cb(false)
	end

	if priceEnabled then
		NotifyClient(source, _U("receivedBookPaid", amount, itemLabel, moneyCost, goldCost), 5000, "success")
	else
		NotifyClient(source, _U("receivedBookFree", amount, itemLabel), 5000, "success")
	end

	local message = _U("craftbookDiscordTitle") .. "\n\n"
		.. _U("craftbookDiscordPlayer", char.firstname, char.lastname, source) .. "\n"
		.. _U("craftbookDiscordItem", itemLabel, amount) .. "\n"
	if priceEnabled then
		message = message .. _U("craftbookDiscordGold", goldCost) .. "\n" .. _U("craftbookDiscordMoney", moneyCost)
	else
		message = message .. _U("craftbookDiscordFree")
	end
	Discord:sendMessage(message)
	cb(true)
end)

AddEventHandler("playerDropped", function()
	activeCrafting[source] = nil
end)

-- Read-only release check, server console only.
RegisterCommand("CraftReleaseSmokeTest", function(source)
	if source ~= 0 then return end
	local jobs = Craft.Call("feather-jobs", "CheckAssignment", { characterId = "00000000-0000-0000-0000-000000000000", jobKey = "craft_probe" })
	local sink = Craft.Call("feather-economy", "GetSystemAccount", { currency = "dollars", accountType = "system_sink" })
	local missingItems, missingBooks, unmappedWeapons = {}, {}, {}
	for _, location in ipairs(CraftingLocations) do
		if location.craftbookCategory and location.craftbookCategory ~= "" and not CraftInventory.Definition(location.craftbookCategory) then
			missingBooks[#missingBooks + 1] = location.craftbookCategory
		end
		for _, category in ipairs(location.categories) do
			if category.craftBookItem and category.craftBookItem ~= "" and not CraftInventory.Definition(category.craftBookItem) then
				missingBooks[#missingBooks + 1] = category.craftBookItem
			end
			for _, item in ipairs(category.items) do
				if IsWeapon(item.itemName) then
					if not CraftWeapons.DefinitionId(item.itemName) then unmappedWeapons[#unmappedWeapons + 1] = item.itemName end
				elseif not CraftInventory.Definition(item.itemName) then
					missingItems[#missingItems + 1] = item.itemName
				end
			end
		end
	end
	local tests = {
		{ "development disabled", Config.devMode == false },
		{ "jobs trust", jobs.ok == true },
		{ "economy reachable", sink.ok == true },
		{ "craft books defined", #missingBooks == 0 },
		{ "recipe items defined", #missingItems == 0 },
		{ "recipe weapons mapped", #unmappedWeapons == 0 },
	}
	local passed = 0
	for _, test in ipairs(tests) do
		if test[2] then passed = passed + 1 end
		print(("[CraftReleaseSmokeTest] %-22s %s"):format(test[1], test[2] and "PASS" or "FAIL"))
	end
	if #missingBooks > 0 then print("[CraftReleaseSmokeTest] missing books: " .. table.concat(missingBooks, ", ")) end
	if #missingItems > 0 then print("[CraftReleaseSmokeTest] missing items: " .. table.concat(missingItems, ", ")) end
	if #unmappedWeapons > 0 then print("[CraftReleaseSmokeTest] weapons without a feather-weapons definition: " .. table.concat(unmappedWeapons, ", ")) end
	print(("[CraftReleaseSmokeTest] done %d/%d passed (read-only)"):format(passed, #tests))
end, true)
