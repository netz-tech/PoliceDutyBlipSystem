fx_version 'cerulean'
game 'gta5'

author 'Netz'
description 'Standalone Duty + Blip System for FiveM'
version '1.0.0'

server_scripts {
    'config.lua',
    'server.lua'
}

client_scripts {
    'config.lua',
    'client.lua'
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js',
    'ui/images/*.png',
    'ui/images/departments/*.png'
}
