local molde = require 'molde'

describe('Molde compile function', function()
	it('empty template', function()
		assert.equals(molde.compile(''), molde.__script_prefix .. molde.__script_suffix)
		assert.equals(molde.compile('opa, meu chapa =] \\{como vai}{% print("oi") %}{{ oi }}'), "")
	end)
end)
