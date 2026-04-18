local Instance = require("@Instance")
local StarterGui = Instance.new("StarterGui")

StarterGui:SetProperties({
	Enabled = true,
	ResetOnSpawn = true,
	ZIndexBehavior = "Sibling",
	CoreGuiEnabled = true,
})

StarterGui.InitRenderer = function(renderer, signal, datamodel)
	return StarterGui
end

return StarterGui
