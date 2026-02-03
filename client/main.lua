local Config = lib.load('config')
local currentStyle = nil
local currentCharId = nil

local function getCharId()
    if currentCharId then return currentCharId end
    return LocalPlayer.state.charId or LocalPlayer.state.charid or LocalPlayer.state.charIdentifier or LocalPlayer.state.character
end

local function getKvpKey()
    local charId = getCharId()
    if Config.PerCharacter and charId then
        return ("walkstyle_%s"):format(charId)
    end
    return "walkstyle"
end

local function saveStyle(style)
    local key = getKvpKey()
    if style and style ~= "" and style ~= "default" then
        SetResourceKvp(key, style)
    else
        DeleteResourceKvp(key)
    end
    currentStyle = style
end

local function loadStyle()
    return GetResourceKvpString(getKvpKey())
end

local function setMovementClipset(ped, clipset)
    SetPedBlackboardBool(ped, clipset, 1, -1)
end

local function removeMovementClipset(ped)
    RemovePedBlackboardBool(ped)
end

local function applyStyle(ped, style)
    if not DoesEntityExist(ped) then return false end
    
    if not style or style == "" or style == "default" then
        removeMovementClipset(ped)
        return true
    end
    
    if currentStyle and currentStyle ~= "" and currentStyle ~= style then
        removeMovementClipset(ped)
    end
    
    setMovementClipset(ped, style)
    return true
end

local function setStatebag(style)
    LocalPlayer.state:set("walkStyle", style, true)
end

AddStateBagChangeHandler("walkStyle", nil, function(bagName, _, value)
    local myBag = "player:" .. GetPlayerServerId(PlayerId())
    if bagName == myBag then return end
    
    local playerId = GetPlayerFromStateBagName(bagName)
    if not playerId or playerId == -1 then return end
    
    local ped = GetPlayerPed(playerId)
    if not DoesEntityExist(ped) then return end
    
    if value and value ~= "" and value ~= "default" then
        setMovementClipset(ped, value)
    else
        removeMovementClipset(ped)
    end
end)

local function setWalkStyle(style, save)
    local ped = PlayerPedId()
    if not applyStyle(ped, style) then return false end
    
    currentStyle = style
    if save ~= false then
        saveStyle(style)
    end
    setStatebag(style)
    return true
end

local function resetWalkStyle()
    local ped = PlayerPedId()
    removeMovementClipset(ped)
    saveStyle(nil)
    setStatebag(nil)
    currentStyle = nil
end

local function getWalkStyle()
    return currentStyle
end

local function restoreWalkStyle()
    Wait(500)
    
    local saved = loadStyle()
end

local function openMenu()
    local activeStyle = currentStyle or loadStyle()
    local options = {}
    
    for _, ws in ipairs(Config.WalkStyles) do
        local isCurrent = (activeStyle == ws.style) or (not activeStyle and ws.style == "default")
        options[#options+1] = {
            label = isCurrent and ("→ " .. ws.name) or ws.name,
            description = "Set walk style to: " .. ws.name,
            args = { style = ws.style, name = ws.name }
        }
    end
    
    lib.registerMenu({
        id = 'jenn_walkstyle_menu',
        title = 'Walk Styles',
        position = 'top-left',
        options = options
    }, function(selected, scrollIndex, args)
        if not args then return end
        if args.style == "default" then
            resetWalkStyle()
        else
            setWalkStyle(args.style)
        end
        lib.notify({ title = 'Walk Style', description = 'Set to: ' .. args.name, type = 'success' })
        openMenu()
    end)
    
    lib.showMenu('jenn_walkstyle_menu')
end

RegisterCommand(Config.Command, function()
    openMenu()
end, false)

RegisterCommand(Config.ResetCommand, function()
    resetWalkStyle()
    lib.notify({ title = 'Walk Style', description = 'Reset to default', type = 'success' })
end, false)

RegisterCommand('checkcharid', function()
    local charId = getCharId()
    print(("charId: %s | kvpKey: %s"):format(tostring(charId), getKvpKey()))
    lib.notify({ title = 'Debug', description = 'charId: ' .. tostring(charId), type = 'info' })
end, false)

TriggerEvent('chat:addSuggestion', '/' .. Config.Command, Config.CommandHelp)
TriggerEvent('chat:addSuggestion', '/' .. Config.ResetCommand, Config.ResetCommandHelp)

exports('SetWalkStyle', setWalkStyle)
exports('GetWalkStyle', getWalkStyle)
exports('ResetWalkStyle', resetWalkStyle)
exports('OpenMenu', openMenu)
exports('SetCharId', function(id) currentCharId = id end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    lib.hideMenu()
end)

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(100)
    end
    Wait(3000)
    restoreWalkStyle()
end)