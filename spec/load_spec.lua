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
		assert.equals("hello not world", hello_template{name = 'not world'})
		_ENV.name = 'test'
		assert.equals("hello test", hello_template(nil, _ENV))
		assert.equals("hello world", hello_template({name = false}, _ENV))
	end)

	it('invalid template, same error from compile', function()
		local function check_load_error(template, expected_err)
			local res, err = molde.load(template)
			assert.is_nil(res)
			local expected = molde.ParseError[expected_err]
			assert.is_not_nil(err:find(expected, 1, true))
		end
		check_load_error('{% this statement never closes', 'EXPECTED_CLOSING_STATEMENT')
		check_load_error('{{ nor does this value } }', 'EXPECTED_CLOSING_VALUE')
		check_load_error('unexpected closing delimiter }}', 'UNEXPECTED_CLOSING_VALUE')
		check_load_error('another unexpected closing delimiter %}', 'UNEXPECTED_CLOSING_STATEMENT')
		check_load_error('{% unmatching delimiters }}', 'UNEXPECTED_CLOSING_VALUE')
		check_load_error('{{ (more) unmatching delimiters %}', 'UNEXPECTED_CLOSING_STATEMENT')

		check_load_error('empty value {{}} oopsy!', 'EMPTY_VALUE')
		check_load_error('empty statement {%%} oops again!', 'EMPTY_STATEMENT')
	end)

	it('invalid generated code', function()
		local invalid_code = molde.load '{% this is invalid Lua code %}'
		assert.is_function(invalid_code)
		assert.is_nil(invalid_code())
		invalid_code = molde.load '{% if without_then %}{% end %}'
		assert.is_function(invalid_code)
		assert.is_nil(invalid_code())
	end)

	it('assignment on template sandboxed env', function()
		local assign_template = molde.load [[Hello {%
			-- variables are registered in _ENV, the sandboxed environment
			hello = "world"
			-- local variables are not
			local world = "is not enough"
		%}{{ hello }}]]
		local values = {hello = "not used"}
		local result, env = assign_template(values, _ENV)
		assert.equals('Hello world', result)
		assert.equals('world', env.hello)
		assert.is_nil(_ENV.hello)
		assert.is_nil(env.world)
		assert.equals("not used", values.hello)
	end)
end)
