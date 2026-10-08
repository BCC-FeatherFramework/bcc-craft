CreatedBlip = {}
CreatedNpc = {}
myCampfire = nil

CreateThread(function()
    devPrint("Thread started") -- Devprint

    -- Prompt through feather-toolkit
    local CraftingMenuPrompt = GetRandomIntInRange(0, 0xffffff)
    local created = Toolkit:CreatePrompt({ control = 0x760A9C6F, label = _U('PromptName'), groupId = CraftingMenuPrompt })
    local craftingprompt = type(created) == 'table' and created.ok and created.value.id or nil

    -- Iterate over CraftingLocations from the config
    for _, location in pairs(CraftingLocations) do
        if type(location.coords) == "table" and type(location.NpcHeading) == "table" then
            for i, coord in ipairs(location.coords) do
                local heading = location.NpcHeading[i]

                -- Blip handling
                if location.blip and location.blip.show then
                    local blip = Toolkit:CreateBlip({ name = location.blip.label, sprite = location.blip.sprite,
                        x = coord.x, y = coord.y, z = coord.z })
                    if type(blip) == 'table' and blip.ok then
                        if location.blip.color then
                            Citizen.InvokeNative(0x662D364ABF16DE2F, blip.value.handle, joaat(location.blip.color)) -- BlipAddModifier
                        end
                        CreatedBlip[#CreatedBlip + 1] = blip.value.id
                    end
                else
                    devPrint("Blips disabled for location: " .. tostring(coord))
                end

                -- NPC handling
                if location.npc and location.npc.show then
                    local ped = Toolkit:CreatePed({ model = location.npc.model, x = coord.x, y = coord.y, z = coord.z - 1,
                        heading = heading, networked = false })
                    if type(ped) == 'table' and ped.ok then
                        local handle = ped.value.entity
                        FreezeEntityPosition(handle, true)
                        SetEntityInvincible(handle, true)
                        SetBlockingOfNonTemporaryEvents(handle, true)
                        CreatedNpc[#CreatedNpc + 1] = ped.value.id
                    end
                else
                    devPrint("NPCs disabled for location: " .. tostring(coord))
                end
            end
        else
            devPrint("Error: 'coords' or 'NpcHeading' is not a table for location.")
        end
    end

    -- Main prompt loop
    while true do
        ::CONTINUE::
        local playerPed = PlayerPedId()

        if IsEntityDead(playerPed) then
            -- Wait while dead to avoid spamming loop
            Citizen.Wait(1000)
            goto CONTINUE
        end

        local playerCoords = GetEntityCoords(playerPed)

        for _, location in pairs(CraftingLocations) do
            if type(location.coords) == "table" then
                for _, coord in ipairs(location.coords) do
                    local dist = #(playerCoords - coord)
                    if dist < 2 then
                        currentCraftingLocationId = location.locationId
                        Toolkit:ShowPromptGroup(CraftingMenuPrompt, location.blip.label)

                        local completed = craftingprompt and Toolkit:IsPromptCompleted(craftingprompt)
                        if type(completed) == 'table' and completed.ok and completed.value.completed then
                            devPrint("Crafting prompt has been completed")
                            TriggerEvent('bcc-crafting:openmenu', location.categories)
                        end
                    end
                end
            end
        end

        Wait(5)
    end
end)

FeatherRPC:Register("bcc-crafting:craftbook:use", function(category, cb)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)

    currentCraftingLocationId = category.locationId or "unknown"

    -- Spawn campfire
    local model = category.campfireModel
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end

    local offset = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 1.0, 0.0)
    myCampfire = CreateObject(model, offset.x, offset.y, offset.z, true, false, true)
    PlaceObjectOnGroundProperly(myCampfire)
    SetEntityHeading(myCampfire, GetEntityHeading(playerPed))
    SetEntityAsMissionEntity(myCampfire, true, true)

    -- Setup animation
    local time = category.setupTime
    local dict = category.setupAnimDict
    local anim = category.setupAnimName
    local scenario = category.setupScenario
    local text = _U("PreparingCampFire")

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(100) end

    FreezeEntityPosition(playerPed, true)
    TaskPlayAnim(playerPed, dict, anim, 8.0, 8.0, -1, 1, 0, true, 0, false, 0, false)
    progressbar.start(text, time, function() end, "innercircle")
    Wait(time)
    StopAnimTask(playerPed, dict, anim)
    FreezeEntityPosition(playerPed, false)

    -- Scenario after setup
    TaskStartScenarioInPlace(playerPed, scenario, -1, true, false, false, false)

    -- Open the crafting menu
    TriggerEvent("bcc-crafting:openmenu", { category })

    if cb then cb(true) end
end)

FeatherRPC:Register("bcc-crafting:craftbook:useLocation", function(data, cb)
    currentCraftingLocationId = data.locationId

    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)

    -- Campfire setup
    local model = "p_campfire03x"
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end

    local offset = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 1.0, 0.0)
    myCampfire = CreateObject(model, offset.x, offset.y, offset.z, true, false, true)
    PlaceObjectOnGroundProperly(myCampfire)
    SetEntityHeading(myCampfire, GetEntityHeading(playerPed))
    SetEntityAsMissionEntity(myCampfire, true, true)

    -- Animation
    local time = 5000
    local dict = "mini_games@story@beechers@build_floor@john"
    local anim = "hammer_loop_good"
    local scenario = "WORLD_HUMAN_WRITE_NOTEBOOK"
    local text = _U("PreparingCampFire")

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(100) end

    FreezeEntityPosition(playerPed, true)
    TaskPlayAnim(playerPed, dict, anim, 8.0, 8.0, -1, 1, 0, true, 0, false, 0, false)
    progressbar.start(text, time, function() end, "innercircle")
    Wait(time)
    StopAnimTask(playerPed, dict, anim)
    FreezeEntityPosition(playerPed, false)

    -- Scenario
    TaskStartScenarioInPlace(playerPed, scenario, -1, true, false, false, false)

    -- Open menu
    TriggerEvent("bcc-crafting:openmenu", data.categories)

    if cb then cb(true) end
end)

-- Cleanup when the resource stops
AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        -- feather-toolkit also releases owned blips and peds when this resource stops.
        for _, id in pairs(CreatedBlip) do
            Toolkit:RemoveBlip(id)
        end
        for _, id in pairs(CreatedNpc) do
            Toolkit:RemoveEntity(id)
        end
        BCCCraftingMenu:Close()
        -- Remove campfire if it exists
        if myCampfire and DoesEntityExist(myCampfire) then
            NetworkRequestControlOfEntity(myCampfire)
            while not NetworkHasControlOfEntity(myCampfire) do
                Wait(10)
            end
            DeleteObject(myCampfire)
            myCampfire = nil
            devPrint("🔥 Campfire cleaned up on resource stop.")
            ClearPedTasksImmediately(PlayerPedId())
        end
    end
end)
