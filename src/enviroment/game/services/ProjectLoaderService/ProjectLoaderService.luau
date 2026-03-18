local Instance = require("@Instance")
local signal = require("@Kinemium.signal")

local ProjectLoaderService = Instance.new("LogService")
ProjectLoaderService.ExplorerHidden = true

local serde = zune.serde

local toml = zune.serde.toml
local fs = zune.fs
local projectsFile = "./src/projects.toml"
local zembed = require("@zembed")

local absolutePath
if zembed.IsEmbedded() then
	local tomlFile = zembed.GetFilesThatHas("projects.toml")
	projectsFile = "../" .. tomlFile[1]
	if fs.stat("./projects.toml").kind == "none" then
		fs.createFile("./projects.toml")
	end
	absolutePath = fs.realPath("./projects.toml")
else
	absolutePath = fs.realPath("./src/projects.toml")
end

local settings = {
	["luau-lsp.types.definitionFiles"] = { absolutePath },
}

ProjectLoaderService.InitRenderer = function(renderer, renderer_signal)
	ProjectLoaderService:SetProperties({
		GetProjects = function()
			local read = fs.readFile(projectsFile)
			local data = toml.decode(read)
			if data then
				if data.projects then
					return data.projects
				else
					return {}
				end
			end
			return {}
		end,

		StartObserve = function(path) end,

		NewProject = function(name, path, iconPath, description)
			if not name then
				return
			end
			if not path then
				return
			end

			local kprojFile = path .. "/kproj.toml"
			-- write to projects list
			local projects = ProjectLoaderService.GetProjects()

			projects[name] = {
				icon = iconPath,
				path = path,
				name = name,
				engine_version = "1.10.4",
				last_opened = os.time(),
			}

			local encoded = toml.encode({
				projects = projects,
			})

			fs.writeFile(projectsFile, encoded)

			-- write project settings file
			local success, result = pcall(function()
				fs.makeDir(path .. "/assets", true)
				fs.makeDir(path .. "/server", true)
				fs.makeDir(path .. "/client", true)
				fs.makeDir(path .. "/gui", true)
				fs.makeDir(path .. "/objects", true)
				fs.makeDir(path .. "/.vscode", true)
				fs.makeDir(path .. "/autosave", true)

				fs.writeFile(
					path .. "/.vscode/settings.json",
					zune.serde.json.encode(settings, {
						pretty_indent = 1,
					})
				)

				fs.createFile(kprojFile, {
					exclusive = true,
				})

				fs.writeFile(
					kprojFile,
					serde.toml.encode({
						info = {
							name = name,
							icon = iconPath,
							desc = description,
						},
						pointers = {
							assets = "game.ReplicatedStorage",
							server = "game.ServerScriptService",
							client = "game.StarterPlayerScripts",
							gui = "game.StarterGui",
							objects = "game.Workspace",
						},
						scripting = {
							polyglot = true,
							ntvcg = true,
						},
					})
				)
			end)
			print(success, result)

			return encoded
		end,

		GetGamesAsSubmenu = function(func)
			local read = fs.readFile(projectsFile)
			local data = toml.decode(read)
			local result = {}

			if data then
				local pjs = data.projects

				if pjs then
					for _, projectData in pairs(pjs) do
						table.insert(result, {
							label = projectData.name,
							onClick = function()
								func(projectData)
							end,
						})
					end
				end
			end

			return result
		end,
	})
end

return ProjectLoaderService
