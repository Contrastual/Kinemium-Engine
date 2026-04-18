local kilang = {}

local Kinemium_env = require("./environment/get")
local sandboxer = require("./modules/sandboxer")
local preprocessor = require("./kilang/Transpiler")
local threads = {}

kilang.renderer = nil
kilang.threads = threads

function kilang:init(cam)
	local luaEnv, CEnv = Kinemium_env(kilang.renderer, cam)
	sandboxer.environment = luaEnv
	kilang.env = sandboxer.environment
	return CEnv
end

function kilang:execute(code, opts)
	opts = opts or {}
	local superset = opts.superset or "kilang"

	local transpileOk, transpiledCode = pcall(preprocessor.runLang, code, superset)
	if not transpileOk then
		return nil, false, transpiledCode
	end

	code = transpiledCode

	local SecurityCapabilities = opts.SecurityCapabilities
	local id = opts.StackId

	if not id then
		id = "stack" .. math.random(0, 9999)
	end

	sandboxer.environment.SecurityCapabilities = SecurityCapabilities

	local thread, success, result = sandboxer.thread.fromCode(id, code, sandboxer.environment)
	if success then
		threads[id] = thread
	end

	return id, success, result
end

return kilang
