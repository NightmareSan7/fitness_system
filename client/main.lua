fitnessSystem = fitnessSystem or {}
fitnessSystem.Client = fitnessSystem.Client or {}
---@type table<FitnessStatName, FitnessStatData>
fitnessSystem.Client.PlayerStats = fitnessSystem.Client.PlayerStats or {}

---Builds default stats from shared config without using database values.
---@return table<FitnessStatName, FitnessStatData>
function fitnessSystem.Client.BuildDefaultStats()
	local stats = {}

	for stat in pairs(fitnessSystem.Config.Stats) do
		stats[stat] = {
			level = 1,
			xp = 0,
		}
	end

	return stats
end

---Returns the configured max level for a stat.
---@param stat FitnessStatName
---@return number
function fitnessSystem.Client.GetMaxLevel(stat)
	local statConfig = fitnessSystem.Config.Stats[stat]

	if not statConfig then
		return 1
	end

	return #statConfig.requiredXP
end

---Returns required XP for a stat level.
---@param stat FitnessStatName
---@param level number
---@return number
function fitnessSystem.Client.GetRequiredXpForLevel(stat, level)
	local statConfig = fitnessSystem.Config.Stats[stat]

	if not statConfig then
		return 0
	end

	return statConfig.requiredXP[level] or 0
end

---Returns whether a stat level is maxed.
---@param stat FitnessStatName
---@param level number
---@return boolean
function fitnessSystem.Client.IsMaxLevel(stat, level)
	local maxLevel = fitnessSystem.Client.GetMaxLevel(stat)
	local requiredXp = fitnessSystem.Client.GetRequiredXpForLevel(stat, level)

	return level >= maxLevel or requiredXp <= 0
end

---Builds UI Ready object for single Stat 
---@param stat FitnessStatName
---@param data FitnessStatData
---@return table
function fitnessSystem.Client.BuildNuiStat(stat, data)
	local statConfig = fitnessSystem.Config.Stats[stat]
	local level = tonumber(data.level) or 1
	local xp = tonumber(data.xp) or 0
	local maxLevel = fitnessSystem.Client.GetMaxLevel(stat)
	local requiredXp = fitnessSystem.Client.GetRequiredXpForLevel(stat, level)

	return {
		label = statConfig and statConfig.label or stat,
		level = level,
		maxLevel = maxLevel,
		xp = xp,
		requiredXp = requiredXp,
		isMaxLevel = level >= maxLevel or requiredXp <= 0,
	}
end

---Builds UI-ready stats for NUI rendering.
---@param stats table<FitnessStatName, FitnessStatData>|nil
---@return table
function fitnessSystem.Client.BuildNuiStats(stats)
	local nuiStats = {}

	for stat, data in pairs(stats or {}) do
		if fitnessSystem.Config.Stats[stat] then
			nuiStats[stat] = fitnessSystem.Client.BuildNuiStat(stat, data)
		end
	end

	return nuiStats
end

---Sends current stats to NUI.
function fitnessSystem.Client.SendStatsToNui()
	SendNUIMessage({
		type = 'updateStats',
		stats = fitnessSystem.Client.BuildNuiStats(fitnessSystem.Client.PlayerStats),
	})
end

---cache stats locally on client
---@param serverStats table<FitnessStatName, FitnessStatData>|nil
function fitnessSystem.Client.SetStats(serverStats)
	local stats = fitnessSystem.Client.BuildDefaultStats()

	for stat, data in pairs(serverStats or {}) do
		if fitnessSystem.Config.Stats[stat] then
			stats[stat] = {
				level = tonumber(data.level) or 1,
				xp = tonumber(data.xp) or 0,
			}
		end
	end

	fitnessSystem.Client.PlayerStats = stats

	if fitnessSystem.Client.UpdateStaminaState and fitnessSystem.Client.PlayerStats[fitnessSystem.Constant.Stat.Stamina] then
		fitnessSystem.Client.UpdateStaminaState(fitnessSystem.Client.PlayerStats
			[fitnessSystem.Constant.Stat.Stamina].level)
	end

	fitnessSystem.Client.SendStatsToNui()
end

---Updates one local stat after server reward.
---@param stat FitnessStatName
---@param level number
---@param xp number
function fitnessSystem.Client.SetStat(stat, level, xp)
	if not fitnessSystem.Config.Stats[stat] then
		return
	end

	fitnessSystem.Client.PlayerStats[stat] = {
		level = tonumber(level) or 1,
		xp = tonumber(xp) or 0,
	}

	fitnessSystem.Client.SendStatsToNui()
end

---Returns the current player stats.
---@return table<FitnessStatName, FitnessStatData>
function fitnessSystem.Client.GetStats()
	return fitnessSystem.Client.PlayerStats
end

--receive server stats and update local stats
RegisterNetEvent('fitness_system:client:sendStats', function(serverStats)
	fitnessSystem.Client.SetStats(serverStats)
end)

CreateThread(function()
	fitnessSystem.Client.PlayerStats = fitnessSystem.Client.BuildDefaultStats()

	fitnessSystem.Client.SendStatsToNui()
end)
