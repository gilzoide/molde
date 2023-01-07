--[[
-- Copyright 2017-2022 Gil Barbosa Reis <gilzoide@gmail.com>
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

--- @module molde
local molde = {
	--- Module version: 2.0.0
	VERSION = "2.0.0",

	--- Tokens returned by `tokenize`
	Token = {
		LITERAL = 'LITERAL',  -- Literal token, accompanied by the read literal value
		NEWLINE = 'NEWLINE',  -- New line token, accompanied by it's value "\n"
		VALUE_BEGIN = 'VALUE_BEGIN',  -- Begin value token, accompanied by it's value "{{"
		VALUE_END = 'VALUE_END',  -- End value token, accompanied by it's value "}}"
		STATEMENT_BEGIN = 'STATEMENT_BEGIN',  -- Begin statement token, accompanied by it's value "{%"
		STATEMENT_END = 'STATEMENT_END',  -- End statement token, accompanied by it's value "}}"
	},

	--- Parse states returned by `parse`
	ParseState = {
		LITERAL = 'LITERAL',  -- Parser read a literal, accompanied by the read text
		VALUE = 'VALUE',  -- Parser read a value, accompanied by the text between "{{" and "}}"
		STATEMENT = 'STATEMENT',  -- Parser read a statement, accompanied by the text between "{%" and "%}"
		ERROR = 'ERROR',  -- Parser error, accompanied by the corresponding `ParseError`
	},

	--- Parse errors that can occur in a template
	ParseError = {
		EXPECTED_CLOSING_VALUE = "closing '}}' expected",  --  "closing '}}' expected"
		EXPECTED_CLOSING_STATEMENT = "closing '%}' expected",  --  "closing '%}' expected"
		UNEXPECTED_OPENING_VALUE = "unexpected opening '{{' found",  --  "unexpected opening '{{' found"
		UNEXPECTED_OPENING_STATEMENT = "unexpected opening '{%' found",  --  "unexpected opening '{%' found"
		UNEXPECTED_CLOSING_VALUE = "unexpected closing '}}' found",  --  "unexpected closing '}}' found"
		UNEXPECTED_CLOSING_STATEMENT = "unexpected closing '%}' found",  --  "unexpected closing '%}' found"
		EMPTY_VALUE = "empty value between '{{' and '}}'",  --  "empty value between '{{' and '}}'"
		EMPTY_STATEMENT = "empty statement between '{%' and '%}'",  --  "empty statement between '{%' and '%}'"
	},
}

--- Internal functions
-- @section

local Token = molde.Token

local function tokenize_coroutine(text)
	local yield = coroutine.yield
	local function yield_literal(index)
		if index >= 1 then
			yield(Token.LITERAL, text:sub(1, index))
		end
	end

	local start_index, end_index, char, next_char, advance, init
	while true do
		start_index, end_index, char, next_char = text:find('([\n{}%%])([{}%%]?)', init)
		if not start_index then
			break
		end

		init = nil
		advance = start_index + 1

		-- New line
		if char == '\n' then
			yield_literal(start_index - 1)
			yield(Token.NEWLINE, '\n')
		-- Escaped character
		elseif start_index > 1 and text:sub(start_index - 1, start_index - 1) == '\\' then
			yield(Token.LITERAL, text:sub(1, start_index - 2) .. char)
		-- Start value
		elseif char == '{' and next_char == '{' then
			yield_literal(start_index - 1)
			yield(Token.VALUE_BEGIN, '{{')
			advance = end_index + 1
		-- Start statement
		elseif char == '{' and next_char == '%' then
			yield_literal(start_index - 1)
			yield(Token.STATEMENT_BEGIN, '{%')
			advance = end_index + 1
		-- End value
		elseif char == '}' and next_char == '}' then
			yield_literal(start_index - 1)
			yield(Token.VALUE_END, '}}')
			advance = end_index + 1
		-- End statement
		elseif char == '%' and next_char == '}' then
			yield_literal(start_index - 1)
			yield(Token.STATEMENT_END, '%}')
			advance = end_index + 1
		-- First character is special, but the next one is not. Keep looking
		else
			init = start_index + 1
		end

		if not init then
			text = text:sub(advance)
		end
	end

	if #text > 0 then
		yield(Token.LITERAL, tostring(text))
	end
end


--- Tokenize template, returning a coroutine that yields pairs of `Token`, `string`.
--
-- @param template  Text string
--
-- @treturn function  `Token`, `string` pair iterator
--
-- @usage
--   for token, value in molde.tokenize(template_text) do
--       if token == molde.Token.LITERAL then
--           print('Literal found: ', value)
--       elseif token == molde.Token.NEWLINE then
--           print('New line found', value == '\n')
--       elseif token == molde.Token.VALUE_BEGIN then
--           print('Value begin found', value == '{{')
--       -- ...
--       end
--   end
function molde.tokenize(template)
	return coroutine.wrap(function() tokenize_coroutine(template) end)
end


local ParseState = molde.ParseState
local ParseError = molde.ParseError

local function parse_coroutine(text)
	local line, column = 1, 1

	local yield = coroutine.yield
	local function yield_error(msg)
		yield(ParseState.ERROR, string.format('Error at line %u (col %u): %s', line, column, msg))
	end

	local state = ParseState.LITERAL
	local current_text = ''
	local function yield_current_text()
		if #current_text > 0 then
			yield(state, current_text)
			current_text = ''
		end
	end

	for token, value in molde.tokenize(text) do
		if token == Token.LITERAL then
			current_text = current_text .. value
		elseif token == Token.NEWLINE then
			current_text = current_text .. value
			line = line + 1
			column = 0
		elseif token == Token.VALUE_BEGIN then
			if state ~= ParseState.LITERAL then
				return yield_error(ParseError.UNEXPECTED_OPENING_VALUE)
			else
				yield_current_text()
				state = ParseState.VALUE
			end
		elseif token == Token.VALUE_END then
			if state ~= ParseState.VALUE then
				return yield_error(ParseError.UNEXPECTED_CLOSING_VALUE)
			elseif not current_text:find('%S') then
				return yield_error(ParseError.EMPTY_VALUE)
			else
				yield_current_text()
				state = ParseState.LITERAL
			end
		elseif token == Token.STATEMENT_BEGIN then
			if state ~= ParseState.LITERAL then
				return yield_error(ParseError.UNEXPECTED_OPENING_STATEMENT)
			else
				yield_current_text()
				state = ParseState.STATEMENT
			end
		elseif token == Token.STATEMENT_END then
			if state ~= ParseState.STATEMENT then
				return yield_error(ParseError.UNEXPECTED_CLOSING_STATEMENT)
			elseif not current_text:find('%S') then
				return yield_error(ParseError.EMPTY_STATEMENT)
			else
				yield_current_text()
				state = ParseState.LITERAL
			end
		else
			-- TODO: after thorough testing, remove this assertion
			error('FIXME!!! Invalid state')
		end

		column = column + #value
	end
	
	if state == ParseState.VALUE then
		return yield_error(ParseError.EXPECTED_CLOSING_VALUE)
	elseif state == ParseState.STATEMENT then
		return yield_error(ParseError.EXPECTED_CLOSING_STATEMENT)
	else
		yield_current_text()
	end
end


--- Parse template, returning a coroutine that yields pairs of `ParseState`, `string`.
--
-- @param template  Text string
--
-- @treturn function  `ParseState`, `string` pair iterator.
--   The parser will stop at the first error it encounters.
--
-- @usage
--   for parse_state, value in molde.parse(template_text) do
--       if parse_state == molde.ParseState.LITERAL then
--           print('Literal found: ', value)
--       elseif parse_state == molde.ParseState.VALUE then
--           print('{{ Value found }}', value)
--       elseif parse_state == molde.ParseState.STATEMENT then
--           print('{% Statement found %}', value)
--       else  -- parse_state == molde.ParseState.ERROR
--           error('Parse error: ' .. value)
--       end
--   end
function molde.parse(template)
	return coroutine.wrap(function() parse_coroutine(template) end)
end


local SCRIPT_PREFIX = "local __molde = {}"
local SCRIPT_SUFFIX = "return __molde_table_concat(__molde)"
local SCRIPT_LITERAL = "__molde[#__molde + 1] = [%s[%s]%s]"
local SCRIPT_VALUE = "__molde[#__molde + 1] = __molde_tostring(%s)"
local SCRIPT_STATEMENT = "%s"

--- Compiles a string with contents to Lua code that generates the (hopefully)
-- desired result.
--
-- The code generated for literals use Lua's long strings, with a level of
-- `string_bracket_level` (default: 1).
-- You should set it to a higher level if your literal may contain the string `"]=]"`.
--
-- @param template  Template string to be compiled
-- @param[opt=1] string_bracket_level  Long string bracket level, used to create the necessary string delimiters for literals:
--  `string.rep('=', string_bracket_level)` 
--
-- @treturn[1] string  Generated code
-- @treturn[2] nil
-- @treturn[2] string  Parse error message
function molde.compile(template, string_bracket_level)
	string_bracket_level = string_bracket_level or 1
	local pieces = {
		SCRIPT_PREFIX
	}
	for key, v in molde.parse(template) do
		if key == ParseState.ERROR then
			return nil, v
		elseif key == ParseState.LITERAL and v ~= '\n' and v ~= '\r\n' then
			local eq = string.rep('=', string_bracket_level)
			pieces[#pieces + 1] = SCRIPT_LITERAL:format(eq, v, eq)
		elseif key == ParseState.VALUE then
			pieces[#pieces + 1] = SCRIPT_VALUE:format(v)
		elseif key == ParseState.STATEMENT then
			pieces[#pieces + 1] = SCRIPT_STATEMENT:format(v)
		end
	end
	pieces[#pieces + 1] = SCRIPT_SUFFIX
	return table.concat(pieces, '\n')
end


--- Load a function and set it's environment.
--
-- This is set for compatibility with both Lua 5.1 and 5.2+
local load_with_env = _VERSION == "Lua 5.1" and function(code, chunk_name, env)
	return setfenv(loadstring(code, chunk_name), env)
end or function(code, chunk_name, env)
	return load(code, chunk_name, 't', env)
end


--- Functions
-- @section


--- Compiles the template, returning a closure that executes the substitution.
--
-- The returned function behaves as described in `TemplateFunctionPrototype`.
--
-- @param template  Template string
-- @param[opt='molde generator'] chunk_name  Name of the chunk for error messages
-- @param[opt=1] string_bracket_level  Long string bracket level, forwarded to `molde.compile`
--
-- @treturn[1] function  Template processor
-- @treturn[2] nil
-- @return[2] Parse error message
-- @treturn[3] nil
-- @return[3] Template process function call error message
--
-- @usage
--   hello_template = molde.load([[Hello {{ name or "world" }}]])
--   hello = hello_template()
--   print(hello) -- "Hello world"
function molde.load(template, chunk_name, string_bracket_level)
	local code, err = molde.compile(template, string_bracket_level)
	if not code then return nil, err end

	return function(value_table, env)
		env = env or _G
		local newenv = {
			__molde_table_concat = table.concat,
			__molde_tostring = tostring,
			__index = function(self, key)
				local v = value_table and value_table[key]
				if v == nil then v = env[key] end
				return v
			end,
		}
		setmetatable(newenv, newenv)
		local success, result = pcall(load_with_env(code, chunk_name or 'molde generator', newenv))
		if success then
			return result, newenv
		else
			return nil, result
		end
	end
end


--- Same as `molde.load`, but loads the template from a file.
--
-- Uses `filename` as chunkname by default.
--
-- Every caveat for `molde.load` applies.
--
-- @see molde.load
--
-- @param filename  Template file path
-- @param[opt=filename] chunk_name  Name of the chunk for error messages
-- @param[opt=1] string_bracket_level  Long string bracket level, forwarded to `molde.load`
--
-- @treturn[1] function Template processor
-- @treturn[2] nil
-- @return[2] File open error
-- @treturn[3] nil
-- @return[3] Parse error
-- @treturn[4] nil
-- @return[4] Template process function call error message
--
-- @usage
--   -- hello_template_file contents == "literal {{ value }} {% statement %}"
--   hello_template = molde.loadfile("hello_template_file")
--   hello = hello_template()
--   print(hello) -- "Hello world"
function molde.loadfile(filename, chunk_name, string_bracket_level)
	local file, err = io.open(filename, 'r')
	if not file then return nil, err end
	local file_contents = file:read('*a')
	file:close()
	return molde.load(file_contents, chunk_name or filename, string_bracket_level)
end

--- This is the prototype of the function returned by `molde.load` and
-- `molde.loadfile`.
--
-- The environment is sandboxed, so assigning variables directly to it won't
-- affect the original tables. Variable lookup order: local environment,
-- `values`, `env`. The `env` table serves as a fallback environment, and is
-- useful when you want to sandbox builtin Lua functions.
--
-- @raise When the generated code is invalid
--
-- @function TemplateFunctionPrototype
-- @param[opt] values  Table with the values to substitute
-- @param[optchain=_G] env  Fallback environment
--
-- @treturn string Processed template
-- @treturn table The sandboxed environment used
--
-- @usage
--   hello_template = molde.load([[
--   {% name = (name or "world") .. "!!!" %}
--   Hello {{ name }}
--   ]])
--   message, template_env = hello_template()
--   print(message, template_env.name) -- "Hello world!!!"  "world!!!"
--   values = { name = "gilzoide" }
--   message, template_env = hello_template(values)
--   print(message, values.name, template_env.name) -- "Hello gilzoide!!!"  "gilzoide"  "gilzoide!!!"
--   env = { name = "y'all" }
--   message, template_env = hello_template(values, env)
--   print(message, template_env.name) -- "Hello gilzoide!!!"  "gilzoide!!!"
--   message, template_env = hello_template(nil, env)
--   print(message, env.name, template_env.name) -- "Hello y'all!!!"  "y'all"  "y'all!!!"

return molde
