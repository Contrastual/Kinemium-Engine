local KinemiumRaylib = game:GetService("KinemiumRaylib")
local RunService = game:GetService("RunService")
local renderer = KinemiumRaylib.renderer
local freecam = renderer.Freecam
local raylib = require("@raylib")
local playtestService = game:GetService("PlaytestService")

RunService.RenderStepped:Connect(function(a0: number)
	local camera = workspace.Camera
	if camera then
		if playtestService.IsPlaytesting then
			return
		end
		if game.Stop3DInput == true then
			return
		end

		local dt = raylib.lib.GetFrameTime()

		freecam.Update(dt, camera)
	end
end)
