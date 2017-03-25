local molde = require 'molde'

describe('Molde loadfile function', function()
	it('existing file #dev', function()
		local template = molde.loadfile 'spec/hello_template.molde'
		assert.is_function(template)
		assert.equals('Hello world', template())
		assert.equals('Hello test', template{name = 'test'})
		name = 'test'
		assert.equals('Hello test', template({}, _ENV))
	end)
end)
