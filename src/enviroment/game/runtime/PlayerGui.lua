local Instance = require("@Instance")
local signal = require("@Kinemium.signal")

local PlayerGui = Instance.new("PlayerGui")

PlayerGui.InitRenderer = function(renderer, renderer_signal)
	PlayerGui:SetProperties({
		ResetOnSpawn = true,
	})

	PlayerGui.ChildAdded:Connect(function(child)
		if type(child) == "table" and child.BaseClass == "UIContainer" then
			if child["render"] then
				renderer.AddToGuiRenderingPool(function()
					return child
				end, child.render)
			end
		end
	end)

	return PlayerGui
end

return PlayerGui
