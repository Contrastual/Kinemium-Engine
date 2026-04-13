local Instance = require("@Instance")
local CFrame = require("@CFrame")
local Color3 = require("@Color3")
local RaycastParams = require("@RaycastParams")
local Vector3 = require("@Vector3")
local Enum = require("@EnumMap")
local signal = require("@Kinemium.signal")
local state = require("@State")
local JSON = zune.serde.json

local ZERO = Vector3.new(0, 0, 0)
local LOOK = Vector3.new(0, 0, -1)
local ID = CFrame.new()

local function isVec3(v)
	return type(v) == "table" and type(v.Magnitude) == "function"
end

local function isCF(v)
	return type(v) == "table" and type(v.ToTable) == "function"
end

local function flat(v)
	if not isVec3(v) then
		return ZERO, false
	end
	local f = Vector3.new(v.X, 0, v.Z)
	local m = f:Magnitude()
	if m <= 1e-4 then
		return ZERO, false
	end
	return f / m, true
end

local function copy(tbl)
	local out = {}
	for k, v in pairs(tbl or {}) do
		out[k] = v
	end
	return out
end

local function signals()
	return {
		Died = signal.new(),
		HealthChanged = signal.new(),
		MoveToFinished = signal.new(),
		Running = signal.new(),
		Jumping = signal.new(),
		FreeFalling = signal.new(),
		Seated = signal.new(),
		Landed = signal.new(),
		StateChanged = signal.new(),
		StanceChanged = signal.new(),
		RigBuilt = signal.new(),
		SprintStarted = signal.new(),
		SprintEnded = signal.new(),
		CrouchStarted = signal.new(),
		CrouchEnded = signal.new(),
		Dashed = signal.new(),
	}
end

local function props()
	local s = signals()
	return {
		AutoJumpEnabled = true,
		AutomaticScalingEnabled = true,
		AutoRotate = true,
		BreakJointsOnDeath = true,
		CameraOffset = ZERO,
		CollisionType = Enum.HumanoidCollisionType.Default,
		ControllerEnabled = true,
		DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer,
		DisplayName = "Humanoid",
		FloorMaterial = Enum.Material.Air,
		FallCap = 1000,
		Gravity = 196.2,
		GravityScale = 1.5,
		GroundProbePadding = 0.25,
		GroundSnapDistance = 0.2,
		AirControl = 0.55,
		Health = 100,
		MaxHealth = 100,
		HealthDisplayDistance = 100,
		HealthDisplayType = Enum.HumanoidHealthDisplayType.DisplayWhenDamaged,
		HipHeight = 1,
		Jump = false,
		JumpHeight = 3.2,
		JumpPower = 20,
		JumpQueueWindow = 0.15,
		MaxSlopeAngle = 45,
		MoveDirection = ZERO,
		WalkSpeed = 16,
		WalkToPoint = ZERO,
		PlatformStand = false,
		RequiresNeck = true,
		RigType = Enum.RigType.K17,
		Sit = false,
		TargetPoint = ZERO,
		TurnSpeed = 18,
		UseJumpPower = true,
		VelocityLerp = 14,
		Sprinting = false,
		SprintMultiplier = 1.65,
		Crouching = false,
		CrouchSpeedMultiplier = 0.45,
		Dashing = false,
		DashSpeed = 42,
		DashDuration = 0.16,
		DashCooldown = 0.85,
		DashLift = 0,
		LeanEnabled = true,
		LeanAngle = math.rad(10),
		LeanLerp = 10,
		FacingDirection = nil,
		Stance = "default",
		Character = nil,
		RootPart = nil,
		SeatPart = nil,
		WalkToPart = nil,
		FocusOffset = Vector3.new(0, 2.35, 0),
		SprintFocusOffset = Vector3.new(0, 0.2, -0.35),
		CrouchFocusOffset = Vector3.new(0, -0.8, 0.1),
		DashFocusOffset = Vector3.new(0, 0.1, -0.55),
		MoveVelocity = ZERO,
		Animator = nil,
		SpeedModifiers = {},
		PoseOffsets = {},
		RigBindings = {},
		RigParts = {},
		RigPartIndex = {},
		RigChains = {},
		RigDescriptor = nil,
		Died = s.Died,
		HealthChanged = s.HealthChanged,
		MoveToFinished = s.MoveToFinished,
		Running = s.Running,
		Jumping = s.Jumping,
		FreeFalling = s.FreeFalling,
		Seated = s.Seated,
		Landed = s.Landed,
		StateChanged = s.StateChanged,
		StanceChanged = s.StanceChanged,
		RigBuilt = s.RigBuilt,
		SprintStarted = s.SprintStarted,
		SprintEnded = s.SprintEnded,
		CrouchStarted = s.CrouchStarted,
		CrouchEnded = s.CrouchEnded,
		Dashed = s.Dashed,
		State = Enum.HumanoidStateType.None,
		StateMachine = state.new(Enum.HumanoidStateType.None),
	}
end

local function controller()
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Exclude
	return {
		animClock = 0,
		animStride = 0,
		bindings = {},
		currentPos = nil,
		dashCooldownUntil = 0,
		dashDirection = LOOK,
		dashEndTime = 0,
		isGrounded = false,
		jumpQueuedTime = 0,
		landBob = 0,
		lastSpeed = -1,
		lookXZ = LOOK,
		partIndex = {},
		rayParams = ray,
		restoringRig = false,
		smoothTilt = 0,
		smoothVelXZ = ZERO,
		state = Enum.HumanoidStateType.None,
		verticalVelocity = 0,
	}
end

local function characterOf(h)
	local c = h.Character
	if c and c.Parent ~= nil then
		return c
	end
	local p = h.Parent
	if p and p.ClassName == "Model" then
		h.Character = p
		return p
	end
	return nil
end

local function ownerRoot(h)
	local c = characterOf(h)
	if c and c.FindFirstChildOfClass and c:FindFirstChildOfClass("NetworkController") then
		return c
	end
	return h.RootPart
end

local function localOwner(h, game)
	if IsClient ~= true or not game or not game.GetService then
		return false
	end

	local players = game:GetService("Players")
	local lp = players and players.LocalPlayer or nil
	if not lp then
		return false
	end

	local replicator = game:GetService("ReplicatorService")
	local ownership = replicator and replicator.NetworkOwnership or nil
	local target = ownerRoot(h)
	if ownership and ownership.IsOwnedByPlayer and target ~= nil then
		return ownership.IsOwnedByPlayer(target, lp) == true
	end

	local char = characterOf(h)
	return char ~= nil and char.Name == lp.Name
end

local function shouldSimulate(h, game)
	local target = ownerRoot(h)
	local isLocalOwner = localOwner(h, game)
	local replicator = game and game.GetService and game:GetService("ReplicatorService") or nil
	local ownership = replicator and replicator.NetworkOwnership or nil
	if ownership and ownership.ShouldSimulatePhysicsForMachine and target ~= nil then
		return ownership.ShouldSimulatePhysicsForMachine(target, game) == true
	end

	if IsServer == true then
		return isLocalOwner ~= true
	end

	return isLocalOwner == true
