-- simple body manager
-- devcell
local body = {
	pool = {},
}

local Vector3 = require("@Vector3")
local utility = require("./utility")
local Vector3Double = utility.Vector3Double

export type Vector3 = typeof(require("@Vector3"))
export type Vector3Double = typeof(Vector3Double.new(0, 0, 0))

export type BodyType = "static" | "dynamic" | "kinematic"

export type Body = {
	size: Vector3Double,
	position: Vector3Double,
	orientation: CFrame,
	velocity: Vector3Double,
	angularVelocity: Vector3Double,
	forces: { Vector3Double },
	bodyType: BodyType,
	isSleeping: boolean,
	sleepTimer: number,
	linearVelocityThreshold: number,
	angularVelocityThreshold: number,
}

body._lastId = 0

function body.new(data: Body)
	local clone = table.clone(data)
	body._lastId += 1
	clone.id = body._lastId

	clone.bodyType = data.bodyType or "dynamic"
	clone.isSleeping = false
	clone.sleepTimer = 0
	clone.linearVelocityThreshold = data.linearVelocityThreshold or 0.01
	clone.angularVelocityThreshold = data.angularVelocityThreshold or 0.01

	body.pool[body._lastId] = clone
	return clone.id
end

function body.get(id: number)
	return body.pool[id]
end

function body.remove(id)
	body.pool[id] = nil
end

function body.edit(id, changes)
	for k, v in pairs(changes) do
		body.pool[id][k] = v
	end
	return body.pool[id]
end

function body.each(func)
	for id, obj in pairs(body.pool) do
		func(id, obj)
	end
end

function body.wakeUp(id: number)
	local b = body.pool[id]
	if b and b.isSleeping then
		b.isSleeping = false
		b.sleepTimer = 0
		b.velocity = Vector3Double.new(0, 0, 0)
		b.angularVelocity = Vector3Double.new(0, 0, 0)
	end
end

function body.putToSleep(id: number)
	local b = body.pool[id]
	if b and not b.isSleeping then
		b.isSleeping = true
		b.sleepTimer = 0
		b.velocity = Vector3Double.new(0, 0, 0)
		b.angularVelocity = Vector3Double.new(0, 0, 0)
	end
end

function body.updateSleepState(id: number, dt: number)
	local b = body.pool[id]
	if not b then
		return
	end

	local shouldSleep = b.velocity.Magnitude < b.linearVelocityThreshold
		and b.angularVelocity.Magnitude < b.angularVelocityThreshold

	if shouldSleep then
		b.sleepTimer += dt
		if b.sleepTimer > 2.0 then -- sleep after 2 seconds of inactivity
			body.putToSleep(id)
		end
	else
		if b.isSleeping then
			body.wakeUp(id)
		end
		b.sleepTimer = 0
	end
end

function body.isAwake(id: number): boolean
	local b = body.pool[id]
	return b and not b.isSleeping
end

return body
