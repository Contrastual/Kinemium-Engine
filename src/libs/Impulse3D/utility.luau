local PhysicsUtils = {}
local Vector3 = require("@Vector3")

-- Double precision vector type
export type Vector3Double = {
	X: number,
	Y: number,
	Z: number,
	Magnitude: number,
	Unit: Vector3Double,
}

local Vector3Double = {}

local Vector3Double_mt = {
	__add = function(a, b)
		return Vector3Double.add(a, b)
	end,
	__sub = function(a, b)
		return Vector3Double.sub(a, b)
	end,
	__mul = function(a, b)
		if type(a) == "number" then
			return Vector3Double.mul(b, a)
		else
			return Vector3Double.mul(a, b)
		end
	end,
	__div = function(a, b)
		return Vector3Double.div(a, b)
	end,
	__unm = function(a)
		return Vector3Double.neg(a)
	end,
	__index = function(vec, key)
		if key == "Magnitude" then
			return math.sqrt(vec.X ^ 2 + vec.Y ^ 2 + vec.Z ^ 2)
		elseif key == "Unit" then
			local mag = vec.Magnitude
			if mag > 0 then
				return Vector3Double.new(vec.X / mag, vec.Y / mag, vec.Z / mag)
			else
				return Vector3Double.new(0, 0, 0)
			end
		else
			return Vector3Double[key]
		end
	end,
}

function Vector3Double.new(x: number, y: number, z: number): Vector3Double
	local vec = {
		X = x or 0,
		Y = y or 0,
		Z = z or 0,
	}
	setmetatable(vec, Vector3Double_mt)
	return vec
end

function Vector3Double.fromVector3(vec: Vector3): Vector3Double
	return Vector3Double.new(vec.X, vec.Y, vec.Z)
end

function Vector3Double.toVector3(vec: Vector3Double): Vector3
	return Vector3.new(vec.X, vec.Y, vec.Z)
end

function Vector3Double.add(a: Vector3Double, b: Vector3Double): Vector3Double
	return Vector3Double.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end

function Vector3Double.sub(a: Vector3Double, b: Vector3Double): Vector3Double
	return Vector3Double.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
end

function Vector3Double.mul(vec: Vector3Double, scalar: number): Vector3Double
	return Vector3Double.new(vec.X * scalar, vec.Y * scalar, vec.Z * scalar)
end

function Vector3Double.div(vec: Vector3Double, scalar: number): Vector3Double
	return Vector3Double.new(vec.X / scalar, vec.Y / scalar, vec.Z / scalar)
end

function Vector3Double.dot(a: Vector3Double, b: Vector3Double): number
	return a.X * b.X + a.Y * b.Y + a.Z * b.Z
end

function Vector3Double.cross(a: Vector3Double, b: Vector3Double): Vector3Double
	return Vector3Double.new(a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X)
end

function Vector3Double.neg(vec: Vector3Double): Vector3Double
	return Vector3Double.new(-vec.X, -vec.Y, -vec.Z)
end

function Vector3Double.abs(vec: Vector3Double): Vector3Double
	return Vector3Double.new(math.abs(vec.X), math.abs(vec.Y), math.abs(vec.Z))
end

setmetatable(Vector3Double, {
	__call = function(_, x, y, z)
		local vec = Vector3Double.new(x, y, z)
		return vec
	end,
})

PhysicsUtils.Vector3Double = Vector3Double

function PhysicsUtils.AABBOverlap(box1, box2)
	local b1min = box1.pos - box1.size / 2
	local b1max = box1.pos + box1.size / 2
	local b2min = box2.pos - box2.size / 2
	local b2max = box2.pos + box2.size / 2

	return (b1min.X <= b2max.X and b1max.X >= b2min.X)
		and (b1min.Y <= b2max.Y and b1max.Y >= b2min.Y)
		and (b1min.Z <= b2max.Z and b1max.Z >= b2min.Z)
end

function PhysicsUtils.getAABBBounds(pos, size)
	local halfSize = size / 2
	return pos - halfSize, pos + halfSize
end

