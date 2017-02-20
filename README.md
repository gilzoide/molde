Molde
=====
[![Build Status](https://travis-ci.org/gilzoide/molde.svg?branch=master)](https://travis-ci.org/gilzoide/molde)

Molde is a template engine for Lua 5.2+. It compiles a template string to a
function that generates the final string by substituting values by the ones in
a sandboxed environment.


Templates
---------
There are 3 constructs templates recognize:

- __Literals__: Content that will be copied unmodified to the resulting string
- __Value__: A value processed by Lua and appended to the resulting string,
  stringified by `tostring`
- __Statement__: A Lua code block to be copied unmodified to the generated code,
  used for variable assignments, repetitions, conditions. It doesn't directly
  generate contents for the resulting string

__Values__ are delimited by matching `{{` and `}}`, __statements__ by `{%` and
`%}`, and everything else is considered __literal__. Braces can be escaped
using a trailing backslash: `\\{` or `\\}`.

Example:

```
This is a molde template.
By default, everything is copied unmodified to the resulting string.

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
- Escaping \{{ Hi! }}
  "Escaping {{ Hi! }}" (no opening '{{', so it is considered literal)
- table.insert is used in values {{ so they must be a valid expression! }}
  Error: ')' expected near 'they'

Statements are Lua statements:
- {% for i = 1, 5 do %}{{ i }} {% end %}
  "1 2 3 4 5 "
- {% -- this is just a comment, y'know %}
  ""
- {{ unbound_variable }}{% unbound_variable = "Hi!" %}{{ unbound_variable }}
  "nilHi!"
- {% if false then %}This will never be printed{% else %}Conditionals!{% end %}
  "Conditionals!"
- {% if without_then %}Statements must form valid Lua code!{% end %}
  Error: 'then' expected near 'table'
```


Usage
-----
```lua
local molde = require 'molde'

-- molde.load and molde.loadfile return a function
-- that receives the environment to use (default = _ENV)
hello_template = molde.load([[Hello {{ name or "world" }}]])
print(hello_template()) -- "Hello world"
-- pass in your variables in a table
print(hello_template{name = "gilzoide"}) -- "Hello gilzoide"
-- or use _ENV
name = gilzoide
print(hello_template()) -- "Hello gilzoide"

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
The API is documented using [LDoc](https://github.com/stevedonovan/LDoc).
To generate:

	$ ldoc ldoc/
