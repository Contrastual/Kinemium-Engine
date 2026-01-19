local UDim = require("@UDim")
local Color3 = require("@Color3")
local CFrame = require("@CFrame")

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
