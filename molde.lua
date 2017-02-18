--[[
-- Copyright 2017 Gil Barbosa Reis <gilzoide@gmail.com>
-- This file is part of Molde.
--
-- Molde is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- Molde is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
--
-- You should have received a copy of the GNU Lesser General Public License
-- along with Molde.  If not, see <http://www.gnu.org/licenses/>.
--]]

local lpeg = require 'lpeglabel'
local re = require 'relabel'

local molde = {
	__script_prefix = "local __molde = {}",
	__script_suffix = "return table.concat(__molde)",
	__script_literal = "table.insert(__molde, [%s[%s]%s])",
	__script_value = "table.insert(__molde, tostring(%s))",
	__script_statement = "%s",
	__string_bracket_level = 3,
}

-- Parser errors
local parseErrors = {}
parseErrors[0] = "PEG couldn't parse"
local function addError(label, msg)
	table.insert(parseErrors, msg)
	parseErrors[label] = #parseErrors
end
addError('ValueError', "closing '}}' expected")
addError('StatementError', "closing '%}' expected")
re.setlabels(parseErrors)

molde.errors = parseErrors

local grammar = re.compile[[
Pattern	<- {| ( Value / Statement / Literal )* |} !.

Value	<- "{{" {| {:value: {~ ValueContent ~} :} |} ("}}" / %{ValueError})
ValueContent	<- (!"}}" Char)+

Statement	<- "{%" {| {:statement: {~ StatementContent ~} :} |} ("%}" / %{StatementError})
StatementContent	<- (!"%}" Char)+

Literal	<- {| {:literal: {~ LiteralContent ~} :} |}
LiteralContent	<- ( !('{' [{%]) Char)+

Char	<- '\{' -> '{' / '\}' -> '}' / .
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
	local res, label, suf = grammar:match(template)
	if res then
		return res
	else
		return nil, parseErrors[label]
	end
end

--- Compiles a table with contents to Lua code that generates the (hopefully)
-- desired result
--
-- @return Generated code string
function molde.compile(template)
	local contents = molde.parse(template)
	local pieces = {}
	table.insert(pieces, molde.__script_prefix)
	for _, c in ipairs(contents) do
		local key, v = next(c)
		if key == 'literal' then
			table.insert(pieces, molde.__script_literal:format(v))
		elseif key == 'value' then
			local eq = string.rep(molde.__string_bracket_level)
			table.insert(pieces, molde.__script_value:format(eq, v, eq))
		elseif key == 'statement' then
			table.insert(pieces, molde.__script_statement:format(v))
		end
	end
	table.insert(pieces, molde.__script_suffix)
	return table.concat(pieces, '\n')
end


--- Compiles the template, returning a closure that executes the substitution
--
-- @raise When resulting Lua code is not valid
function molde.load(template)
	local code = molde.compile(template)
	return function(env)
		local newenv = {
			table = table,
			tostring = tostring,
			__index = env or _ENV
		}
		return assert(load(code, 'molde generator', 't', setmetatable(newenv, newenv)))()
	end
end


--- Same as `molde.load`, but loads the template from a file
--
-- @raise When file can't be opened, or resulting Lua code is not valid
function molde.loadfile(template_file, env)
	local file = assert(io.open(template_file, 'r'))
	local file_contents = file:read('a')
	file:close()
	return molde.load(file_contents, env)
end

return molde
