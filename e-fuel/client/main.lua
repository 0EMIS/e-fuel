local ped = cache.ped
local vehicle = cache.vehicle
local seat = cache.seat
local Inventory = exports.ox_inventory

lib.onCache('ped', function(value) ped = value end)
lib.onCache('vehicle', function(value) vehicle = value end)
lib.onCache('seat', function(value) seat = value end)

exports.ox_target:addModel(Config.PumpObjects, {
    {
        name = 'e-fuel:fuel',
        icon = 'fa-solid fa-gas-pump',
        label = ('Refuel vehicle'):format(Config.FuelPrice),
        distance = 2.0,
        onSelect = function(data)
            local closestVehicle, closestDistance = ESX.Game.GetClosestVehicle()
            local vehicleFuel = ESX.Math.Round(GetVehicleFuelLevel(closestVehicle))
        
            if closestVehicle == -1 or not DoesEntityExist(closestVehicle) then
                lib.notify({
                    title = 'ERROR!',
                    description = 'There is no vehicles around you.',
                    showDuration = false,
                    position = 'top',
                    style = {
                        backgroundColor = '#141517',
                        color = '#C1C2C5',
                        ['.description'] = {
                          color = '#909296'
                        }
                    },
                    icon = 'ban',
                    iconColor = '#C53030'
                })
                return
            elseif closestDistance > 3.0 then
                lib.notify({
                    title = 'ERROR!',
                    description = 'The nearest vehicle is too far from you.',
                    showDuration = false,
                    position = 'top',
                    style = {
                        backgroundColor = '#141517',
                        color = '#C1C2C5',
                        ['.description'] = {
                          color = '#909296'
                        }
                    },
                    icon = 'ban',
                    iconColor = '#C53030'
                })
                return
            elseif vehicleFuel >= 100 then
                lib.notify({
                    title = 'ERROR!',
                    description = 'The vehicles tank is already full.',
                    showDuration = false,
                    position = 'top',
                    style = {
                        backgroundColor = '#141517',
                        color = '#C1C2C5',
                        ['.description'] = {
                          color = '#909296'
                        }
                    },
                    icon = 'ban',
                    iconColor = '#C53030'
                })
                return
            end
        
            lib.registerContext({
                id = 'fuel_payment_menu',
                title = 'Payment method',
                options = {
                    {
                        title = 'Pay in cash',
                        icon = 'fa-solid fa-money-bill-wave',
                        onSelect = function()
                            startFueling(data.entity, 'cash')
                        end
                    },
                    {
                        title = 'Pay by card',
                        icon = 'fa-solid fa-credit-card',
                        onSelect = function()
                            startFueling(data.entity, 'bank')
                        end
                    }
                }
            })
        
            lib.showContext('fuel_payment_menu')
        end        
    },
    
    {
        name = 'e-fuel:buyCan',
        icon = 'fa-solid fa-money-bills',
        label = ('Buy a fuel can (%s€)'):format(Config.GasCanPrice),
        distance = 2.0,
        onSelect = function(data)
            buyGasCan()
        end
    },
})

exports.ox_target:addGlobalVehicle({
    {
        name = 'e-fuel:useCan',
        icon = 'fa-solid fa-gas-pump',
        label = 'Fuel up the vehicle',
        canInteract = function(entity, distance, coords, name, bone)
            return GetSelectedPedWeapon(ped) == `weapon_petrolcan`
        end,
        onSelect = function(data)
            local hasCan = lib.callback.await('e-fuel:useGasCan', false)
            
            if hasCan then
                local closestVehicle, closestDistance = ESX.Game.GetClosestVehicle()
                local vehicleFuel = ESX.Math.Round(GetVehicleFuelLevel(closestVehicle))
                
                if vehicleFuel >= 100 then
                    lib.notify({
                        title = 'ERROR!',
                        description = 'The vehicles tank is already full.',
                        showDuration = false,
                        position = 'top',
                        style = {
                            backgroundColor = '#141517',
                            color = '#C1C2C5',
                            ['.description'] = {
                              color = '#909296'
                            }
                        },
                        icon = 'ban',
                        iconColor = '#C53030'
                    })
                    return
                end

                lib.progressCircle({
                    duration = 10000,
                    label = 'Pouring fuel...',
                    position = 'bottom',
                    useWhileDead = false,
                    canCancel = false,
                    disable = {
                        move = true, 
                        combat = true, 
                        car = true, 
                        mouse = true
                    },
                    anim = {
                        dict = 'timetable@gardener@filling_can',
                        clip = 'gar_ig_5_filling_can'
                    },
                }) 
                local newFuel = ESX.Math.Round(GetVehicleFuelLevel(closestVehicle)) + 50.0
                SetFuel(closestVehicle, newFuel)                  
            end   
        end
    }
})

