local Instance = require("@Instance")
local signal = require("@Kinemium.signal")

local ScriptContext = Instance.new("ScriptContext")
ScriptContext.ExplorerHidden = true

local kilang = require("@kilang")

local Enum = require("@EnumMap")

local activeThreads = {}

export type LanguageRuntime = {
	newthread: (Instance, DataModel) -> (),
	killthread: (thread) -> (),
}

ScriptContext.InitRenderer = function(renderer, signal, datamodel)
	local requiredCache = {}

	task.spawn(function()
		local function getserv(service)
			repeat
				task.wait()
			until datamodel.Loaded == true
			return datamodel:GetService(service)
		end

		local pluginLoader = getserv("PluginLoader")

		local runtimes = {
			Luau = {
				newthread = function(scriptObject: Instance, datamodel: DataModel)
					local script_environment
					script_environment = {
						script = scriptObject,
						src = scriptObject,
						require = function(target)
							if type(target) == "string" then
								local api = pluginLoader.GetPluginApi(target)
								if api then
									return api
								end
								return require(target)
							end

							if type(target) ~= "table" then
								error("require: expected ModuleScript or string, got " .. type(target), 2)
							end

							if target.ClassName ~= "ModuleScript" then
								error(
									`require: cannot require {target.ClassName} '{target.Name}'; expected ModuleScript`,
									2
								)
							end

							if requiredCache[target] then
								return requiredCache[target]
							end

							if requiredCache[target] == false then
								error(`require: circular dependency detected on '{target.Name}'`, 2)
							end

							requiredCache[target] = false

							local source = target.Source
							local success, result, id, thread
							if source and type(source) == "string" then
								id, success, result, thread = kilang:execute(source, { StackId = target.Name }, {
									script = target,
									src = target,
									loader = scriptObject,
									require = script_environment.require,
								})
							end

							if thread and result ~= nil then
								-- save thread
								if not activeThreads["Luau"] then
									activeThreads["Luau"] = {}
								end
								activeThreads["Luau"][scriptObject.UniqueId] = thread
							end

							if result == nil then
								error(`require: ModuleScript '{target.Name}' did not return a value`, 2)
							end

							requiredCache[target] = result
							return result
						end,
					}

					local source = scriptObject.Source

					if not activeThreads["Luau"] then
						activeThreads["Luau"] = {}
					end

					local id, success, result, thread = kilang:execute(
						source,
						{ StackId = `{scriptObject.Name} ({scriptObject:GetFullName()})` },
						script_environment
					)

					-- add to thread table
					activeThreads["Luau"][scriptObject.UniqueId] = thread

					return thread
				end,

				killthread = function(uniqueId)
					local thread = activeThreads["Luau"][uniqueId]
					if thread then
						task.cancel(thread)
						activeThreads["Luau"][uniqueId] = nil
					end
				end,
			},
		}

		local function runScriptOfClass(object, class)
			for _, descendant in pairs(object:GetDescendantsOfClass(class)) do
				if descendant.Enabled == false then
					return
				end
				task.spawn(function()
					ScriptContext.MakeThreadObject(descendant)
				end)
			end

			object.DescendantAdded:Connect(function(descendant)
				if descendant.ClassName == class then
					if descendant.Enabled == false then
						return
					end
					task.spawn(function()
						ScriptContext.MakeThreadObject(descendant)
					end)
				end
			end)

			object.DescendantRemoving:Connect(function(descendant)
				if descendant.ClassName == class then
					ScriptContext.KillThread(descendant.UniqueId, descendant.Language)
				end
			end)
		end

		ScriptContext:SetProperties({
			NewRuntime = function(api: LanguageRuntime)
				local name = api.name

				if not api.newthread then
					print("Runtime function newthread not found")
					return
				end

				if not api.killthread then
					print("Runtime function killthread not found")
					return
				end

				runtimes[name] = api

				Enum.newValue(name, math.random(1, 1000), Enum.Language)

				return Enum.Language[name]
			end,

			GetActiveThreads = function()
				return activeThreads
			end,

			GetRuntimeThreadsActive = function(language)
				return activeThreads[language.Name]
			end,

			KillThread = function(uniqueId: string, language: Enum.Language)
				local api = runtimes[language.Name]
				if api then
					api.killthread(uniqueId)
				end
			end,

			MakeThreadObject = function(scriptInstance: Script | LocalScript)
				local language = scriptInstance.Language.Name
				if language then
					if runtimes[language] then
						local api: LanguageRuntime? = runtimes[language]
						if api then
							return api.newthread(scriptInstance, datamodel)
						end
					else
						print("No runtime found for language " .. language)
						return
					end
				end
				return
			end,

			RunClientScripts = function()
				local StarterGui, StarterPlayer, Players, CoreGui, InternalStorage =
					getserv("StarterGui"),
					getserv("StarterPlayer"),
					getserv("Players"),
					getserv("CoreGui"),
					getserv("InternalStorage")

				runScriptOfClass(StarterGui, "LocalScript")
				runScriptOfClass(StarterPlayer, "LocalScript")
				runScriptOfClass(Players, "LocalScript")
				runScriptOfClass(CoreGui, "LocalScript")
				runScriptOfClass(InternalStorage, "LocalScript")

				return true
			end,

			RunServerScripts = function()
				local ServerScriptService, ServerStorage, Workspace, StarterGui =
					getserv("ServerScriptService"),
					getserv("ServerStorage"),
					getserv("Workspace"),
					getserv("StarterGui")

				runScriptOfClass(ServerScriptService, "Script")
				runScriptOfClass(ServerStorage, "Script")
				runScriptOfClass(Workspace, "Script")
				runScriptOfClass(StarterGui, "Script")

				return true
			end,
		})
	end)
end

return ScriptContext
