local lpeg = require 'lpeg'
local re = require 're'

local molde = {}

local grammar = re.compile[[
Pattern	<- {| ( Value / Statement / Literal )* |} !.

Value	<- "{{" {| {:value: ValueContent :} |} "}}"
ValueContent	<- (!"}}" .)+

Statement	<- "{%" {| {:statement: StatementContent :} |} "%}"
StatementContent	<- (!"%}" .)+

Literal	<- {| {:literal: LiteralContent :} |}
LiteralContent	<- ( !('{' [{%]) Char)+
Char	<- '\{' -> '{' / .
]]

--- Parse a template, returning a table with the matched contents
--
-- The parser tags the contents as:
-- + Literal: text that should be just copied to result
-- + Value: a value to be substituted using Lua, usually a variable. It will be
--   stringified using `tostring`
-- + Statement: one or more Lua statements that will be copied directly into the
--   compiled function
--
-- Results are in the format `{['literal' | 'value' | 'statement'] = <captured value>}`
function molde.parse(template)
	return grammar:match(template)
end

--- Compiles a table with contents to Lua code that generates the (hopefully)
-- desired result
--
-- @return Generated code string
function molde.compile(template)
	local contents = molde.parse(template)
	local pieces = {}
	for _, c in ipairs(contents) do
		local key, v = next(c)
		if key == 'literal' then
			-- table.insert(
		end
	end
	return table.concat(pieces, '\n')
end


function molde.load(template, env)
	local generator_code = molde.compile(template)
	local __molde = {
		insert = table.insert,
		concat = table.concat,
		__index = env
	}
	return load(generator_code, 'molde generator', 't', setmetatable(__molde, __molde))
end


function molde.loadfile(template_file, env)
	local file = assert(io.open(template_file, 'r'))
	local file_contents = file:read('a')
	file:close()
	return molde.load(file_contents, env)
end

return molde
