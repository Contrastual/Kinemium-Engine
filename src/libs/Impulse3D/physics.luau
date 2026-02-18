local physics = {}

local Vector3, CFrame, Utility = require("@Vector3"), require("@CFrame"), require("./utility")
local Vector3Double = Utility.Vector3Double
local joints = require("./joints")

export type BodyManager = typeof(require("./body"))
export type JointManager = typeof(joints)
export type Vector3Double = typeof(Vector3Double.new(0, 0, 0))

physics.gravity = Vector3Double.new(0, -9.81, 0)
physics.wind_direction = Vector3Double.new(0, 0, 0)
physics.render = nil
physics.hertz = 60
physics.substeps = 4
physics.accumulator = 0
physics.constraintIterations = 4 -- Number of constraint solver iterations
physics.jointWarmStarting = true -- Use warm starting for joints

function physics.step(body_manager: BodyManager, joint_manager: JointManager?, dt: number)
	dt = math.min(dt, 0.1)

	physics.accumulator += dt

	local subDt = 1 / (physics.hertz * physics.substeps)

	while physics.accumulator >= subDt do
		physics.substep(body_manager, joint_manager, subDt)
		physics.accumulator -= subDt
	end
end

function physics.substep(body_manager: BodyManager, joint_manager: JointManager?, dt: number)
	body_manager.each(function(id, body)
		body.velocity = body.velocity or Vector3Double.new(0, 0, 0)
		body.position = body.position or Vector3Double.new(0, 0, 0)
		body.orientation = body.orientation or CFrame.new()
		body.angularVelocity = body.angularVelocity or Vector3Double.new(0, 0, 0)

		-- Skip sleeping bodies
		if body.isSleeping then
			return
		end
	end)

	for id, body in pairs(body_manager.pool) do
		if body.bodyType == "dynamic" then
			body.velocity = body.velocity + physics.gravity * dt
			body.velocity = body.velocity + physics.wind_direction * dt

			local airDamping = 0.99
			body.velocity = body.velocity * math.pow(airDamping, dt * physics.hertz)

			body.position = body.position + body.velocity * dt
		elseif body.bodyType == "kinematic" then
			local airDamping = 0.99
			body.velocity = body.velocity * math.pow(airDamping, dt * physics.hertz)
			body.position = body.position + body.velocity * dt
		end
	end

	for id, body in pairs(body_manager.pool) do
		body.orientation = body.orientation
			* CFrame.fromEulerAnglesXYZ(
				body.angularVelocity.X * dt,
				body.angularVelocity.Y * dt,
				body.angularVelocity.Z * dt
			)
	end

	-- Simple collision detection (O(n²) - acceptable for small numbers of bodies)
	for id, body in pairs(body_manager.pool) do
		-- Skip sleeping bodies in collision detection
		if body.isSleeping then
			continue
		end

		for otherId, other in pairs(body_manager.pool) do
			if otherId ~= id and not other.isSleeping then
				-- Check if both bodies can collide
				local canCollide = true

				-- Static bodies only collide with dynamic/kinematic bodies
				if body.bodyType == "static" and other.bodyType == "static" then
					canCollide = false
				end

				if
					canCollide
					and Utility.AABBOverlap(
						{ pos = body.position, size = body.size },
						{ pos = other.position, size = other.size }
					)
				then
					local normal, penetration = Utility.resolveCollision(body, other)

					-- Calculate position correction based on body types
					local bodyCorrection = 0
					local otherCorrection = 0

					if body.bodyType == "static" then
						-- Static bodies don't move
						bodyCorrection = 0
						otherCorrection = penetration
					elseif other.bodyType == "static" then
						-- Other body is static
						bodyCorrection = penetration
						otherCorrection = 0
					else
						-- Both bodies can move
						bodyCorrection = penetration / 2
						otherCorrection = penetration / 2
					end

					-- Calculate proposed new positions
					local proposedBodyPos = body.position + normal * (bodyCorrection + 0.01)
					local proposedOtherPos = other.position - normal * (otherCorrection + 0.01)

					-- Check if any other bodies would be penetrated by these new positions
					local bodyPosValid = true
					local otherPosValid = true

					for checkId, checkBody in pairs(body_manager.pool) do
						if checkId ~= id and checkId ~= otherId and not checkBody.isSleeping then
							-- Check if proposed body position overlaps with other bodies
							if
								bodyCorrection > 0
								and Utility.AABBOverlap(
									{ pos = proposedBodyPos, size = body.size },
									{ pos = checkBody.position, size = checkBody.size }
								)
							then
								bodyPosValid = false
								break
							end

							-- Check if proposed other position overlaps with other bodies
							if
								otherCorrection > 0
								and Utility.AABBOverlap(
									{ pos = proposedOtherPos, size = other.size },
									{ pos = checkBody.position, size = checkBody.size }
								)
							then
								otherPosValid = false
								break
							end
						end
					end

					-- Apply position corrections
					if bodyPosValid and bodyCorrection > 0 then
						body.position = proposedBodyPos
					elseif bodyCorrection > 0 then
						-- Use conservative separation
						body.position = body.position + normal * (penetration + 0.05)
					end

					if otherPosValid and otherCorrection > 0 then
						other.position = proposedOtherPos
					elseif otherCorrection > 0 then
						-- Use conservative separation
						other.position = other.position - normal * (penetration + 0.05)
					end

					-- Apply velocity impulses based on body types
					local relativeVel = body.velocity - other.velocity
					local velAlongNormal = Vector3Double.dot(relativeVel, normal)

					if velAlongNormal < 0 then
						local restitution = 0.2 -- Reduced bounciness for stable stacking
						local j = -(1 + restitution) * velAlongNormal

						-- Distribute impulse based on body types
						local bodyImpulse = 0
						local otherImpulse = 0

						if body.bodyType == "static" then
							-- Static bodies don't respond to impulses
							bodyImpulse = 0
							otherImpulse = j
						elseif other.bodyType == "static" then
							-- Other body is static
							bodyImpulse = j
							otherImpulse = 0
						else
							-- Both bodies respond (equal mass assumption)
							bodyImpulse = j / 2
							otherImpulse = -j / 2
						end

						if body.bodyType ~= "static" then
							local impulse = normal * bodyImpulse
							body.velocity = body.velocity + impulse
						end

						if other.bodyType ~= "static" then
							local impulse = normal * otherImpulse
							other.velocity = other.velocity + impulse
						end
					end
				end
			end
		end
	end

	for id, body in pairs(body_manager.pool) do
		if body.position.Y - body.size.Y / 2 <= 0 then
			body.position = Vector3Double.new(body.position.X, body.size.Y / 2, body.position.Z)

			local restitution = 0.3
			body.velocity = Vector3Double.new(body.velocity.X, -body.velocity.Y * restitution, body.velocity.Z)

			local friction = 0.85
			body.velocity = Vector3Double.new(
				body.velocity.X * math.pow(friction, dt * physics.hertz),
				body.velocity.Y,
				body.velocity.Z * math.pow(friction, dt * physics.hertz)
			)
		end

		if physics.render then
			physics.render(id, body, dt)
		end
	end

	-- Solve joint constraints
	if joint_manager then
		joints.solveAll(body_manager, dt, physics.constraintIterations)
	end

	-- Update sleep states for all bodies
	body_manager.each(function(id, body)
		body_manager.updateSleepState(id, dt)
	end)
end

function physics.applyImpulse(body, impulse: Vector3Double)
	body.velocity = body.velocity + impulse
end

function physics.applyForce(body, force: Vector3Double, dt: number)
	body.velocity = body.velocity + force * dt
end

return physics
