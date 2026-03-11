local Part = require("./Part")

local propTable = {
	Name = "Union",
}
Part.inherit(propTable)

return {
	class = "Union",

	callback = function(instance, renderer)
		propTable.render = function(part, camera, lib) end

		instance:SetProperties(propTable)

		instance.Changed:Connect(function(property)
			if property == "Anchored" then
				renderer.Signal:Fire("UpdatePart", instance)
			end
		end)

		return instance
	end,

	inherit = function(tble)
		for prop, val in pairs(propTable) do
			tble[prop] = val
		end
	end,
}
