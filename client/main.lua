-- ================================================
-- CLIENT MAIN
-- nb-pedwelcome
-- ================================================

local RESOURCE_NAME = GetCurrentResourceName()

-- Runtime state
local pedHandle = nil
local blipHandle = nil
local targetRegistered = false
local distanceThreadActive = false
local interactionEnabled = true   -- becomes false after claim if HideAfterClaim
local claiming = false

-- ================================================
-- HELPERS
-- ================================================

local function getTargetSystem()
    local mode = Config.Interaction and Config.Interaction.Mode or 'auto'
    if mode == 'distance' then return nil end

    if GetResourceState('ox_target') == 'started' then return 'ox' end
    if GetResourceState('qb-target') == 'started' then return 'qb' end

    if mode == 'target' then
        Debugger('Target', 'Target mode forced but no target system found, falling back to distance.')
    end
    return nil
end

local function loadModel(model)
    local hash = type(model) == 'string' and joaat(model) or model
    if not IsModelInCdimage(hash) then return nil end
    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) do
        Wait(0)
        if GetGameTimer() > timeout then return nil end
    end
    return hash
end

-- ================================================
-- BLIP
-- ================================================
local function createBlip()
    local b = Config.Ped and Config.Ped.Blip
    if not b or not b.Enabled then return end

    local c = Config.Ped.Coords
    local blip = AddBlipForCoord(c.x, c.y, c.z)
    SetBlipSprite(blip, b.Sprite or 280)
    SetBlipColour(blip, b.Color or 2)
    SetBlipScale(blip, b.Scale or 0.8)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(b.Label or 'Welcome')
    EndTextCommandSetBlipName(blip)

    blipHandle = blip
end

local function removeBlip()
    if blipHandle and DoesBlipExist(blipHandle) then
        RemoveBlip(blipHandle)
    end
    blipHandle = nil
end

-- ================================================
-- INTERACTION HANDLERS
-- ================================================

local function startClaim()
    if not interactionEnabled or claiming then return end
    claiming = true

    Bridge.TriggerServerCallback(RESOURCE_NAME .. ':isEligible', function(result)
        if not result or not result.eligible then
            if result and result.reason == 'already' then
                Bridge.ShowNotification(Locale('already_received'), 'error')
            else
                Bridge.ShowNotification(Locale('server_error'), 'error')
            end
            claiming = false
            return
        end

        Bridge.ShowNotification(Locale('welcome_starting'), 'info')

        if Config.Welcome and Config.Welcome.ProgressEnabled then
            Bridge.Progress(
                Config.Welcome.ProgressDuration or 3000,
                Config.Welcome.ProgressLabel or 'Receiving welcome package...',
                Config.Welcome.ProgressAnim
            )
        end

        TriggerServerEvent(RESOURCE_NAME .. ':server:claim')
        -- claiming flag cleared in welcomeComplete handler (or 5s safety reset below)
        SetTimeout(5000, function() claiming = false end)
    end)
end

-- ----- Target system registration -----
local function registerTarget(system)
    if targetRegistered or not pedHandle or not DoesEntityExist(pedHandle) then return end

    if system == 'ox' then
        exports.ox_target:addLocalEntity(pedHandle, {{
            name     = RESOURCE_NAME .. ':welcome',
            label    = Config.Interaction.TargetLabel or 'Receive Welcome',
            icon     = Config.Interaction.TargetIcon or 'fa-solid fa-hand-wave',
            distance = Config.Interaction.InteractDistance or 2.0,
            onSelect = startClaim,
            canInteract = function() return interactionEnabled end,
        }})
        targetRegistered = true
    elseif system == 'qb' then
        exports['qb-target']:AddTargetEntity(pedHandle, {
            options = {{
                type     = 'client',
                icon     = Config.Interaction.TargetIcon or 'fas fa-hand-wave',
                label    = Config.Interaction.TargetLabel or 'Receive Welcome',
                action   = startClaim,
                canInteract = function() return interactionEnabled end,
            }},
            distance = Config.Interaction.InteractDistance or 2.0,
        })
        targetRegistered = true
    end
end

local function unregisterTarget(system)
    if not targetRegistered or not pedHandle then return end
    if system == 'ox' then
        pcall(exports.ox_target.removeLocalEntity, exports.ox_target, pedHandle, RESOURCE_NAME .. ':welcome')
    elseif system == 'qb' then
        pcall(exports['qb-target'].RemoveTargetEntity, exports['qb-target'], pedHandle)
    end
    targetRegistered = false
