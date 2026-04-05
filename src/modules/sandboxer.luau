local sandboxer = {}

local luau = zune.luau
local task = zune.task
local filesystem = require("./filesystem")

sandboxer.enviroment = {}
sandboxer.native_code_gen = true
sandboxer.thread = { active = {} }

function sandboxer.run(code, chunk, env)
	local options = {
		env = env or sandboxer.enviroment,
		chunk_name = chunk,
		native_code_gen = sandboxer.native_code_gen,
	}

	local success, result = pcall(function(...)
		local bytecode = luau.compile(code, {
			optimization_level = 2,
		})
		local thread = luau.load(bytecode, options)
		setfenv(thread, setmetatable(env or sandboxer.enviroment, { __index = getfenv(1) }))

		return thread()
	end)

	local thread
	if success then
		thread = result
	else
		thread = nil
	end

	return thread, success, result
end

-- Threads API
function sandboxer.thread.new(path, entry, env)
	local code = filesystem.read(path)
	local _, success, result

	local thread = task.spawn(function()
		_, success, result = sandboxer.run(code, entry.name, env)
	end)

	local info = { thread = thread, flags = { running = true } }
	sandboxer.thread.active[path] = info

	local wrapper = {}

	function wrapper.set(prop, val)
		sandboxer.thread.active[path][prop] = val
		wrapper.info = sandboxer.thread.active[path][prop]

		return wrapper
	end

	function wrapper.get()
		return sandboxer.thread.active[path]
	end

	return wrapper
end

function sandboxer.thread.fromCode(id, code, env)
	local success, result
	local thread = task.spawn(function()
		local _
		_, success, result = sandboxer.run(code, id, env)
	end)
	local info = { thread = thread, flags = { running = true } }
	sandboxer.thread.active[id] = info

	local wrapper = {}

	function wrapper.set(prop, val)
		sandboxer.thread.active[id][prop] = val
		wrapper.info = sandboxer.thread.active[id][prop]

		return wrapper
	end

	function wrapper.get()
		return sandboxer.thread.active[id]
	end

	return wrapper, success, result
end

function sandboxer.thread.kill(thread)
	thread.flags.running = false
	task.cancel(thread.thread)
end

function sandboxer.thread.clear()
	for _, thread in pairs(sandboxer.thread.active) do
		sandboxer.thread.kill(thread)
	end
end

return sandboxer
