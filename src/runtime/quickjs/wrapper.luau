-- wrapper.lua
-- QuickJS FFI wrapper for Kinemium

local ffi = zune.ffi
local constants = require("./constants")
local funcs = require("./funcs")

local libname = "libqjs." .. ffi.suffix

local dll = "./src/runtime/quickjs/bin/"
local zembed = require("@zembed")
if zembed.IsEmbedded() then
	dll = "./"
end
local lib = ffi.dlopen(dll .. libname, funcs)

local JSVM = {}

function JSVM.new()
	local runtime = lib.JS_NewRuntime()
	local ctx = lib.JS_NewContext(runtime)

	lib.JS_SetModuleLoaderFunc2(runtime, nil, nil, nil, nil)
	lib.JS_SetDumpFlags(runtime, constants.JS_DUMP_BYTECODE_FINAL)

	local values = {}

	return {
		Evaluate = function(code)
			local JSValue = lib.JS_Eval(ctx, code, string.len(code), "<input>", 0) -- JS_EVAL_TYPE_GLOBAL = 0

			return JSValue
		end,

		InitJobLoop = function()
			zune.task.spawn(function()
				while lib.JS_IsJobPending(runtime) do
					lib.JS_ExecutePendingJob(runtime, ctx)
					task.wait(0)
				end
			end)
		end,

		Destroy = function()
			for _, value in pairs(values) do
				lib.JS_FreeValue(ctx, value)
			end
			values = {}
			lib.JS_FreeContext(ctx)
			lib.JS_FreeRuntime(runtime)
		end,
	}
end

return JSVM
