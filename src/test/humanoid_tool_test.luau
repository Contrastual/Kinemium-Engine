_G.log = function() end
_G.warn = function() end
local Instance = require("@Instance")
local testing = zune.testing
local expect = testing.expect

testing.describe("Humanoid Tool Support", function()
	testing.test("EquipTool and UnequipTools", function()
		local registry = require("../environment/class/Registry")
		local char = Instance.new("Model")
		local humanoid = registry.new("Humanoid", nil, nil, true)
		humanoid.Parent = char

		local rightArm = Instance.new("Part")
		rightArm.Name = "RightArm"
		rightArm.CFrame = require("@CFrame").new()
		rightArm.Parent = char

		local root = Instance.new("Part")
		root.Name = "HumanoidRootPart"
		root.Parent = char

		local tool = registry.new("Tool", nil, nil, true)
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Parent = tool

		-- Equip Tool
		humanoid:EquipTool(tool)

		expect(tool.Parent).toBe(char)
		local weld = rightArm:FindFirstChildOfClass("WeldConstraint", true) or char:FindFirstChildOfClass("WeldConstraint", true)
		expect(weld ~= nil).toBe(true)
		expect(weld.Part0).toBe(rightArm)
		expect(weld.Part1).toBe(handle)

		-- Unequip Tool
		pcall(function()
			humanoid:UnequipTools()
		end)

		local weldAfter = char:FindFirstChildOfClass("WeldConstraint", true)
		expect(weldAfter == nil).toBe(true)
	end)
end)
