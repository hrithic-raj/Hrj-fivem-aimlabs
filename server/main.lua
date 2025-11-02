-- server/main.lua
local ActiveSessions = {} -- active sessions per player source
local QBCore = exports['qb-core']:GetCoreObject()

-- Utility: produce random bot position inside configured box
local function GetRandomBotPosition()
    local A, B = Config.Arena.botArea.A, Config.Arena.botArea.B
    local minX, maxX = math.min(A.x, B.x), math.max(A.x, B.x)
    local minY, maxY = math.min(A.y, B.y), math.max(A.y, B.y)
    local x = math.random(minX * 100, maxX * 100) / 100
    local y = math.random(minY * 100, maxY * 100) / 100
    local z = A.z
    local w = math.random(0, 360)
    return { x = x, y = y, z = z, w = w }
end


-- Player requests to start a match
-- RegisterNetEvent("aimlabs:server:StartMatch", function(payload)
--     local src = source
--     local ply = QBCore.Functions.GetPlayer(src)

--     if ActiveSessions[src] then
--         TriggerClientEvent('QBCore:Notify', src, "You already have an active AimLabs session.", "error")
--         print("[DEBUG] StartMatch blocked - player already has active session: " .. tostring(src))
--         return
--     end

--     ActiveSessions[src] = true
--     local difficulty = payload and payload.difficulty or "Easy"
--     local weapon = payload and payload.weapon or Config.Weapons[1]

--     -- Pass starting info to client
--     TriggerClientEvent("aimlabs:client:StartMatch", src, { difficulty = difficulty, weapon = weapon })
--     print(("[DEBUG] Session started for %d (diff=%s, wep=%s)"):format(src, difficulty, weapon))
-- end)


RegisterNetEvent("aimlabs:server:StartMatch", function(payload)
    local src = source

    if ActiveSessions[src] then
        TriggerClientEvent('QBCore:Notify', src, "You already have an active AimLabs session.", "error")
        print("[DEBUG] StartMatch blocked - already active:", src)
        return
    end

    -- ✅ Mark player active immediately to prevent race condition
    ActiveSessions[src] = true

    local difficulty = payload and payload.difficulty or "Easy"
    local weapon = payload and payload.weapon or Config.Weapons[1]

    TriggerClientEvent("aimlabs:client:StartMatch", src, { difficulty = difficulty, weapon = weapon })
    print(("[DEBUG] AimLabs session started for %d (diff=%s, wep=%s)"):format(src, difficulty, weapon))
end)



-- Client requests a bot position (during match)
-- RegisterNetEvent("aimlabs:server:RequestBotPos", function()
--     local src = source
--     print("[DEBUG] Server received RequestBotPos from:", src)
--     if not ActiveSessions[src] then
--         -- If no active session, ignore and tell client to leave
--         TriggerClientEvent("aimlabs:client:ForceLeave", src)
--         print("[DEBUG] RequestBotPos rejected - no active session for: " .. tostring(src))
--         return
--     end

--     local pos = GetRandomBotPosition()
--     print("[DEBUG] Generated bot position:", pos.x, pos.y, pos.z)
--     TriggerClientEvent("aimlabs:client:SpawnBot", src, pos)
-- end)

-- RegisterNetEvent("aimlabs:server:RequestBotPos", function()
--     local src = source
--     print("[DEBUG] Server received RequestBotPos from:", src)

--     if not ActiveSessions[src] then
--         Wait(1000) -- small delay before re-check (race condition)
--         if not ActiveSessions[src] then
--             TriggerClientEvent("aimlabs:client:ForceLeave", src)
--             print("[DEBUG] RequestBotPos rejected - no active session for: " .. tostring(src))
--             return
--         end
--     end

--     local pos = GetRandomBotPosition()
--     print("[DEBUG] Generated bot position:", pos.x, pos.y, pos.z)
--     TriggerClientEvent("aimlabs:client:SpawnBot", src, pos)
-- end)



RegisterNetEvent("aimlabs:server:RequestBotPos", function()
    local src = source

    if not ActiveSessions[src] then
        print("[DEBUG] Ignored RequestBotPos - no session for src:", src)
        return -- ❌ Don't ForceLeave here, just ignore safely
    end

    local pos = GetRandomBotPosition()
    TriggerClientEvent("aimlabs:client:SpawnBot", src, pos)
    print(("[DEBUG] Sent bot spawn position to %d (%.2f, %.2f, %.2f)"):format(src, pos.x, pos.y, pos.z))
end)


-- Player requests to leave the session
RegisterNetEvent("aimlabs:server:LeaveSession", function()
    local src = source
    if ActiveSessions[src] then
        ActiveSessions[src] = nil
        TriggerClientEvent("aimlabs:client:ForceLeave", src)
        print("[DEBUG] Player left session: " .. tostring(src))
    else
        TriggerClientEvent('QBCore:Notify', src, "You are not in an AimLabs session.", "error")
    end
end)

-- Score submission (store/print for now)
RegisterNetEvent("aimlabs:server:SubmitScore", function(score)
    local src = source
    local playerName = GetPlayerName(src)
    print(("[AIMLABS] %s (src=%d) scored %d / %d"):format(playerName, src, score, Config.MatchBotCount))

    -- TODO: save to DB (MySQL) if you want leaderboards
end)

-- Cleanup on player disconnect
AddEventHandler("playerDropped", function(reason)
    local src = source
    if ActiveSessions[src] then
        ActiveSessions[src] = nil
        print("[DEBUG] Cleaned up AimLabs session for disconnected player: " .. tostring(src))
    end
end)
