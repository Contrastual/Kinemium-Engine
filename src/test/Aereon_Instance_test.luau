local Instance = require("../modules/Aereon/component/objects/Instance")
local testing = zune.testing
local expect = testing.expect

testing.describe("Aereon Instance", function()
	testing.test("can be instantiated with default ClassName", function()
		local inst = Instance.new()
		expect(inst).toBeDefined()
		expect(inst.ClassName).toBe("Instance")
		expect(type(inst.Properties)).toBe("table")
	end)

	testing.test("can be instantiated with custom ClassName", function()
		local inst = Instance.new("CustomClass")
		expect(inst).toBeDefined()
		expect(inst.ClassName).toBe("CustomClass")
		expect(type(inst.Properties)).toBe("table")
	end)
end)
