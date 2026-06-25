fitnessSystem = fitnessSystem or {}
fitnessSystem.Client = fitnessSystem.Client or {}

local isTraining = false
local trainingCooldowns = {}
---Draws a marker for a training spot.
---@param spot TrainingSpot
local function drawTrainingMarker(spot)
	DrawMarker(
		1,
		spot.coords.x,
		spot.coords.y,
		spot.coords.z - 1.0,
		0.0,
		0.0,
		0.0,
		0.0,
		0.0,
		0.0,
		1.0,
		1.0,
		0.2,
		0,
		200,
		100,
		150,
		false,
		true,
		2,
		false,
		nil,
		nil,
		false
	)
end


---Checks if the player has got an active cooldown for a training spot.
---@param spotType string
---@return number
local function getLocalCooldownLeft(spotType)
	local endsAt = trainingCooldowns[spotType]

	if not endsAt then
		return 0
	end

	local left = math.ceil((endsAt - GetGameTimer()) / 1000)

	if left <= 0 then
		trainingCooldowns[spotType] = nil
		return 0
	end

	return left
end

---Caches a local cooldown for a training spot to prevent Server spam.
---@param spotType string
---@param seconds number
local function setLocalCooldown(spotType, seconds)
	seconds = tonumber(seconds) or 0

	if seconds <= 0 then
		return
	end

	trainingCooldowns[spotType] = GetGameTimer() + (seconds * 1000)
end

---Starts local training animation and asks server for reward afterwards.
---@param spot TrainingSpot
local function startTraining(spot)
	if isTraining then
		return
	end
	local cooldownLeft = getLocalCooldownLeft(spot.type)

	if cooldownLeft > 0 then
		exports['esx_notify']:Notify(
			'error',
			3000,
			('Du musst noch %d Sekunden warten.'):format(tonumber(cooldownLeft) or 0),
			'Fitness')
		return
	end

	isTraining = true

	ESX.TriggerServerCallback('fitness_system:server:canStartTraining', function(canStart, reason, cooldownLeft)
		if not canStart then
			isTraining = false
			if reason == 'cooldown' then
				cooldownLeft = tonumber(cooldownLeft) or 0
				setLocalCooldown(spot.type, cooldownLeft)
				exports['esx_notify']:Notify(
					'error',
					3000,
					('Du musst noch %d Sekunden warten.'):format(tonumber(cooldownLeft) or 0),
					'Fitness')
				return
			end
			exports['esx_notify']:Notify(
				'error',
				3000,
				'Training aktuell nicht möglich.',
				'Fitness'
			)
			return
		end

		local ped = PlayerPedId()
		local endTime = GetGameTimer() + spot.duration

		FreezeEntityPosition(ped, true)

		if spot.scenario then
			TaskStartScenarioInPlace(ped, spot.scenario, 0, true)
		end

		SendNUIMessage({
			type = 'trainingStart',
			label = spot.label,
			duration = spot.duration,
		})

		while GetGameTimer() < endTime do
			if not IsPedUsingAnyScenario(ped) and spot.scenario then
				TaskStartScenarioInPlace(ped, spot.scenario, 0, true)
			end
			Wait(500)
		end

		ClearPedTasksImmediately(ped)
		FreezeEntityPosition(ped, false)

		local cooldownSeconds = math.ceil((spot.cooldown or fitnessSystem.Config.DefaultTrainingCooldown) / 1000)
		setLocalCooldown(spot.type, cooldownSeconds)

		isTraining = false
		TriggerServerEvent('fitness_system:server:requestTrain', spot.type)
	end, spot.type)
end

CreateThread(function()
	while true do
		local sleep = 1000
		local ped = PlayerPedId()
		local coords = GetEntityCoords(ped)

		for _, spot in ipairs(fitnessSystem.Config.TrainingPoints) do
			local distance = #(coords - spot.coords)

			if distance < 20.0 then
				sleep = 0
				drawTrainingMarker(spot)
			end

			if distance <= spot.radius and not isTraining then
				sleep = 0

				ESX.ShowHelpNotification(('Drücke ~INPUT_CONTEXT~ für ~b~%s~s~'):format(spot.label))

				if IsControlJustReleased(0, 38) then
					startTraining(spot)
				end
			end
		end

		Wait(sleep)
	end
end)


AddEventHandler('onResourceStop', function(resourceName)
	if GetCurrentResourceName() ~= resourceName then
		return
	end

	if isTraining then
		local ped = PlayerPedId()
		ClearPedTasksImmediately(ped)
		FreezeEntityPosition(ped, false)
		isTraining = false
	end
end)
