local IsHostage = false
local Entity = nil

CreateThread(function()
    lib.requestAnimDict("random@arrests@busted", 5000)
    lib.requestAnimDict("random@arrests", 5000)
    lib.requestAnimDict('anim@gangops@hostage@', 5000)

    exports.ox_target:addGlobalPed({
        {
            label = "Threaten",
            icon = "fa-solid fa-gun",
            distance = 5.0,
            canInteract = function()
                local closestPed = lib.getClosestPed(GetEntityCoords(cache.ped), 10)
                if cache.weapon then
                    if not IsEntityPositionFrozen(closestPed) then
                        if not cache.vehicle and not IsPedDeadOrDying(closestPed, true) then
                            return true
                        end
                    end
                end
            end,
            onSelect = function()
                TriggerEvent('gHostage:client:attemptHostage')
            end,
        }
    })
end)

RegisterNetEvent('gHostage:client:attemptHostage', function()
    if Config.Defend.Enable then
        local agressive = math.random(0, 100) <= Config.Defend.Chance
        print(agressive)
        if agressive then
            local closestPed = lib.getClosestPed(GetEntityCoords(cache.ped), 10)
            local weaponhash = GetHashKey(Config.Defend.Weapon)
            GiveWeaponToPed(closestPed, weaponhash, 100, false, true)
            SetPedCombatAttributes(closestPed, 46, true)
            SetPedCombatAttributes(closestPed, 2, true)
            SetPedCombatAbility(closestPed, 2)
            SetPedCombatMovement(closestPed, 2)
            SetPedAccuracy(closestPed, Config.Defend.Accuracy)
            TaskCombatPed(closestPed, cache.ped, 0, 16)
            TaskShootAtEntity(closestPed, cache.ped, 30000, "FIRING_PATTERN_FULL_AUTO")
        else
            local closestPed = lib.getClosestPed(GetEntityCoords(cache.ped), 10)
            Entity = closestPed
            local hostagenet = NetworkGetNetworkIdFromEntity(closestPed)
            TriggerServerEvent('gHostage:server:threaten', hostagenet, closestPed)
        end
    else
        local closestPed = lib.getClosestPed(GetEntityCoords(cache.ped), 10)
        Entity = closestPed
        local hostagenet = NetworkGetNetworkIdFromEntity(closestPed)
        TriggerServerEvent('gHostage:server:threaten', hostagenet, closestPed)
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000
        if IsHostage then
            local health = GetEntityHealth(Entity)
            sleep = 0
            if health == 0 then
                TriggerServerEvent('gHostage:server:hostageDied', Entity)
                exports.ox_target:removeLocalEntity(Entity, { "host:free", "host:handsup", "host:kneel", "host:follow" })
                IsHostage = false
            end
        end
        Wait(sleep)
    end
end)

RegisterNetEvent('gHostage:client:addTarget', function(npch)
    SetTimeout(6000, function()
        exports.ox_target:addLocalEntity(npch, {
            {
                label = "Free The Hostage",
                icon = "fa-solid fa-person",
                name = "host:free",
                distance = 5.0,
                onSelect = function()
                    exports.ox_target:removeLocalEntity(npch,
                    { "host:free", "host:handsup", "host:kneel", "host:follow" })
                    TriggerServerEvent('gHostage:server:freehostage', npch, cache.ped)
                    Entity = nil
                end
            },
            {
                label = "Hands Up",
                icon = "fa-solid fa-people-robbery",
                name = "host:handsup",
                distance = 5.0,
                onSelect = function()
                    TriggerServerEvent('gHostage:server:taskhandsup', npch)
                end
            },
            {
                label = "Kneel Down",
                icon = "fa-solid fa-person-praying",
                name = "host:kneel",
                distance = 5.0,
                onSelect = function()
                    TriggerServerEvent('gHostage:server:kneel', npch)
                end
            },
            {
                label = "Follow Me",
                icon = "fa-solid fa-person-walking",
                distance = 5.0,
                name = "host:follow",
                onSelect = function()
                    TriggerServerEvent('gHostage:server:follow', npch, cache.ped)
                end
            },
        })
    end)
end)

RegisterNetEvent('gHostage:client:follow')
AddEventHandler('gHostage:client:follow', function(hostage, player)
    SetPedFleeAttributes(hostage, 0, false)
    SetPedCombatAttributes(hostage, 17, true)
    FreezeEntityPosition(hostage, false)
    TaskSetBlockingOfNonTemporaryEvents(hostage, true)
    TaskFollowToOffsetOfEntity(hostage, player, 2.0, 2.0, 1.0, 2.0, -1, 6.0, true)
end)

RegisterNetEvent('gHostage:client:enteredVehicle')
AddEventHandler('gHostage:client:enteredVehicle', function(vehicle)
    TriggerServerEvent('gHostage:server:enterVehicle', Entity, vehicle)
end)

