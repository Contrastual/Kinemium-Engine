-- Joint and constraint system
-- devcell
local joints = {
	pool = {},
}

local utility = require("./utility")
local Vector3Double = utility.Vector3Double

export type Vector3Double = typeof(Vector3Double.new(0, 0, 0))

export type Joint = {
	bodyA: number, -- body ID
	bodyB: number, -- body ID
	anchorA: Vector3Double, -- local anchor point on body A
	anchorB: Vector3Double, -- local anchor point on body B
	enabled: boolean,
}

-- Hinge joint (revolute joint)
export type HingeJoint = Joint & {
	type: "hinge",
	axis: Vector3Double, -- rotation axis
	limits: { min: number, max: number }?, -- optional angle limits
	motor: { speed: number, torque: number }?, -- optional motor
}

-- Spring joint (distance joint with spring)
export type SpringJoint = Joint & {
	type: "spring",
	restLength: number,
	stiffness: number,
	damping: number,
}

-- Fixed joint (weld joint)
export type FixedJoint = Joint & {
	type: "fixed",
}

-- Ball joint (spherical joint)
export type BallJoint = Joint & {
	type: "ball",
	limits: { twistMin: number, twistMax: number, swingMin: number, swingMax: number }?, -- optional angular limits
}

-- Slider joint (prismatic joint)
export type SliderJoint = Joint & {
	type: "slider",
	axis: Vector3Double, -- translation axis
	limits: { min: number, max: number }?, -- optional distance limits
	motor: { speed: number, force: number }?, -- optional linear motor
}

-- Wheel joint (for vehicles)
export type WheelJoint = Joint & {
	type: "wheel",
	axis: Vector3Double, -- suspension axis (usually up)
	suspension: { restLength: number, stiffness: number, damping: number },
	motor: { speed: number, torque: number }?, -- optional motor
	brake: { torque: number }?, -- optional brake
}

-- Piston joint (linear with rotation)
export type PistonJoint = Joint & {
	type: "piston",
	axis: Vector3Double, -- translation axis
	limits: { min: number, max: number }?, -- optional distance limits
	motor: { speed: number, force: number, torque: number }?, -- optional motor (linear + angular)
}

-- Universal joint
export type UniversalJoint = Joint & {
	type: "universal",
	axis1: Vector3Double, -- first rotation axis
	axis2: Vector3Double, -- second rotation axis
}

export type AnyJoint =
	HingeJoint
	| SpringJoint
	| FixedJoint
	| BallJoint
	| SliderJoint
	| WheelJoint
	| PistonJoint
	| UniversalJoint

joints._lastId = 0

function joints.new(data: AnyJoint): number
	local clone = table.clone(data)
	joints._lastId += 1
	clone.id = joints._lastId
	joints.pool[joints._lastId] = clone
	return clone.id
end

function joints.get(id: number): AnyJoint
	return joints.pool[id]
end

function joints.remove(id: number)
	joints.pool[id] = nil
end

function joints.edit(id: number, changes: any)
	for k, v in pairs(changes) do
		joints.pool[id][k] = v
	end
	return joints.pool[id]
end

function joints.each(func: (number, AnyJoint) -> ())
	for id, joint in pairs(joints.pool) do
		func(id, joint)
	end
end

-- Constraint solving functions
function joints.solveHinge(joint: HingeJoint, bodyA: any, bodyB: any, dt: number)
	if not joint.enabled then
		return
	end

	-- Get world positions of anchors
	local worldAnchorA = bodyA.position + joint.anchorA
	local worldAnchorB = bodyB.position + joint.anchorB

	-- Position constraint (keep anchors together)
	local delta = worldAnchorB - worldAnchorA
	local distance = delta.Magnitude

	if distance > 0.001 then -- small epsilon
		local normal = delta / distance
		local relativeVel = bodyB.velocity - bodyA.velocity
		local velAlongNormal = Vector3Double.dot(relativeVel, normal)

		-- Baumgarte stabilization
		local bias = distance * 0.1 / dt

		local impulse = normal * (velAlongNormal + bias) * 0.5
		bodyA.velocity = bodyA.velocity + impulse
		bodyB.velocity = bodyB.velocity - impulse
	end

	-- Motor torque
	if joint.motor then
		local torqueAxis = joint.axis
		local torqueImpulse = torqueAxis * joint.motor.torque * dt
		bodyB.angularVelocity = bodyB.angularVelocity + torqueImpulse
	end

	-- Angular constraint (keep axis aligned)
	-- This is a simplified version - full hinge would need more complex math
	local axisA = joint.axis
	local axisB = joint.axis -- assuming same axis for both bodies

	-- For now, just keep basic positional constraint
	-- Full hinge implementation would require quaternion math for angular constraints
