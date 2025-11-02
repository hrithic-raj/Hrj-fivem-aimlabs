--client/menu.lua
local menuOpen = false

-- open UI from ped interaction
RegisterNetEvent("aimlabs:client:OpenMenu", function()
    if menuOpen then return end
    menuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "open",
        difficulties = {"Easy", "Medium", "Hard"},
        weapons = Config.Weapons
    })
end)

-- NUI callback: close
RegisterNUICallback("closeMenu", function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
    menuOpen = false
    cb("ok")
end)

-- NUI callback: start match
RegisterNUICallback("startMatch", function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
    menuOpen = false

    -- ✅ FIXED: call the correct event used in match.lua
    TriggerEvent("aimlabs:client:StartMatch", {
        difficulty = data.difficulty,
        weapon = data.weapon
    })

    cb("ok")
end)