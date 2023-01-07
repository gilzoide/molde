local molde = require 'molde'

describe('Molde compile function', function()
	it('invalid template, same error from parsing', function()
		local function check_compile_error(template, expected_err)
			local res, err = molde.compile(template)
			assert.is_nil(res)
			local expected = molde.ParseError[expected_err]
			assert.is_not_nil(err:find(expected, 1, true))
		end
		check_compile_error('{% this statement never closes', 'EXPECTED_CLOSING_STATEMENT')
		check_compile_error('{{ nor does this value } }', 'EXPECTED_CLOSING_VALUE')
		check_compile_error('unexpected closing delimiter }}', 'UNEXPECTED_CLOSING_VALUE')
		check_compile_error('another unexpected closing delimiter %}', 'UNEXPECTED_CLOSING_STATEMENT')
		check_compile_error('{% unmatching delimiters }}', 'UNEXPECTED_CLOSING_VALUE')
		check_compile_error('{{ (more) unmatching delimiters %}', 'UNEXPECTED_CLOSING_STATEMENT')

		check_compile_error('empty value {{}} oopsy!', 'EMPTY_VALUE')
		check_compile_error('empty statement {%%} oops again!', 'EMPTY_STATEMENT')
	end)
end)
