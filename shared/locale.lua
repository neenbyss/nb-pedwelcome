-- ================================================
-- LOCALE (Shared: client + server)
-- Multi-language string system.
-- Usage: Locale('key')  or  Locale('key_with_format', arg1)
-- ================================================

---@type table<string, table<string, string>>
local Locales = {}

-- ================================================
-- ENGLISH
-- ================================================
Locales['en'] = {
    ['no_permission']        = 'You do not have permission.',
    ['invalid_data']         = 'Invalid data provided.',
    ['server_error']         = 'An internal error occurred.',

    -- Indicators
    ['floating_label']       = 'Welcome - press to interact',

    -- Welcome flow
    ['already_received']     = 'You have already received your welcome package.',
    ['welcome_starting']     = 'Welcome to the city! Preparing your starter package...',
    ['welcome_complete']     = 'Welcome package delivered. Enjoy the city!',
    ['rewards_money']        = 'You received $%s cash and $%s bank.',
    ['rewards_items']        = 'You received %d items.',
    ['rewards_vehicles']     = 'You received %d vehicle(s).',

    -- Vehicle spawn
    ['vehicle_spawn_blocked'] = 'A vehicle (%s) could not spawn (area blocked). Find it in your garage.',
    ['vehicle_spawn_failed']  = 'A vehicle (%s) failed to spawn. Find it in your garage.',
    ['vehicle_spawned']       = 'Your %s is parked nearby. Plate: %s.',

    -- Admin
    ['reset_success']         = 'Welcome status reset for player %s.',
    ['reset_self']            = 'Your welcome status has been reset.',
    ['reset_target_invalid']  = 'Target player not found.',
}

-- ================================================
-- SPANISH
-- ================================================
Locales['es'] = {
    ['no_permission']        = 'No tienes permiso.',
    ['invalid_data']         = 'Datos invalidos proporcionados.',
    ['server_error']         = 'Ocurrio un error interno.',

    -- Indicators
    ['floating_label']       = 'Bienvenido - presiona para interactuar',

    -- Welcome flow
    ['already_received']     = 'Ya recibiste tu paquete de bienvenida.',
    ['welcome_starting']     = 'Bienvenido a la ciudad! Preparando tu paquete inicial...',
    ['welcome_complete']     = 'Paquete de bienvenida entregado. Disfruta la ciudad!',
    ['rewards_money']        = 'Recibiste $%s en efectivo y $%s en banco.',
    ['rewards_items']        = 'Recibiste %d items.',
    ['rewards_vehicles']     = 'Recibiste %d vehiculo(s).',

    -- Vehicle spawn
    ['vehicle_spawn_blocked'] = 'Un vehiculo (%s) no pudo aparecer (zona bloqueada). Encuentralo en tu garaje.',
    ['vehicle_spawn_failed']  = 'Un vehiculo (%s) no pudo aparecer. Encuentralo en tu garaje.',
    ['vehicle_spawned']       = 'Tu %s esta estacionado cerca. Placa: %s.',

    -- Admin
    ['reset_success']         = 'Estado de bienvenida reiniciado para el jugador %s.',
    ['reset_self']            = 'Tu estado de bienvenida fue reiniciado.',
    ['reset_target_invalid']  = 'Jugador objetivo no encontrado.',
}

-- ================================================
-- LOCALE FUNCTION (do not modify)
-- ================================================

---@param key string
---@param ... any
---@return string
function Locale(key, ...)
    local lang = Config.Locale or 'en'
    local str = Locales[lang] and Locales[lang][key] or Locales['en'][key] or key
    if select('#', ...) > 0 then
        return string.format(str, ...)
    end
    return str
end
