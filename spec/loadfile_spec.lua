local molde = require 'molde'


describe('Molde loadfile function error handling', function()
	it('oie =] #skip', function()
		assert.has_error(function() print(molde.loadfile('.')) end)
	end)
end)
