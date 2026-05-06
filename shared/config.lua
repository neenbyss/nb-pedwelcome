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
    -- mode = 'garage' : only inserted into owned_vehicles / player_vehicles
    -- mode = 'spawn'  : also spawned at Spawn coords (after collision check)
    --
    -- For 'spawn' mode, if the spawn area is blocked the vehicle is still
    -- saved to the player's garage (so the reward is never lost) and a
    -- notification tells the player to retrieve it manually.
    Vehicles = {
        {
            Model = 'blista',
            Mode  = 'garage',
        },
        {
            Model = 'sultan',
            Mode  = 'spawn',
            Spawn = vector4(-1031.85, -2730.17, 20.16, 240.0),
        },
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

    -- Optional: trigger a key-system event after spawn so the player
    -- has keys for the new vehicle. Set Event = nil to disable.
    -- Common values:
    --   { Event = 'vehiclekeys:client:SetOwner',   ArgsType = 'plate'  }  -- qb-vehiclekeys
    --   { Event = 'qs-vehiclekeys:client:AddKeys', ArgsType = 'plate'  }  -- qs-vehiclekeys
    Keys = {
        Event    = nil,
        ArgsType = 'plate', -- 'plate' = pass plate; 'vehicle' = pass vehicle entity
    },

    -- Lock state on spawn ('unlocked' or 'locked')
    LockState = 'unlocked',
}

-- ================================================
-- ADMIN COMMAND
-- /nbpwreset [serverId]  - reset welcome status so target can claim again.
-- ================================================
Config.ResetCommand = 'nbpwreset'
