Config = Config or {}

-- ================================================
-- ADMIN
-- ================================================
Config.AdminGroups = { 'admin', 'superadmin', 'god' }

-- ================================================
-- GENERAL
-- ================================================
Config.Debug = false
Config.Locale = 'en'

-- ================================================
-- ELIGIBILITY
-- One-time only: each identifier (license/citizenid)
-- can only claim the welcome once (tracked in DB).
-- Set to false to allow infinite claims (testing).
-- ================================================
Config.OneTimeOnly = true

-- Hide the blip and disable interaction once claimed.
Config.HideAfterClaim = true

-- ================================================
-- PED
-- The NPC that gives the welcome.
-- ================================================
Config.Ped = {
    Model    = 'a_m_y_business_03',
    -- vector4 = { x, y, z, heading }
    Coords   = vector4(-1037.27, -2737.65, 19.17, 311.0),
    Scenario = 'WORLD_HUMAN_CLIPBOARD', -- nil to disable
    Frozen     = true,
    Invincible = true,
    Blip = {
        Enabled = true,
        Sprite  = 280,
        Color   = 2,
        Scale   = 0.8,
        Label   = 'Welcome',
    },
}

-- ================================================
-- INTERACTION
-- Mode = 'auto'     : ox_target > qb-target > distance fallback
-- Mode = 'target'   : force target only (ox_target/qb-target)
-- Mode = 'distance' : marker + key prompt
-- ================================================
Config.Interaction = {
    Mode = 'auto',

    -- Target options (used in target mode)
    TargetIcon  = 'fa-solid fa-hand-wave',
    TargetLabel = 'Receive Welcome',

    -- Distance options (used in distance mode)
    DrawDistance     = 15.0,
    InteractDistance = 1.5,
    Key              = 38, -- E
    PromptText       = '~INPUT_PICKUP~ Receive Welcome',

    -- Marker (only in distance mode)
    Marker = {
        Enabled      = true,
        Type         = 27,
        Size         = vector3(0.8, 0.8, 0.4),
        Color        = { r = 41, g = 121, b = 255, a = 100 },
        HeightOffset = -0.95,
        BobUpAndDown = false,
        Rotate       = false,
    },
}

-- ================================================
-- WELCOME (visual feedback)
-- ================================================
Config.Welcome = {
    -- Progress bar (after interaction, before rewards)
    ProgressEnabled  = true,
    ProgressDuration = 3000,
    ProgressLabel    = 'Receiving welcome package...',
    ProgressAnim     = { dict = 'mp_common', name = 'givetake1_a' },
}

-- ================================================
-- REWARDS
-- ================================================
Config.Rewards = {
    -- Money (set to 0 to disable that account)
    Money = {
        Cash = 5000,
        Bank = 10000,
    },

    -- Items: list of { name = 'item_name', amount = N }
    Items = {
        { name = 'phone',      amount = 1 },
        { name = 'water',      amount = 5 },
        { name = 'bread',      amount = 5 },
        { name = 'id_card',    amount = 1 },
    },

    -- Vehicles
    -- Mode = 'garage' : only inserted into owned_vehicles / player_vehicles
    -- Mode = 'spawn'  : also spawned at Spawn coords (after collision check)
    --
    -- Per-vehicle Garage (optional): label of the nb-garages garage where the
    -- vehicle should appear. If nil, falls back to Config.NbGarages.AssignGarage
    -- (for Mode = 'garage') or 'OUT' (for Mode = 'spawn').
    --
    -- For 'spawn' mode, if the spawn area is blocked the vehicle is still
    -- saved to the player's garage (so the reward is never lost) and a
    -- notification tells the player to retrieve it manually.
    Vehicles = {
        {
            Model  = 'blista',
            Mode   = 'garage',
            Garage = nil, -- nil = use Config.NbGarages.AssignGarage
        },
        {
            Model  = 'sultan',
            Mode   = 'spawn',
            Spawn  = vector4(-1031.85, -2730.17, 20.16, 240.0),
            Garage = nil, -- nil = 'OUT' (the player can store it in any garage)
        },
    },
}

-- ================================================
-- NB-GARAGES INTEGRATION
-- Auto-detected: only used if 'nb-garages' resource is started.
-- Disable to skip integration even when nb-garages is present.
-- ================================================
Config.NbGarages = {
    -- Master switch. Set to false to ignore nb-garages and use Bridge.GiveVehicle
    -- defaults plus manual client spawn for 'spawn' mode.
    Enabled = true,

    -- Default garage label for vehicles with Mode = 'garage'.
    -- MUST exist in your nb-garages `neenbyss_garages` table (label column).
    -- Can be overridden per-vehicle with the `Garage` field above.
    AssignGarage = 'PillboxGarage',

    -- For Mode = 'spawn': use exports['nb-garages']:SpawnPersistentVehicle
    -- (requires nb-garages with Config.PersistentVehicles = true).
    -- When enabled and the export is available, the persistent system spawns
    -- the vehicle (server-side, surviving restarts). When disabled or
    -- unavailable, the script falls back to client-side spawn.
    UseSpawnExport = true,
}

-- ================================================
-- VEHICLE KEYS
-- After a 'spawn' vehicle is created, give the player keys for it.
-- Mode = 'auto'   : detect a known key resource and trigger the right event
-- Mode = 'manual' : use Config.Keys.Manual entry
-- Mode = 'off'    : do nothing (rely on the framework's plate/ownership lookup)
--
-- Auto-detected resources (in priority order):
--   qs-vehiclekeys, wasabi_carlock, MrNewbVehicleKeys,
--   mk_vehiclekeys, qb-vehiclekeys, t1ger_keys
-- ================================================
Config.Keys = {
    Mode = 'auto',

    -- Used when Mode = 'manual'. Side: 'server' (TriggerEvent server-side and
    -- pass the source) or 'client' (TriggerClientEvent for the player).
    -- ArgsType: 'plate' = pass the plate; 'vehicle' = pass the vehicle entity
    -- (client only). Args: extra static args appended after plate/vehicle.
    Manual = {
        Event    = 'vehiclekeys:client:SetOwner',
        Side     = 'client',
        ArgsType = 'plate',
        Args     = {},
    },
}

-- ================================================
-- VEHICLE SPAWN
-- ================================================
Config.VehicleSpawn = {
    -- Radius (meters) for the "is the area clear?" check.
    -- Blocks if any vehicle / object / non-self ped is within radius.
    ClearCheckRadius = 3.5,

    -- Try a fallback offset if the primary spot is blocked.
    -- Set to 0 to disable retries.
    RetryOffsets = {
        vector3(0.0, 0.0, 0.0),
        vector3(3.5, 0.0, 0.0),
        vector3(-3.5, 0.0, 0.0),
        vector3(0.0, 3.5, 0.0),
        vector3(0.0, -3.5, 0.0),
    },

    -- Lock state on spawn ('unlocked' or 'locked')
    LockState = 'unlocked',
}

-- ================================================
-- ADMIN COMMAND
-- /nbpwreset [serverId]  - reset welcome status so target can claim again.
-- ================================================
Config.ResetCommand = 'nbpwreset'
