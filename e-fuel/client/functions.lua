function CreateBlip(coords)
	local blip = AddBlipForCoord(coords)

	SetBlipSprite(blip, 361)
	SetBlipScale(blip, 0.55)
	SetBlipColour(blip, 1)
	SetBlipDisplay(blip, 4)
	SetBlipAsShortRange(blip, true)

	BeginTextCommandSetBlipName('STRING')
	AddTextComponentString('Gas Station')
	EndTextCommandSetBlipName(blip)
end

function GetFuel(vehicle)
	local fuel = DecorGetFloat(vehicle, Config.FuelDecor)
	return fuel or math.random(20, 40)
end

function SetFuel(vehicle, fuel)
	local fuel = tonumber(fuel)

	if fuel > 100 then 
		fuel = 100 
	elseif fuel < 0 then
		fuel = 0 
	end
	
	DecorSetFloat(vehicle, Config.FuelDecor, fuel + 0.0)
	SetVehicleFuelLevel(vehicle, fuel + 0.0)
end

exports('GetFuel', GetFuel)

exports('SetFuel', function(vehicle, amount)
    SetFuel(vehicle, amount)
end)