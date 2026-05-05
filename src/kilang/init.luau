-- kilang.lua
-- Runtime execution module for the Kinemium/Zune engine

local kilang = {}

local Kinemium_env = require("./environment/get")
local preprocessor = require("./kilang/Transpiler")
local luau = zune.luau

--  State

kilang.renderer = nil
kilang.env = {}
kilang.threads = {}
kilang.UseWorkers = true

local workers = {}
local pendingRequests = {}
local reqIdCounter = 0
local nextWorkerIndex = 1
local MAX_WORKERS = 18

local function initWorkers()
	if #workers > 0 then
		return
	end

	for i = 1, MAX_WORKERS do
		local w = zune.thread.fromModule("./kilang/_worker")
		w:start()
		table.insert(workers, w)

		task.spawn(function()
			while true do
				local res = w:receive()
				if res and res.id and pendingRequests[res.id] then
					print(`[kilang] Worker {i} finished task {res.id}`)
					local t = pendingRequests[res.id]
					pendingRequests[res.id] = nil
					task.spawn(t, res)
				end
			end
		end)
	end
end

local function getNextWorker()
	initWorkers()
	local w = workers[nextWorkerIndex]
	nextWorkerIndex = (nextWorkerIndex % MAX_WORKERS) + 1
	return w
end

local function asyncCompile(code, superset)
	if not kilang.UseWorkers then
		local transpiledCode = preprocessor.runLang(code, superset)
		local bytecode, compile_err = luau.compile(transpiledCode, { optimization_level = 2 })
		if not bytecode then
			return nil, compile_err
		end
		return bytecode, nil
	end

	local w = getNextWorker()
	reqIdCounter += 1
	local id = reqIdCounter
	pendingRequests[id] = coroutine.running()
	print(`[kilang] Sending compile task {id} to worker...`)
	w:send({ id = id, action = "compile", code = code, superset = superset })
	local res = coroutine.yield()
	if res.error then
		return nil, res.error
	end
	return res.result, nil
end

local function run_bytecode(bytecode, env, chunk, native_code_gen)
	local thread = luau.load(bytecode, {
		env = env,
		chunk_name = chunk,
		native_code_gen = native_code_gen,
	})

	setfenv(thread, setmetatable(env, { __index = getfenv(1) }))

	local ok, result = pcall(thread)
	return (ok and result or nil), ok, result
end

--  kilang:init

--- Initialise the runtime against a camera and renderer.
--- Returns the C-side environment handle.
---@param cam any
---@return any CEnv
function kilang:init(cam)
	local luaEnv, CEnv = Kinemium_env(self.renderer, cam)
	self.env = luaEnv
	return CEnv
end

--  kilang:execute

--- Transpile and execute a kilang script in an isolated environment.
---
---@param code      string   Source code to run
---@param opts      table?   Options: superset, SecurityCapabilities, StackId
---@param env_other table?   Additional environment bindings to inject
---@return string?  id       Stack ID for the spawned thread (nil on failure)
---@return boolean  success  Whether execution succeeded
---@return any      result   Return value or error message
---@return thread?  thread   The coroutine handle (if spawned)
function kilang:execute(code, opts, env_other)
	opts = opts or {}

	local superset = opts.superset or "kilang"
	local SecurityCapabilities = opts.SecurityCapabilities
	local id = opts.StackId or ("stack" .. math.random(0, 9999))

	-- Don't allow duplicate stacks for the same ID
	if self.threads[id] then
		return id, false, "Stack ID already running"
	end

	-- Build sandboxed environment: base env → caller overrides
	local environment = {}
	for k, v in pairs(self.env) do
		environment[k] = v
	end
	if env_other then
		for k, v in pairs(env_other) do
			environment[k] = v
		end
	end
	environment.SecurityCapabilities = SecurityCapabilities

	local bytecode, err = asyncCompile(code, superset)
	if not bytecode then
		print(`[kilang] Compile task {id} for {(environment and environment.StackId) or "unknown"} failed: {err}`)
		return nil, false, err
	end

	print(`[kilang] Compile task {id} for {(environment and environment.StackId) or "unknown"} successful, running...`)
	local s, r
	local ok, err = pcall(function()
		local _, success, result = run_bytecode(bytecode, environment, id, true)
		s = success
		r = result
	end)

	if not ok then
		s = false
		r = err
	end

	local currentThread = coroutine.running()
	if s then
		self.threads[id] = currentThread
	end

	return id, s, r, currentThread
end

--  kilang:remove

--- Remove a tracked stack thread by ID.
---@param id string
function kilang:remove(id)
	self.threads[id] = nil
end

return kilang
