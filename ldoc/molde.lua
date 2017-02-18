--- @module molde
local molde = {}

--- Long string bracket level.
--
-- It is used as `string.rep('=', molde.string_bracket_level)` to create the
-- necessary string delimiters for literals.
molde.string_bracket_level = 1

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
-- @return[1] Generated code string
-- @return[2] `nil`
-- @return[2] Parse error
function molde.compile(template) end


--- Compiles the template, returning a closure that executes the substitution
--
-- @raise When resulting Lua code is not valid
function molde.load(template) end


--- Same as `molde.load`, but loads the template from a file
--
-- @raise When file can't be opened, or resulting Lua code is not valid
function molde.loadfile(template_file) end

