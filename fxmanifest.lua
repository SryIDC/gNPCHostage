fx_version "cerulean"
game "gta5"
lua54 "yes"

name "npcHostage"
author "gigo"
version "1.0.0"
description "Npc hostage script by gigo"

shared_scripts {
    "@ox_lib/init.lua",
    '@qbx_core/modules/lib.lua',
    'config.lua'
}

client_scripts {
    "client.lua",
}

server_scripts {
    "server.lua",
}