end

-- ----- Distance / key prompt loop -----
local function startDistanceLoop()
    if distanceThreadActive then return end
    distanceThreadActive = true

    CreateThread(function()
        local cfg = Config.Interaction
        local m = cfg.Marker or {}
        local pedCoords = vector3(Config.Ped.Coords.x, Config.Ped.Coords.y, Config.Ped.Coords.z)

        while distanceThreadActive do
            local sleep = 750
            if interactionEnabled and pedHandle and DoesEntityExist(pedHandle) then
                local playerCoords = GetEntityCoords(PlayerPedId())
                local dist = #(playerCoords - pedCoords)

                if dist < (cfg.DrawDistance or 15.0) then
                    sleep = 0

                    if m.Enabled then
                        DrawMarker(
                            m.Type or 27,
                            pedCoords.x, pedCoords.y, pedCoords.z + (m.HeightOffset or -0.95),
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            (m.Size and m.Size.x) or 0.8,
                            (m.Size and m.Size.y) or 0.8,
                            (m.Size and m.Size.z) or 0.4,
                            (m.Color and m.Color.r) or 41,
                            (m.Color and m.Color.g) or 121,
                            (m.Color and m.Color.b) or 255,
                            (m.Color and m.Color.a) or 100,
                            m.BobUpAndDown or false,
                            true, 2,
                            m.Rotate or false,
                            nil, nil, false
                        )
                    end

                    if dist < (cfg.InteractDistance or 1.5) then
                        BeginTextCommandDisplayHelp('STRING')
                        AddTextComponentSubstringPlayerName(cfg.PromptText or '~INPUT_PICKUP~ Receive Welcome')
                        EndTextCommandDisplayHelp(0, false, true, -1)

                        if IsControlJustReleased(0, cfg.Key or 38) then
                            startClaim()
                        end
                    end
                end
            end
            Wait(sleep)
        end
    end)
end

local function stopDistanceLoop()
    distanceThreadActive = false
end

-- ================================================
-- PED SPAWN
-- ================================================
local function spawnPed()
    if pedHandle and DoesEntityExist(pedHandle) then return end

    local cfg = Config.Ped
    local hash = loadModel(cfg.Model)
    if not hash then
        Debugger('Ped', 'Failed to load model:', cfg.Model)
        return
    end

    local c = cfg.Coords
    local ped = CreatePed(0, hash, c.x, c.y, c.z - 1.0, c.w or 0.0, false, true)
    SetModelAsNoLongerNeeded(hash)

    if not DoesEntityExist(ped) then
        Debugger('Ped', 'Failed to create ped at', c)
        return
    end

    if cfg.Frozen then FreezeEntityPosition(ped, true) end
    if cfg.Invincible then
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
    end
    if cfg.Scenario then
        TaskStartScenarioInPlace(ped, cfg.Scenario, 0, true)
    end

    pedHandle = ped
    Debugger('Ped', 'Spawned ped', ped)
end

local function despawnPed()
    if pedHandle and DoesEntityExist(pedHandle) then
        DeleteEntity(pedHandle)
    end
    pedHandle = nil
end

-- ================================================
-- INTERACTION SETUP
-- ================================================
local function setupInteraction()
    local system = getTargetSystem()
    if system then
        registerTarget(system)
    else
        startDistanceLoop()
    end
end

local function teardownInteraction()
    unregisterTarget('ox')
    unregisterTarget('qb')
    stopDistanceLoop()
end

-- ================================================
-- VEHICLE SPAWN (collision-checked)
-- ================================================

---@param coords vector3
---@param radius number
---@return boolean clear
local function isAreaClear(coords, radius)
    radius = radius or 3.5

    if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, radius) then
        return false
    end

    -- Other players
    for _, pid in ipairs(GetActivePlayers()) do
        if pid ~= PlayerId() then
            local p = GetPlayerPed(pid)
            if p ~= 0 and DoesEntityExist(p) then
                local pc = GetEntityCoords(p)
                if #(pc - coords) < radius then return false end
            end
        end
    end

    -- Object check via raycast (covers most static props in the way)
    local ray = StartShapeTestSphere(coords.x, coords.y, coords.z, radius * 0.6, -1, nil, 0)
    local _, hit, _, _, _ = GetShapeTestResult(ray)
    if hit and hit ~= 0 then return false end

    return true
end

