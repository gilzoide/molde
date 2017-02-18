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
	string_bracket_level = 1,
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


function molde.parse(template)
	local res, label, suf = grammar:match(template)
	if res then
		return res
	else
		return nil, parseErrors[label]
	end
end


function molde.compile(template)
	local contents, err = molde.parse(template)
	if contents == nil then return nil, err end

	local pieces = {}
	table.insert(pieces, molde.__script_prefix)
	for _, c in ipairs(contents) do
		local key, v = next(c)
		if key == 'literal' then
			local eq = string.rep('=', molde.string_bracket_level)
			table.insert(pieces, molde.__script_literal:format(eq, v, eq))
		elseif key == 'value' then
			table.insert(pieces, molde.__script_value:format(v))
		elseif key == 'statement' then
			table.insert(pieces, molde.__script_statement:format(v))
		end
	end
	table.insert(pieces, molde.__script_suffix)
	return table.concat(pieces, '\n')
end


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


function molde.loadfile(template_file)
	local file = assert(io.open(template_file, 'r'))
	local file_contents = file:read('a')
	file:close()
	return molde.load(file_contents)
end

return molde