end

local function canSim(h)
	if h.ControllerEnabled == false or h.PlatformStand == true or h.Health <= 0 then
		return false
	end

	return true
end

local function stanceOffset(h)
	if h.Dashing then
		return h.DashFocusOffset
	elseif h.Crouching then
		return h.CrouchFocusOffset
	elseif h.Sprinting then
		return h.SprintFocusOffset
	end
	return ZERO
end

local humanoidDebugAt = setmetatable({}, { __mode = "k" })

local function shouldLogHumanoidRoot(root, interval)
	if root == nil then
		return false
	end

	local isRoot = (root.GetAttribute and root:GetAttribute("__humanoidRigRoot") == true)
		or root.Name == "HumanoidRootPart"
	if not isRoot then
		return false
	end

	local now = os.clock()
	local minInterval = interval or 0.5
	if now - (humanoidDebugAt[root] or -math.huge) < minInterval then
		return false
	end

	humanoidDebugAt[root] = now
	return true
end

local function formatDebugVec3(v)
	if type(v) ~= "table" or type(v.X) ~= "number" then
		return "nil"
	end

	return `({string.format("%.2f", v.X)}, {string.format("%.2f", v.Y)}, {string.format("%.2f", v.Z)})`
end

local function speedMul(h)
	local m = 1
	for _, v in pairs(h.SpeedModifiers or {}) do
		if type(v) == "number" and v == v then
			m *= v
		end
	end
	if h.Crouching then
		m *= h.CrouchSpeedMultiplier
	elseif h.Sprinting then
		m *= h.SprintMultiplier
	end
	return math.max(m, 0)
end

local function markRigPart(part, isRoot)
	if not part or part.SetAttribute == nil then
		return
	end

	part:SetAttribute("__humanoidRigPart", true)
	part:SetAttribute("__humanoidRigRoot", isRoot == true)
	part:SetAttribute("__humanoidRigSkipOwnedState", isRoot ~= true)
end

local function partFor(name, parent, spec, isRoot, createInstance)
	local existing = spec.Part ~= nil
	local part = spec.Part or createInstance("Part")
	part.Name = spec.Name or name
	if spec.Size ~= nil or not existing then
		part.Size = spec.Size or Vector3.new(2, 2, 1)
	end
	if spec.Color ~= nil or not existing then
		part.Color = spec.Color or Color3.new(1, 1, 1)
	end
	if spec.Material ~= nil then
		part.Material = spec.Material
	end
	if spec.Transparency ~= nil or not existing then
		part.Transparency = spec.Transparency or 0
	end
	if spec.Anchored ~= nil or not existing then
		part.Anchored = if spec.Anchored ~= nil then spec.Anchored else true
	end
	if spec.CanCollide ~= nil or not existing then
		part.CanCollide = if spec.CanCollide ~= nil then spec.CanCollide else false
	end
	if spec.CastsShadow ~= nil or not existing then
		part.CastsShadow = if spec.CastsShadow ~= nil then spec.CastsShadow else true
	end
	if spec.CFrame ~= nil then
		part.CFrame = spec.CFrame
	end
	markRigPart(part, isRoot)
	part.Parent = parent
	return part
end

local function buildRig(parent, bindings, createInstance)
	local built, parts, chains, index = {}, {}, {}, {}
	for bindName, spec in pairs(bindings or {}) do
		local bind = { Name = bindName, Transform = spec.Transform or ID, Segments = {} }
		local segs = spec.Segments
		if type(segs) ~= "table" or #segs == 0 then
			segs = {
				{
					Name = "Main",
					Part = spec.Part,
					Size = spec.Size,
					Color = spec.Color,
					Material = spec.Material,
					Transparency = spec.Transparency,
					Anchored = spec.Anchored,
					CanCollide = spec.CanCollide,
					CastsShadow = spec.CastsShadow,
					CFrame = spec.CFrame,
					Transform = ID,
					CenterOffset = spec.CenterOffset or ID,
				},
			}
		end

		local chain = {}
		for i, segSpec in ipairs(segs) do
			local segName = segSpec.Name or segSpec.Key or tostring(i)
			local partName = if segName == "Main" then bindName else `{bindName}_{segName}`
			local partSpec = copy(segSpec)
			partSpec.Name = segSpec.PartName or partName
			local part = partFor(partName, parent, partSpec, false, createInstance)
			local seg = {
				Name = segName,
				Part = part,
				Transform = segSpec.Transform or ID,
				CenterOffset = segSpec.CenterOffset or ID,
			}
			table.insert(bind.Segments, seg)
			table.insert(chain, part)
			index[bindName] = index[bindName] or part
			index[`{bindName}.{segName}`] = part
		end

		built[bindName] = bind
		chains[bindName] = chain
		parts[bindName] = if #chain == 1 then chain[1] else chain
	end
	return built, parts, chains, index
end

local function encodeRigDescriptor(descriptor)
	if type(descriptor) ~= "table" then
		return nil
	end

	local serializable = {
		RootPartName = descriptor.RootPartName or "HumanoidRootPart",
		Bindings = {},
	}

	for bindingName, binding in pairs(descriptor.Bindings or {}) do
		local bindingData = {
			Transform = (binding.Transform or ID):ToTable(),
			Segments = {},
		}

		for _, seg in ipairs(binding.Segments or {}) do
			table.insert(bindingData.Segments, {
				Name = seg.Name,
				PartName = seg.PartName,
				Transform = (seg.Transform or ID):ToTable(),
				CenterOffset = (seg.CenterOffset or ID):ToTable(),
			})
		end

		serializable.Bindings[bindingName] = bindingData
	end

	local ok, encoded = pcall(JSON.encode, serializable)
	return ok and encoded or nil
end

local function decodeRigDescriptor(rawDescriptor)
	local descriptor = rawDescriptor
	if type(rawDescriptor) == "string" then
		if rawDescriptor == "" then
			return nil
		end

		local ok, decoded = pcall(JSON.decode, rawDescriptor)
		if not ok or type(decoded) ~= "table" then
			return nil
		end
		descriptor = decoded
	end

	if type(descriptor) ~= "table" or type(descriptor.Bindings) ~= "table" then
		return nil
	end

	local normalized = {
		RootPartName = descriptor.RootPartName or "HumanoidRootPart",
		Bindings = {},
	}

	for bindingName, binding in pairs(descriptor.Bindings) do
		local normalizedBinding = {
			Transform = isCF(binding.Transform) and binding.Transform
				or CFrame.FromTable(binding.Transform or ID:ToTable()),
			Segments = {},
		}

		for _, seg in ipairs(binding.Segments or {}) do
			table.insert(normalizedBinding.Segments, {
				Name = seg.Name or "Main",
				PartName = seg.PartName,
				Transform = isCF(seg.Transform) and seg.Transform or CFrame.FromTable(seg.Transform or ID:ToTable()),
				CenterOffset = isCF(seg.CenterOffset) and seg.CenterOffset
					or CFrame.FromTable(seg.CenterOffset or ID:ToTable()),
			})
		end

		normalized.Bindings[bindingName] = normalizedBinding
	end

	return normalized
