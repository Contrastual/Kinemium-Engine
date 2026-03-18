local Instance = require("@Instance")
local Enum = require("@EnumMap")

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

		local syncedPaths = {}

		local function syncDirectory(dirPath, parentObject)
			FileWalker.Walk(dirPath, function(objPath, entry)
				if syncedPaths[objPath] == true then
					return
				end
				syncedPaths[objPath] = true
				if objPath == dirPath then
					return
				end
				if entry.kind == "file" then
					local read = fs.readFile(objPath)
					local extension = entry.name:gsub("^[^.]+", "")
					local stripped = entry.name:gsub("%.[^.]+%.[^.]+$", ""):gsub("%.[^.]+$", "")

					local scriptType = "ModuleScript"
					local language = Enum.Language.Luau
					local runContext = Enum.RunContext.Server

					local serverExts = {
						[".server.luau"] = Enum.Language.Luau,
						[".server.ts"] = Enum.Language.JavaScript,
						[".server.py"] = Enum.Language.Python,
						[".server.wasm"] = Enum.Language.WASM,
					}
					local clientExts = {
						[".client.luau"] = Enum.Language.Luau,
						[".client.ts"] = Enum.Language.JavaScript,
						[".client.py"] = Enum.Language.Python,
						[".client.wasm"] = Enum.Language.WASM,
					}
					local moduleExts = {
						[".luau"] = Enum.Language.Luau,
						[".ts"] = Enum.Language.JavaScript,
						[".py"] = Enum.Language.Python,
						[".wasm"] = Enum.Language.WASM,
					}

					if serverExts[extension] then
						scriptType = "Script"
						language = serverExts[extension]
						runContext = Enum.RunContext.Server
					elseif clientExts[extension] then
						scriptType = "LocalScript"
						language = clientExts[extension]
						runContext = Enum.RunContext.Client
					elseif moduleExts[extension] then
						scriptType = "ModuleScript"
						language = moduleExts[extension]
					end

					if read then
						local new = Instance.new(scriptType)
						new.Source = read
						new.Name = stripped
						new.Language = language
						new.RunContext = runContext
						new.BaseClass = "ScriptContainer"
						new.Parent = parentObject
					end
				elseif entry.kind == "directory" then
					local folder = Instance.new("Folder")
					folder.Name = entry.name
					folder.Parent = parentObject
					syncDirectory(objPath, folder)
				end
			end)
		end

		zune.task.spawn(function()
			for path, serviceObject in pairs(paths) do
				print("Watching " .. path)
				syncDirectory(path, serviceObject)
			end
		end)
	end
end

return ProjectSyncService
