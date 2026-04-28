local propTable = {
	Name = "DataModel",
}

return {
	class = "DataModel",
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
