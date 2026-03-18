local UDim = require("@datatypes/UDim")
local Color3 = require("@datatypes/Color3")
local CFrame = require("@datatypes/CFrame")

local propTable = {
	Value = CFrame.new(0, 0, 0),
}

return {
	class = "CFrameValue",
	non_creatable = true,
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
