local Color3 = require("@Color3")

local propTable = {
	Color = Color3.new(1, 1, 1),
	Enabled = true,
	LocalTransparencyModifier = 0,
	SparkleColor = Color3.new(1, 1, 1),
	TimeScale = 1,
	Name = "Sparkles",
	BaseClass = "Instance",
}

return {
	class = "Sparkles",

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
