local molde = require 'molde'

describe('Molde load function #nyi', function()
	it('just literal', function()
		assert.equals(molde.load('oie'), 'oie')
	end)
end)
