local Instance = require("@Instance")

local serde = zune.serde
local ffi = zune.ffi
local fs = zune.fs

local Enum = require("@EnumMap")

local raylib = require("@raylib")
local PluginLoader = Instance.new("PluginLoader")
PluginLoader.ExplorerHidden = true

local Schema = require("@Schema")

local function fileExists(path)
	if fs.stat(path).kind == "none" then
		return false
	else
		return true
	end
end

local plugin_schema = Schema.new({
	name = Schema.nonEmptyString(),
	id = Schema.stringPattern("^[%a%d_%-]+%.[%a%d_%-]+$"),
	version = Schema.stringPattern("^%d+%.%d+%.%d+$"),
	description = Schema.optional(Schema.string()),
	icon = Schema.optional(Schema.string()),
	homepage = Schema.optional(Schema.url()),
	repository = Schema.optional(Schema.url()),
	keywords = Schema.optional(Schema.arrayOf(Schema.string())),
	author = Schema.optional(Schema.string()),
	license = Schema.optional(Schema.string()),
	main = Schema.nonEmptyString(),
	engine = Schema.optional(Schema.map({
		minVersion = Schema.stringPattern("^%d+%.%d+%.%d+$"),
	})),
	dependencies = Schema.optional(Schema.record(Schema.string())),
	permissions = Schema.optional(Schema.arrayOf(Schema.string())),
})

local loadedPlugins = {}
local kilang = require("@Kilang")

PluginLoader.InitRenderer = function(renderer, signal, datamodel)
	PluginLoader:SetProperties({
		LoadPlugin = function(pluginDir)
			local success, result = pcall(function()
				local manifest_path = pluginDir .. "/manifest.json"
				if not fileExists(manifest_path) then
					print("Manifest does not exist")
					return
				end

				local read = fs.readFile(manifest_path)
				local json = serde.json.decode(read)

				if not json then
					print("File did not decode to json")
					return
				end

				--[[
                {
                    "name": "My Example Plugin",
                    "id": "devcell.my-example-plugin",
                    "version": "1.0.0",
                    "description": "A simple test plugin.",
                    "icon": "icon.png",
                    "homepage": "https://github.com/Qquaded/Kinemium-Engine",
                    "repository": "https://github.com/Qquaded/Kinemium-Engine",
                    "keywords": [
                        "test",
                        "other"
                    ],
                    "author": "devcell",
                    "license": "MIT",
                    "main": "main.luau",
                    "engine": {
                        "minVersion": "1.10.7"
                    },
                    "dependencies": {},
                    "permissions": []
                }
            --]]

				local _plugin_name = json.name
				local _plugin_icon = json.icon
				local _plugin_id = json.id
				local _plugin_version = json.version
				local _plugin_description = json.description
				local _plugin_homepage = json.homepage
				local _plugin_repository = json.repository
				local _plugin_keywords = json.keywords
				local _plugin_author = json.author
				local _plugin_license = json.license
				local _plugin_engine = json.engine
				local _plugin_dependencies = json.dependencies
				local _plugin_permissions = json.permissions
				local plugin_boot = json.main

				local plugin_main_file = pluginDir .. "/" .. plugin_boot

				if loadedPlugins[_plugin_id] then
					print("Plugin already loaded")
					return
				end

				if _plugin_dependencies then
					for dep in pairs(_plugin_dependencies) do
						if not loadedPlugins[dep] then
							print("Missing dependency: " .. dep)
							return
						end
					end
				end

				local ok, path, err = plugin_schema:validate(json)
				if not ok then
					print("Invalid manifest at", path, "-", err)
					return
				end

				if not fileExists(pluginDir .. "/" .. plugin_boot) then
					print("Main file does not exist")
					return
				end

				local plugin_boot_read = fs.readFile(plugin_main_file)

				local _, success, result = kilang:execute(plugin_boot_read, {
					SecurityCapabilities = Enum.SecurityCapabilities.Internals,
				})

				if not success then
					print(`Failed to load plugin {_plugin_id}: {result}`)
					return
				else
					if type(result) ~= "table" then
						print(`Plugin {_plugin_id} does not return table`)
						return
					else
						if type(result.activate) ~= "function" then
							print(`Expected function for activate, Got {type(result.activate)}`)
							return
						end

						if type(result.deactivate) ~= "function" then
							print(`Expected function for deactivate, Got {type(result.deactivate)}`)
							return
						end

						result.activate({
							Renderer = renderer,
							Signal = signal,
						})
						loadedPlugins[_plugin_id] = {
							manifest = json,
							module = result,
							path = pluginDir,
						}
					end
				end
			end)
			return success, result
		end,

		UnloadPlugin = function(pluginId)
			local plugin = loadedPlugins[pluginId]

			if not plugin then
				print(`Plugin {pluginId} does not exist`)
				return
			end

			plugin.module.deactivate({
				Renderer = renderer,
				Signal = signal,
			})

			loadedPlugins[pluginId] = nil
		end,

		GetLoadedPlugins = function()
			return loadedPlugins
		end,

		GetPluginsMarketplace = function()
			local HttpService = datamodel:GetService("HttpService")

			local endpoint = ENGINE_ENDPOINT.MARKETPLACE

			local data = HttpService:GetAsync(endpoint, {
				["User-Agent"] = "Kinemium-Engine",
			})

			local list = {}

			for _, plugin in ipairs(data.plugins or {}) do
				local manifest, icon_data

				for _, file in ipairs(plugin.files or {}) do
					-- manifest.json
					if file.path == "manifest.json" then
						local decoded = serde.base64.decode(file.content)
						local json = serde.json.decode(decoded)

						if json then
							manifest = json

							-- icon loading (from same dump)
							if json.icon then
								for _, f in ipairs(plugin.files) do
									if f.path == json.icon then
										icon_data = buffer.fromstring(serde.base64.decode(f.content))
										break
									end
								end
							end
						end
					end
				end

				if manifest then
					list[manifest.id] = {
						manifest = manifest,
						icon = icon_data,
					}
				end
			end

			return list
		end,
	})
end

return PluginLoader
