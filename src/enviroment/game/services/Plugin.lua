local Instance = require("@Instance")
local signal = require("@Kinemium.signal")

local Plugin = Instance.new("Plugin")
local aereon = require("@Aereon")
local raylib = require("@raylib")
local lib = raylib.lib

Plugin.InitRenderer = function(renderer, renderer_signal, game)
	task.spawn(function()
		Plugin:SetProperties({
			ResetOnSpawn = true,
		})

		repeat
			task.wait()
		until game.GetService

		local window = aereon.window(game)

		function Plugin:CreateWindow(config)
			local new = window.create(config)
			return new
		end

		renderer.Pool.new("2d", function()
			if not game.GetService then
				return
			end
			local StudioThemeService = game:GetService("StudioThemeService")
			if StudioThemeService then
				local dt = lib.GetFrameTime()
				window.update(dt, StudioThemeService.SelectedTheme.aereon)
				window.draw(dt, StudioThemeService.SelectedTheme.aereon)
			end
		end)
	end)

	return Plugin
end

return Plugin
