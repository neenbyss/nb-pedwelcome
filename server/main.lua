-- ================================================
-- SERVER MAIN
-- nb-pedwelcome
-- ================================================

local RESOURCE_NAME = GetCurrentResourceName()

-- ================================================
-- INTERNAL: build the list of vehicles to spawn on the client
-- after the server has committed them to the player's garage.
-- Returns: { { model, plate, mode, spawn = vector4 }, ... }
-- ================================================
---@param src number
---@return table
local function grantVehicles(src)
    local out = {}
    local vehicles = (Config.Rewards and Config.Rewards.Vehicles) or {}

    for _, v in ipairs(vehicles) do
        if v and v.Model then
            local plate = Bridge.NormalizePlate(Bridge.GeneratePlate())
            local props = { plate = plate }

            -- Server-side: persist the vehicle in the player's garage table.
            local ok = pcall(Bridge.GiveVehicle, src, v.Model, props)
            if not ok then
                Debugger('Rewards', 'Bridge.GiveVehicle failed for', v.Model, 'plate', plate)
            end

            if v.Mode == 'spawn' and v.Spawn then
                out[#out + 1] = {
                    model = v.Model,
                    plate = plate,
                    spawn = v.Spawn,
                }
            end
        end
    end

    return out
end

-- ================================================
-- INTERNAL: deliver money rewards
-- ================================================
local function grantMoney(src)
    local money = (Config.Rewards and Config.Rewards.Money) or {}
    if money.Cash and money.Cash > 0 then
        Bridge.AddMoney(src, 'cash', money.Cash, 'nb-pedwelcome')
    end
    if money.Bank and money.Bank > 0 then
        Bridge.AddMoney(src, 'bank', money.Bank, 'nb-pedwelcome')
    end
    return money.Cash or 0, money.Bank or 0
end

-- ================================================
-- INTERNAL: deliver inventory items
-- ================================================
local function grantItems(src)
    local items = (Config.Rewards and Config.Rewards.Items) or {}
    local count = 0
    for _, item in ipairs(items) do
        if item and item.name and (item.amount or 0) > 0 then
            local ok = pcall(Bridge.AddItem, src, item.name, item.amount)
            if ok then
                count = count + 1
            else
                Debugger('Rewards', 'Bridge.AddItem failed for', item.name)
            end
        end
    end
    return count
end

-- ================================================
-- CALLBACK: client asks "can I claim?"
-- Returned: { eligible = bool, reason = 'already' | nil }
-- ================================================
Bridge.CreateCallback(RESOURCE_NAME .. ':isEligible', function(source, respond)
    if not Config.OneTimeOnly then
        return respond({ eligible = true })
    end

    local identifier = Bridge.GetIdentifier(source)
    if not identifier then
        return respond({ eligible = false, reason = 'no_identifier' })
    end

    if Bridge.DB.HasReceived(identifier) then
        return respond({ eligible = false, reason = 'already' })
    end

    respond({ eligible = true })
end)

-- ================================================
-- EVENT: client requests to claim the welcome
-- ================================================
RegisterNetEvent(RESOURCE_NAME .. ':server:claim', function()
    local src = source
    local identifier = Bridge.GetIdentifier(src)
    if not identifier then
        return Bridge.Notify(src, Locale('server_error'), 'error')
    end

    -- Race-safe re-check: HasReceived + MarkReceived in two steps;
    -- the UNIQUE index on identifier guarantees only one INSERT wins.
    if Config.OneTimeOnly then
        if Bridge.DB.HasReceived(identifier) then
            return Bridge.Notify(src, Locale('already_received'), 'error')
        end
        local affected = Bridge.DB.MarkReceived(identifier)
        if affected == 0 then
            -- Concurrent claim won; treat as already received.
            return Bridge.Notify(src, Locale('already_received'), 'error')
        end
    end

    Debugger('Claim', 'Granting welcome to', src, identifier)

    -- Money + items
    local cash, bank = grantMoney(src)
    local itemsGiven = grantItems(src)

    -- Vehicles (DB writes for all, returns the spawn-mode subset)
    local toSpawn = grantVehicles(src)

    -- Tell the client what physical vehicles to attempt to spawn
    if #toSpawn > 0 then
        TriggerClientEvent(RESOURCE_NAME .. ':client:spawnVehicles', src, toSpawn)
    end

    -- Summary notifications
    if cash > 0 or bank > 0 then
        Bridge.Notify(src, Locale('rewards_money', cash, bank), 'success')
    end
    if itemsGiven > 0 then
        Bridge.Notify(src, Locale('rewards_items', itemsGiven), 'success')
    end
    if #(Config.Rewards.Vehicles or {}) > 0 then
        Bridge.Notify(src, Locale('rewards_vehicles', #Config.Rewards.Vehicles), 'success')
    end

    -- Tell the client to refresh blip / target visibility
    TriggerClientEvent(RESOURCE_NAME .. ':client:welcomeComplete', src)
end)

-- ================================================
-- ADMIN COMMAND: reset welcome status for a player
-- /nbpwreset           -> resets self
-- /nbpwreset <serverId> -> resets target
-- ================================================
RegisterCommand(Config.ResetCommand or 'nbpwreset', function(source, args)
    local src = source
    -- Allow console (src == 0) without admin check; players require admin.
    if src ~= 0 and not Bridge.IsAdmin(src) then
        return Bridge.Notify(src, Locale('no_permission'), 'error')
    end

    local targetId = tonumber(args[1]) or src
    if targetId == 0 then
        if src == 0 then
            print('[nb-pedwelcome] Usage: nbpwreset <serverId>')
        end
        return
    end

    local identifier = Bridge.GetIdentifier(targetId)
    if not identifier then
        if src ~= 0 then
            Bridge.Notify(src, Locale('reset_target_invalid'), 'error')
        else
            print('[nb-pedwelcome] Target player not found.')
        end
        return
    end

    Bridge.DB.Reset(identifier)

    if src == targetId and src ~= 0 then
        Bridge.Notify(src, Locale('reset_self'), 'success')
    elseif src ~= 0 then
        Bridge.Notify(src, Locale('reset_success', tostring(targetId)), 'success')
        Bridge.Notify(targetId, Locale('reset_self'), 'info')
    else
        print(('[nb-pedwelcome] Reset welcome status for serverId %d (%s)'):format(targetId, identifier))
        Bridge.Notify(targetId, Locale('reset_self'), 'info')
    end
end, false)

-- ================================================
-- STARTUP
-- ================================================
CreateThread(function()
    print(('[%s] Server loaded. OneTimeOnly=%s'):format(RESOURCE_NAME, tostring(Config.OneTimeOnly)))
end)
