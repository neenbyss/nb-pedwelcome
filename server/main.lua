-- ================================================
-- SERVER MAIN
-- nb-pedwelcome
-- ================================================

local RESOURCE_NAME = GetCurrentResourceName()

-- ================================================
-- INTEGRATIONS: nb-garages + key system detection
-- ================================================
local function nbGaragesAvailable()
    return Config.NbGarages
        and Config.NbGarages.Enabled
        and GetResourceState('nb-garages') == 'started'
end

local function nbGaragesPersistentSpawnAvailable()
    if not nbGaragesAvailable() then return false end
    if not Config.NbGarages.UseSpawnExport then return false end
    -- The export is only registered when nb-garages has Config.PersistentVehicles = true
    -- so a pcall'd call returning a usable result means it's available.
    local exp = exports['nb-garages']
    return exp and exp.SpawnPersistentVehicle ~= nil
end

---Detect which vehicle-keys resource is running.
---@return string|nil  one of: 'qs','wasabi','mrnewb','mk','qb','t1ger', or nil
local function detectKeyResource()
    if GetResourceState('qs-vehiclekeys')   == 'started' then return 'qs'     end
    if GetResourceState('wasabi_carlock')   == 'started' then return 'wasabi' end
    if GetResourceState('MrNewbVehicleKeys') == 'started' then return 'mrnewb' end
    if GetResourceState('mk_vehiclekeys')   == 'started' then return 'mk'     end
    if GetResourceState('qb-vehiclekeys')   == 'started' then return 'qb'     end
    if GetResourceState('t1ger_keys')       == 'started' then return 't1ger'  end
    return nil
end

---Give keys for a plate to a player, by either auto-detection or manual config.
---Safe: any resource missing or export erroring is logged and ignored.
---@param src number
---@param plate string
local function giveVehicleKeys(src, plate)
    local mode = (Config.Keys and Config.Keys.Mode) or 'auto'
    if mode == 'off' then return end

    if mode == 'manual' then
        local m = Config.Keys.Manual or {}
        if not m.Event then return end
        -- Manual server side fires here; manual client side is fired from client/main.lua
        if m.Side == 'server' then
            TriggerEvent(m.Event, src, plate, table.unpack(m.Args or {}))
        end
        return
    end

    -- mode == 'auto'
    local resource = detectKeyResource()
    if not resource then
        Debugger('Keys', 'No supported key resource detected; skipping')
        return
    end

    local ok, err = pcall(function()
        if resource == 'qs' then
            -- exports['qs-vehiclekeys']:GiveKeys(plate, source, isPersist)
            exports['qs-vehiclekeys']:GiveKeys(plate, src, true)
        elseif resource == 'wasabi' then
            -- exports.wasabi_carlock:GiveKey(source, plate)
            exports.wasabi_carlock:GiveKey(src, plate)
        elseif resource == 'mrnewb' then
            -- exports['MrNewbVehicleKeys']:GiveKeys(source, plate)
            exports['MrNewbVehicleKeys']:GiveKeys(src, plate)
        elseif resource == 'mk' then
            -- mk_vehiclekeys exposes a client event most commonly
            TriggerClientEvent('mk_vehiclekeys:client:add', src, plate)
        elseif resource == 'qb' then
            -- qb-vehiclekeys: client event sets the local owner
            TriggerClientEvent('vehiclekeys:client:SetOwner', src, plate)
        elseif resource == 't1ger' then
            TriggerClientEvent('t1ger_keys:client:addKey', src, plate)
        end
    end)
    if not ok then
        Debugger('Keys', 'Failed to give keys via', resource, '->', tostring(err))
    end
end

---Spawn a vehicle via nb-garages persistent system. Returns true on success.
---@param plate string
---@param spawn vector4
---@return boolean
local function nbGaragesSpawn(plate, spawn)
    local pos = vector4(spawn.x, spawn.y, spawn.z, spawn.w or 0.0)
    local ok, netIdOrErr = pcall(function()
        return exports['nb-garages']:SpawnPersistentVehicle(plate, pos)
    end)
    if not ok or not netIdOrErr or netIdOrErr == false then
        Debugger('NbGarages', 'SpawnPersistentVehicle failed for plate', plate, '->', tostring(netIdOrErr))
        return false
    end
    return true
end

-- ================================================
-- INTERNAL: build the list of vehicles to spawn on the client.
-- Returns: { { model, plate, spawn }, ... } only for entries that
-- still need a client-side spawn (nb-garages spawn export not used).
-- ================================================
---@param src number
---@return table
local function grantVehicles(src)
    local toSpawnClient = {}
    local vehicles = (Config.Rewards and Config.Rewards.Vehicles) or {}
    local hasNbGarages = nbGaragesAvailable()
    local canPersistSpawn = nbGaragesPersistentSpawnAvailable()
    local defaultGarage = (Config.NbGarages and Config.NbGarages.AssignGarage) or 'PillboxGarage'

    for _, v in ipairs(vehicles) do
        if v and v.Model then
            local plate = Bridge.NormalizePlate(Bridge.GeneratePlate())
            local props = { plate = plate }

            -- 1) Persist the vehicle in the framework's vehicle table.
            local ok = pcall(Bridge.GiveVehicle, src, v.Model, props)
            if not ok then
                Debugger('Rewards', 'Bridge.GiveVehicle failed for', v.Model, 'plate', plate)
            end

            -- 2) Set the garage column (nb-garages compat).
            if hasNbGarages then
                local label
                if v.Mode == 'spawn' then
                    label = v.Garage or 'OUT'
                else
                    label = v.Garage or defaultGarage
                end
                Bridge.DB.SetVehicleGarage(plate, label)
            end

            -- 3) Give keys (most modern key resources cope without this, but
            --    the explicit handshake helps with key UIs / temp spawn caches).
            giveVehicleKeys(src, plate)

            -- 4) Physical spawn for Mode = 'spawn'.
            if v.Mode == 'spawn' and v.Spawn then
                local spawnedByGarages = false
                if canPersistSpawn then
                    spawnedByGarages = nbGaragesSpawn(plate, v.Spawn)
                end
                if not spawnedByGarages then
                    -- Fall back to client-side spawn.
                    toSpawnClient[#toSpawnClient + 1] = {
                        model = v.Model,
                        plate = plate,
                        spawn = v.Spawn,
                    }
                end
            end
        end
    end

    return toSpawnClient
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
