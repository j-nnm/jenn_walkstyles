local currentStyle = nil
local currentCharId = nil
local isLoaded = false
local vorpMenu = nil
local vorpCore = nil

local function getCore()
    if vorpCore then return vorpCore end
    local success, result = pcall(function()
        return exports.vorp_core:GetCore()
    end)
    if success then vorpCore = result end
    return vorpCore
end

local function notify(message, duration)
    if not Config.Notifications then return end
    duration = duration or Config.NotificationDuration or 4000
    local core = getCore()
    local notifType = Config.NotificationType or "right"
    
    if core then
        if notifType == "objective" and core.NotifyObjective then
            core.NotifyObjective(message, duration)
        elseif notifType == "right" and core.NotifyRightTip then
            core.NotifyRightTip(message, duration)
        elseif notifType == "left" and core.NotifyLeft then
            core.NotifyLeft(message, duration)
        elseif notifType == "bottom" and core.NotifyBottomRight then
            core.NotifyBottomRight(message, duration)
        else
            TriggerEvent("vorp:TipRight", message, duration)
        end
        return
    end
    
    if notifType == "objective" then
        TriggerEvent("vorp:TipObjective", message, duration)
    elseif notifType == "left" then
        TriggerEvent("vorp:TipLeft", message, duration)
    elseif notifType == "bottom" then
        TriggerEvent("vorp:TipBottom", message, duration)
    else
        TriggerEvent("vorp:TipRight", message, duration)
    end
end

local function getKvpKey()
    if Config.PerCharacter and currentCharId then
        return ("walkstyle_%s"):format(currentCharId)
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
    Citizen.InvokeNative(0xCB9401F918CB0F75, ped, clipset, 1, -1)
end

local function removeMovementClipset(ped, clipset)
    Citizen.InvokeNative(0xA6F67BEC53379A32, ped, clipset)
end

local function applyStyle(ped, style)
    if not DoesEntityExist(ped) then return false end
    
    if not style or style == "" or style == "default" then
        if currentStyle and currentStyle ~= "" then
            removeMovementClipset(ped, currentStyle)
        end
        removeMovementClipset(ped, "MP_Style_Casual")
        return true
    end
    
    if currentStyle and currentStyle ~= "" and currentStyle ~= style then
        removeMovementClipset(ped, currentStyle)
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
        removeMovementClipset(ped, "MP_Style_Casual")
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
    if currentStyle and currentStyle ~= "" then
        removeMovementClipset(ped, currentStyle)
    end
    removeMovementClipset(ped, "MP_Style_Casual")
    saveStyle(nil)
    setStatebag(nil)
    currentStyle = nil
end

local function getWalkStyle()
    return currentStyle
end

local function restoreWalkStyle()
    if not isLoaded then return end
    Wait(5000)
    
    local saved = loadStyle()
    if saved and saved ~= "" then
        setWalkStyle(saved, false)
    end
end

local function openMenu()
    if not Config.UseVorpMenu then
        for i, ws in ipairs(Config.WalkStyles) do
            print(("%d. %s"):format(i, ws.name))
        end
        return
    end
    
    if not vorpMenu then
        vorpMenu = exports.vorp_menu:GetMenuData()
    end
    
    local activeStyle = currentStyle or loadStyle()
    local elements = {}
    for _, ws in ipairs(Config.WalkStyles) do
        local isCurrent = (activeStyle == ws.style) or (not activeStyle and ws.style == "default")
        elements[#elements+1] = {
            label = isCurrent and ("→ " .. ws.name) or ws.name,
            value = ws.style,
            desc = "Set walk style to: " .. ws.name
        }
    end
    
    vorpMenu.CloseAll()
    vorpMenu.Open('default', GetCurrentResourceName(), 'walkstyle_menu', {
        title = "Walk Styles",
        align = 'top-left',
        elements = elements
    }, function(data)
        local style = data.current.value
        if style == "default" then
            resetWalkStyle()
        else
            setWalkStyle(style)
        end
        openMenu()
    end, function()
        vorpMenu.CloseAll()
    end)
end

RegisterNetEvent('vorp:SelectedCharacter', function(charId)
    currentCharId = charId
    isLoaded = true
    Wait(7000) 
    CreateThread(restoreWalkStyle)
end)

AddEventHandler('playerSpawned', function()
    if isLoaded then return end
    isLoaded = true
    CreateThread(restoreWalkStyle)
end)

RegisterNetEvent('jenn_walkstyles:receiveCharId', function(charId)
    if not charId then return end
    currentCharId = charId
    if isLoaded then
        restoreWalkStyle()
    end
end)

RegisterCommand(Config.Command, function()
    if not isLoaded then
        notify("Please wait until your character is loaded", 4000)
        return
    end
    openMenu()
end, false)

RegisterCommand(Config.ResetCommand, function()
    resetWalkStyle()
    notify("Walk style reset to default", 3000)
end, false)

RegisterCommand('setwalk', function(_, args)
    local index = tonumber(args[1])
    if not index then
        notify("Usage: /setwalk [number]", 5000)
        return
    end
    
    local ws = Config.WalkStyles[index]
    if not ws then
        notify("Invalid walk style number", 3000)
        return
    end
    
    if ws.style == "default" then
        resetWalkStyle()
    else
        setWalkStyle(ws.style)
    end
    notify("Walk style set to: " .. ws.name, 3000)
end, false)

TriggerEvent('chat:addSuggestion', '/' .. Config.Command, Config.CommandHelp)
TriggerEvent('chat:addSuggestion', '/' .. Config.ResetCommand, Config.ResetCommandHelp)
TriggerEvent('chat:addSuggestion', '/setwalk', 'Set walk style by number', {{ name = "number", help = "Walk style number" }})
TriggerEvent('chat:addSuggestion', '/checkwalk', 'Check saved walk style')

exports('SetWalkStyle', setWalkStyle)
exports('GetWalkStyle', getWalkStyle)
exports('ResetWalkStyle', resetWalkStyle)
exports('OpenMenu', openMenu)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if vorpMenu then
        pcall(function() vorpMenu.CloseAll() end)
    end
end)

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(100)
    end
    Wait(2000)
    
    local ped = PlayerPedId()
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end
    
    TriggerServerEvent('jenn_walkstyles:getCharId')
    
    if not currentCharId then
        local stateCharId = LocalPlayer.state.charid or LocalPlayer.state.charId or LocalPlayer.state.charIdentifier
        if stateCharId then
            currentCharId = stateCharId
        end
    end
    
    if not currentCharId then
        local success, result = pcall(function()
            return exports.vorp_core:GetCharacter()
        end)
        if success and result then
            currentCharId = result.charIdentifier or result.charid or result.id or result.charId
        end
    end
    
    isLoaded = true
    Wait(3000)
    restoreWalkStyle()
end)