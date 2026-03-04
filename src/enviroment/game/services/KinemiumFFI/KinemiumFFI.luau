local Instance = require("@Instance")
local signal = require("@Kinemium.signal")

local KinemiumFFI = Instance.new("KinemiumFFI")
KinemiumFFI.ExplorerHidden = true

KinemiumFFI.InitRenderer = function(renderer, renderer_signal)
	KinemiumFFI:SetProperties(zune.ffi)
end

return KinemiumFFI
