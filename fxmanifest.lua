fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'bp_megaphone'
version '1.1.0'
bp_script 'bp_megaphone'
description 'FiveM megaphone script'
author 'BP Development'
url 'https://tebex.bhavikp.in/'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'bp_versioncheck.lua',
    'server/main.lua',
}

dependencies {
    'ox_lib',
    'bp_lib',
}

escrow_ignore {
    'config.lua',
}
