local UDim = require("@UDim")
local Color3 = require("@Color3")

local propTable = {
	Value = nil,
}

return {
	class = "ValueBase",
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
