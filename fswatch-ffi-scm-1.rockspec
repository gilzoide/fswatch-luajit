rockspec_format = "3.0"
package = 'fswatch-ffi'
version = 'scm-1'
source = {
    url = 'https://github.com/gilzoide/fswatch-luajit',
}
description = {
    summary = 'LuaJIT FFI and wrapper for libfswatch (https://github.com/emcrisostomo/fswatch)',
	license = 'Unlicense',
	maintainer = 'gilzoide <gilzoide@gmail.com>',
    labels = { 'ffi', 'filesystem' },
}
dependencies = {
	'lua >= 5.1',
}
build = {
	type = 'builtin',
	modules = {
        libfswatch = 'libfswatch.lua',
		fswatch = 'fswatch.lua',
	},
}