function startFueling(pumpObject, paymentType)
    local pumpCoords = GetEntityCoords(pumpObject) + vec(0.0, 0.0, 1.0)
    local closestVehicle, closestDistance = ESX.Game.GetClosestVehicle()
    local vehicleFuel = ESX.Math.Round(GetVehicleFuelLevel(closestVehicle))

    local isFueling = true
    local fuelPrice = 0
    local tankCapacity = 100
    LocalPlayer.state:set('invBusy', true, false)

    ESX.Streaming.RequestAnimDict('timetable@gardener@filling_can')
    TaskTurnPedToFaceEntity(ped, closestVehicle, 500)
    TaskPlayAnim(ped, 'timetable@gardener@filling_can', 'gar_ig_5_filling_can', 2.0, 8.0, -1, 50, 0, 0, 0, 0)

    CreateThread(function()
        while isFueling do
            Wait(1000)

            if vehicleFuel < 100 and isFueling then
                local payPrice = Config.FuelPrice * 2
                local Money

                if paymentType == 'bank' then
                    Money = lib.callback.await('e-fuel:getBankBalance', false)
                else
                    Money = Inventory:Search('count', 'money')
                end
                              

                local enoughMoney = Money >= payPrice

                if enoughMoney then
                    fuelPrice = fuelPrice + payPrice
                    vehicleFuel = vehicleFuel + 2.0
                    SetFuel(closestVehicle, vehicleFuel)
                    if Money <= fuelPrice then
                        isFueling = false
                        lib.notify({
                            title = 'ERROR!',
                            description = 'Insufficient funds. Fuel delivery suspended.',
                            showDuration = false,
                            position = 'top',
                            style = {
                                backgroundColor = '#141517',
                                color = '#C1C2C5',
                                ['.description'] = {
                                  color = '#909296'
                                }
                            },
                            icon = 'ban',
                            iconColor = '#C53030'
                        })
                    end
                else
                    isFueling = false
                    lib.notify({
                        title = 'ERROR!',
                        description = 'Insufficient funds. Fuel delivery suspended.',
                        showDuration = false,
                        position = 'top',
                        style = {
                            backgroundColor = '#141517',
                            color = '#C1C2C5',
                            ['.description'] = {
                              color = '#909296'
                            }
                        },
                        icon = 'ban',
                        iconColor = '#C53030'
                    })
                end

                if not IsEntityPlayingAnim(ped, 'timetable@gardener@filling_can', 'gar_ig_5_filling_can', 3) then
                    TaskPlayAnim(ped, 'timetable@gardener@filling_can', 'gar_ig_5_filling_can', 2.0, 2.0, -1, 50, 0, 0, 0, 0)
                end
            else
                isFueling = false
            end
        end

        if fuelPrice > 0 then
            TriggerServerEvent('e-fuel:payMoney', fuelPrice, paymentType)
            lib.notify({
                title = 'SUCCESSFUL!',
                description = 'You paid '..fuelPrice..'€ for the fuel.',
                position = 'top',
                type = 'success'
            })
        end

        LocalPlayer.state:set('invBusy', false, false)
        StopAnimTask(ped, 'timetable@gardener@filling_can', 'gar_ig_5_filling_can', 3.0)
        RemoveAnimDict('gestures@f@standing@casual')
    end)

    CreateThread(function()
        while isFueling do
            Wait(0)
    
            DisableControlAction(0, 23, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 30, true)
            DisableControlAction(0, 31, true)
            DisableControlAction(0, 32, true)
            DisableControlAction(0, 33, true)
            DisableControlAction(0, 34, true)
            DisableControlAction(0, 35, true)
            DisablePlayerFiring(PlayerId(), true)
    
            lib.showTextUI('Fuel price: ' .. fuelPrice .. '€ | Fuel rate: ' .. Config.FuelPrice .. '€/L | Fueled: ' .. math.floor(vehicleFuel) ..  '/' .. tankCapacity .. 'L', {
                position = 'bottom-center',
                icon = 'fa-gas-pump'
            })
    
            if IsControlJustPressed(0, 38) then 
                isFueling = false
            elseif #(GetEntityCoords(closestVehicle) - GetEntityCoords(ped)) > 3.0 then
                lib.notify({
                    title = 'ERROR!',
                    description = 'You are too far from your vehicle, so refueling has been stopped.',
                    showDuration = false,
                    position = 'top',
                    style = {
                        backgroundColor = '#141517',
                        color = '#C1C2C5',
                        ['.description'] = {
                          color = '#909296'
                        }
                    },
                    icon = 'ban',
                    iconColor = '#C53030'
                })
                isFueling = false
            end
        end
    
        lib.hideTextUI()
    end)
end

function buyGasCan()
    local result = lib.callback.await('e-fuel:buyGasCan', false)

    if result == 'purchased' then
        lib.notify({
            title = 'SUCCESSFUL!',
            description = 'You paid '..Config.GasCanPrice..'€ for the fuel can.',
            position = 'top',
            type = 'success'
        })
    elseif result == 'no_money' then
        lib.notify({
            title = 'ERROR!',
            description = 'Insufficient funds.',
            showDuration = false,
            position = 'top',
            style = {
                backgroundColor = '#141517',
                color = '#C1C2C5',
                ['.description'] = {
                  color = '#909296'
                }
            },
            icon = 'ban',
            iconColor = '#C53030'
        })
    end
end

CreateThread(function()
	DecorRegister(Config.FuelDecor, 1)

	while true do
		Wait(1000)
		if vehicle then
			if Config.Blacklist[GetEntityModel(vehicle)] then
				inBlacklisted = true
			else
				inBlacklisted = false
			end

			if not inBlacklisted and seat == -1 then
				if not DecorExistOn(vehicle, Config.FuelDecor) then
                    SetFuel(vehicle, math.random(200, 800) / 10)
                elseif not fuelSynced then
                    SetFuel(vehicle, GetFuel(vehicle))
                    fuelSynced = true
                end
            
                if vehicle and IsVehicleEngineOn(vehicle) then
                    SetFuel(vehicle, GetVehicleFuelLevel(vehicle) - Config.FuelUsage[ESX.Math.Round(GetVehicleCurrentRpm(vehicle), 1)] * (Config.Classes[GetVehicleClass(vehicle)] or 1.0) / 10)
                end
			end
		else
			if fuelSynced then
				fuelSynced = false
			end

			if inBlacklisted then
				inBlacklisted = false
			end
		end
	end
end)

for _, gasStationCoords in pairs(Config.GasStations) do
    CreateBlip(gasStationCoords)
end
