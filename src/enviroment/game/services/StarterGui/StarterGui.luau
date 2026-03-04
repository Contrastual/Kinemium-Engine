local Instance = require("@Instance")
local signal = require("@Kinemium.signal")
local Vector3 = require("@Vector3")

local StarterGui = Instance.new("StarterGui")

StarterGui:SetProperties({
	Enabled = true,
	ResetOnSpawn = true,
	ZIndexBehavior = "Sibling",
	CoreGuiEnabled = true,
})

StarterGui.InitRenderer = function(renderer, signal, datamodel)
	StarterGui.ChildAdded:Connect(function(child)
		if type(child) == "table" and child.BaseClass == "UIContainer" then
			if child["render"] then
				renderer.AddToGuiRenderingPool(function()
					return child
				end, child.render)
			end
		end
	end)
end

return StarterGui