end

function joints.solveSpring(joint: SpringJoint, bodyA: any, bodyB: any, dt: number)
	if not joint.enabled then
		return
	end

	-- Get world positions of anchors
	local worldAnchorA = bodyA.position + joint.anchorA
	local worldAnchorB = bodyB.position + joint.anchorB

	local delta = worldAnchorB - worldAnchorA
	local distance = delta.Magnitude
	local normal = distance > 0 and delta / distance or Vector3Double.new(0, 0, 0)

	-- Spring force
	local displacement = distance - joint.restLength
	local springForce = -joint.stiffness * displacement

	-- Damping
	local relativeVel = bodyB.velocity - bodyA.velocity
	local velAlongNormal = Vector3Double.dot(relativeVel, normal)
	local dampingForce = -joint.damping * velAlongNormal

	local totalForce = springForce + dampingForce

	if distance > 0 then
		local impulse = normal * totalForce * dt
		bodyA.velocity = bodyA.velocity + impulse
		bodyB.velocity = bodyB.velocity - impulse
	end
end

function joints.solveFixed(joint: FixedJoint, bodyA: any, bodyB: any, dt: number)
	if not joint.enabled then
		return
	end

	-- Get world positions of anchors
	local worldAnchorA = bodyA.position + joint.anchorA
	local worldAnchorB = bodyB.position + joint.anchorB

	-- Position constraint
	local delta = worldAnchorB - worldAnchorA
	local distance = delta.Magnitude

	if distance > 0.001 then
		local normal = delta / distance
		local relativeVel = bodyB.velocity - bodyA.velocity
		local velAlongNormal = Vector3Double.dot(relativeVel, normal)

		local bias = distance * 0.1 / dt
		local impulse = normal * (velAlongNormal + bias) * 0.5

		bodyA.velocity = bodyA.velocity + impulse
		bodyB.velocity = bodyB.velocity - impulse
	end

	-- Orientation constraint (simplified)
	-- Full fixed joint would also constrain orientation
end

function joints.solveBall(joint: BallJoint, bodyA: any, bodyB: any, dt: number)
	if not joint.enabled then
		return
	end

	-- Ball joints only constrain position, allowing free rotation
	local worldAnchorA = bodyA.position + joint.anchorA
	local worldAnchorB = bodyB.position + joint.anchorB

	local delta = worldAnchorB - worldAnchorA
	local distance = delta.Magnitude

	if distance > 0.001 then
		local normal = delta / distance
		local relativeVel = bodyB.velocity - bodyA.velocity
		local velAlongNormal = Vector3Double.dot(relativeVel, normal)

		local bias = distance * 0.1 / dt
		local impulse = normal * (velAlongNormal + bias) * 0.5

		bodyA.velocity = bodyA.velocity + impulse
		bodyB.velocity = bodyB.velocity - impulse
	end
end

function joints.solveSlider(joint: SliderJoint, bodyA: any, bodyB: any, dt: number)
	if not joint.enabled then
		return
	end

	local worldAnchorA = bodyA.position + joint.anchorA
	local worldAnchorB = bodyB.position + joint.anchorB

	-- Project onto slider axis
	local delta = worldAnchorB - worldAnchorA
	local projection = Vector3Double.dot(delta, joint.axis)
	local targetPos = worldAnchorA + joint.axis * projection

	-- Position constraint along axis
	local constraintDelta = worldAnchorB - targetPos
	local distance = constraintDelta.Magnitude

	if distance > 0.001 then
		local normal = constraintDelta / distance
		local relativeVel = bodyB.velocity - bodyA.velocity
		local velAlongNormal = Vector3Double.dot(relativeVel, normal)

		local bias = distance * 0.1 / dt
		local impulse = normal * (velAlongNormal + bias) * 0.5

		bodyA.velocity = bodyA.velocity + impulse
		bodyB.velocity = bodyB.velocity - impulse
	end

	-- Motor force
	if joint.motor then
		local motorImpulse = joint.axis * joint.motor.force * dt
		bodyB.velocity = bodyB.velocity + motorImpulse
		bodyA.velocity = bodyA.velocity - motorImpulse
	end
end

