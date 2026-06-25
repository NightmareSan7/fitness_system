fitnessSystem = fitnessSystem or {}
fitnessSystem.Server = fitnessSystem.Server or {}
fitnessSystem.Server.Service = fitnessSystem.Server.Service or {}

local playerCooldowns = {}

---Returns persisted stats only. Missing stats are handled client-side.
---@param identifier string
---@return table<FitnessStatName, FitnessStatData>
function fitnessSystem.Server.Service.GetStats(identifier)
	return fitnessSystem.Server.Repository.GetStats(identifier)
end

---Checks if given spotType is valid and returns it
---@param spotType string
---@return TrainingSpot|nil Spot Table or nil if not found
function fitnessSystem.Server.Service.GetSpot(spotType)
	for _, spot in ipairs(fitnessSystem.Config.TrainingPoints) do
		if spot.type == spotType then
			return spot
		end
	end

	return nil
end

---Checks if the player can use the station based on cooldowns.
---@param src number player source Id
---@param spot TrainingSpot
---@return boolean canUse
---@return number cooldownLeft Cooldown left in seconds.
function fitnessSystem.Server.Service.CanUseStation(src, spot)
	local lastUsed = playerCooldowns[src] and playerCooldowns[src][spot.type]

	if not lastUsed then
		return true, 0
	end

	local cooldownLeft = math.max(0,
		math.ceil((spot.cooldown or fitnessSystem.Config.DefaultTrainingCooldown) / 1000) - (os.time() - lastUsed))

	return cooldownLeft <= 0, cooldownLeft
end

---Sets the cooldown for a player at a specific training spot.
---@param src number player source Id
---@param spot TrainingSpot
function fitnessSystem.Server.Service.SetStationCooldown(src, spot)
	playerCooldowns[src] = playerCooldowns[src] or {}
	playerCooldowns[src][spot.type] = os.time()
end

---Calculate XP gained and apply level up if needed
---@param requiredXP table table of required XP for Stat
---@param currentLevel number current level of the player Stat
---@param currentXp number current XP of the player Stat
---@param xpGained number XP gained from training
---@return number newLevel
---@return number newXp
---@return boolean leveledUp
function fitnessSystem.Server.Service.CalculateXpProgress(requiredXP, currentLevel, currentXp, xpGained)
	local level = currentLevel
	local xp = currentXp + xpGained
	local leveledUp = false
	local needed = requiredXP[level] or 0

	while needed > 0 and xp >= needed do
		xp = xp - needed
		level = level + 1
		leveledUp = true
		needed = requiredXP[level] or 0
	end
	if needed <= 0 then
		xp = 0
	end

	return level, xp, leveledUp
end

---Check if the Player is in range of the training spot
---@param src number player source Id
---@param spot TrainingSpot
---@return boolean
function fitnessSystem.Server.Service.IsPlayerNearSpot(src, spot)
	local ped = GetPlayerPed(src)

	if not ped or ped == 0 then
		return false
	end

	local coords = GetEntityCoords(ped)
	local tolerance = fitnessSystem.Config.ServerDistanceTolerance or 2.0
	local distance = #(coords - spot.coords)

	if distance >= (spot.radius + tolerance) then
		print(('[FitnessSystem] Player %s is too far from spot %s: distance=%.2f, tolerance=%.2f'):format(
			src, spot.type, distance, spot.radius + tolerance))
		return false
	end

	return true
end

---Clears the cooldown of a player
---@param src number player source Id
function fitnessSystem.Server.Service.ClearPlayer(src)
	if not src then return end
	playerCooldowns[src] = nil
end

---Clears spot cooldown for player
---@param src number player source Id
---@param spotType string
function fitnessSystem.Server.Service.ClearStationCooldown(src, spotType)
    if playerCooldowns[src] then
        playerCooldowns[src][spotType] = nil
    end
end

---check if player satisfies conditions for training
---@param src number player source Id
---@param spotType string spot Type
---@return boolean canTrain
---@return string|nil reason
---@return integer cooldownLeft
function fitnessSystem.Server.Service.CanStartTraining(src, spotType)
	local spot = fitnessSystem.Server.Service.GetSpot(spotType)

	if not spot then
		print(('[FitnessSystem] Invalid training spot type requested by player %s: %s'):format(src, spotType))
		return false, 'invalid_spot', 0
	end

	local canUse, cooldownLeft = fitnessSystem.Server.Service.CanUseStation(src, spot)

	if not canUse then
		return false, 'cooldown', cooldownLeft
	end

	if not fitnessSystem.Server.Service.IsPlayerNearSpot(src, spot) then
		return false, 'too_far', 0
	end
	return true, nil, 0
end

---Processes a training request for a player. Checks cooldowns, distance, and applies XP and level up if needed.
---@param src number player source Id
---@param identifier string player db identifier
---@param spotType string
---@return TrainingProcessResult
function fitnessSystem.Server.Service.ProcessTrainingRequest(src, identifier, spotType)
	local spot = fitnessSystem.Server.Service.GetSpot(spotType)
	if not spot then
		return { ok = false, reason = 'invalid_spot' }
	end

	local canUse, cooldownLeft = fitnessSystem.Server.Service.CanUseStation(src, spot)

	if not canUse then
		return { ok = false, reason = 'cooldown', cooldownLeft = cooldownLeft }
	end

	if not fitnessSystem.Server.Service.IsPlayerNearSpot(src, spot) then
		return { ok = false, reason = 'too_far' }
	end

	local statName = type(spot.stat) == 'table' and spot.stat[math.random(#spot.stat)] or spot.stat
	if not statName or not fitnessSystem.Config.Stats[statName] then
		return { ok = false, reason = 'invalid_stat' }
	end

	local xpGained = type(spot.xp) == 'table' and math.random(spot.xp.min, spot.xp.max) or spot.xp
	if type(xpGained) ~= 'number' or xpGained <= 0 then
		return { ok = false, reason = 'invalid_xp' }
	end

	fitnessSystem.Server.Service.SetStationCooldown(src, spot)

	local currentStat = fitnessSystem.Server.Repository.GetStat(identifier, statName)
	local currentLevel = currentStat and currentStat.level or 1
	local currentXp = currentStat and currentStat.xp or 0
	local maxLevel = fitnessSystem.Shared.Helpers.GetMaxLevel(statName)

	if currentLevel >= maxLevel then
		return {
			ok = false,
			reason = 'max_level',
			statName = fitnessSystem.Config.Stats[statName].label,
			maxLevel =
				maxLevel
		}
	end

	local newLevel, newXp, leveledUp = fitnessSystem.Server.Service.CalculateXpProgress(
		fitnessSystem.Config.Stats[statName].requiredXP, currentLevel, currentXp, xpGained)

	local saved = fitnessSystem.Server.Repository.UpsertStat(identifier, statName, newLevel, newXp)

	if not saved then
		fitnessSystem.Server.Service.ClearStationCooldown(src, spotType)
		return { ok = false, reason = 'save_failed' }
	end

	return {
		ok = true,
		stat = statName,
		level = newLevel,
		xp = newXp,
		xpGained = xpGained,
		leveledUp = leveledUp
	}
end
