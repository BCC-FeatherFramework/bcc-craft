-- bcc-craft's boundaries to feather-jobs, feather-inventory, feather-weapons and
-- feather-economy. Each returns plain values or { ok, code, message } envelopes.

-- Jobs -------------------------------------------------------------------------
-- Recipes keep their requiredJobs format: 'job' or { 'job', grade }. The job is a
-- feather-jobs key and grade is the minimum grade ordinal.

CraftJobs = {}

function CraftJobs.Holds(characterId, jobKey, minGrade)
    if type(jobKey) ~= 'string' or not jobKey:match('^[a-z][a-z0-9_]*$') then return false end
    local request = { characterId = characterId, jobKey = jobKey }
    if tonumber(minGrade) and tonumber(minGrade) > 0 then request.minGradeOrdinal = math.floor(tonumber(minGrade)) end
    if Config.JobAccess and Config.JobAccess.requireOnDuty then request.dutyState = 'on_duty' end
    local result = Craft.Call('feather-jobs', 'CheckAssignment', request)
    if not result.ok then
        devPrint('[jobs] check failed:', jobKey, tostring(result.code))
        return false
    end
    return type(result.value) == 'table' and result.value.matched == true
end

-- True when the character meets one of the recipe's job entries (or there are none).
function CraftJobs.MeetsRecipe(characterId, requiredJobs)
    if type(requiredJobs) ~= 'table' or #requiredJobs == 0 then return true end
    for _, allowed in ipairs(requiredJobs) do
        local job, grade = allowed, 0
        if type(allowed) == 'table' then
            job = allowed[1] or allowed.job or allowed.name
            grade = tonumber(allowed[2] or allowed.grade or allowed.rank or 0) or 0
        end
        if CraftJobs.Holds(characterId, job, grade) then return true end
    end
    return false
end

-- Inventory --------------------------------------------------------------------

CraftInventory = {}
local api
local definitions -- name -> definition row

local function Api()
    if api then return api end
    if GetResourceState('feather-inventory') ~= 'started' then return nil end
    local called, value = pcall(function() return exports['feather-inventory']:initiate() end)
    api = called and type(value) == 'table' and value or nil
    return api
end

AddEventHandler('onResourceStart', function(resource)
    if resource == 'feather-inventory' then api, definitions = nil, nil end
end)

local function Flat(result)
    if type(result) == 'table' and result.ok then return result end
    local problem = type(result) == 'table' and (type(result.error) == 'table' and result.error or result) or {}
    return Craft.Err(problem.code or 'inventory_failed', problem.message)
end

-- The item definition (max_quantity, display_name, ...) or nil.
function CraftInventory.Definition(itemName)
    if not definitions then
        local inventory = Api()
        local result = inventory and inventory.Items.GetDefinitions()
        if type(result) ~= 'table' or not result.ok then return nil end
        definitions = {}
        for _, row in ipairs(result.value or {}) do definitions[row.name] = row end
    end
    return definitions[itemName]
end

function CraftInventory.Count(src, itemName)
    local inventory = Api()
    if not inventory or type(itemName) ~= 'string' then return 0 end
    local result = inventory.Items.GetItemCount(itemName, src)
    if type(result) ~= 'table' or not result.ok then return 0 end
    return tonumber(result.value) or 0
end

function CraftInventory.Remove(src, itemName, quantity)
    local inventory = Api()
    if not inventory then return Craft.Err('dependency_unavailable', 'Inventory API is unavailable.') end
    return Flat(inventory.Items.RemoveItemByName(itemName, quantity, src))
end

-- Largest quantity (up to `wanted`) the player's inventory can accept now.
function CraftInventory.CarryableAmount(src, itemName, wanted)
    local inventory = Api()
    wanted = math.floor(tonumber(wanted) or 0)
    if not inventory or wanted < 1 then return 0 end
    local function fits(quantity)
        local result = inventory.Inventory.InventoryCanHold({ { item = itemName, quantity = quantity } }, src)
        return type(result) == 'table' and result.ok == true
            and type(result.value) == 'table' and result.value.accepted == true
    end
    if fits(wanted) then return wanted end
    local low, high = 0, wanted - 1
    while low < high do
        local middle = math.ceil((low + high) / 2)
        if fits(middle) then low = middle else high = middle - 1 end
    end
    return low
