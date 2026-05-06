fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Neenbyss Studios'
description 'NB Ped Welcome - Welcome NPC that grants money, items and vehicles to new players'
version '1.0.0'

dependencies {
    'oxmysql',
    'nb-bridge',
}

shared_scripts {
    '@nb-bridge/loader.lua',
    'shared/config.lua',
    'shared/debugger.lua',
    'shared/locale.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    '@nb-bridge/modules/framework/server.lua',
    'bridge/database.lua',
    'server/main.lua',
}

-- ================================================
-- ESCROW CONFIG (Tebex)
-- Files listed here are OPEN SOURCE (not encrypted).
-- Everything else is CLOSED SOURCE (encrypted).
-- ================================================
escrow_ignore {
    'shared/config.lua',
    'shared/debugger.lua',
    'shared/locale.lua',
    'bridge/database.lua',
}
