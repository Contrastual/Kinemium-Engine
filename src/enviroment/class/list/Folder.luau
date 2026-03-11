local Color3 = require("@Color3")

local propTable = {
	Name = "Folder",
	IconColor = Color3.new(1, 1, 1),
	IconSize = 21,
	IconTransparency = 0,
}

return {
	class = "Folder",
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
