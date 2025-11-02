-- client/main.lua
local menuPed = nil
local spawnedDebugPeds = {} -- DEBUG: store peds created by test commands

-- Create the menu NPC and add qb-target interaction
CreateThread(function()
    local pedData = Config.MenuPed
    local modelHash = GetHashKey(pedData.model)
    print("[DEBUG] Loading ped model:", pedData.model)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(0)
    end

    menuPed = CreatePed(4, modelHash, pedData.coords.x, pedData.coords.y, pedData.coords.z - 1.0, pedData.coords.w, false, true)
    SetEntityInvincible(menuPed, true)
    SetBlockingOfNonTemporaryEvents(menuPed, true)
    FreezeEntityPosition(menuPed, true)
    SetEntityAsMissionEntity(menuPed, true, true)

    -- Add qb-target interaction
    exports['qb-target']:AddTargetEntity(menuPed, {
        options = {
            {
                type = "client",
                event = "aimlabs:client:OpenMenu",
                icon = "fa-solid fa-bullseye",
                label = "Open AimLabs Menu"
            },
        },
        distance = 2.5
    })

    -- DEBUG
    print("[DEBUG] AimLabs Menu ped spawned and qb-target attached.")
end)

-- Client command to leave aimlabs (sends to server)
RegisterCommand("leaveaimlabs", function()
    TriggerServerEvent("aimlabs:server:LeaveSession")
end, false)

-- DEBUG command: spawn one test bot locally (uses server GetRandomBotPosition if you want server pos, but here quick local)
RegisterCommand("spawnnpctest", function()
    local pos = GetRandomBotPosition()
    local modelHash = GetHashKey(Config.BotModel)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do Wait(0) end
    local ped = CreatePed(4, modelHash, pos.x, pos.y, pos.z, pos.w, true, false)
    SetEntityHeading(ped, GetHeadingFromVector_2d((Config.Arena.playerSpawn.x - pos.x), (Config.Arena.playerSpawn.y - pos.y)))
    SetPedArmour(ped, Config.BotArmor)
    SetEntityHealth(ped, Config.BotHealth)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskStandStill(ped, -1)
    table.insert(spawnedDebugPeds, ped)
    print(("[DEBUG] spawnnpctest -> spawned ped at %.2f %.2f"):format(pos.x, pos.y))
end, false)

-- DEBUG command: clear debug peds spawned locally
RegisterCommand("clearnpcs", function()
    for _, p in ipairs(spawnedDebugPeds) do
        if DoesEntityExist(p) then
            DeletePed(p)
        end
    end
    spawnedDebugPeds = {}
    print("[DEBUG] clearnpcs -> cleared debug peds")
end, false)
