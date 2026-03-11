local Instance = require("@Instance")

local ProjectSyncService = Instance.new("LogService")
ProjectSyncService.ExplorerHidden = true

local toml = zune.serde.toml
local fs = zune.fs

local function resolvePath(root, path)
	local current = root

	for segment in path:gmatch("[^%.]+") do
		if segment == "game" then
			current = root
		else
			if not current then
				return nil
			end
			current = current:FindFirstChild(segment)
		end
	end

	return current
end

ProjectSyncService.InitRenderer = function(renderer, renderer_signal, game)
	ProjectSyncService:SetProperties({})

	local FileWalker = require("@FileWalker")

	function ProjectSyncService:StartSyncing(projectPath)
		if not projectPath or projectPath == "" then
			return
		end
		print("Began watching " .. projectPath)
		local configFile = fs.readFile(projectPath .. "/kproj.toml")
		local tomlObject = toml.decode(configFile)
		local paths = {}

		for dirName, pointer in pairs(tomlObject.pointers) do
			local service = resolvePath(game, pointer)
			if service then
				local dirPath = projectPath .. "/" .. dirName
				local stat = fs.stat(dirPath)
				if stat.kind == "directory" then
					paths[dirPath] = service
				end
			else
				print(`Directory {dirName} has no pointer, Not syncing`)
				continue
			end
		end

		zune.task.spawn(function()
			for path, serviceObject in pairs(paths) do
				print("Watching " .. path)
				FileWalker.Walk(path, function(objPath, entry)
					if objPath == path then
						return
					end
					if entry.kind == "file" then
						local read = fs.readFile(objPath)
						local extension = entry.name:gsub("^[^.]+", "")
						local stripped = entry.name:gsub("%.[^.]+%.[^.]+$", ""):gsub("%.[^.]+$", "")

						local scriptType = ""
						if extension == ".server.luau" then
							scriptType = "Script"
						elseif extension == ".client.luau" then
							scriptType = "LocalScript"
						elseif extension == ".luau" then
							scriptType = "ModuleScript"
						else
							scriptType = "ModuleScript"
						end

						if read then
							local new = Instance.new(scriptType)
							new.Source = read
							new.Name = stripped
							new.BaseClass = "ScriptContainer"
							new.Parent = serviceObject
						end
					elseif entry.kind == "directory" then
					end
				end)
			end
		end)
	end
end

return ProjectSyncService