end

function CraftInventory.Grant(src, itemName, quantity)
    local inventory = Api()
    if not inventory then return Craft.Err('dependency_unavailable', 'Inventory API is unavailable.') end
    return Flat(inventory.Items.GrantItem(itemName, quantity, src))
end

local function CharacterItems(characterId)
    local inventory = Api()
    if not inventory then return {} end
    local found = inventory.Inventory.GetCharacterInventory(characterId)
    if type(found) ~= 'table' or not found.ok or type(found.value) ~= 'table' then return {} end
    local items = inventory.Inventory.GetInventoryItems(found.value.id)
    return type(items) == 'table' and items.ok and items.value or {}
end

-- Weapons the character carries (feather-weapons items are named weapon_*).
function CraftInventory.WeaponCount(characterId)
    local count = 0
    for _, row in ipairs(CharacterItems(characterId)) do
        if type(row.name) == 'string' and row.name:sub(1, 7) == 'weapon_' then count = count + 1 end
    end
    return count
end

-- Wears one tool instance by `use` out of `max` durability. A tool whose
-- definition does not track condition (stackable) is not worn. Returns
-- 'worn', 'broken' or 'untracked', or nil and an error code.
function CraftInventory.WearTool(characterId, itemName, use, max)
    local inventory = Api()
    if not inventory then return nil, 'dependency_unavailable' end
    local instanceId
    for _, row in ipairs(CharacterItems(characterId)) do
        if row.name == itemName then instanceId = tonumber(row.id) break end
    end
    if not instanceId then return nil, 'not_found' end

    -- Inventory condition is 0-100; recipe durability is use out of max.
    local drop = math.max(1, math.floor((tonumber(use) or 0) / math.max(1, tonumber(max) or 100) * 100 + 0.5))
    local current = inventory.Items.GetCondition(instanceId)
    local value = type(current) == 'table' and current.ok and tonumber(current.value) or 100
    local remaining = value - drop
    if remaining <= 0 then
        local removed = Flat(inventory.Items.RemoveItemById(instanceId))
        if not removed.ok then return nil, removed.code end
        return 'broken'
    end
    local set = inventory.Items.SetCondition(instanceId, remaining)
    if type(set) == 'table' and not set.ok then
        local code = type(set.error) == 'table' and set.error.code or set.code
        if code == 'condition_not_supported' then return 'untracked' end
        return nil, code
    end
    return 'worn'
end

function CraftInventory.RegisterUsable(itemName, callback)
    local inventory = Api()
    if not inventory then return Craft.Err('dependency_unavailable', 'Inventory API is unavailable.') end
    return Flat(inventory.Items.RegisterUsableItem(itemName, callback))
end

function CraftInventory.Close(src)
    local inventory = Api()
    if inventory then inventory.Inventory.CloseInventory(src) end
end

-- Weapons ----------------------------------------------------------------------
-- Recipes name weapons by their native name (WEAPON_REVOLVER_CATTLEMAN); the
-- matching feather-weapons definition is found by nativeWeaponName.

CraftWeapons = {}
local weaponIds -- NATIVE_NAME -> definition id

function CraftWeapons.DefinitionId(nativeName)
    if not weaponIds then
        if GetResourceState('feather-weapons') ~= 'started' then return nil end
        local ok, weapons = pcall(function() return exports['feather-weapons']:initiate() end)
        if not ok or type(weapons) ~= 'table' then return nil end
        local list = weapons.Definitions.List('weapon')
        if type(list) == 'table' and list.ok ~= nil then list = list.ok and list.value or {} end
        weaponIds = {}
        for key, definition in pairs(list or {}) do
            if type(definition) == 'table' and type(definition.nativeWeaponName) == 'string' then
                weaponIds[definition.nativeWeaponName:upper()] = definition.id or key
            end
        end
    end
    return weaponIds[tostring(nativeName):upper()]
