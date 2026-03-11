local Instance = require("@Instance")
local signal = require("@Kinemium.signal")

local GongService = Instance.new("GongService")
GongService.ExplorerHidden = true

GongService.InitRenderer = function(renderer, renderer_signal, datamodel)
	GongService:SetProperties({
		Hit = function()
			return "Gong."
		end,
	})
end

return GongService
