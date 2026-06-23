local errorMessages = {
    cooldown = function(result)
        return ('Du musst noch %d Sekunden warten, bevor du wieder trainieren kannst.'):format(
            tonumber(result.cooldownLeft) or 0
        )
    end,

    too_far = 'Player is too far away from the training spot.',
    invalid_spot = 'Invalid training spot.',
    invalid_stat = 'Invalid training stat.',
    invalid_xp = 'Invalid XP configuration for training spot.',
    save_failed = 'Failed to save training progress.',
}

local shouldLogReason = {
    too_far = true,
    invalid_spot = true,
    invalid_stat = true,
    invalid_xp = true,
    save_failed = true,
}

ESX.RegisterServerCallback('fitness_system:server:canStartTraining', function(src, cb, spotType)
    local xPlayer = ESX.GetPlayerFromId(src)

    if not xPlayer then
        cb(false, 'player_not_found', 0)
        return
    end

    cb(fitnessSystem.Server.Service.CanStartTraining(src, spotType))
end)

---Sends fitness stats to the client.
---@param playerId number
---@param identifier string
local function sendFitnessStats(playerId, identifier)
    local stats = fitnessSystem.Server.Service.GetStats(identifier)
    TriggerClientEvent('fitness_system:client:sendStats', playerId, stats)
end

-- setup stats for loaded players
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer, isNew)
    if not xPlayer or not xPlayer.identifier then
        return
    end

    if isNew then -- If the player is new he doesnt need data. Defaults are build clientside
        return
    end

    sendFitnessStats(playerId, xPlayer.identifier)
end)

AddEventHandler('playerDropped', function()
    fitnessSystem.Server.Service.ClearPlayer(source)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    CreateThread(function()
        for _, xPlayer in ipairs(ESX.GetExtendedPlayers()) do
            local src = tonumber(xPlayer.source)

            if src then
                fitnessSystem.Server.Service.ClearPlayer(src)
                
                if xPlayer and xPlayer.identifier then
                    sendFitnessStats(src, xPlayer.identifier)
                end
            end
        end
    end)
end)

---@param src number player source Id
---@param identifier string player db identifier
---@param result TrainingProcessResult
local function handleTrainingError(src, identifier, result)
    local reason = result.reason or 'unknown'
    local message = errorMessages[reason]

    if shouldLogReason[reason] then
        print(('[FitnessSystem] Training failed | player=%s | reason=%s | message=%s'):format(
            tostring(identifier),
            tostring(reason),
            tostring(errorMessages[reason] or 'Unknown training error.')
        ))
    end

    if type(message) == 'function' then
        message = message(result)
    else
        message = 'Training aktuell nicht möglich.'
    end

    TriggerClientEvent('esx:showNotification', src, message)
end

RegisterNetEvent('fitness_system:server:requestTrain', function(spotType)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if not xPlayer then
        return
    end
    local identifier = xPlayer.identifier

    local result = fitnessSystem.Server.Service.ProcessTrainingRequest(
        src,
        identifier,
        spotType
    )

    if not result.ok then
        handleTrainingError(src, identifier, result)
        return
    end

    TriggerClientEvent(
        'fitness_system:client:rewarded',
        src,
        result.stat,
        result.level,
        result.xp,
        result.xpGained,
        result.leveledUp
    )
end)
