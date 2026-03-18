local Instance = require("@Instance")
local signal = require("@Kinemium.signal")
local UDim2 = require("@datatypes/UDim2")
local task = zune.task

local Box2DService = Instance.new("Box2DService")
Box2DService.ExplorerHidden = true

local box2d = require("@box2d")
local utils = require("@bufferutils")

local bodies = {}
local worlds = {}

--[[
    /// The body simulation type.
    /// Each body is one of these three types. The type determines how the body behaves in the simulation.
    /// @ingroup body
    typedef enum b2BodyType
    {
        /// zero mass, zero velocity, may be manually moved
        b2_staticBody = 0,

        /// zero mass, velocity set by user, moved by solver
        b2_kinematicBody = 1,

        /// positive mass, velocity determined by forces, moved by solver
        b2_dynamicBody = 2,

        /// number of body types
        b2_bodyTypeCount,
    } b2BodyType;
--]]

local function createBody(object, worldId)
	if not object.AbsoluteSize then
		return
	end
	local x = object.AbsoluteSize.X
	local y = object.AbsoluteSize.Y

	print(x, y)

	local motionType = object.Anchored == false and 2 or 0

	local posX = object.AbsolutePosition.X + object.AbsoluteSize.X / 2
	local posY = object.AbsolutePosition.Y + object.AbsoluteSize.Y / 2

	local position = box2d.structs.b2Vec2:new({
		x = utils:float(posX),
		y = utils:float(posY),
	})

	local bodyDef = box2d.lib.b2DefaultBodyDef()
	buffer.copy(bodyDef, box2d.structs.b2BodyDef:offset("position"), position, 0, box2d.structs.b2Vec2:size())
	buffer.writei32(bodyDef, box2d.structs.b2BodyDef:offset("type"), motionType)

	local bodyID = box2d.lib.b2CreateBody(worldId, bodyDef)
	local box = box2d.lib.b2MakeBox(x / 2, y / 2)

	local groundShapeDef = box2d.lib.b2DefaultShapeDef()
	box2d.lib.b2CreatePolygonShape(bodyID, groundShapeDef, box)

	log(
		`Created body ${object.Name} with stats \nBodyID: ${bodyID} \nMotionType: ${motionType} \nPosition: ${position}\nBox: ${box}\nGroundShapeDef: ${groundShapeDef}`
	)
	object.BodyID = bodyID
	local data = { bodyID = bodyID, box = box, bodyDef = bodyDef, motionType = motionType, object = object }
	table.insert(bodies, data)
	return data
end

Box2DService.InitRenderer = function(renderer, renderer_signal, game)
	Box2DService:SetProperties({
		lib = renderer.lib,
		const = renderer.const,
		structs = renderer.structs,
		init = function(World2D, body_update)
			local box2d = require("@box2d")

			local grav = box2d.structs.b2Vec2:new({
				x = World2D.Gravity.X or 0,
				y = World2D.Gravity.Y or -9.81,
			})
			local ptr = zune.ffi.ptrFromAddress(grav)

			local wdef = box2d.structs.b2WorldDef:new({
				gravity = ptr,
				restitutionThreshold = World2D.restitutionThreshold or 1.0,
				hitEventThreshold = World2D.hitEventThreshold or 0.0,
				contactHertz = World2D.contactHertz or 60.0,
				contactDampingRatio = World2D.contactDampingRatio or 1.0,
				maxContactPushSpeed = World2D.maxContactPushSpeed or 3.0,
				maximumLinearSpeed = World2D.maximumLinearSpeed or 40.0,
				frictionCallback = zune.ffi.null,
				restitutionCallback = zune.ffi.null,
				enableSleep = World2D.enableSleep or 1,
				motionLocks = box2d.structs.b2MotionLocks:new({
					linearX = World2D.MotionLocks.LinearX or false,
					linearY = World2D.MotionLocks.LinearY or false,
					angularZ = World2D.MotionLocks.AngularZ or false,
				}),
				enableContinuous = World2D.enableContinuous or 1,
				workerCount = World2D.workerCount or 0,
				enqueueTask = zune.ffi.null,
				finishTask = zune.ffi.null,
				userTaskContext = zune.ffi.null,
				userData = zune.ffi.null,
				internalValue = 0x5A55A5A5,
			})

			local worldId = box2d.lib.b2CreateWorld(wdef)
			print("World created:", worldId ~= zune.ffi.null)
			print("World pointer:", worldId)

			if worldId == zune.ffi.null then
				error("Failed to create Box2D world")
			end

			local world_data = { worldId = worldId, object = World2D, body_update = body_update, bodies = {} }

			local replaced = false
			if World2D._world then
				for _, b in pairs(World2D._world.bodies) do
					box2d.lib.b2DestroyBody(b.bodyID)
				end
				for i, w in pairs(worlds) do
					if w.object == World2D then
						worlds[i] = world_data
						replaced = true
						break
					end
				end
			end
			if not replaced then
				table.insert(worlds, world_data)
			end

			World2D._world = world_data

			for _, object in pairs(World2D:GetChildren()) do
				repeat
					task.wait()
				until object.AbsolutePosition
				local newBody = createBody(object, worldId)
				table.insert(world_data.bodies, newBody)
			end

			return worldId
		end,
	})

	renderer_signal:Connect(function(route, dt)
		if route == "RenderStepped" then
			for _, world in pairs(worlds) do
				box2d.lib.b2World_Step(world.worldId, world.object.FixedDeltaTime or dt, 4)
				world.object.ElapsedTime += world.object.FixedDeltaTime or dt

				for _, body in pairs(world.bodies) do
					local pos = box2d.lib.b2Body_GetPosition(body.bodyID)
					local x = buffer.readf32(pos, 0)
					local y = buffer.readf32(pos, 4)
					local halfW = body.object.AbsoluteSize.X / 2
					local halfH = body.object.AbsoluteSize.Y / 2

					local newPosition =
						UDim2.new(body.object.Position.X.Scale, x - halfW, body.object.Position.Y.Scale, y - halfH)

					world.body_update(body.object, newPosition)
				end
			end
		end
	end)

	table.insert(game.ShutdownCallbacks, function()
		for _, world in pairs(worlds) do
			for _, body in pairs(world.bodies) do
				box2d.lib.b2DestroyBody(body.bodyID)
			end
			box2d.lib.b2DestroyWorld(world.worldId)
		end
		bodies = {}
		worlds = {}
	end)
end

return Box2DService
