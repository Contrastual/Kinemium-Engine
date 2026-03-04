local Instance = require("@Instance")
local signal = require("@Kinemium.signal")

local ProjectSyncService = Instance.new("LogService")
ProjectSyncService.ExplorerHidden = true

local serde = zune.serde

local toml = zune.serde.toml
local fs = zune.fs

ProjectSyncService.InitRenderer = function(renderer, renderer_signal)
	ProjectSyncService:SetProperties({})

	function ProjectSyncService:StartSyncing(projectPath)
		fs.watch(projectPath, function(event)
			print("Got watch event " .. event)
		end)
	end
end

return ProjectSyncService
