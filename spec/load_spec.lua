local molde = require 'molde'

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
		assert.equals("hello test", hello_template({}, _ENV))
		assert.equals("hello world", hello_template({name = false}, _ENV))
	end)

	it('invalid template, same error from compile', function()
		local function check_load_error(template, expected_err)
			local res, err = molde.load(template)
			assert.is_nil(res)
			assert.equals(molde.errors[expected_err], err)
		end
		check_load_error('{% this statement never closes } }', 'ClosingStatementError')
		check_load_error('{{ nor does this value } }', 'ClosingValueError')
		check_load_error('{% unmatching delimiters }}', 'ClosingStatementError')
		check_load_error('{{ (more) unmatching delimiters %}', 'ClosingValueError')

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
end)
