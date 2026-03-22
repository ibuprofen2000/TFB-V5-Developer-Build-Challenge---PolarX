fx_version 'cerulean'
game 'gta5'

name        'tfb-parking'
author      'TFB Dev Applicant'
description 'Persistent Vehicle Parking System for TFB'
version     '1.0.0'

shared_scripts {
    'shared/sh_config.lua',
}

client_scripts {
    'client/cl_main.lua',
    'client/ui.lua',
    'client/cl_zones.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/sv_database.lua',
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/app.js',
}

lua54 'yes'
