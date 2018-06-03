local molde = require 'molde'
local doc_molde = require 'ldoc.molde'

describe('Check version match', function()
	it('from module and documentation', function()
		assert.equal(molde.VERSION, doc_molde.VERSION)
	end)
end)

