local Instance = require("@Instance")

local ImpulsePhysicsService = Instance.new("ImpulsePhysicsService")
ImpulsePhysicsService.ExplorerHidden = true

local Impulse3D = require("@Impulse3D")
local util = Impulse3D.utility
local Vector3Double = util.Vector3Double
local CFrame = require("@datatypes/CFrame")
local Vector3 = require("@datatypes/Vector3")
local Enum = require("@EnumMap")

local registered = {}
local registeredUniqueId = {}

local function createPhysicsBody(part, props)
	local bodyType = "dynamic"
	if part.Anchored == true then
		bodyType = "static"
	elseif props.kinematic == true then
		bodyType = "kinematic"
	end

	local bodyId = Impulse3D.body.new({
		position = Vector3Double.new(part.CFrame.Position.X, part.CFrame.Position.Y, part.CFrame.Position.Z),
		size = Vector3Double.new(part.Size.X, part.Size.Y, part.Size.Z),
		velocity = props.velocity and Vector3Double.new(props.velocity.X, props.velocity.Y, props.velocity.Z) or nil,
		orientation = props.orientation or CFrame.new(),
		bodyType = bodyType,
		linearVelocityThreshold = props.sleepThreshold or 0.01,
		angularVelocityThreshold = props.sleepThreshold or 0.01,
	})

	return bodyId, part
end

ImpulsePhysicsService.InitRenderer = function(renderer, renderer_signal, game)
	ImpulsePhysicsService:SetProperties({})

	task.spawn(function()
		repeat
			task.wait()
		until game.Workspace

		local workspace = game.Workspace

		Impulse3D.physics.render = function(id, body, dt)
			if workspace.PhysicsEngine ~= Enum.PhysicsEngine.Impulse3D then
				return
			end
			local pool = workspace.Pool.GetIdPool()
			local partRefId = registered[id]
			if not partRefId then
				return
			end
			local partRef = pool[partRefId]
			if not partRef then
				return
			end
			if partRef.BaseClass ~= "BasePart" then
				return
			end

			local bodyType = "dynamic"
			if partRef.Anchored == true then
				bodyType = "kinematic"
			end
			body.bodyType = bodyType

			if partRef.Anchored == false then
				partRef.CFrame = CFrame.new(body.position.X, body.position.Y, body.position.Z) * body.orientation
				partRef.AssemblyAngularVelocity =
					Vector3.new(body.angularVelocity.X, body.angularVelocity.Y, body.angularVelocity.Z)
				partRef.Size = Vector3.new(body.size.X, body.size.Y, body.size.Z)
				partRef.AssemblyLinearVelocity = Vector3.new(body.velocity.X, body.velocity.Y, body.velocity.Z)
			elseif partRef.Anchored == true then
				body.position =
					Vector3Double.new(partRef.CFrame.Position.X, partRef.CFrame.Position.Y, partRef.CFrame.Position.Z)
				body.orientation = partRef.CFrame.Rotation
			end
		end

		renderer_signal:Connect(function(route, dt)
			if route == "RenderStepped" then
				local pool = workspace.Pool.GetIdPool()

				Impulse3D.physics.gravity = Vector3Double.new(0, workspace.Gravity, 0)
				Impulse3D.physics.wind_direction =
					Vector3Double.new(workspace.GlobalWind.X, workspace.GlobalWind.Y, workspace.GlobalWind.Z)
				Impulse3D.Step(dt)

				for _, object in pairs(pool) do
					if not registeredUniqueId[object.UniqueId] then
						if object.BaseClass == "BasePart" and not object.Anchored and object.CanCollide then
							local bodyId, partRef = createPhysicsBody(object, {
								orientation = object.CFrame,
							})
							registered[bodyId] = partRef.UniqueId
							registeredUniqueId[partRef.UniqueId] = true
						end
					end
				end
			end
		end)
	end)
end

return ImpulsePhysicsService