end

local function exportRigDescriptor(root, bindings)
	local descriptor = {
		RootPartName = root and root.Name or "HumanoidRootPart",
		Bindings = {},
	}

	for bindingName, binding in pairs(bindings or {}) do
		local bindingDescriptor = {
			Transform = binding.Transform or ID,
			Segments = {},
		}

		for _, seg in ipairs(binding.Segments or {}) do
			table.insert(bindingDescriptor.Segments, {
				Name = seg.Name,
				PartName = seg.Part and seg.Part.Name or nil,
				Transform = seg.Transform or ID,
				CenterOffset = seg.CenterOffset or ID,
			})
		end

		descriptor.Bindings[bindingName] = bindingDescriptor
	end

	return encodeRigDescriptor(descriptor)
end

local function defaultRig(options)
	options = options or {}
	local shirt = options.ShirtColor or Color3.fromRGB(196, 40, 28)
	local pants = options.PantsColor or Color3.fromRGB(13, 105, 172)
	local headColor = options.HeadColor or Color3.fromRGB(255, 204, 153)
	local rootColor = options.RootColor or Color3.new(0, 0, 0)
	local spawn = options.SpawnCFrame or CFrame.new(0, 20, 0)

	return {
		RigType = Enum.RigType.K17,
		HipHeight = options.HipHeight or 1,
		RootPart = {
			Name = "HumanoidRootPart",
			Size = Vector3.new(2, 2, 1),
			Color = rootColor,
			Transparency = 1,
			Anchored = true,
			CanCollide = false,
			CFrame = spawn,
		},
		Bindings = {
			Torso = {
				Size = Vector3.new(2, 2, 1),
				Color = shirt,
				Transform = CFrame.new(0, 1, 0),
				CenterOffset = CFrame.new(0, 1, 0),
			},
			Head = {
				Size = Vector3.new(2, 1, 1),
				Color = headColor,
				Transform = CFrame.new(0, 3, 0),
				CenterOffset = CFrame.new(0, 0.5, 0),
			},
			LeftArm = {
				Size = Vector3.new(1, 2, 1),
				Color = shirt,
				Transform = CFrame.new(-1.5, 3, 0),
				CenterOffset = CFrame.new(0, -1, 0),
			},
			RightArm = {
				Size = Vector3.new(1, 2, 1),
				Color = shirt,
				Transform = CFrame.new(1.5, 3, 0),
				CenterOffset = CFrame.new(0, -1, 0),
			},
			LeftLeg = {
				Size = Vector3.new(1, 2, 1),
				Color = pants,
				Transform = CFrame.new(-0.5, 1, 0),
				CenterOffset = CFrame.new(0, -1, 0),
			},
			RightLeg = {
				Size = Vector3.new(1, 2, 1),
				Color = pants,
				Transform = CFrame.new(0.5, 1, 0),
				CenterOffset = CFrame.new(0, -1, 0),
			},
		},
	}
end

local function inferRigDescriptorFromCharacter(char, root)
	if not char or char.FindFirstChild == nil then
		return nil
	end

	local template = defaultRig({})
	local bindings = {}

	for bindingName, bindingSpec in pairs(template.Bindings or {}) do
		local part = char:FindFirstChild(bindingName)
		if part then
			bindings[bindingName] = {
				Transform = bindingSpec.Transform or ID,
				Segments = {
					{
						Name = "Main",
						PartName = part.Name,
						Transform = ID,
						CenterOffset = bindingSpec.CenterOffset or ID,
					},
				},
			}
		end
	end

	if next(bindings) == nil then
		return nil
	end

	return {
		RootPartName = (root and root.Name) or "HumanoidRootPart",
		Bindings = bindings,
	}
end

local function syncRoot(h)
	local root = h.RootPart
	if not root or root.Parent == nil then
		return
	end
	local c = rawget(h, "_humanoidController")
	if not c then
		return
	end
	-- Only initialize currentPos once. The authoritative physics loop accumulates
	-- it every tick via c.currentPos += vel * dt; resetting it here (e.g. when a
	-- replicated Character/RigDescriptor patch fires Changed) would teleport the
	-- character back to origin. The non-authoritative branch syncs it explicitly.
	if c.currentPos == nil then
		c.currentPos = root.CFrame.Position
	end
	local look, ok = flat(root.CFrame:GetLookVector())
	c.lookXZ = ok and look or LOOK
end

local function segPose(pose, name, i)
	if isCF(pose) then
		return pose
	end
	if type(pose) ~= "table" then
		return ID
	end
	if isCF(pose[name]) then
		return pose[name]
	end
	local shortName = name:match("_(.+)$")
	if shortName and isCF(pose[shortName]) then
		return pose[shortName]
	end
	if isCF(pose[i]) then
		return pose[i]
	end
	return ID
end

local function poseOffset(h, bindingName, segName, i)
	local offsets = h.PoseOffsets and h.PoseOffsets[bindingName] or nil
	return segPose(offsets, segName, i)
end

local function applyPose(h, rootCF, pose)
	local c = rawget(h, "_humanoidController")
	if not c then
		return
	end
	for bindingName, binding in pairs(c.bindings) do
		local bindPose = pose[bindingName]
		for i, seg in ipairs(binding.Segments) do
			if seg.Part and seg.Part.Parent ~= nil then
				local finalCF = rootCF
					* binding.Transform
					* seg.Transform
					* segPose(bindPose, seg.Name, i)
					* poseOffset(h, bindingName, seg.Name, i)
					* seg.CenterOffset

				seg.Part.CFrame = finalCF
			end
		end
	end
end

local function setState(h, c, nextState)
	if c.state == nextState then
		return
	end
	local prev = c.state
	c.state = nextState
	h.State = nextState
	h.StateMachine:ChangeState(nextState)
	h.StateChanged:Fire(prev, nextState)
	if nextState == Enum.HumanoidStateType.Jumping then
		h.Jumping:Fire(true)
	elseif nextState == Enum.HumanoidStateType.Freefall then
		h.FreeFalling:Fire(true)
	elseif nextState == Enum.HumanoidStateType.Landed then
		h.FreeFalling:Fire(false)
		h.Landed:Fire()
	end
end

local function updateStance(h)
	local nextStance = "default"
	if h.Dashing then
		nextStance = "dash"
	elseif h.Crouching then
		nextStance = "crouch"
	elseif h.Sprinting then
		nextStance = "sprint"
	end
	if h.Stance ~= nextStance then
		local prev = h.Stance
		h.Stance = nextStance
		h.StanceChanged:Fire(prev, nextStance)
	end