RegisterNetEvent('gHostage:client:leftVehicle')
AddEventHandler('gHostage:client:leftVehicle', function(vehicle)
    TriggerServerEvent('gHostage:server:leaveVehicle', Entity, vehicle)
end)

RegisterNetEvent('gHostage:client:hostageDied')
AddEventHandler('gHostage:client:hostageDied', function(hostage)
    FreezeEntityPosition(hostage, false)
    TaskSetBlockingOfNonTemporaryEvents(hostage, false)
    ClearPedTasksImmediately(hostage)
    ClearPedSecondaryTask(hostage)
end)

RegisterNetEvent('gHostage:client:enterVehicle')
AddEventHandler('gHostage:client:enterVehicle', function(hostage, vehicle)
    local seatCount = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle))
    for seatIndex = -1, seatCount - 2 do
        if IsVehicleSeatFree(vehicle, seatIndex) then
            if DoesEntityExist(hostage) then
                TaskEnterVehicle(hostage, vehicle, -1, seatIndex, 2.0, 1, 0)
                CreateThread(function()
                    while true do
                        local sleep = 1000
                        if IsPedInAnyVehicle(hostage, true) then
                            SetPedFleeAttributes(hostage, 0, false)
                            SetPedCombatAttributes(hostage, 17, true)
                            TaskSetBlockingOfNonTemporaryEvents(hostage, true)
                            sleep = 0
                            break
                        end
                        Wait(sleep)
                    end
                end)
                break
            else
                print(hostage .. " doesnt exist")
            end
        end
    end
end)

RegisterNetEvent('gHostage:client:leaveVehicle', function(hostage)
    TaskLeaveAnyVehicle(hostage, 0, 1)
    SetTimeout(200, function()
        TaskHandsUp(hostage, -1, 0, -1, false)
        SetPedFleeAttributes(hostage, 0, false)
        SetPedCombatAttributes(hostage, 17, true)
    end)
end)


RegisterNetEvent('gHostage:client:threaten')
AddEventHandler('gHostage:client:threaten', function(hostageid)
    local hostage = NetworkGetEntityFromNetworkId(hostageid)

    if DoesEntityExist(hostage) then
        ClearPedTasksImmediately(hostage)
        TaskPlayAnim(hostage, "random@arrests", "idle_2_hands_up", 8.0, 1.0, -1, 2, 0, 0, 0, 0)
        Wait(4000)
        TaskPlayAnim(hostage, "random@arrests", "kneeling_arrest_idle", 8.0, 1.0, -1, 2, 0, 0, 0, 0)
        Wait(500)
        TaskPlayAnim(hostage, "random@arrests@busted", "enter", 8.0, 1.0, -1, 2, 0, 0, 0, 0)
        Wait(1000)
        TaskPlayAnim(hostage, "random@arrests@busted", "idle_a", 8.0, 1.0, -1, 9, 0, 0, 0, 0)
    end
end)

RegisterNetEvent('gHostage:client:kneel')
AddEventHandler('gHostage:client:kneel', function(hostage)
    if DoesEntityExist(hostage) then
        ClearPedTasksImmediately(hostage)
        TaskPlayAnim(hostage, "random@arrests", "idle_2_hands_up", 8.0, 1.0, -1, 2, 0, 0, 0, 0)
        Wait(4000)
        TaskPlayAnim(hostage, "random@arrests", "kneeling_arrest_idle", 8.0, 1.0, -1, 2, 0, 0, 0, 0)
        Wait(500)
        TaskPlayAnim(hostage, "random@arrests@busted", "enter", 8.0, 1.0, -1, 2, 0, 0, 0, 0)
        Wait(1000)
        TaskPlayAnim(hostage, "random@arrests@busted", "idle_a", 8.0, 1.0, -1, 9, 0, 0, 0, 0)
    end
end)

RegisterNetEvent('gHostage:client:taskhandsup')
AddEventHandler('gHostage:client:taskhandsup', function(hostage)
    ClearPedTasksImmediately(hostage)
    FreezeEntityPosition(hostage, true)
    SetPedFleeAttributes(hostage, 0, false)
    SetPedCombatAttributes(hostage, 17, true)
    TaskHandsUp(hostage, -1, 0, -1, false)
end)

RegisterNetEvent('gHostage:client:freehostage')
AddEventHandler('gHostage:client:freehostage', function(hostage, player)
    FreezeEntityPosition(hostage, false)
    TaskSetBlockingOfNonTemporaryEvents(hostage, false)
    ClearPedTasksImmediately(hostage)
    ClearPedSecondaryTask(hostage)
    TaskReactAndFleePed(hostage, player)
    --[[SetTimeout(3000, function ()
        if DoesEntityExist(hostage) then
            DeleteEntity(hostage)
        end
    end)]] --
end)
