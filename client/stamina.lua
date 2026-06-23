fitnessSystem = fitnessSystem or {}
fitnessSystem.Client = fitnessSystem.Client or {}

local staminaThreadActive = false
local currentStaminaLevel = 1
local RESTORE_INTERVAL = 1000
local RESTORE_PER_LEVEL = 0.01
local MAX_PARTIAL_RESTORE = 0.08

local function startStaminaThread()
	if staminaThreadActive then
		return
	end

	staminaThreadActive = true

	CreateThread(function()
		local maxLevel = fitnessSystem.Client.GetMaxLevel(fitnessSystem.Constant.Stat.Stamina)
		while staminaThreadActive do
			local level = tonumber(currentStaminaLevel) or 1

			if level >= maxLevel then
				RestorePlayerStamina(PlayerId(), 1.0)
			elseif level > 1 then
				local restoreAmount = math.min(
					MAX_PARTIAL_RESTORE,
					(level - 1) * RESTORE_PER_LEVEL
				)

				RestorePlayerStamina(PlayerId(), restoreAmount)
			end

			Wait(RESTORE_INTERVAL)
		end
	end)
end

local function stopStaminaThread()
	staminaThreadActive = false
end

---@param level number
function fitnessSystem.Client.UpdateStaminaState(level)
	currentStaminaLevel = tonumber(level) or 1

	if currentStaminaLevel <= 1 then
		stopStaminaThread()
		return
	end

	startStaminaThread()
end

AddEventHandler('onResourceStop', function(resourceName)
	if resourceName ~= GetCurrentResourceName() then
		return
	end

	stopStaminaThread()
end)
