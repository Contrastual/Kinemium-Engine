local Color3 = require("@Color3")

local propTable = {
	Name = "ShirtGraphic",
	BaseClass = "Kinemium.instance",

	Graphic = "",
	Color3 = Color3.new(1, 1, 1),
}

return {
	class = "ShirtGraphic",
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
