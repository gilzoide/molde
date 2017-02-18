Molde
=====
[![Build Status](https://travis-ci.org/gilzoide/molde.svg?branch=master)](https://travis-ci.org/gilzoide/molde)

Molde is a template engine for Lua 5.2+. It compiles a template string to a
function that generates the final string by substituting values by the ones in
a sandboxed environment.


Testing
-------
Run automated tests using [busted](http://olivinelabs.com/busted/):

	$ busted


Documentation
-------------
The API is documented using [LDoc](https://github.com/stevedonovan/LDoc).
To generate:

	$ ldoc ldoc/
