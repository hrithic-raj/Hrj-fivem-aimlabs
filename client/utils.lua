-- client/utils.lua
-- Helper functions used across client files

function LoadModel(model)
    if not HasModelLoaded(model) then
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(0) end
    end
end

function LoadAnimDict(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do Wait(0) end
    end
end

function DrawText3D(coords, text)
    local x, y, z = table.unpack(coords)
    SetDrawOrigin(x, y, z + 1.0, 0)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextCentre(true)
    AddTextEntry('aimlabtext', text)
    BeginTextCommandDisplayText('aimlabtext')
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

-- Return a random position inside Config.Arena.botArea (2-corner rectangle)
function GetRandomBotPosition()
    local A, B = Config.Arena.botArea.A, Config.Arena.botArea.B
    local minX, maxX = math.min(A.x, B.x), math.max(A.x, B.x)
    local minY, maxY = math.min(A.y, B.y), math.max(A.y, B.y)
    local x = math.random() * (maxX - minX) + minX
    local y = math.random() * (maxY - minY) + minY
    local z = A.z
    local w = math.random(0, 360)
    return { x = x, y = y, z = z, w = w }
end
