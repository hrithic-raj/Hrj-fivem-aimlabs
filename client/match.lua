-- client/match.lua
local isInMatch = false
local score = 0
local currentBot = nil
local spawnedBotEntities = {}
local QBCore = exports['qb-core']:GetCoreObject()

local function ShowSubtitle(msg, time)
    BeginTextCommandPrint("STRING")
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandPrint(time or 2000, 1)
end

-- Server tells client to start match with chosen options
RegisterNetEvent("aimlabs:client:StartMatch", function(payload)
    if isInMatch then
        QBCore.Functions.Notify("Match already running.", "error")
        return
    end

    isInMatch = true
    score = 0

    local diff = payload.difficulty or "Easy"
    local weapon = payload.weapon or Config.Weapons[1]
    local timeVisible = Config.Difficulties[diff].botVisibleTime or 2000
    local player = PlayerPedId()

    -- Teleport player to arena
    SetEntityCoords(player, Config.Arena.playerSpawn.x, Config.Arena.playerSpawn.y, Config.Arena.playerSpawn.z)
    SetEntityHeading(player, Config.Arena.playerSpawn.w)
    ClearPedTasksImmediately(player)

    -- Give weapon + infinite ammo (client-side)
    local hashWep = GetHashKey(weapon)
    GiveWeaponToPed(player, hashWep, 9999, false, true)
    SetPedAmmo(player, hashWep, 9999)
    -- Prevent weapon from being removed when leaving by not setting drops (cleanup later)

    -- Countdown
    for i = 3, 1, -1 do
        ShowSubtitle("Starting in ~y~" .. i .. "~s~...", 1000)
        Wait(1000)
    end

    -- Sequential spawn loop (client asks server for positions)
    for i = 1, Config.MatchBotCount do
        -- Request spawn pos from server (server returns by event aimlabs:client:SpawnBot)
        TriggerServerEvent("aimlabs:server:RequestBotPos")
        print("[DEBUG] Requested bot spawn from server...") 
        -- wait until server sends SpawnBot event and currentBot is set
        local startTime = GetGameTimer()
        local killed = false

        -- wait until currentBot is set by server event
        local waitStart = GetGameTimer()
        while not currentBot and (GetGameTimer() - waitStart) < 2000 do Wait(0) end

        -- if no bot arrived, skip
        if not currentBot then
            QBCore.Functions.Notify("Failed to spawn bot, skipping...", "error")
            goto continueBotLoop
        end

        -- loop until bot dies or time exceeded
        while (GetGameTimer() - startTime) < timeVisible do
            Wait(0)
            if not DoesEntityExist(currentBot) then
                killed = true
                break
            end
        end

        -- cleanup bot if still exists
        if DoesEntityExist(currentBot) then
            DeleteEntity(currentBot)
        end

        if killed then score = score + 1 end

        ::continueBotLoop::
        currentBot = nil
        Wait(250) -- small pause between bots
    end

    -- Match finished
    ShowSubtitle("~g~Match Finished! Score: "..score.."/"..Config.MatchBotCount, 5000)

    -- Send score to server for potential saving/logging
    TriggerServerEvent("aimlabs:server:SubmitScore", score)

    -- Teleport player back to menu ped
    SetEntityCoords(player, Config.MenuPed.coords.x, Config.MenuPed.coords.y, Config.MenuPed.coords.z)
    SetEntityHeading(player, Config.MenuPed.coords.w)

    -- cleanup
    isInMatch = false
    score = 0
    currentBot = nil
end)

-- Server gave us a bot spawn position — spawn it locally and set currentBot
RegisterNetEvent("aimlabs:client:SpawnBot", function(botPos)
    print("[DEBUG] aimlabs:client:SpawnBot triggered with coords", botPos.x, botPos.y, botPos.z)
    if not botPos then return end
    local model = GetHashKey(Config.BotModel)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    local ped = CreatePed(4, model, botPos.x, botPos.y, botPos.z, botPos.w, true, true)
    SetEntityInvincible(ped, false)
    SetPedArmour(ped, Config.BotArmor)
    SetEntityHealth(ped, Config.BotHealth)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskStandStill(ped, -1)

    -- Make ped face the player spawn area
    local dir = vector3(Config.Arena.playerSpawn.x, Config.Arena.playerSpawn.y, Config.Arena.playerSpawn.z) - vector3(botPos.x, botPos.y, botPos.z)
    local heading = GetHeadingFromVector_2d(dir.x, dir.y)
    SetEntityHeading(ped, heading)

    currentBot = ped
    table.insert(spawnedBotEntities, ped)

    -- DEBUG:
    print(("[DEBUG] Spawned match bot at %.2f, %.2f, %.2f"):format(botPos.x, botPos.y, botPos.z))
end)

-- Server told client to forcefully leave (cleanup)
RegisterNetEvent("aimlabs:client:ForceLeave", function()
    -- Cleanup spawned bots
    for _, ped in ipairs(spawnedBotEntities) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
    spawnedBotEntities = {}

    -- Teleport back
    local player = PlayerPedId()
    SetEntityCoords(player, Config.MenuPed.coords.x, Config.MenuPed.coords.y, Config.MenuPed.coords.z)
    SetEntityHeading(player, Config.MenuPed.coords.w)
    isInMatch = false
    currentBot = nil
    QBCore.Functions.Notify("You have left the AimLabs session.", "success")
end)
