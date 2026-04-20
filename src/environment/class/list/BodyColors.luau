local Color3 = require("@Color3")

local propTable = {
	Name = "BodyColors",
	BaseClass = "Kinemium.instance",

	HeadColor3 = Color3.new(1, 1, 1),
	LeftArmColor3 = Color3.new(1, 1, 1),
	LeftLegColor3 = Color3.new(1, 1, 1),
	RightArmColor3 = Color3.new(1, 1, 1),
	RightLegColor3 = Color3.new(1, 1, 1),
	TorsoColor3 = Color3.new(1, 1, 1),
}

return {
	class = "BodyColors",
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