function PhysicsUtils.resolveCollision(body, other)
	local b1min, b1max = PhysicsUtils.getAABBBounds(body.position, body.size)
	local b2min, b2max = PhysicsUtils.getAABBBounds(other.position, other.size)

	local overlapX = math.min(b1max.X - b2min.X, b2max.X - b1min.X)
	local overlapY = math.min(b1max.Y - b2min.Y, b2max.Y - b1min.Y)
	local overlapZ = math.min(b1max.Z - b2min.Z, b2max.Z - b1min.Z)

	local minOverlap = math.min(overlapX, overlapY, overlapZ)
	local normal = Vector3Double.new(0, 0, 0)
	local penetration = 0

	if minOverlap == overlapX then
		normal = Vector3Double.new(body.position.X > other.position.X and 1 or -1, 0, 0)
		penetration = overlapX
	elseif minOverlap == overlapY then
		normal = Vector3Double.new(0, body.position.Y > other.position.Y and 1 or -1, 0)
		penetration = overlapY
	else
		normal = Vector3Double.new(0, 0, body.position.Z > other.position.Z and 1 or -1)
		penetration = overlapZ
	end

	return normal, penetration
end

function PhysicsUtils.SphereOverlap(sphere1, sphere2)
	local diff = sphere1.pos - sphere2.pos
	local distSq = diff.Magnitude ^ 2
	local radiusSum = sphere1.radius + sphere2.radius
	return distSq <= radiusSum * radiusSum
end

function PhysicsUtils.SphereAABBOverlap(sphere, box)
	local bmin = box.pos - box.size / 2
	local bmax = box.pos + box.size / 2

	-- Find closest point on AABB to sphere center
	local closest = Vector3.new(
		math.max(bmin.X, math.min(sphere.pos.X, bmax.X)),
		math.max(bmin.Y, math.min(sphere.pos.Y, bmax.Y)),
		math.max(bmin.Z, math.min(sphere.pos.Z, bmax.Z))
	)

	local diff = sphere.pos - closest
	return diff.Magnitude ^ 2 <= sphere.radius * sphere.radius
end

function PhysicsUtils.RayAABBIntersection(rayOrigin, rayDir, box)
	local bmin = box.pos - box.size / 2
	local bmax = box.pos + box.size / 2

	local tmin = (bmin - rayOrigin) / rayDir
	local tmax = (bmax - rayOrigin) / rayDir

	if tmin.X > tmax.X then
		tmin.X, tmax.X = tmax.X, tmin.X
	end
	if tmin.Y > tmax.Y then
		tmin.Y, tmax.Y = tmax.Y, tmin.Y
	end
	if tmin.Z > tmax.Z then
		tmin.Z, tmax.Z = tmax.Z, tmin.Z
	end

	local tEnter = math.max(tmin.X, tmin.Y, tmin.Z)
	local tExit = math.min(tmax.X, tmax.Y, tmax.Z)

	return tEnter <= tExit and tExit >= 0, tEnter, tExit
end

function PhysicsUtils.PointInAABB(point, box)
	local bmin = box.pos - box.size / 2
	local bmax = box.pos + box.size / 2

	return point.X >= bmin.X
		and point.X <= bmax.X
		and point.Y >= bmin.Y
		and point.Y <= bmax.Y
		and point.Z >= bmin.Z
		and point.Z <= bmax.Z
end

function PhysicsUtils.BoxInertia(mass, size)
	local w, h, d = size.X, size.Y, size.Z
	return (mass / 12) * (h * h + d * d), (mass / 12) * (w * w + d * d), (mass / 12) * (w * w + h * h)
end

function PhysicsUtils.CenterOfMass(bodies)
	local totalMass = 0
	local com = Vector3Double.new(0, 0, 0)

	for _, body in ipairs(bodies) do
		local mass = body.mass or 1
		totalMass += mass
		com = com + body.position * mass
	end

	return totalMass > 0 and com / totalMass or Vector3Double.new(0, 0, 0)
end

-- Clamp vector magnitude
function PhysicsUtils.ClampMagnitude(vec, maxMagnitude)
	local mag = vec.Magnitude
	if mag > maxMagnitude then
		return (vec / mag) * maxMagnitude
	end
	return vec
end

function PhysicsUtils.Reflect(velocity, normal)
	return velocity - normal * (2 * Vector3Double.dot(velocity, normal))
end

function PhysicsUtils.SweepAABB(box, moveVec, other)
	local expandedBox = { pos = box.pos + moveVec / 2, size = box.size + moveVec:Abs() }
	return PhysicsUtils.AABBOverlap(expandedBox, other)
end

function PhysicsUtils.ApplyTorque(body, torque, dt)
	body.angularVelocity += torque * dt
end

function PhysicsUtils.ResolveFriction(body, other, normal, dt)
	local tangent = (body.velocity - normal * Vector3Double.dot(body.velocity, normal))
	local frictionCoefficient = 0.5
	body.velocity = body.velocity - tangent * frictionCoefficient * dt
end

return PhysicsUtils
