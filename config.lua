fitnessSystem = fitnessSystem or {}
---@type FitnessConfig
fitnessSystem.Config = {}
fitnessSystem.Config.DefaultTrainingCooldown = 30000
fitnessSystem.Config.ServerDistanceTolerance = 2.5

---@type FitnessConstants
fitnessSystem.Constant = {
	Stat = {
		Strength = 'strength',
		Stamina = 'stamina',
	},
}

---@type table<string, FitnessStatConfig>
fitnessSystem.Config.Stats = {
	[fitnessSystem.Constant.Stat.Strength] = {
		label = 'Kraft',
		requiredXP = {
			[1] = 10,
			[2] = 20,
			[3] = 30,
			[4] = 40,
			[5] = 50,
			[6] = 60,
			[7] = 70,
			[8] = 80,
			[9] = 90,
			[10] = 0,
		},
	},

	[fitnessSystem.Constant.Stat.Stamina] = {
		label = 'Ausdauer',
		requiredXP = {
			[1] = 10,
			[2] = 20,
			[3] = 30,
			[4] = 40,
			[5] = 50,
			[6] = 60,
			[7] = 70,
			[8] = 80,
			[9] = 90,
			[10] = 0,
		},
	},
}

---@type TrainingSpot[]
fitnessSystem.Config.TrainingPoints = {
	{
		label = 'Hanteltraining',
		type = 'dumbbells',
		stat = {fitnessSystem.Constant.Stat.Strength},
		xp = { min = 15, max = 30 },
		duration = 1000,
		coords = vector3(1645.4064, 2536.7456, 45.5648),
		radius = 1.5,
		cooldown = 2500,
		scenario = 'WORLD_HUMAN_MUSCLE_FREE_WEIGHTS',
	},
	{
		label = 'Bankdrücken',
		type = 'bench',
		stat = {fitnessSystem.Constant.Stat.Strength},
		xp = { min = 20, max = 40 },
		duration = 1000,
		coords = vector3(1640.5424, 2532.8516, 45.9485),
		radius = 1.5,
		cooldown = 2500,
		scenario = 'WORLD_HUMAN_PUSH_UPS',
	},
	{
		label = 'Klimmzüge',
		type = 'pullups',
		stat = {fitnessSystem.Constant.Stat.Stamina, fitnessSystem.Constant.Stat.Strength},
		xp = { min = 15, max = 25 },
		duration = 1000,
		coords = vector3(1643.0869, 2528.0415, 45.5570),
		radius = 1.5,
		cooldown = 2500,
		scenario = 'WORLD_HUMAN_CHIN_UPS',
	},
	{
		label = 'Sit-Ups',
		type = 'situps',
		stat = {fitnessSystem.Constant.Stat.Stamina},
		xp = { min = 15, max = 45 },
		duration = 1000,
		coords = vector3(1646.1146, 2526.0100, 45.5648),
		radius = 1.5,
		cooldown = 2500,
		scenario = 'WORLD_HUMAN_SIT_UPS',
	},
}