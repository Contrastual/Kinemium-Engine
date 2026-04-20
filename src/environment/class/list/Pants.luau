local Color3 = require("@Color3")

local propTable = {
	Name = "Pants",
	BaseClass = "Kinemium.instance",

	PantsTemplate = "",
	Color3 = Color3.new(1, 1, 1),
}

return {
	class = "Pants",
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
