local Instance = require("@Instance")
local signal = require("@Kinemium.signal")
local Vector3 = require("@datatypes/Vector3")

local VideoService = Instance.new("VideoService")
VideoService.ExplorerHidden = true

VideoService.InitRenderer = function(renderer, signal, datamodel)
	local exampleVideo = "./src/assets/videos/example.mp4"

	VideoService:SetProperties({})
end

return VideoService
