local propTable = {
	Name = "DialogChoice",
	BaseClass = "Kinemium.instance",

	GoodbyeChoiceActive = true,
	GoodbyeDialog = "",
	ResponseDialog = "",
	UserDialog = "",
}

return {
	class = "DialogChoice",
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
