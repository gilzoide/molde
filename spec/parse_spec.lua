local molde = require 'molde'

describe('Molde parse function', function()
	it('empty template', function()
		assert.are.same(molde.parse '', {})
	end)

	it('content tags', function()
		local one_of_each = molde.parse 'literal {{ value }} {% statement %}'
		assert.are.same({
			{literal = 'literal '},
			{value = ' value '},
			{literal = ' '},
			{statement = ' statement '},
		}, one_of_each)
	end)

	it('invalid template', function()
		local function check_parse_error(template, expected_err)
			local res, err = molde.parse(template)
			assert.is_nil(res)
			assert.equals(molde.errors[expected_err], err)
		end
		check_parse_error('{% this statement never closes } }', 'ClosingStatementError')
		check_parse_error('{{ nor does this value } }', 'ClosingValueError')
		check_parse_error('{% unmatching delimiters }}', 'ClosingStatementError')
		check_parse_error('{{ (more) unmatching delimiters %}', 'ClosingValueError')

		check_parse_error('nothing after value opening {{', 'EmptyValueError')
		check_parse_error('nothing after statement opening {%', 'EmptyStatementError')
		check_parse_error('empty value {{}} oopsy!', 'EmptyValueError')
		check_parse_error('empty statement {%%} oops again!', 'EmptyStatementError')
	end)

	it("if ain't open, don't close, nor give error", function()
		local function check_literal_only(template)
			local literal_only = molde.parse(template)
			assert.truthy(literal_only)
			assert.equals(1, #literal_only)
			local tag, _ = next(literal_only[1])
			assert.equals('literal', tag)
		end
		check_literal_only("{ %didn't open statement properly%}}}}")
		check_literal_only("\\{{didn't open value properly}}}}}")
	end)

	it('escaping braces on literal', function()
		local escaped_literal = molde.parse([[\{\{this is escaped\}\}]])
		assert.are.same(1, #escaped_literal)
		local tag, literal = next(escaped_literal[1])
		assert.are.same('literal', tag)
		assert.are.same('{{this is escaped}}', literal)
	end)

	it('escaping braces on value', function()
		local escaped_value = molde.parse([[{{\{{this is escaped}\}}}]])
		assert.are.same(1, #escaped_value)
		local tag, value = next(escaped_value[1])
		assert.are.same('value', tag)
		assert.are.same('{{this is escaped}}', value)
	end)

	it('escaping braces on statement', function()
		local escaped_statement = molde.parse([[{%\{%this is escaped%\}%}]])
		assert.are.same(1, #escaped_statement)
		local tag, statement = next(escaped_statement[1])
		assert.are.same('statement', tag)
		assert.are.same('{%this is escaped%}', statement)
	end)
end)