end

AddEventHandler('onResourceStart', function(resource)
    if resource == 'feather-weapons' then weaponIds = nil end
end)

-- Issues one crafted weapon. The crafting log ID makes a retry return the same weapon.
function CraftWeapons.Issue(src, character, nativeName, craftingId)
    local definitionId = CraftWeapons.DefinitionId(nativeName)
    if not definitionId then return Craft.Err('weapon_unknown', 'No feather-weapons definition for ' .. tostring(nativeName)) end
    local issued = Craft.Call('feather-weapons', 'IssueWeapon', {
        characterId = character.charIdentifier,
        definitionId = definitionId,
        purpose = 'crafting',
        requestId = ('bcc-craft:%s'):format(tostring(craftingId)),
        provenance = { type = 'crafting', reference = tostring(craftingId) }
    }, {
        actorSource = src,
        actorCharacterId = character.charIdentifier,
        characterId = character.charIdentifier,
        reason = 'crafting'
    })
    if issued.ok then return issued end
    local problem = type(issued.error) == 'table' and issued.error or issued
    return Craft.Err(problem.code or 'weapon_issue_failed', problem.message)
end

-- Economy ----------------------------------------------------------------------
-- Craft book prices are whole dollars and gold; Economy amounts are minor units.

CraftEconomy = {}

local function Wallets(characterId)
    local result = Craft.Call('feather-economy', 'EnsureCharacterWallets', { characterId = characterId })
    if not result.ok then return result end
    local wallets = {}
    for _, account in ipairs(result.value) do
        if account.accountType == 'wallet' then wallets[account.currency] = account end
    end
    return Craft.Ok(wallets)
end

local function Sink(currency)
    local result = Craft.Call('feather-economy', 'GetSystemAccount', { currency = currency, accountType = 'system_sink' })
    return result.ok and result.value.accountId or nil
end

-- Pays `dollars` and `gold` from the character's wallets. Balances are checked
-- first; the two currencies are separate Economy transfers.
function CraftEconomy.Pay(character, dollars, gold, reference)
    local wallets = Wallets(character.charIdentifier)
    if not wallets.ok then return wallets end
    local charges = {}
    if (tonumber(dollars) or 0) > 0 then charges[#charges + 1] = { currency = 'dollars', amount = math.floor(dollars * 100 + 0.5) } end
    if (tonumber(gold) or 0) > 0 then charges[#charges + 1] = { currency = 'gold', amount = math.floor(gold * 100 + 0.5) } end

    for _, charge in ipairs(charges) do
        local wallet = wallets.value[charge.currency]
        if not wallet or (tonumber(wallet.balance) or 0) < charge.amount then
            return Craft.Err('insufficient_funds', 'Not enough ' .. charge.currency .. '.')
        end
    end
    for _, charge in ipairs(charges) do
        local sink = Sink(charge.currency)
        if not sink then return Craft.Err('dependency_unavailable', 'Economy sink unavailable.') end
        local key = ('bcc-craft:book:%s:%s:%s'):format(reference, charge.currency, DB.value('SELECT UUID()'))
        local paid = Craft.Call('feather-economy', 'Transfer', {
            fromAccountId = wallets.value[charge.currency].accountId,
            toAccountId = sink,
            currency = charge.currency,
            amount = charge.amount,
            reasonCode = 'craft.book.purchase',
            referenceType = 'craft_book',
            referenceId = tostring(reference),
            idempotencyKey = key
        }, {
            actorCharacterId = character.charIdentifier,
            actorAccountId = character.accountId,
            correlationId = key
        })
        if not paid.ok then return paid end
    end
    return Craft.Ok(true)
end
