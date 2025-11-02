fx_version 'cerulean'
game 'gta5'

author 'Hrj'
description 'FiveM AimLabs - Training & Match System'
version '1.0.0'

lua54 'yes'

shared_script 'config.lua'

client_scripts {
    'client/utils.lua',
    'client/main.lua',   -- <-- ensure this is included
    'client/menu.lua',
    'client/match.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}