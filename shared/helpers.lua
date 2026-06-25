fitnessSystem = fitnessSystem or {}
fitnessSystem.Shared = fitnessSystem.Shared or {}
fitnessSystem.Shared.Helpers = fitnessSystem.Shared.Helpers or {}

---Returns the configured max level for a stat.
---@param stat FitnessStatName
---@return number
function fitnessSystem.Shared.Helpers.GetMaxLevel(stat)
    local statConfig = fitnessSystem.Config.Stats[stat]

    if not statConfig then
        return 1
    end

    return #statConfig.requiredXP
end
