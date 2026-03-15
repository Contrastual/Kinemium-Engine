local Color3 = require("@Color3")

local propTable = {
	Name = "Folder",
}

return {
	class = "Folder",
	callback = function(instance)
		instance:SetProperties(propTable)
		instance:SetMetadata("ExplorerIconColor", Color3.new(1, 0, 0))
		instance:SetMetadata("ExplorerIconTransparency", 0.3)

		return instance
	end,
	inherit = function(tble)
		for prop, val in pairs(propTable) do
			tble[prop] = val
		end
	end,
}
