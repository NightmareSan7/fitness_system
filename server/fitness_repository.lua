fitnessSystem = fitnessSystem or {}
fitnessSystem.Server = fitnessSystem.Server or {}
fitnessSystem.Server.Repository = fitnessSystem.Server.Repository or {}

--- Initialize the DB if it doesnt exist
function fitnessSystem.Server.Repository.Initialize()
	MySQL.query.await([[
		CREATE TABLE IF NOT EXISTS `fitness_stats` (
			`identifier` VARCHAR(60) NOT NULL,
			`stat` VARCHAR(32) NOT NULL,
			`level` INT NOT NULL DEFAULT 1,
			`xp` INT NOT NULL DEFAULT 0,
			PRIMARY KEY (`identifier`, `stat`),
			CONSTRAINT `fk_fitness_stats_users_identifier`
				FOREIGN KEY (`identifier`)
				REFERENCES `users` (`identifier`)
				ON DELETE CASCADE
				ON UPDATE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	]])
end

CreateThread(function()
	fitnessSystem.Server.Repository.Initialize()
end)

---Fetches one fitness stat for an identifier.
---@param identifier string
---@param stat FitnessStatName
---@return FitnessStatData|nil
function fitnessSystem.Server.Repository.GetStat(identifier, stat)
	local row = MySQL.single.await(
		'SELECT level, xp FROM fitness_stats WHERE identifier = ? AND stat = ?',
		{ identifier, stat }
	)

	if not row then
		return nil
	end

	return {
		level = row.level,
		xp = row.xp,
	}
end

---Fetches all fitness stats for an identifier.
---@param identifier string
---@return table<FitnessStatName, FitnessStatData>
function fitnessSystem.Server.Repository.GetStats(identifier)
	local rows = MySQL.query.await(
		'SELECT stat, level, xp FROM fitness_stats WHERE identifier = ?',
		{ identifier }
	)

	local stats = {}

	for _, row in ipairs(rows or {}) do
		stats[row.stat] = {
			level = row.level,
			xp = row.xp,
		}
	end

	return stats
end

---Creates or updates one fitness stat.
---@param identifier string
---@param stat FitnessStatName
---@param level number
---@param xp number
---@return boolean success
function fitnessSystem.Server.Repository.UpsertStat(identifier, stat, level, xp)
	local affectedRows = MySQL.update.await(
		[[
			INSERT INTO fitness_stats (identifier, stat, level, xp)
			VALUES (?, ?, ?, ?)
			ON DUPLICATE KEY UPDATE
				level = VALUES(level),
				xp = VALUES(xp)
		]],
		{ identifier, stat, level, xp }
	)

	return affectedRows ~= nil and affectedRows >= 0
end
