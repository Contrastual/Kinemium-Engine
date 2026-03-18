local Vector3 = require("@datatypes/Vector3")
local CFrame = require("@datatypes/CFrame")

local propTable = {
	Part0 = nil,
	Part1 = nil,

	Enabled = true,
	Name = "WeldConstraint",
	ElapsedTime = 0,
}

return {
	class = "WeldConstraint",

	callback = function(instance, renderer, datamodel)
		local KinemiumPhysicsService = datamodel:GetService("JoltPhysicsService")

		local lib = KinemiumPhysicsService.jolt.lib

		instance:SetProperties(propTable)

		local function rebuild()
			if instance._active then
				lib.JPH_PhysicsSystem_RemoveConstraint(KinemiumPhysicsService.jolt.physicsSystem, instance._active)
				instance._active = nil
			end

			if not instance.Enabled then
				return
			end

			if not instance.Part0 or not instance.Part1 then
				return
			end

			instance._active = KinemiumPhysicsService.CreateWeld(instance.Part0, instance.Part1)
		end

		instance.Changed:Connect(function(property)
			if property == "Part0" or property == "Part1" or property == "Enabled" then
				print("Rebuilt")
				rebuild()
			end
		end)

		return instance
	end,

	inherit = function(tble)
		for prop, val in pairs(propTable) do
			tble[prop] = val
		end
	end,
}
