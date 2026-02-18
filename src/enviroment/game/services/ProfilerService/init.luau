local Instance = require("@Instance")
local signal = require("@Kinemium.signal")

local ProfilerService = Instance.new("ProfilerService")
ProfilerService.ExplorerHidden = true

ProfilerService.InitRenderer = function(renderer, renderer_signal)
	ProfilerService:SetProperties({
		ENGINE_PROFILER = ENGINE_PROFILER,
	})
end

return ProfilerService
