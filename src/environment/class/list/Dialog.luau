local propTable = {
	Name = "Dialog",
	BaseClass = "Kinemium.instance",

	BehaviorType = 1, -- Enum
	ConversationDistance = 25,
	GoodbyeChoiceActive = true,
	GoodbyeDialog = "",
	InUse = false,
	InitialPrompt = "",
	Purpose = 1, -- Enum
	Tone = 1, -- Enum
}

return {
	class = "Dialog",
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
