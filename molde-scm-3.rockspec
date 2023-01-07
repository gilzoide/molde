package = 'molde'
version = 'scm-3'
source = {
	url = 'git://github.com/gilzoide/molde',
}
description = {
	summary = 'Zero dependency, single file template engine for Lua 5.1+ with builtin sandbox support',
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
}
build = {
	type = 'builtin',
	modules = {
		molde = 'molde.lua'
	}
}
