local propTable = {
	Name = "TouchTransmitter",
	BaseClass = "Kinemium.instance",
	IsDragging = false,  -- Track drag state
}

return {
	class = "TouchTransmitter",
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
