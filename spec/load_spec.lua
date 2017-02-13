local molde = require 'molde'

describe('Molde load function', function()
	it('just literal', function()
		assert.equals(molde.load('oie'), 'oie')
	end)
end)
