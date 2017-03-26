Molde
=====
[![Build Status](https://travis-ci.org/gilzoide/molde.svg?branch=master)](https://travis-ci.org/gilzoide/molde)

Molde is a template engine for Lua 5.2+. It compiles a template string to a
function that generates the final string by substituting values by the ones in
a sandboxed environment.


Templates
---------
There are 3 constructs templates recognize:

- __Literals__: Content that will be copied unmodified to the final string
- __Value__: A value processed by Lua and appended to the final string,
  stringified by `tostring`
- __Statement__: A Lua code block to be copied unmodified to the generated code,
  used for variable assignments, repetitions, conditions, etc. It doesn't
  directly generate contents for the final string

__Values__ are delimited by matching `{{` and `}}`, __statements__ by `{%` and
`%}`, and everything else is considered __literal__. Delimiter characters `{`,
`}` and `%` can be escaped using a leading backslash. If you want literal `}}`
or `%}` in your template, they __must__ be escaped, or _molde_ will return
error.

Example:

```
NOTE: This is not a valid molde template for educational purposes.

By default, everything is copied unmodified to the final string.

Values are just Lua expressions:
- Hello {{ "world" }}
  "Hello world"
- {{ 5 + 3 * 4 }}
  "17"
- {{ nil or "default" }}
  "default"
- You are using {{ _VERSION }}
  "You are using Lua 5.3" (You may use Lua 5.2 as well)
- Line 1{{ "\n" }}Line 2
  "Line 1
  Line 2"
- Escaping \{{ Hi! \}} (Note that you MUST escape the closing '}}')
  "Escaping {{ Hi! }}"
- Escaping is characterwise, so \{{ is as valid as {\{
  "Escaping is characterwise, so {{ is as valid as {{"
- table.insert is used in values {{ so they must be a valid expression! }}
  Error: ')' expected near 'they'

Statements are Lua statements:
- {% for i = 1, 5 do %}{{ i }} {% end %}
  "1 2 3 4 5 "
- {% -- this is just a comment, y'know %}
  ""
- {{ unbound_variable }}{% unbound_variable = "Hi!" %} {{ unbound_variable }}
  "nil Hi!"
- {% if false then %}This will never be printed{% else %}Conditionals!{% end %}
  "Conditionals!"
- \{% Escaping works \%} {\% here as well %\} (You MUST escape closing '%}' too)
  "{% Escaping works %} {% here as well %}"
- {% if without_then %}Statements must form valid Lua code!{% end %}
  Error: 'then' expected near 'table'
```


Usage
-----
```lua
local molde = require 'molde'

-- molde.load and molde.loadfile return a function that receives a table
-- with the values to substitute, and the optional environment (default: _G)
hello_template = molde.load([[Hello {{ name or "world" }}]])
print(hello_template()) -- "Hello world"
print(hello_template{name = "gilzoide"}) -- "Hello gilzoide"
name = "gilzoide"
print(hello_template({}, _ENV)) -- "Hello gilzoide"

-- load the template from a file (same template)
hello_template = molde.loadfile("hello_template")
name = nil
print(hello_template()) -- "Hello world"
```



Testing
-------
Run automated tests using [busted](http://olivinelabs.com/busted/):

	$ busted


Documentation
-------------
The API is documented using [LDoc](https://github.com/stevedonovan/LDoc) and
is available at [github pages](http://gilzoide.github.io/molde).

To generate:

	$ ldoc ldoc/

