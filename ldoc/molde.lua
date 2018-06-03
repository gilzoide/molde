--- @module molde
local molde = {}

--- Module version 1.0.0
molde.VERSION = "1.0.0"

--- Long string bracket level.
--
-- It is used as `string.rep('=', molde.string_bracket_level)` to create the
-- necessary string delimiters for literals.
molde.string_bracket_level = 1

--- Parse errors that can occur in a template
molde.errors = {
	PegError = nil,	             -- When PEG couldn't parse
	ExpectedClosingValueError = nil,     -- There is no closing `"}}"` to a value
	ExpectedClosingStatementError = nil, -- There is no closing `"%}"` to a statement
	UnexpectedClosingValueError = nil,     -- There is a closing `"}}"` without the corresponding `"{{"`
	UnexpectedClosingStatementError = nil, -- There is a closing `"%}"` without the corresponding `"{%"`
	EmptyValueError = nil,       -- There is no content after value opening `"{{"`
	EmptyStatementError = nil,   -- There is no content after statement opening `"{%"`
}

--- Parse a template, returning a table with the matched contents.
--
-- The parser tags the contents as:
--
-- + Literal: text that should be just copied to result
-- + Value: a value to be substituted using Lua, usually a variable; it will be
--   stringified using `tostring`
-- + Statement: one or more Lua statements that will be copied directly into the
--   compiled function
--
-- Results are in the format `{['literal' | 'value' | 'statement'] = <captured value>}`
--
-- @param template Template string to be parsed
--
-- @return[1] Table with results
-- @return[2] `nil`
-- @return[2] Parse error
--
-- @usage
--   local results = molde.parse([[literal {{ value }} {% statement %}]])
--   --[[
--   -- results: {
--   --     {literal = "literal "},
--   --     {value = " value "},
--   --     {literal = " "},
--   --     {statement = " statement "}
--   -- }
--   --]]
function molde.parse(template) end

--- Compiles a table with contents to Lua code that generates the (hopefully)
-- desired result.
--
-- The code generated for literals use Lua's long strings, with a default level
-- of 1. This level is taken from `molde.string_bracket_level`, and can be changed
-- if your literal may contain the string `"]=]"`, for example.
--
-- @param template Template string to be compiled
--
-- @treturn[1] string Generated code
-- @return[2] `nil`
-- @return[2] Parse error
function molde.compile(template) end


--- Compiles the template, returning a closure that executes the substitution.
--
-- The returned function behaves as described in `__process_template_function`.
--
-- @param template Template string
-- @param[opt='molde generator'] chunkname Name of the chunk for error messages
--
-- @treturn[1] function Template processor
-- @return[2] `nil`
-- @return[2] Parse error
--
-- @usage
--   hello_template = molde.load([[Hello {{ name or "world" }}]])
--   print(hello_template()) -- "Hello world"
function molde.load(template, chunkname) end


--- Same as `molde.load`, but loads the template from a file.
--
-- Uses `template_file` as chunkname.
--
-- Every caveat for `molde.load` applies.
--
-- @see molde.load
--
-- @param template_file Template file path
--
-- @treturn[1] function Template processor
-- @return[2] `nil`
-- @return[2] File open error
-- @return[3] `nil`
-- @return[3] Parse error
--
-- @usage
--   hello_template = molde.loadfile("hello_template_file")
--   print(hello_template()) -- "Hello world"
function molde.loadfile(template_file) end

--- This is the prototype of the function returned by `molde.load` and
-- `molde.loadfile`.
--
-- The environment is sandboxed, and assigning variables directly to it won't
-- affect the original tables. Variable lookup order: local environment,
-- `values`, `env`. The `env` table serves as a fallback
-- environment, and is useful when you want to sandbox builtin Lua functions.
--
-- Any non-local variables assigned in the template are stored in the sandboxed
-- environment, which is the function's environment (`_ENV or getfenv()`).
--
-- @raise When the generated code is invalid
--
-- @param[opt] values Table with the values to substitute
-- @param[optchain=_G] env Fallback environment
--
-- @treturn string Processed template
-- @treturn table The sandboxed environment used
function __process_template_function(values, env) end

return molde