end

local function reportSpeed(h, c, speed)
	if math.abs(speed - c.lastSpeed) <= 0.05 then
		return
	end
	c.lastSpeed = speed
	h.Running:Fire(speed)
end

local function restoreRigFromDescriptor(h, c)
	if not c or c.restoringRig == true then
		return false
	end
	c.restoringRig = true

	local success = false
	local char = characterOf(h)
	local descriptor = decodeRigDescriptor(h.RigDescriptor)
	if descriptor == nil then
		descriptor = inferRigDescriptorFromCharacter(char, h.RootPart)
	end
	repeat
		if not char or type(descriptor) ~= "table" or type(descriptor.Bindings) ~= "table" then
			break
		end

		local root = h.RootPart
		if not root or root.Parent ~= char then
			root = descriptor.RootPartName and char:FindFirstChild(descriptor.RootPartName)
				or char:FindFirstChild("HumanoidRootPart")
			if not root then
				break
			end
			-- Only set RootPart if it changed, to avoid triggering Changed
			if h.RootPart ~= root then
				h.RootPart = root
			end
		end
		markRigPart(root, true)

		local bindings, rigParts, rigChains, partIndex = {}, {}, {}, {}
		for bindingName, bindingDescriptor in pairs(descriptor.Bindings) do
			local restoredBinding = {
				Name = bindingName,
				Transform = bindingDescriptor.Transform or ID,
				Segments = {},
			}
			local chain = {}

			for i, segDescriptor in ipairs(bindingDescriptor.Segments or {}) do
				local partName = segDescriptor.PartName
					or (segDescriptor.Name == "Main" and bindingName or `{bindingName}_{segDescriptor.Name}`)
				local part = char:FindFirstChild(partName)
				if part then
					markRigPart(part, false)
					local segment = {
						Name = segDescriptor.Name or tostring(i),
						Part = part,
						Transform = segDescriptor.Transform or ID,
						CenterOffset = segDescriptor.CenterOffset or ID,
					}
					table.insert(restoredBinding.Segments, segment)
					table.insert(chain, part)
					partIndex[bindingName] = partIndex[bindingName] or part
					partIndex[`{bindingName}.{segment.Name}`] = part
				end
			end

			if #restoredBinding.Segments > 0 then
				bindings[bindingName] = restoredBinding
				rigChains[bindingName] = chain
				rigParts[bindingName] = #chain == 1 and chain[1] or chain
			end
		end

		if next(bindings) == nil then
			break
		end

		h.RigBindings = bindings
		h.RigParts = rigParts
		h.RigChains = rigChains
		h.RigPartIndex = partIndex
		c.bindings = bindings
		c.partIndex = partIndex
		syncRoot(h)
		if root then
			applyPose(h, root.CFrame, {})
		end
		success = true
	until true
	c.restoringRig = false
	return success
end

