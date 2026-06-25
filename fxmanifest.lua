fx_version 'cerulean'
game 'gta5'

author 'NightmareSan'
description 'Fitness Trainingssystem for ESX Legacy'
version '1.0.0'

dependencies {
	'es_extended',
	'oxmysql',
	'esx_notify'
}

shared_scripts {
	'@es_extended/imports.lua',
	'class_types.lua',
	'config.lua',
	'shared/helpers.lua'
}
client_scripts {
	'client/main.lua',
	'client/stamina.lua',
	'client/nui.lua',
	'client/training.lua'
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server/fitness_repository.lua',
	'server/fitness_service.lua',
	'server/fitness_events.lua'
}

ui_page 'web/index.html'

files {
	'web/index.html',
	'web/style.css',
	'web/script.js'
}