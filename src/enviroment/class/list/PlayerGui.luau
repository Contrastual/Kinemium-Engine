local propTable = {}

return {
	class = "PlayerGui",
	callback = function(instance, starterGui)
		return instance
	end,
	inherit = function(tble)
		for prop, val in pairs(propTable) do
			tble[prop] = val
		end
	end,
}
