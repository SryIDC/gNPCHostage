local hostages = {}
local pHostage = {}
local following = {}

RegisterNetEvent('gHostage:server:threaten')
AddEventHandler('gHostage:server:threaten', function(hostage, npch)
    local src = source
    if not hostages[hostage] then 
        TriggerClientEvent('gHostage:client:threaten', -1, hostage)
        TriggerClientEvent('gHostage:client:addTarget', -1, npch)
        hostages[hostage] = true
    else
        TriggerClientEvent('gHostage:client:threaten', -1, hostage)
    end
end)

RegisterNetEvent('gHostage:server:freehostage')
AddEventHandler('gHostage:server:freehostage', function (hostage, player)
    local src = source
    lib.notify(src, {description = "Releasing hostage"})
    TriggerClientEvent('gHostage:client:freehostage', -1, hostage, player)
    hostages[hostage] = false
    pHostage[src] = false
    hostages[hostage].following = false
end)

RegisterNetEvent('gHostage:server:taskhandsup')
AddEventHandler('gHostage:server:taskhandsup', function (hostage)
    local src = source
    TriggerClientEvent('gHostage:client:taskhandsup', -1, hostage)
    following[hostage] = false
end)

RegisterNetEvent('gHostage:server:kneel')
AddEventHandler('gHostage:server:kneel', function (hostage)
    TriggerClientEvent('gHostage:client:kneel', -1, hostage)
    following[hostage] = false
end)

RegisterNetEvent('gHostage:server:follow')
AddEventHandler('gHostage:server:follow', function(hostage, player)
    local src = source
    if hostages[hostage].following then return lib.notify(src, { description = "The local is already following another player" }) end
    lib.notify(src, {description="Hostage is following you!"})
    TriggerClientEvent('gHostage:client:follow', -1, hostage, player)
    hostages[hostage].following = true
end)

RegisterNetEvent('gHostage:server:hostageDied')
AddEventHandler('gHostage:server:hostageDied', function (hostage)
    local src = source
    lib.notify(src, {description = "Hostage died"})
    TriggerClientEvent('gHostage:client:hostageDied', -1, hostage)
    hostages[hostage].following = false
    hostages[hostage] = nil
end)

RegisterNetEvent('gHostage:server:enterVehicle')
AddEventHandler('gHostage:server:enterVehicle', function (hostage, vehicle)
    local src = source
    if not hostages[hostage].following then return end
    TriggerClientEvent('gHostage:client:enterVehicle', -1, hostage, vehicle)
end)


RegisterNetEvent('gHostage:server:leaveVehicle')
AddEventHandler('gHostage:server:leaveVehicle', function (hostage)
    if not hostages[hostage].following then return end
    TriggerClientEvent('gHostage:client:leaveVehicle', -1, hostage)
end)

RegisterNetEvent('baseevents:enteredVehicle', function(currentVehicle, currentSeat, vehicleDisplayName)
    local src = source
    local hostage = pHostage[src]
    if not hostage then return end
    if not following[hostage] then return end
    TriggerClientEvent('gHostage:client:enteredVehicle', src, currentVehicle)
end)

RegisterNetEvent('baseevents:leftVehicle', function(currentVehicle, currentSeat, vehicleDisplayName)
    local src = source
    local hostage = pHostage[src]
    if not hostage then return end
    if not following[hostage] then return end
    TriggerClientEvent('gHostage:client:leftVehicle', src, currentVehicle)
end)