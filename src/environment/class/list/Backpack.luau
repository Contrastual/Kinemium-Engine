local propTable = {}

return {
	class = "Backpack",
	callback = function(instance, renderer, game)
		instance:SetProperties(propTable)
		return instance
	end,
	inherit = function(tble)
		for prop, val in pairs(propTable) do
			tble[prop] = val
		end
	end,
}
