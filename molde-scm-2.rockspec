package = 'molde'
version = 'scm-2'
source = {
	url = 'git://github.com/gilzoide/molde',
}
description = {
	summary = 'A template engine for Lua 5.1+',
	detailed = [[
Molde is a template engine for Lua 5.1+. It compiles a template string to a
function that generates the final string by substituting values by the ones in
a sandboxed environment.
]],
	license = 'LGPLv3',
	maintainer = 'gilzoide <gilzoide@gmail.com>'
}
dependencies = {
	'lua >= 5.1',
	'lpeglabel >= 1.5',
}
build = {
	type = 'builtin',
	modules = {
		molde = 'molde.lua'
	}
}
