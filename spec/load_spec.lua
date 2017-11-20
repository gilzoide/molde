local molde = require 'molde'

_ENV = _ENV or getfenv()

describe('Molde load function', function()
	it('empty', function()
		local empty_template = molde.load ''
		assert.equals('', empty_template())
	end)

	it('just literal', function()
		local just_literal = molde.load 'hello'
		assert.equals('hello', just_literal())
		assert.equals('hello', just_literal{hello = 'not hello'})
	end)

	it('values', function()
		local hello_template = molde.load 'hello {{ name or "world" }}'
		assert.equals("hello world", hello_template())
		name = 'test'
		assert.equals("hello test", hello_template(nil, _ENV))
		assert.equals("hello world", hello_template({name = false}, _ENV))
	end)

	it('invalid template, same error from compile', function()
		local function check_load_error(template, expected_err)
			local res, err = molde.load(template)
			assert.is_nil(res)
			local expected = molde.errors[expected_err]
			assert.equal(expected, err:sub(1, #expected))
		end
		check_load_error('{% this statement never closes } }', 'ExpectedClosingStatementError')
		check_load_error('{{ nor does this value } }', 'ExpectedClosingValueError')
		check_load_error('unexpected closing delimiter }}', 'UnexpectedClosingValueError')
		check_load_error('another unexpected closing delimiter %}', 'UnexpectedClosingStatementError')
		check_load_error('{% unmatching delimiters }}', 'UnexpectedClosingValueError')
		check_load_error('{{ (more) unmatching delimiters %}', 'UnexpectedClosingStatementError')

		check_load_error('nothing after value opening {{', 'EmptyValueError')
		check_load_error('nothing after statement opening {%', 'EmptyStatementError')
		check_load_error('empty value {{}} oopsy!', 'EmptyValueError')
		check_load_error('empty statement {%%} oops again!', 'EmptyStatementError')
	end)

	it('invalid generated code', function()
		local invalid_code = molde.load '{% this is invalid Lua code %}'
		assert.is_function(invalid_code)
		assert.has_error(invalid_code)
		invalid_code = molde.load '{% if without_then %}{% end %}'
		assert.is_function(invalid_code)
		assert.has_error(invalid_code)
	end)

	it('assignment on template sandboxed env', function()
		local assign_template = molde.load [[Hello {%
			-- variables are registered in _ENV, the sandboxed environment
			hello = "world"
			-- local variables are not
			local world = "is not enough"
		%}{{ hello }}]]
		local values = {hello = "not used"}
		local result, env = assign_template(values)
		assert.equals('Hello world', result)
		assert.equals('world', env.hello)
		assert.is_nil(env.world)
		assert.equals("not used", values.hello)
	end)
end)
