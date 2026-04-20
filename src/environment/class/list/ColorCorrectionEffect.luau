local Color3 = require("@Color3")

local propTable = {
	Name = "ColorCorrectionEffect",
	BaseClass = "Kinemium.posteffect",

	Brightness = 0,
	Contrast = 0,
	Saturation = 0,
	TintColor = Color3.new(1, 1, 1),
}

return {
	class = "ColorCorrectionEffect",
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
