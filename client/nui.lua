fitnessSystem = fitnessSystem or {}
fitnessSystem.Client = fitnessSystem.Client or {}

local statsPanelOpen = false

---Opens the stats panel and builds the latest stats.
local function openStatsPanel()
	statsPanelOpen = true

	SendNUIMessage({
		type = 'openStats',
		stats = fitnessSystem.Client.BuildNuiStats(fitnessSystem.Client.GetStats()),
	})

	SetNuiFocus(true, true)
end

---Closes the stats panel.
local function closeStatsPanel()
	statsPanelOpen = false

	SendNUIMessage({
		type = 'closeStats',
	})

	SetNuiFocus(false, false)
end

RegisterCommand('fitness', function()
	if statsPanelOpen then
		closeStatsPanel()
		return
	end

	openStatsPanel()
end, false)

RegisterNUICallback('close', function(_, cb)
	closeStatsPanel()
	cb('ok')
end)

---handles Training rewards and notifies Player
RegisterNetEvent('fitness_system:client:rewarded', function(stat, level, xp, xpGained, leveledUp)
	if not stat or not fitnessSystem.Config.Stats[stat] then
		return
	end

	level = tonumber(level) or 1
	xp = tonumber(xp) or 0
	xpGained = tonumber(xpGained) or 0

	fitnessSystem.Client.SetStat(stat, level, xp)

	local requiredXp = fitnessSystem.Client.GetRequiredXpForLevel(stat, level)
	local isMaxLevel = fitnessSystem.Client.IsMaxLevel(stat, level)
	local statConfig = fitnessSystem.Config.Stats[stat]

	SendNUIMessage({
		type = 'xpPopup',
		stat = stat,
		label = statConfig and statConfig.label or stat,
		xp = xpGained,
		level = level,
		currentXp = xp,
		requiredXp = requiredXp,
		isMaxLevel = isMaxLevel,
		leveledUp = leveledUp == true,
	})

	if stat == fitnessSystem.Constant.Stat.Stamina then
		fitnessSystem.Client.UpdateStaminaState(level)
	end
end)
