local propTable = {
	Name = "UIAspectRatioConstraint",
	BaseClass = "Kinemium.uimodifier",

	AspectRatio = 1,
	AspectType = 1, -- Placeholder until enums are properly handled
	DominantAxis = 1, -- Placeholder until enums are properly handled
}

return {
	class = "UIAspectRatioConstraint",
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
