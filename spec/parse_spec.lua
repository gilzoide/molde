local molde = require 'molde'

describe('Molde parse function', function()
	it('empty template', function()
		assert.are.same(molde.parse(''), {})
	end)

	it('content tags', function()
		local one_of_each = molde.parse('literal {{ value }}{% statement %}')
		assert.are.same('literal', next(one_of_each[1]))
		assert.are.same('value', next(one_of_each[2]))
		assert.are.same('statement', next(one_of_each[3]))
	end)

	it('invalid template', function()
		assert.is_nil(molde.parse('{% this statement never closes } }'))
		assert.is_nil(molde.parse('{{ nor does this value } }'))
		assert.is_nil(molde.parse('{% unmatching delimiters }}'))
		assert.is_nil(molde.parse('{{ (more) unmatching delimiters %}'))
	end)
end)
