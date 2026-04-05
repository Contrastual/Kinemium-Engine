local Instance = require("@Instance")

local CoreGui = Instance.new("CoreGui")

CoreGui:SetProperties({
	Version = "1.0.9",
})

CoreGui.InitRenderer = function(renderer, signal, datamodel)
	return CoreGui
end

return CoreGui
