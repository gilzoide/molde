--[[
-- Copyright 2017, 2018 Gil Barbosa Reis <gilzoide@gmail.com>
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
	VERSION = "1.0.0",
	__script_prefix = "local __molde = {}",
	__script_suffix = "return __molde_table.concat(__molde)",
	__script_literal = "__molde_table.insert(__molde, [%s[%s]%s])",
	__script_value = "__molde_table.insert(__molde, __molde_tostring(%s))",
	__script_statement = "%s",
	string_bracket_level = 1,
	errors = {
		[0] = "PEG couldn't parse",
		ExpectedClosingValueError = "closing '}}' expected",
		ExpectedClosingStatementError = "closing '%}' expected",
		UnexpectedClosingValueError = "unexpected closing '}}' found",
		UnexpectedClosingStatementError = "unexpected closing '%}' found",
		EmptyValueError = "empty value after '{{'",
		EmptyStatementError = "empty statement after '{%'",
	},
}

local grammar = re.compile[[
Pattern <- {| ( Value / Statement / Literal )* |} !.

Value <- "{{" {| {:value: {~ ValueContent ~} :} |} ("}}" / %{ExpectedClosingValueError})
ValueContent <- (!"}}" Char)+ / %{EmptyValueError}

Statement <- "{%" {| {:statement: {~ StatementContent ~} :} |} ("%}" / %{ExpectedClosingStatementError})
StatementContent <- (!"%}" Char)+ / %{EmptyStatementError}

Literal	<- {| {:literal: {~ LiteralContent ~} :} |}
LiteralContent <- (!('{' [{%]) Char)+

Char <- '\{' -> '{'
      / '\}' -> '}'
      / '\%' -> '%%'
      / ('}}' %{UnexpectedClosingValueError})
      / ('%}' %{UnexpectedClosingStatementError})
      / .
]]


function molde.parse(template)
	local res, label, suf = grammar:match(template)
	if res then
		return res
	else
		local whereErr = #template - suf
		local lin, col = re.calcline(template, whereErr)
		return nil, string.format("%s at %d:%d", molde.errors[label], lin, col)
	end
end


function molde.compile(template)
	local contents, err = molde.parse(template)
	if not contents then return nil, err end

	local pieces = {}
	table.insert(pieces, molde.__script_prefix)
	for _, c in ipairs(contents) do
		local key, v = next(c)
		if key == 'literal' and v ~= '\n' and v ~= '\r\n' then
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


--- Load a function and set it's environment.
--
-- This is set for compatibility with both Lua 5.1 and 5.2+
local load_with_env = _VERSION == "Lua 5.1" and function(code, chunkname, env)
	return setfenv(loadstring(code, chunkname), env)
end or function(code, chunkname, env)
	return load(code, chunkname, 't', env)
end


function molde.load(template, string_name)
	local code, err = molde.compile(template)
	if not code then return nil, err end
	return function(value_table, env)
		if env == nil then env = _G end
		local __index = value_table and function(t, k)
			local v = rawget(t, k)
			if v == nil then v = value_table[k] end
			if v == nil then v = env[k] end
			return v
		end or function(t, k)
			local v = rawget(t, k)
			if v == nil then v = env[k] end
			return v
		end
		local newenv = {
			__molde_table = table,
			__molde_tostring = tostring,
			__index = __index,
		}
		setmetatable(newenv, newenv)
		return assert(load_with_env(code, string_name or 'molde generator', newenv))(), newenv
	end
end


function molde.loadfile(template_file)
	local file, err = io.open(template_file, 'r')
	if not file then return nil, err end
	local file_contents = file:read('*a')
	file:close()
	return molde.load(file_contents, template_file)
end

return molde
