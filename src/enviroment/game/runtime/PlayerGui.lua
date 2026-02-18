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
				renderer.Pool.new("2d", function()
					local dt = renderer.Raylib.lib.GetFrameTime()
					child.render(renderer.Raylib.lib, child, dt, renderer.Raylib.structs, renderer)
				end, -5)
			end
		end
	end)

	return PlayerGui
end

return PlayerGui
