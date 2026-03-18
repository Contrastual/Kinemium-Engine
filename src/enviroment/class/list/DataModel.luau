local Vector3 = require("@datatypes/Vector3")
local Color3 = require("@datatypes/Color3")
local CFrame = require("@datatypes/CFrame")
local Enum = require("@EnumMap")

local propTable = {
	Name = "DataModel",
}

return {
	class = "DataModel",
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
