-- devcell
local Instance = require("@Instance")
local signal = require("@Kinemium.signal")
local Enum = require("@EnumMap")
local sandboxer = require("@sandboxer")
local task = zune.task
local fs = zune.fs
local process = zune.process

local qjsvm = require("@quickjs")
local python = require("@python")

local ScriptRunnerService = Instance.new("ScriptRunnerService")
ScriptRunnerService.ExplorerHidden = true

local threads = { luau = {}, python = {}, duktape = {}, quickjs = {}, luajit = {} }

ScriptRunnerService.InitEnviroment = function(enviroment, datamodel)
	local ScriptRan = signal.new()

	ScriptRunnerService:SetProperties({
		RunLuauScript = function(ScriptInstance)
			local LogService = datamodel:GetService("LogService")
			local outsideSuccess, outsideResult
			local object = task.spawn(function()
				enviroment.script = ScriptInstance

				local thread, success, result = sandboxer.run(ScriptInstance.Source, ScriptInstance.Name, enviroment)

				enviroment.script = nil
				outsideSuccess = success
				outsideResult = result
			end)
			if outsideSuccess then
				threads.luau[ScriptInstance.Name] = object
			else
				LogService.CreateLog("error", outsideResult)
			end
			print(outsideSuccess)
			print(outsideResult)
			return outsideResult
		end,

		RunPythonScript = function(ScriptInstance)
			local VM = python.PythonVM.new()

			for k, p in pairs(enviroment) do
				VM:setGlobal(k, p)
			end

			threads.python[ScriptInstance.Name] = VM

			return VM:execute(ScriptInstance.Source), VM
		end,

		RunQuickJS = function(ScriptInstance)
			local object = task.spawn(function()
				local VM = qjsvm.new()
				VM.Evaluate(ScriptInstance.Source)
			end)

			threads.duktape[ScriptInstance.Name] = object
			return object
		end,

		RunScript = function(ScriptInstance)
			local language = ScriptInstance.Language

			if language == Enum.Language.Luau then
				return ScriptRunnerService.RunLuauScript(ScriptInstance)
			elseif language == Enum.Language.Python then
				return ScriptRunnerService.RunPythonScript(ScriptInstance)
			elseif language == Enum.Language.JavaScript then
				return ScriptRunnerService.RunQuickJS(ScriptInstance)
			end
			return
		end,

		GetActive = function()
			return threads
		end,

		Clear = function()
			for _, thread in pairs(threads.luau) do
				task.cancel(thread)
			end

			for _, thread in pairs(threads.python) do
				thread:close()
			end

			for _, thread in pairs(threads.duktape) do
				thread:close()
			end
		end,

		OpenInExternalEditor = function(script, program, folderPath)
			if program == "vscode" then
				local path = folderPath .. "/" .. script.UniqueId .. ".luau"
				fs.writeFile(path, script.Source)

				script.IsOverridden = true

				local abs = fs.realPath(path)

				task.spawn(function()
					process.run("code", { abs }, { shell = true })
				end)
				task.spawn(function()
					while true do
						if fs.stat(path).kind ~= "none" then
							script.Source = fs.readFile(path)
							task.wait(0.3)
						else
							print("File not found")
							break
						end
					end
				end)
			end
		end,
	})

	return ScriptRunnerService
end

return ScriptRunnerService
