local propTable = {
	Name = "PathfindingModifier",
	BaseClass = "Kinemium.instance",

	Label = "",
	PassThrough = false,
}

return {
	class = "PathfindingModifier",
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
