local lpeg = require 'lpeg'
local re = require 're'

local molde = {
	__script_prefix = "local __molde = {};",
	__script_suffix = "return __molde_table_concat(__molde)",
	__newline = '\n',
}

local grammar = re.compile([[
Pattern	<- {| '' -> __script_prefix
			  ( Value / Statement / Literal )*
			  '' -> __script_suffix
			  !.
		   |}

Value	<- "{{" -> '__molde_table_insert(__molde, ' { ValueContent } "}}" -> ');'
ValueContent	<- (!"}}" .)+
-- CloseValue	<- !"}}" -> ');' /  {.} CloseValue

Statement	<- "{%" { StatementContent } "%}" -> __newline
StatementContent	<- (!"%}" .)+
-- CloseStatement	<- !"%}" .

Literal	<- '' -> '__molde_table_insert(__molde, [===[' { LiteralContent } '' -> ']===]);'
LiteralContent	<- ( !('{' [{%]) Char)+
Char	<- '\{' -> '{' / .
]], molde)

function molde.compile(template)
	return table.concat(grammar:match(template))
end


function molde.load(template, env)
	local generator_code = molde.compile(template)
	env.__molde_table_insert = table.insert
	env.__molde_table_concat = table.concat
	return load(generator_code, 'molde generator', 't', env)
end


function molde.loadfile(template_file, env)
	local file = assert(io.open(template_file, 'r'))
	local file_contents = file:read('a')
	file:close()
	return molde.load(file_contents, env)
end

return molde
