fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

name 'jenn_walkstyles'
description 'Walk style selector for RedM'
version '1.0.1'
author 'Jenn'

shared_script '@ox_lib/init.lua'
client_script 'client/main.lua'

files {
    'config.lua'
}

lua54 'yes'