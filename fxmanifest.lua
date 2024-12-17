fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Tinus_NL'
description 'Tinus Flatbed'

shared_scripts {
    '@ox_lib/init.lua'
}

client_scripts {
    'Config.lua',
    'Client/Main.lua'
}

server_scripts { 
    'Config.lua',
    'Server/Main.lua'
}

files {
    'stream/def_flatbed3_props.ytyp',
    'Meta/*.meta'
}

data_file 'VEHICLE_METADATA_FILE' 'Meta/vehicles.meta'
data_file 'VEHICLE_VARIATION_FILE' 'Meta/carvariations.meta'
data_file 'DLC_ITYP_REQUEST' 'stream/def_flatbed3_props.ytyp'
