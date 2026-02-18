-- soft body manager
-- devcell
local softbody = {
	pool = {},
}

local utility = require("./utility")
local Vector3Double = utility.Vector3Double

export type Vector3 = typeof(require("@Vector3"))
export type Vector3Double = typeof(Vector3Double.new(0, 0, 0))

export type Particle = {
	position: Vector3Double,
	velocity: Vector3Double,
	mass: number,
	forces: { Vector3Double },
}

export type Spring = {
	p1: number, -- particle index
	p2: number,
	restLength: number,
	stiffness: number,
	damping: number,
}

export type SoftBody = {
	particles: { Particle },
	springs: { Spring },
}

softbody._lastId = 0

function softbody.new(data: SoftBody)
	local clone = table.clone(data)
	softbody._lastId += 1
	clone.id = softbody._lastId
	softbody.pool[softbody._lastId] = clone
	return clone.id
end

function softbody.get(id: number)
	return softbody.pool[id]
end

function softbody.remove(id)
	softbody.pool[id] = nil
end

function softbody.edit(id, changes)
	for k, v in pairs(changes) do
		softbody.pool[id][k] = v
	end
	return softbody.pool[id]
end

function softbody.each(func)
	for id, obj in pairs(softbody.pool) do
		func(id, obj)
	end
end

return softbody
