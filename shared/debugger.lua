-- ================================================
-- DEBUGGER (Shared: client + server)
-- Prints formatted debug messages when Config.Debug = true.
-- Usage: Debugger('ModuleName', 'message', var1, var2)
-- Output: [resource][SERVER|CLIENT][ModuleName] message var1 var2
--
-- DO NOT MODIFY - shared across all NB resources.
-- ================================================

local RESOURCE = GetCurrentResourceName()
local isServer = IsDuplicityVersion()
local side = isServer and 'SERVER' or 'CLIENT'

function Debugger(module, ...)
    if not Config.Debug then return end
    local args = { ... }
    local parts = {}
    for i = 1, #args do
        local v = args[i]
        if type(v) == 'table' then
            parts[i] = json.encode(v)
        else
            parts[i] = tostring(v)
        end
    end
    print(('[%s][%s][%s] %s'):format(RESOURCE, side, module, table.concat(parts, ' ')))
end
