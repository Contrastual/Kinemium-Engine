local Instance = require("@Instance")
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
				local renderId
				renderId = renderer.Pool.new("2d", function()
					if not child.render then
						renderer.Pool.Destroy(renderId)
						return
					end
					local dt = renderer.Raylib.lib.GetFrameTime()
					child.render(renderer.Raylib.lib, child, dt, renderer.Raylib.structs, renderer)
				end, -5)
			end
		end
	end)
end

return StarterGui