local function humanoidDefaultPose(animator, humanoid, context)
	context = context or {}

	local clock = context.clock or animator.Clock or 0
	local speed = math.max(context.speed or 0, 0)
	local walkSpeed = math.max(context.walkSpeed or humanoid.WalkSpeed or 16, 1)
	local moveAlpha = math.clamp(speed / walkSpeed, 0, 1)
	local airborne = context.airborne == true
	local lean = context.lean or 0
	local landBob = math.max(context.landBob or 0, 0)
	local stance = context.stance or humanoid.Stance or "default"
	local verticalVelocity = context.verticalVelocity or 0

	local sprintAlpha = stance == "sprint" and 1 or 0
	local crouchAlpha = stance == "crouch" and 1 or 0
	local dashAlpha = stance == "dash" and 1 or 0

	local walkSwingLimit = 0.52
	local sprintSwingMultiplier = 1.35
	local stride = context.stride or (clock * 4)

	local armSwing = math.sin(stride) * walkSwingLimit * (1 + sprintAlpha * (sprintSwingMultiplier - 1)) * moveAlpha
	local legSwing = math.sin(stride) * walkSwingLimit * (1 + sprintAlpha * (sprintSwingMultiplier - 1)) * moveAlpha
	local sideBob = math.cos(stride) * 0.05 * moveAlpha

	-- Run lean: pitch torso forward based on speed
	local runLean = moveAlpha * (0.12 + sprintAlpha * 0.1)

	local idleAlpha = (1 - moveAlpha)
	local breathing = math.sin(clock * 1.2)
	local idleArmSway = (0.08 + breathing * 0.04) * idleAlpha
	local idleTorsoBob = breathing * 0.015 * idleAlpha
	local idleHeadTilt = math.sin(clock * 0.8) * 0.012 * idleAlpha

	local torsoPitch = idleTorsoBob
		- crouchAlpha * 0.45
		+ sprintAlpha * 0.08
		+ dashAlpha * 0.35
		- landBob * 0.22
		+ runLean
	local torsoTwist = math.sin(stride * 0.5) * 0.08 * moveAlpha + (breathing * 0.01 * idleAlpha)
	local headPitch = crouchAlpha * 0.18 - dashAlpha * 0.08 - breathing * 0.02 * idleAlpha - runLean * 0.5
	local armRoll = lean * 0.35
	local legRoll = lean * 0.18

	-- Squash & stretch scalars (applied via pose offsets on torso/legs)
	-- >0 = squash (landing), <0 = stretch (rising fast)
	local stretchAlpha = 0
	local squashAlpha = 0

	if airborne then
		local absVel = math.abs(verticalVelocity)

		-- Peak hang: near apex, limbs spread for floaty feel
		local peakAlpha = math.clamp(1 - absVel / 8, 0, 1)
		peakAlpha = peakAlpha * peakAlpha -- ease in

		-- Rising: stretch upward
		local riseAlpha = math.clamp(verticalVelocity / 20, 0, 1)
		stretchAlpha = riseAlpha * (1 - peakAlpha)

		-- Falling: tuck legs, pull arms in
		local fallAlpha = math.clamp(-verticalVelocity / 20, 0, 1)

		local flail = math.sin(clock * 18) * 0.08

		if verticalVelocity > 0.5 then
			-- Rising: arms back and up, legs kick back
			torsoPitch -= 0.1 + stretchAlpha * 0.08
			headPitch += 0.06 + stretchAlpha * 0.04
			armSwing = -0.55 - stretchAlpha * 0.2 + flail
			legSwing = 0.3 + stretchAlpha * 0.15
		elseif verticalVelocity < -0.5 then
			-- Falling: lean forward, tuck legs, arms wide
			torsoPitch += 0.18 + fallAlpha * 0.12
			headPitch -= 0.12 - fallAlpha * 0.05
			armSwing = 0.75 + fallAlpha * 0.2 + flail
			legSwing = -0.45 - fallAlpha * 0.2 -- legs tuck up behind
		else
			-- Peak hang: spread everything out
			armSwing = (0.55 + peakAlpha * 0.2) + flail
			legSwing = 0.35 + peakAlpha * 0.15
			torsoPitch -= peakAlpha * 0.05
		end

		-- At apex: arms splay outward (roll) for that classic hang look
		armRoll = armRoll + peakAlpha * 0.3
	else
		-- Grounded landing squash: stronger than just landBob on torso
		squashAlpha = landBob
		torsoPitch += squashAlpha * 0.1
		-- Legs bend more on landing
		legSwing = legSwing + squashAlpha * 0.2
	end

	if dashAlpha > 0 then
		armSwing = -0.8
		legSwing = 0.55
	end

	local microHeadYaw = math.sin(clock * 0.9) * 0.02 * idleAlpha
	local microHeadPitch = math.sin(clock * 1.1 + 2) * 0.015 * idleAlpha
	local microTorsoRoll = math.sin(clock * 0.7 + 1) * 0.01 * idleAlpha
	local microShoulderBob = math.sin(clock * 1.5 + 3) * 0.01 * idleAlpha
	local microHipBob = math.sin(clock * 1.3 + 4) * 0.01 * idleAlpha

	local lookActivity = math.clamp(math.sin(clock * 0.45) * 2.5 - 1.5, 0, 1)
	local idleLookYaw = math.sin(clock * 0.8) * math.sin(clock * 0.3) * 0.6 * lookActivity * idleAlpha
	local idleLookPitch = math.cos(clock * 0.7) * math.sin(clock * 0.2) * 0.25 * lookActivity * idleAlpha

	local handCheckActivity = math.clamp(math.sin(clock * 0.15) * 6 - 5, 0, 1) * idleAlpha
	local handSide = math.sin(clock * 0.075) > 0 and 1 or -1
	local checkPitch = -1.2 * handCheckActivity
	local checkYaw = -0.45 * handSide * handCheckActivity

	idleLookYaw = (idleLookYaw * (1 - handCheckActivity)) + (checkYaw * handCheckActivity)
	idleLookPitch = (idleLookPitch * (1 - handCheckActivity)) + (0.22 * handCheckActivity)

	local headHeightOffset = -crouchAlpha * 0.55 + sprintAlpha * 0.05
	local headDepthOffset = crouchAlpha * 0.15 - sprintAlpha * 0.1

	local pose = {
		Torso = CFrame.Angles(torsoPitch + sideBob + microHipBob, torsoTwist, lean * 0.4 + microTorsoRoll),
		Head = CFrame.new(0, headHeightOffset, headDepthOffset) * CFrame.Angles(
			headPitch + idleHeadTilt + microHeadPitch + idleLookPitch,
			-torsoTwist * 0.35 + microHeadYaw + idleLookYaw,
			-lean * 0.35
		),
		LeftArm = CFrame.Angles(
			-armSwing - crouchAlpha * 0.2 + dashAlpha * 0.35 + microShoulderBob + (handSide == -1 and checkPitch or 0),
			(handSide == -1 and 0.45 * handCheckActivity or 0),
			-armRoll - idleArmSway + (handSide == -1 and 0.2 * handCheckActivity or 0)
		),
		RightArm = CFrame.Angles(
			armSwing - crouchAlpha * 0.2 + dashAlpha * 0.35 - microShoulderBob + (handSide == 1 and checkPitch or 0),
			(handSide == 1 and -0.45 * handCheckActivity or 0),
			armRoll + idleArmSway + (handSide == 1 and -0.2 * handCheckActivity or 0)
		),
		-- Legs spread slightly at apex, tuck on fall
		LeftLeg = CFrame.Angles(
			legSwing + (crouchAlpha * 0.25) + sideBob * 0.5,
			0,
			legRoll + (airborne and armRoll * 0.3 or 0)
		),
		RightLeg = CFrame.Angles(
			-legSwing + (crouchAlpha * 0.25) - sideBob * 0.5,
			0,
			-legRoll - (airborne and armRoll * 0.3 or 0)
		),
	}

	return pose
end

local function configureAnimator(animator, autoEnableDefaults)
	if not animator or animator.ClassName ~= "Animator" then
		return nil
	end

	if animator.SetDefaultProvider and animator.DefaultProvider == nil then
		animator:SetDefaultProvider(humanoidDefaultPose)
	end

	if autoEnableDefaults == true then
		animator.UseDefaultAnimations = true
	elseif
		animator.DefaultProvider == humanoidDefaultPose
		and animator.PoseProvider == nil
		and next(animator.PoseLayers or {}) == nil
	then
		animator.UseDefaultAnimations = true
	end

	return animator
end

local function getAnimator(h, createIfMissing, createInstance)
	local animator = h.Animator
	if animator and animator.Parent ~= nil and animator.ClassName == "Animator" then
		return configureAnimator(animator, false)
	end

	local childAnimator = h:FindFirstChildOfClass("Animator")
	if childAnimator then
		h.Animator = childAnimator
		return configureAnimator(childAnimator, false)
	end

	if createIfMissing and IsClient == true and h.NetworkId ~= nil then
		return nil
	end

	if createIfMissing then
		animator = createInstance("Animator")
		animator.Parent = h
		h.Animator = animator
		return configureAnimator(animator, true)
	end

	return nil
end

