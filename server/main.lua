-- -- server/main.lua
local ActiveSessions = {} -- active sessions per player source
local QBCore = exports['qb-core']:GetCoreObject()

-- Utility: produce random bot position inside configured box
local function GetRandomBotPosition()
    local A, B = Config.Arena.botArea.A, Config.Arena.botArea.B
    local minX, maxX = math.min(A.x, B.x), math.max(A.x, B.x)
    local minY, maxY = math.min(A.y, B.y), math.max(A.y, B.y)

    -- ✅ Convert to integers for math.random
    local intMinX = math.floor(minX * 100)
    local intMaxX = math.ceil(maxX * 100)
    local intMinY = math.floor(minY * 100)
    local intMaxY = math.ceil(maxY * 100)

    local x = math.random(intMinX, intMaxX) / 100
    local y = math.random(intMinY, intMaxY) / 100
    local z = A.z
    local w = math.random(0, 360)

    return { x = x, y = y, z = z, w = w }
end


-- ✅ DEBUG helper to print all active sessions
local function DebugPrintSessions()
    local keys = {}
    for k in pairs(ActiveSessions) do table.insert(keys, k) end
    print(("[DEBUG] ActiveSessions = [%s]"):format(table.concat(keys, ", ")))
end

-- Start match request from client
RegisterNetEvent("aimlabs:server:StartMatch", function(payload)
    local src = source
    print("[DEBUG] ➡️ StartMatch received from src:", src)

    if ActiveSessions[src] then
        TriggerClientEvent('QBCore:Notify', src, "You already have an active AimLabs session.", "error")
        print("[DEBUG] ❌ StartMatch blocked - already active:", src)
        DebugPrintSessions()
        return
    end

    ActiveSessions[src] = true
    print("[DEBUG] ✅ Marked session active for src:", src)
    DebugPrintSessions()

    local difficulty = payload and payload.difficulty or "Easy"
    local weapon = payload and payload.weapon or Config.Weapons[1]

    SetTimeout(500, function()
        TriggerClientEvent("aimlabs:client:StartMatch", src, { difficulty = difficulty, weapon = weapon })
        print(("[DEBUG] ▶️ Triggered client StartMatch for src=%d (diff=%s, wep=%s)"):format(src, difficulty, weapon))
    end)
end)

-- Client requests a bot position
RegisterNetEvent("aimlabs:server:RequestBotPos", function()
    local src = source
    print("[DEBUG] RequestBotPos received from src:", src)
    DebugPrintSessions()

    if not ActiveSessions[src] then
        print("[DEBUG] ❌ Ignored RequestBotPos - NO SESSION for src:", src)
        return
    end

    local pos = GetRandomBotPosition()
    TriggerClientEvent("aimlabs:client:SpawnBot", src, pos)
    print(("[DEBUG] ✅ Sent bot position to %d -> (%.2f, %.2f, %.2f)"):format(src, pos.x, pos.y, pos.z))
end)

-- Player leaves session manually
RegisterNetEvent("aimlabs:server:LeaveSession", function()
    local src = source
    if ActiveSessions[src] then
        ActiveSessions[src] = nil
        TriggerClientEvent("aimlabs:client:ForceLeave", src)
        print("[DEBUG] 👋 Player left AimLabs session:", src)
    else
        TriggerClientEvent('QBCore:Notify', src, "You are not in an AimLabs session.", "error")
        print("[DEBUG] ❌ LeaveSession ignored - no active session for src:", src)
    end
    DebugPrintSessions()
end)

-- Match score submission
RegisterNetEvent("aimlabs:server:SubmitScore", function(score)
    local src = source
    local playerName = GetPlayerName(src)
    print(("[AIMLABS] 🧠 %s (src=%d) scored %d / %d"):format(playerName, src, score, Config.MatchBotCount))
end)

-- Cleanup on player drop
AddEventHandler("playerDropped", function(reason)
    local src = source
    if ActiveSessions[src] then
        ActiveSessions[src] = nil
        print("[DEBUG] 🧹 Cleaned up AimLabs session for disconnected player:", src)
    end
    DebugPrintSessions()
end)

-- Command for manual debug
RegisterCommand("aimdebug", function(src)
    print("[DEBUG] Manual /aimdebug called")
    DebugPrintSessions()
end, true)
