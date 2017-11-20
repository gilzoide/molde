local molde = require 'molde'

_ENV = _ENV or getfenv()

describe('Molde loadfile function', function()
	it('existing file', function()
		local template = molde.loadfile 'spec/hello_template.molde'
		assert.is_function(template)
		assert.equals('Hello world', template())
		assert.equals('Hello test', template{name = 'test'})
		name = 'test'
		assert.equals('Hello test', template({}, _ENV))
	end)

	it('non-existing file', function()
		local template = molde.loadfile 'spec/non_existent.molde'
		assert.is_nil(template)
	end)
end)
