local Color3 = require("@Color3")

local propTable = {
	Color = Color3.new(1, 1, 1),
	Enabled = true,
	Heat = 0,
	LocalTransparencyModifier = 0,
	SecondaryColor = Color3.new(1, 1, 1),
	Size = 0,
	TimeScale = 1,
	Name = "Fire",
	BaseClass = "Instance",
}

return {
	class = "Fire",

	callback = function(instance)
		instance:SetProperties(propTable)

		-- TODO: Implement functionality, use already existing Particle Emitter

		return instance
	end,

	inherit = function(tble)
		for prop, val in pairs(propTable) do
			tble[prop] = val
		end
	end,
}
