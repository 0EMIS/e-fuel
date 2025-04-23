fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'EMIS'

client_scripts {
    'client/functions.lua', 
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

exports {'GetFuel', 'SetFuel'}

shared_scripts {
    '@es_extended/imports.lua', 
    '@ox_lib/init.lua',
    'config.lua'
}

