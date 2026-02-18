local Instance = require("@Instance")
local signal = require("@Kinemium.signal")

local KinemiumRaylib = Instance.new("KinemiumRaylib")
KinemiumRaylib.ExplorerHidden = true

KinemiumRaylib.InitRenderer = function(renderer, renderer_signal)
	KinemiumRaylib:SetProperties({
		lib = renderer.Raylib.lib,
		const = renderer.Raylib.const,
		structs = renderer.Raylib.structs,
		renderer = renderer,
	})
end

return KinemiumRaylib