function joints.solveWheel(joint: WheelJoint, bodyA: any, bodyB: any, dt: number)
	if not joint.enabled then
		return
	end

	local worldAnchorA = bodyA.position + joint.anchorA
	local worldAnchorB = bodyB.position + joint.anchorB

	-- Suspension spring
	local delta = worldAnchorB - worldAnchorA
	local compression = Vector3Double.dot(delta, joint.axis)
	local displacement = joint.suspension.restLength - compression

	if displacement > 0 then
		local springForce = displacement * joint.suspension.stiffness
		local dampingForce = -Vector3Double.dot(bodyB.velocity - bodyA.velocity, joint.axis) * joint.suspension.damping
		local totalForce = springForce + dampingForce

		local impulse = joint.axis * totalForce * dt
		bodyB.velocity = bodyB.velocity + impulse
		bodyA.velocity = bodyA.velocity - impulse
	end

	-- Motor torque (for driving)
	if joint.motor then
		-- Simplified: apply torque around the axis perpendicular to suspension
		local torqueAxis = Vector3Double.new(-joint.axis.Z, 0, joint.axis.X) -- perpendicular to axis
		if torqueAxis.Magnitude > 0 then
			torqueAxis = torqueAxis.Unit
			local torqueImpulse = torqueAxis * joint.motor.torque * dt
			bodyB.angularVelocity = bodyB.angularVelocity + torqueImpulse
		end
	end

	-- Brake
	if joint.brake then
		local brakeImpulse = bodyB.angularVelocity * joint.brake.torque * dt
		bodyB.angularVelocity = bodyB.angularVelocity - brakeImpulse
	end
end

function joints.solvePiston(joint: PistonJoint, bodyA: any, bodyB: any, dt: number)
	if not joint.enabled then
		return
	end

	local worldAnchorA = bodyA.position + joint.anchorA
	local worldAnchorB = bodyB.position + joint.anchorB

	-- Linear constraint along axis
	local delta = worldAnchorB - worldAnchorA
	local projection = Vector3Double.dot(delta, joint.axis)
	local targetPos = worldAnchorA + joint.axis * projection

	local constraintDelta = worldAnchorB - targetPos
	local distance = constraintDelta.Magnitude

	if distance > 0.001 then
		local normal = constraintDelta / distance
		local relativeVel = bodyB.velocity - bodyA.velocity
		local velAlongNormal = Vector3Double.dot(relativeVel, normal)

		local bias = distance * 0.1 / dt
		local impulse = normal * (velAlongNormal + bias) * 0.5

		bodyA.velocity = bodyA.velocity + impulse
		bodyB.velocity = bodyB.velocity - impulse
	end

	-- Motor forces
	if joint.motor then
		-- Linear motor
		local linearImpulse = joint.axis * joint.motor.force * dt
		bodyB.velocity = bodyB.velocity + linearImpulse
		bodyA.velocity = bodyA.velocity - linearImpulse

		-- Angular motor
		local torqueAxis = joint.axis
		local torqueImpulse = torqueAxis * joint.motor.torque * dt
		bodyB.angularVelocity = bodyB.angularVelocity + torqueImpulse
	end
end

function joints.solveUniversal(joint: UniversalJoint, bodyA: any, bodyB: any, dt: number)
	if not joint.enabled then
		return
	end

	-- Universal joints allow rotation around two axes
	-- Simplified implementation: position constraint only
	local worldAnchorA = bodyA.position + joint.anchorA
	local worldAnchorB = bodyB.position + joint.anchorB

	local delta = worldAnchorB - worldAnchorA
	local distance = delta.Magnitude

	if distance > 0.001 then
		local normal = delta / distance
		local relativeVel = bodyB.velocity - bodyA.velocity
		local velAlongNormal = Vector3Double.dot(relativeVel, normal)

		local bias = distance * 0.1 / dt
		local impulse = normal * (velAlongNormal + bias) * 0.5

		bodyA.velocity = bodyA.velocity + impulse
		bodyB.velocity = bodyB.velocity - impulse
	end
end

function joints.solveAll(bodyManager: any, dt: number, iterations: number)
	if not iterations or iterations < 1 then
		iterations = 4
	end

	for iteration = 1, iterations do
		joints.each(function(id, joint)
			local bodyA = bodyManager.get(joint.bodyA)
			local bodyB = bodyManager.get(joint.bodyB)

			if bodyA and bodyB then
				if joint.type == "hinge" then
					joints.solveHinge(joint, bodyA, bodyB, dt)
				elseif joint.type == "spring" then
					joints.solveSpring(joint, bodyA, bodyB, dt)
				elseif joint.type == "fixed" then
					joints.solveFixed(joint, bodyA, bodyB, dt)
				elseif joint.type == "ball" then
					joints.solveBall(joint, bodyA, bodyB, dt)
				elseif joint.type == "slider" then
					joints.solveSlider(joint, bodyA, bodyB, dt)
				elseif joint.type == "wheel" then
					joints.solveWheel(joint, bodyA, bodyB, dt)
				elseif joint.type == "piston" then
					joints.solvePiston(joint, bodyA, bodyB, dt)
				elseif joint.type == "universal" then
					joints.solveUniversal(joint, bodyA, bodyB, dt)
				end
			end
		end)
	end
end

return joints
