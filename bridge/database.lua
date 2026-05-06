-- ================================================
-- DATABASE BRIDGE (Server only)
-- Tracks which identifiers have already received the welcome package.
-- ================================================

if not IsDuplicityVersion() then return end

Bridge = Bridge or {}
Bridge.DB = {}

-- ================================================
-- Has the identifier already claimed the welcome?
-- ================================================
---@param identifier string
---@return boolean
function Bridge.DB.HasReceived(identifier)
    if not identifier then return false end
    local row = MySQL.scalar.await(
        'SELECT 1 FROM nb_pedwelcome_received WHERE identifier = ? LIMIT 1',
        { identifier }
    )
    return row ~= nil
end

-- ================================================
-- Mark an identifier as having received the welcome.
-- INSERT IGNORE so concurrent claims don't double-insert.
-- ================================================
---@param identifier string
---@return number affectedRows
function Bridge.DB.MarkReceived(identifier)
    return MySQL.insert.await(
        'INSERT IGNORE INTO nb_pedwelcome_received (identifier) VALUES (?)',
        { identifier }
    ) or 0
end

-- ================================================
-- Reset (admin) - delete the row so the player can claim again.
-- ================================================
---@param identifier string
---@return number affectedRows
function Bridge.DB.Reset(identifier)
    return MySQL.update.await(
        'DELETE FROM nb_pedwelcome_received WHERE identifier = ?',
        { identifier }
    ) or 0
end

-- ================================================
-- VEHICLE GARAGE COLUMN
-- nb-garages reads `garage` from owned_vehicles (ESX) /
-- player_vehicles (QBCore) to decide where a vehicle lives.
-- After Bridge.GiveVehicle inserts the row, we update the
-- column to either the configured garage label or 'OUT'.
-- ================================================

local _vehicleTable = (GetResourceState('qb-core') == 'started') and 'player_vehicles' or 'owned_vehicles'

---@param plate string
---@param garageLabel string  -- 'OUT' or a nb-garages label
---@return number affectedRows
function Bridge.DB.SetVehicleGarage(plate, garageLabel)
    if not plate or not garageLabel then return 0 end
    plate = Bridge.NormalizePlate(plate)
    return MySQL.update.await(
        ('UPDATE %s SET garage = ? WHERE TRIM(plate) = ?'):format(_vehicleTable),
        { garageLabel, plate }
    ) or 0
end
