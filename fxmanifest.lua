fx_version 'adamant'
games { 'rdr3' }
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

author 'BCC Team @iseeyoucopy'

description 'Advanced Craft Script for the Feather Framework.'

shared_scripts {
    'configs/*.lua',
    'locale.lua',
    'languages/*.lua'
}

client_scripts {
    'client/feather/menu_v2.lua',
    'client/feather/init.lua',
    'client/functions.lua',
    'client/client.lua',
    'client/MenuSetup.lua'
}

server_scripts {
    '@feather-mysql/lib/DB.lua',
    'server/feather/init.lua',
    'server/feather/domains.lua',
    'server/dbUpdater.lua',
    'server/server.lua'
}

-- bcc-userlog is optional (Config.useBccUserlog).
dependencies {
    'feather-mysql',
    'feather-core',
    'feather-character',
    'feather-notify',
    'feather-toolkit',
    'feather-menu-v2',
    'feather-inventory',
    'feather-jobs',
    'feather-weapons',
    'feather-economy'
}

version '2.0.0'