return {
	class = "Humanoid",
	callback = function(h, renderer, game)
		local InputActionService = require("../../game/services/InputActionService/InputActionService")
		local RollbackEngine = require("../../game/services/RunService/RollbackEngine")

		local function getAssociatedPlayer(humanoid)
			local char = humanoid.Parent
			if char and char.ClassName == "Model" then
				local players = game:GetService("Players")
				return players:GetPlayerFromCharacter(char)
			end
			return nil
		end
		if rawget(h, "_humanoidCallbackInitialized") == true and rawget(h, "_humanoidController") ~= nil then
			return h
		end

		local c = controller()
		rawset(h, "_humanoidCallbackInitialized", true)
		rawset(h, "_humanoidController", c)

		h:SetProperties(props())

		local function getRegistry()
			return require("@Kinemium.registry")
		end

		local function createObject(className)
			local registry = getRegistry()
			if registry and registry.new then
				local ok, created = pcall(registry.new, className, renderer, game)
				if ok and created then
					return created
				end
			end
			return Instance.new(className)
		end

		local function bind(def)
			local char = def.Character or characterOf(h)
			if not char or char.ClassName ~= "Model" then
				return nil
			end

			local rootSpec = copy(def.RootPart or {})
			rootSpec.CFrame = rootSpec.CFrame or (h.RootPart and h.RootPart.CFrame) or CFrame.new(0, 20, 0)
			if rootSpec.Anchored == nil then
				rootSpec.Anchored = true
			end

			local root = partFor(rootSpec.Name or "HumanoidRootPart", char, rootSpec, true, createObject)
			local bindings, rigParts, rigChains, partIndex = buildRig(char, def.Bindings, createObject)

			char.PrimaryPart = root
			char.WorldPivot = root.CFrame
			h.Character = char
			h.RootPart = root
			h.RigType = def.RigType or h.RigType
			h.HipHeight = def.HipHeight or h.HipHeight
			h.CameraOffset = def.CameraOffset or h.CameraOffset
			h.FocusOffset = def.FocusOffset or h.FocusOffset
			h.RigBindings = bindings
			h.RigParts = rigParts
			h.RigChains = rigChains
			h.RigPartIndex = partIndex
			h.RigDescriptor = exportRigDescriptor(root, bindings)

			local c = rawget(h, "_humanoidController")
			c.bindings = bindings
			c.partIndex = partIndex

			getAnimator(h, true, createObject)
			syncRoot(h)
			applyPose(h, root.CFrame, {})
			h.RigBuilt:Fire(char, rigParts)
			return char
		end

		function h:BindRig(def)
			return bind(def or {})
		end

		function h:BuildRig(def)
			return bind(def or {})
		end

		function h:CreateDefaultRig(options)
			local def = defaultRig(options)
			def.Character = options and options.Character or characterOf(self)
			return bind(def)
		end

		function h:RestoreRig()
			return restoreRigFromDescriptor(self, c)
		end

		function h:GetRigPart(name)
			return (self.RigPartIndex and self.RigPartIndex[name]) or (self.RigParts and self.RigParts[name]) or nil
		end

		function h:GetRigChain(name)
			return self.RigChains and self.RigChains[name] or nil
		end

		function h:GetRigBindings()
			return self.RigBindings or {}
		end

		function h:SetAnimator(animatorOrProvider)
			if type(animatorOrProvider) == "function" then
				local animator = getAnimator(self, true, createObject)
				animator:SetPoseProvider(animatorOrProvider)
				self.Animator = animator
				return animator
			end
			if type(animatorOrProvider) == "table" and animatorOrProvider.ClassName == "Animator" then
				if animatorOrProvider.Parent ~= self then
					animatorOrProvider.Parent = self
				end
				self.Animator = configureAnimator(animatorOrProvider, false)
				return self.Animator
			end
			return nil
		end

		function h:SetPoseOffset(name, offset)
			local t = copy(self.PoseOffsets)
			t[name] = offset
			self.PoseOffsets = t
		end

		function h:ClearPoseOffset(name)
			local t = copy(self.PoseOffsets)
			t[name] = nil
			self.PoseOffsets = t
		end

		function h:SetSpeedModifier(key, mult)
			local t = copy(self.SpeedModifiers)
			t[key] = mult
			self.SpeedModifiers = t
		end

		function h:RemoveSpeedModifier(key)
			local t = copy(self.SpeedModifiers)
			t[key] = nil
			self.SpeedModifiers = t
		end

		function h:SetIKCallback(source, callback)
			if type(source) == "function" and callback == nil then
				rawset(self, "_ikCallback", source)
				rawset(self, "_ikSource", nil)
			else
				rawset(self, "_ikSource", source)
				rawset(self, "_ikCallback", callback)
			end
		end

		function h:GetEffectiveWalkSpeed()
			return self.WalkSpeed * speedMul(self)
		end

		function h:SetSprinting(on)
			on = on == true
			if self.Sprinting == on then
				return
			end
			self.Sprinting = on
			if on then
				self.SprintStarted:Fire()
			else
				self.SprintEnded:Fire()
			end
			updateStance(self)
		end

		function h:SetCrouching(on)
			on = on == true
			if self.Crouching == on then
				return
			end
			self.Crouching = on
			if on then
				self.CrouchStarted:Fire()
			else
				self.CrouchEnded:Fire()
			end
			updateStance(self)
		end

		function h:ToggleCrouch()
			self:SetCrouching(not self.Crouching)
		end

		function h:Move(dir)
			self.MoveDirection = dir or ZERO
		end

		function h:MoveRelative(localDir, ref)
			if type(ref) == "table" and ref.CFrame then
				ref = ref.CFrame
			end
			if not ref or type(ref.GetLookVector) ~= "function" or not isVec3(localDir) then
				self.MoveDirection = localDir or ZERO
				return
			end
			local f, okF = flat(ref:GetLookVector())
			local r, okR = flat(ref:GetRightVector())
			if not okF or not okR then
				self.MoveDirection = ZERO
				return
			end
			self.MoveDirection = r * localDir.X + f * -localDir.Z
		end

		function h:Face(dir)
			local f, ok = flat(dir)
			self.FacingDirection = ok and f or nil
		end

		function h:ClearFacingDirection()
			self.FacingDirection = nil
		end

		function h:Stop()
			self.MoveDirection = ZERO
		end

		function h:RequestJump()
			self.Jump = true
			c.jumpQueuedTime = os.clock()
		end

		function h:CanDash()
			return os.clock() >= c.dashCooldownUntil
		end

		function h:Dash(dir)
			local now = os.clock()
			if now < c.dashCooldownUntil then
				return false
			end
			local f, ok = flat(dir or self.MoveDirection)
			if not ok then
				f, ok = flat(self.FacingDirection or c.lookXZ)
			end
			c.dashDirection = ok and f or c.lookXZ
			c.dashEndTime = now + self.DashDuration
			c.dashCooldownUntil = now + self.DashCooldown
			self.Dashing = true
			updateStance(self)
			self.Dashed:Fire(c.dashDirection)
			return true
		end

		function h:GetState()
			return c.state
		end

		function h:GetRootCFrame()
			return self.RootPart and self.RootPart.CFrame or CFrame.new()
		end

		function h:GetLookVector()
			return c.lookXZ
		end

		function h:GetFocusPosition()
			if not self.RootPart then
				return self.FocusOffset + self.CameraOffset + stanceOffset(self)
			end
			return self.RootPart.CFrame.Position + self.FocusOffset + self.CameraOffset + stanceOffset(self)
		end

		h.Changed:Connect(function(prop, value)
			if prop == "Health" then
				h.HealthChanged:Fire(value)
				if value <= 0 then
					setState(h, c, Enum.HumanoidStateType.Dead)
					h.Died:Fire()
				end
			elseif prop == "Jump" and value == true then
				c.jumpQueuedTime = os.clock()
			elseif prop == "RootPart" and value ~= nil then
				syncRoot(h)
			elseif prop == "Character" and value ~= nil then
				syncRoot(h)
				restoreRigFromDescriptor(h, c)
			elseif prop == "RigDescriptor" and value ~= nil then
				restoreRigFromDescriptor(h, c)
			elseif prop == "Sprinting" or prop == "Crouching" or prop == "Dashing" then
				updateStance(h)
			end
		end)

		local run = game and game.GetService and game:GetService("RunService") or nil
		if run then
			local workspace = game:GetService("Workspace")

			local function stepHumanoid(dt)
				dt = math.min(dt or 0, 0.1)
				local authoritative = shouldSimulate(h, game) == true

				local char = characterOf(h)
				local root = h.RootPart
				if not char or not root or root.Parent == nil or canSim(h) ~= true then
					return
				end

				if authoritative then
					RollbackEngine:SetTracked(root, true)
					RollbackEngine:SetTracked(h, true)
				end

				if next(c.bindings) == nil then
					restoreRigFromDescriptor(h, c)
				end
				c.rayParams.FilterDescendantsInstances = { char }
				if c.currentPos == nil then
					syncRoot(h)
				end
				local now = os.clock()

				if shouldLogHumanoidRoot(root, 0.5) then
					local owner = ownerRoot(h)
					local ownerName = owner and owner.NetworkOwner and owner.NetworkOwner.Name or "Server"
					local branch = authoritative and "authoritative" or "replica"
					--[[
					print(
						`[HumanoidDebug][Simulation][{branch}] char={char.Name} root=#{root.NetworkId or "?"} owner={ownerName} pos={formatDebugVec3(
							root.CFrame.Position
						)} vel={formatDebugVec3(root.AssemblyLinearVelocity)}`
					)
						--]]
				end

				c.animClock += dt
				local moveAlpha = math.clamp(root.AssemblyLinearVelocity:Magnitude() / h.WalkSpeed, 0, 1)
				local stance = h.Stance or "default"
				local sprintAlpha = stance == "sprint" and 1 or 0
				local dashAlpha = stance == "dash" and 1 or 0
				local cadence = 8 + moveAlpha * (3 + sprintAlpha * 1.5) + dashAlpha * 5
				c.animStride = (c.animStride or 0) + dt * cadence

				if authoritative ~= true then
					local rootVelocity = isVec3(root.AssemblyLinearVelocity) and root.AssemblyLinearVelocity or ZERO
					c.currentPos = root.CFrame.Position
					local look, ok = flat(root.CFrame:GetLookVector())
					c.lookXZ = ok and look or LOOK
					h.MoveVelocity = rootVelocity
					c.verticalVelocity = rootVelocity.Y

					local horiz = Vector3.new(rootVelocity.X, 0, rootVelocity.Z)
					local speed = horiz:Magnitude()

					local standHit = workspace:Raycast(
						c.currentPos,
						Vector3.new(0, -(h.HipHeight + h.GroundProbePadding), 0),
						c.rayParams
					)
					c.isGrounded = standHit ~= nil and rootVelocity.Y <= 0.1
					h.FloorMaterial = standHit and standHit.Instance and standHit.Instance.Material or Enum.Material.Air

					reportSpeed(h, c, speed)

					local right = Vector3.new(-c.lookXZ.Z, 0, c.lookXZ.X)
					local side = right.X * horiz.X + right.Z * horiz.Z
					local targetTilt = h.LeanEnabled
							and math.clamp(-side / math.max(h:GetEffectiveWalkSpeed(), 1), -1, 1) * h.LeanAngle
						or 0
					c.smoothTilt += (targetTilt - c.smoothTilt) * math.min(1, dt * h.LeanLerp)
					c.landBob = math.max(0, c.landBob - dt * 4)

					local animState = c.isGrounded
							and (speed > 0.05 and Enum.HumanoidStateType.Running or Enum.HumanoidStateType.None)
						or (rootVelocity.Y > 0 and Enum.HumanoidStateType.Jumping or Enum.HumanoidStateType.Freefall)
					c.state = animState -- local controller copy only, not h.State

					char.WorldPivot = root.CFrame

					local animator = getAnimator(h, true, createObject)
					local animContext = {
						clock = c.animClock,
						stride = c.animStride,
						dt = dt,
						airborne = not c.isGrounded,
						lean = c.smoothTilt,
						landBob = c.landBob,
						lookVector = c.lookXZ,
						speed = speed,
						state = animState,
						stance = h.Stance, -- read from adapter-delivered value
						walkSpeed = h.WalkSpeed,
					}
					local pose = animator and animator:StepAnimation(h, animContext) or {}

					local ikCallback = rawget(h, "_ikCallback")
					local ikSource = rawget(h, "_ikSource")
					if ikCallback then
						local ikResult = ikCallback(ikSource or h, dt, pose)
						if type(ikResult) == "table" then
							for partName, cf in pairs(ikResult) do
								pose[partName] = cf
							end
						end
					end

					applyPose(h, root.CFrame, type(pose) == "table" and pose or {})
					return
				end

				local player = getAssociatedPlayer(h)
				local moveDir = h.MoveDirection
				local facingDir = h.FacingDirection

				if
					workspace.ServerAuthority
					and workspace.ServerAuthority.AuthorityMode == Enum.AuthorityMode.Server
				then
					local moveX = InputActionService:GetActionValue("MoveX", player) or 0
					local moveZ = InputActionService:GetActionValue("MoveZ", player) or 0
					moveDir = Vector3.new(moveX, 0, moveZ)
					if moveDir:Magnitude() > 1 then
						moveDir = moveDir:Unit()
					end

					local jumpAction = InputActionService:GetActionValue("Jump", player) or 0
					if jumpAction > 0 then
						c.jumpQueuedTime = os.clock()
					end

					local sprintAction = InputActionService:GetActionValue("Sprint", player) or 0
					local crouchAction = InputActionService:GetActionValue("Crouch", player) or 0
					h:SetSprinting(sprintAction > 0)
					h:SetCrouching(crouchAction > 0)
				end

				local moveDirFlat, hasMove = flat(moveDir)
				local aimDirFlat, hasAim = flat(facingDir)

				if h.AutoRotate ~= false then
					local desired = nil
					if hasAim and facingDir ~= nil then
						desired = aimDirFlat
					elseif hasMove then
						desired = moveDirFlat
					end
					if desired then
						c.lookXZ = c.lookXZ:Lerp(desired, math.min(1, dt * h.TurnSpeed))
						local look, ok = flat(c.lookXZ)
						c.lookXZ = ok and look or LOOK
					end
				end

				c.isGrounded = false

				local groundY
				local standHit = workspace:Raycast(
					c.currentPos,
					Vector3.new(0, -(h.HipHeight + h.GroundProbePadding), 0),
					c.rayParams
				)

				if standHit and (h.MoveVelocity and h.MoveVelocity.Y or 0) <= 0 then
					groundY = standHit.Position.Y
					local floorY = groundY + h.HipHeight
					if c.currentPos.Y - floorY <= h.GroundSnapDistance then
						c.isGrounded = true
						h.FloorMaterial = standHit.Instance and standHit.Instance.Material or Enum.Material.Air
					end
				else
					h.FloorMaterial = Enum.Material.Air
				end

				local jumpRequest = c.jumpQueuedTime ~= 0 and (os.clock() - c.jumpQueuedTime < h.JumpQueueWindow)
				if jumpRequest and c.isGrounded then
					c.verticalVelocity = h.JumpPower
					c.isGrounded = false
					c.jumpQueuedTime = 0
					setState(h, c, Enum.HumanoidStateType.Jumping)
				end
				h.Jump = false
				local velY = c.verticalVelocity
				if c.isGrounded then
					velY = 0
					if groundY then
						local hip = math.max(h.HipHeight - (h.Crouching and 0.55 or 0), 0.5)
						c.currentPos = Vector3.new(c.currentPos.X, groundY + hip, c.currentPos.Z)
					end
					c.verticalVelocity = 0
				else
					local nextVelY = math.max(velY - h.Gravity * h.GravityScale * dt, -h.FallCap)
					local fall = math.max(0, -nextVelY * dt)
					if fall > 0 then
						local sweepHit = workspace:Raycast(
							c.currentPos,
							Vector3.new(0, -(h.HipHeight + fall + h.GroundProbePadding), 0),
							c.rayParams
						)
						if sweepHit then
							groundY = sweepHit.Position.Y
							local floorY = groundY + h.HipHeight
							if c.currentPos.Y + nextVelY * dt <= floorY then
								c.currentPos = Vector3.new(c.currentPos.X, floorY, c.currentPos.Z)
								nextVelY = 0
								c.isGrounded = true
								h.FloorMaterial = sweepHit.Instance and sweepHit.Instance.Material or Enum.Material.Air
							end
						end
					end
					velY = nextVelY
					c.verticalVelocity = nextVelY
				end

				local walkSpeed = h:GetEffectiveWalkSpeed()
				local horiz
				if h.Dashing then
					horiz = c.dashDirection * h.DashSpeed
					if h.DashLift ~= 0 and c.isGrounded then
						velY = h.DashLift
					end
				else
					local air = c.isGrounded and 1 or math.max(h.AirControl, 0)
					c.smoothVelXZ = c.smoothVelXZ:Lerp(moveDirFlat * walkSpeed, math.min(1, dt * h.VelocityLerp * air))
					horiz = Vector3.new(c.smoothVelXZ.X, 0, c.smoothVelXZ.Z)
				end

				local horizOffset = Vector3.new(horiz.X, 0, horiz.Z) * dt
				local minHorizDist = horizOffset:Magnitude()
				local slideNormal = nil

				if minHorizDist > 0.001 then
					local hasBlockcast = type(workspace.Blockcast) == "function"
					for _, binding in pairs(c.bindings) do
						for _, seg in ipairs(binding.Segments) do
							if seg.Part and seg.Part.Parent ~= nil then
								local sweepHit
								if hasBlockcast then
									local cf = seg.Part.CFrame + Vector3.new(0, 0.05, 0)
									local size = seg.Part.Size * 0.95
									pcall(function()
										sweepHit = workspace:Blockcast(cf, size, horizOffset, c.rayParams)
									end)
								end
								if not sweepHit then
									pcall(function()
										sweepHit = workspace:Raycast(seg.Part.Position, horizOffset, c.rayParams)
									end)
								end

								if
									sweepHit
									and math.abs(sweepHit.Normal.Y) < 0.7
									and sweepHit.Distance < minHorizDist
								then
									minHorizDist = sweepHit.Distance
									slideNormal = sweepHit.Normal
								end
							end
						end
					end
				end

				if slideNormal then
					slideNormal = Vector3.new(slideNormal.X, 0, slideNormal.Z)
					if slideNormal:Magnitude() > 0.001 then
						slideNormal = slideNormal:Unit()
					else
						slideNormal = Vector3.new(0, 0, 1)
					end

					local safeTravel = math.max(0, minHorizDist - 0.05)
					local hitPoint = horizOffset:Unit() * safeTravel
					local leftover = horizOffset - hitPoint
					local slide = leftover - (slideNormal * leftover:Dot(slideNormal))
					horizOffset = hitPoint + slide

					horiz = Vector3.new(horizOffset.X / dt, 0, horizOffset.Z / dt)
					c.smoothVelXZ = horiz
				end

				local vel = Vector3.new(horiz.X, velY, horiz.Z)
				c.currentPos += vel * dt
				h.MoveVelocity = vel
				local speed = horiz:Magnitude()
				reportSpeed(h, c, speed)
				if c.isGrounded then
					if c.state == Enum.HumanoidStateType.Freefall or c.state == Enum.HumanoidStateType.Jumping then
						c.landBob = 1
						setState(h, c, Enum.HumanoidStateType.Landed)
					elseif speed > 0.05 then
						setState(h, c, Enum.HumanoidStateType.Running)
					else
						setState(h, c, Enum.HumanoidStateType.None)
					end
				elseif velY > 0 then
					setState(h, c, Enum.HumanoidStateType.Jumping)
				else
					setState(h, c, Enum.HumanoidStateType.Freefall)
				end
				local right = Vector3.new(-c.lookXZ.Z, 0, c.lookXZ.X)
				local side = right.X * horiz.X + right.Z * horiz.Z
				local targetTilt = h.LeanEnabled and math.clamp(-side / math.max(walkSpeed, 1), -1, 1) * h.LeanAngle
					or 0
				c.smoothTilt += (targetTilt - c.smoothTilt) * math.min(1, dt * h.LeanLerp)
				c.landBob = math.max(0, c.landBob - dt * 4)
				local rootCF = CFrame.new(c.currentPos, c.currentPos + c.lookXZ)
				root.CFrame = rootCF
				root.Position = rootCF.Position
				root.AssemblyLinearVelocity = vel
				root.Velocity = vel
				root.AssemblyAngularVelocity = ZERO

				char.WorldPivot = rootCF
				local animator = getAnimator(h, true, createObject)
				local animContext = {
					clock = c.animClock,
					stride = c.animStride,
					dt = dt,
					airborne = not c.isGrounded,
					lean = c.smoothTilt,
					landBob = c.landBob,
					lookVector = c.lookXZ,
					speed = speed,
					state = c.state,
					stance = h.Stance,
					walkSpeed = h.WalkSpeed,
				}
				local pose = animator and animator:StepAnimation(h, animContext) or {}

				local ikCallback = rawget(h, "_ikCallback")
				local ikSource = rawget(h, "_ikSource")
				if ikCallback then
					local ikResult = ikCallback(ikSource or h, dt, pose)
					if type(ikResult) == "table" then
						for partName, cf in pairs(ikResult) do
							pose[partName] = cf
						end
					end
				end

				applyPose(h, rootCF, type(pose) == "table" and pose or {})
			end

			if workspace.UseFixedSimulation then
				run:BindToSimulation(stepHumanoid)
			else
				run.Heartbeat:Connect(stepHumanoid)
			end
		end

		return h
	end,
	inherit = function(t)
		for k, v in pairs(props()) do
			t[k] = v
		end
	end,
}
