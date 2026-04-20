local Color3 = require("@Color3")

local propTable = {
	Name = "Atmosphere",
	BaseClass = "Kinemium.posteffect",

	Density = 0.3,
	Offset = 0,
	Color = Color3.new(0.5, 0.5, 0.5),
	Decay = Color3.new(0.5, 0.5, 0.5),
	Glare = 0,
	Haze = 0,
}

return {
	class = "Atmosphere",
	callback = function(instance)
		instance:SetProperties(propTable)
		return instance
	end,
	inherit = function(tble)
		for prop, val in pairs(propTable) do
			tble[prop] = val
		end
	end,
}
