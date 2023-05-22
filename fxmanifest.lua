-- NC PROTECT+
shared_scripts { '@nc_PROTECT+/exports/sh.lua' }

fx_version 'adamant'
game 'gta5'

author 'Luciano Coder'
description 'Es Extended Modify'
version '1.4'

shared_scripts {
	'locale.lua',
	'locales/*.lua',
	'config/config.general.lua',
	'config/config.weapons.lua'
}

server_scripts {
	'@async/async.lua',
	'@mysql-async/lib/MySQL.lua',
	'server/common.lua',
	'server/classes/player.lua',
	'server/functions.lua',
	'server/paycheck.lua',
	'server/main.lua',
	'server/commands.lua',
	'server/server.lua',
	'common/modules/math.lua',
	'common/modules/table.lua',
	'common/functions.lua'
}

client_scripts {
	'client/common.lua',
	'client/functions.lua',
	'client/wrapper.lua',
	'client/main.lua',
	'client/modules/death.lua',
	'client/modules/font.lua',
	'client/modules/scaleform.lua',
	'client/modules/streaming.lua',
	'common/modules/math.lua',
	'common/modules/table.lua',
	'common/functions.lua'
}

ui_page {
	'html/ui.html'
}

files {
	'locale.js',
	'html/ui.html',
	'html/css/app.css',
	'html/js/mustache.min.js',
	'html/js/wrapper.js',
	'html/js/app.js',
	'html/fonts/pdown.ttf',
	'html/fonts/bankgothic.ttf',
	'html/img/accounts/bank.png',
	'html/img/accounts/black_money.png',
	'html/img/accounts/money.png'
}

exports {
	'getSharedObject'
}

server_exports {
	'getSharedObject'
}

dependencies {
	'mysql-async',
	'async'
}