---@class FitnessStatData
---@field level number Current level of the stat.
---@field xp number Current XP progress within the current level.

---@alias FitnessStatName 'stamina'|'strength'

---@class FitnessConstants
---@field Stat FitnessStatConstants

---@class FitnessStatConstants
---@field Strength FitnessStatName
---@field Stamina FitnessStatName

---@class FitnessStatConfig
---@field label string Stat Name label for display in the UI.
---@field requiredXP table<number, number> required XP to advance to the next level. Value 0 = max level.

---@class TrainingSpotXpRange
---@field min number
---@field max number

---@class TrainingSpot
---@field label string Spot Name label for display in the UI.
---@field type string Unique station key used for cooldown tracking.
---@field stat FitnessStatName|FitnessStatName[] Stat rewarded by this station.
---@field xp number|TrainingSpotXpRange XP awarded per completed session.
---@field duration number Training animation duration in milliseconds.
---@field coords vector3 Coordinates of the training spot.
---@field radius number Interaction radius in metres.
---@field cooldown number|nil Cooldown in milliseconds, uses Default if not defined
---@field scenario string|nil Scenario Animation during training

---@class FitnessConfig
---@field DefaultTrainingCooldown number Default cooldown in milliseconds if CD is not defined
---@field ServerDistanceTolerance number tolerance for distance verification 
---@field Stats table<FitnessStatName, FitnessStatConfig>
---@field TrainingPoints TrainingSpot[]

---@class TrainingProcessResult
---@field ok boolean
---@field reason string|nil
---@field cooldownLeft number|nil if cooldown exists
---@field statName string|nil if reached maxlevel
---@field maxLevel number|nil if reached maxlevel
---@field stat FitnessStatName|nil
---@field level number|nil
---@field xp number|nil
---@field xpGained number|nil
---@field leveledUp boolean|nil