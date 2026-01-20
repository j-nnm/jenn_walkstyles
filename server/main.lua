local vorpCore = nil

CreateThread(function()
    TriggerEvent("getCore", function(core)
        vorpCore = core
    end)
end)

RegisterNetEvent('jenn_walkstyles:getCharId', function()
    local src = source
    if not vorpCore then return end
    
    local user = vorpCore.getUser(src)
    if not user then return end
    
    local character = user.getUsedCharacter
    if not character then return end
    
    TriggerClientEvent('jenn_walkstyles:receiveCharId', src, character.charIdentifier)
end)