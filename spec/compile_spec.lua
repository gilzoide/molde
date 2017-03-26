local molde = require 'molde'

describe('Molde compile function', function()
	it('empty template', function()
		assert.equals(molde.compile(''), molde.__script_prefix .. '\n' .. molde.__script_suffix)
	end)

	it('invalid template, same error from parsing', function()
		local function check_compile_error(template, expected_err)
			local res, err = molde.compile(template)
			assert.is_nil(res)
			local expected = molde.errors[expected_err]
			assert.equal(expected, err:sub(1, #expected))
		end
		check_compile_error('{% this statement never closes } }', 'ExpectedClosingStatementError')
		check_compile_error('{{ nor does this value } }', 'ExpectedClosingValueError')
		check_compile_error('unexpected closing delimiter }}', 'UnexpectedClosingValueError')
		check_compile_error('another unexpected closing delimiter %}', 'UnexpectedClosingStatementError')
		check_compile_error('{% unmatching delimiters }}', 'UnexpectedClosingValueError')
		check_compile_error('{{ (more) unmatching delimiters %}', 'UnexpectedClosingStatementError')

		check_compile_error('nothing after value opening {{', 'EmptyValueError')
		check_compile_error('nothing after statement opening {%', 'EmptyStatementError')
		check_compile_error('empty value {{}} oopsy!', 'EmptyValueError')
		check_compile_error('empty statement {%%} oops again!', 'EmptyStatementError')
	end)

	it('string braces level changes', function()
		local function check_braces_level(level, expect_error)
			molde.string_bracket_level = level
			local assertion = expect_error and assert.has_error or assert.has_no.errors
			assertion(function() molde.compile('long strings are used in literals') end)
		end
		check_braces_level(-1, false)
		check_braces_level(nil, true)
		check_braces_level('string', true)
		check_braces_level(false, true)
		check_braces_level(5, false)
	end)
end)
