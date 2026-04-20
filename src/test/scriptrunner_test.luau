_G.log = function(...) print(...) end

local ScriptRunnerService = require("../environment/game/services/ScriptRunnerService/ScriptRunnerService")
local testing = zune.testing
local test = testing.test
local expect = testing.expect

test("ScriptRunnerService customRuntimes", function()
	local dummyEnvironment = {}
	local dummyDatamodel = {
		GetService = function(self, serviceName)
			return {
				CreateLog = function(...) print(...) end
			}
		end
	}

	-- mock platform memory
	local oldTotalMemory = zune.platform.getTotalMemory

	-- initialize the service
	ScriptRunnerService.Initenvironment(dummyEnvironment, dummyDatamodel)

	local myCustomLanguage = "MyCustomLang"
	local ran = false

	-- register a custom runtime
	ScriptRunnerService.CreateScriptingRuntime(myCustomLanguage, function(scriptInstance)
		ran = true
		return "hello world"
	end, function()
		print("Clearing custom runtime")
	end)

	local result = ScriptRunnerService.RunScript({
		Language = myCustomLanguage,
		Name = "TestScript",
		Source = "print('running!')"
	})

	expect(ran).toBe(true)
	expect(result).toBe("hello world")

    -- Call Clear
    ScriptRunnerService.Clear()
end)