---@param baseCoords vector4
---@return vector3|nil clearOffsetCoords, number? heading
local function findClearSpot(baseCoords)
    local cfg = Config.VehicleSpawn or {}
    local radius = cfg.ClearCheckRadius or 3.5
    local offsets = cfg.RetryOffsets or { vector3(0, 0, 0) }
    local heading = baseCoords.w or 0.0

    for _, offset in ipairs(offsets) do
        local test = vector3(baseCoords.x + offset.x, baseCoords.y + offset.y, baseCoords.z + offset.z)
        if isAreaClear(test, radius) then
            return test, heading
        end
    end
    return nil, heading
end

-- Server-side already gives keys for known systems; this is a client-only
-- safety net for resources that need a local "I just got this car" event
-- (typically to refresh a local cache or show an icon).
local function fireKeysEvent(plate, vehicle)
    local cfg = Config.Keys or {}
    if cfg.Mode == 'off' then return end

    if cfg.Mode == 'manual' then
        local m = cfg.Manual or {}
        if not m.Event or m.Side ~= 'client' then return end
        local payload = (m.ArgsType == 'vehicle') and vehicle or plate
        TriggerEvent(m.Event, payload, table.unpack(m.Args or {}))
        return
    end

    -- mode == 'auto' (default): refresh client caches for known systems
    if GetResourceState('qb-vehiclekeys') == 'started' then
        TriggerEvent('vehiclekeys:client:SetOwner', plate)
    elseif GetResourceState('mk_vehiclekeys') == 'started' then
        TriggerEvent('mk_vehiclekeys:client:add', plate)
    elseif GetResourceState('t1ger_keys') == 'started' then
        TriggerEvent('t1ger_keys:client:addKey', plate)
    end
    -- qs-vehiclekeys, wasabi_carlock, MrNewbVehicleKeys are handled server-side.
end

---@param entry table { model, plate, spawn = vector4 }
local function spawnRewardVehicle(entry)
    local clearCoords, heading = findClearSpot(entry.spawn)
    if not clearCoords then
        Bridge.ShowNotification(Locale('vehicle_spawn_blocked', entry.model), 'warning')
        return
    end

    Bridge.SpawnVehicle(entry.model, clearCoords, heading, nil, entry.plate, function(vehicle)
        if not vehicle or not DoesEntityExist(vehicle) then
            Bridge.ShowNotification(Locale('vehicle_spawn_failed', entry.model), 'warning')
            return
        end

        SetVehicleNumberPlateText(vehicle, entry.plate)
        SetVehicleEngineOn(vehicle, false, true, true)

        local lockState = (Config.VehicleSpawn or {}).LockState or 'unlocked'
        SetVehicleDoorsLocked(vehicle, lockState == 'locked' and 2 or 1)

        fireKeysEvent(entry.plate, vehicle)
        Bridge.ShowNotification(Locale('vehicle_spawned', entry.model, entry.plate), 'success')
    end)
end

-- ================================================
-- NET EVENTS
-- ================================================

RegisterNetEvent(RESOURCE_NAME .. ':client:spawnVehicles', function(list)
    if type(list) ~= 'table' then return end
    for _, entry in ipairs(list) do
        if entry and entry.model and entry.spawn then
            spawnRewardVehicle(entry)
        end
    end
end)

RegisterNetEvent(RESOURCE_NAME .. ':client:welcomeComplete', function()
    claiming = false
    Bridge.ShowNotification(Locale('welcome_complete'), 'success')

    if Config.HideAfterClaim then
        interactionEnabled = false
        teardownInteraction()
        removeBlip()
    end
end)

-- ================================================
-- LIFECYCLE
-- ================================================

local function bootstrap()
    -- Decide visibility based on eligibility (so claimed players don't see the blip)
    Bridge.TriggerServerCallback(RESOURCE_NAME .. ':isEligible', function(result)
        local eligible = result and result.eligible
        interactionEnabled = eligible and true or (not Config.HideAfterClaim)

        spawnPed()

        if interactionEnabled then
            createBlip()
            setupInteraction()
        end
    end)
end

Bridge.OnPlayerLoaded(function()
    bootstrap()
end)

-- If the resource is started while a player is already in-game.
CreateThread(function()
    Wait(2000)
    if not pedHandle then
        bootstrap()
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= RESOURCE_NAME then return end
    teardownInteraction()
    despawnPed()
    removeBlip()
end)

print('[' .. RESOURCE_NAME .. '] Client loaded')
