local CFrame = require("@CFrame")
local Vector2 = require("@Vector2")
local Vector3 = require("@Vector3")
local NetworkOwnership = require("./NetworkOwnership")

local StateRegistry = {}

local adapters = {}
local adapterOrder = {}

local ok, HumanoidStateAdapter = require("./HumanoidStateAdapter")
if ok and HumanoidStateAdapter then
	StateRegistry.RegisterAdapter("Humanoid", HumanoidStateAdapter)
end

local function getSafeVector3(value)
	if type(value) == "table" and type(value.ToTable) == "function" then
		return value
	end

	return Vector3.zero
end

local function getSafeCFrame(value)
	if type(value) == "table" and type(value.ToTable) == "function" then
		return value
	end

	return CFrame.new()
end

local function getSafeVector2(value)
	if type(value) == "table" and type(value.ToTable) == "function" then
		return value
	end

	return Vector2.new(0, 0)
end

local function applyCFrameToObject(object, cframe)
	if object == nil or cframe == nil then
		return
	end

	object.CFrame = cframe

	if cframe.Position then
		object.Position = cframe.Position
	end

	if cframe.ToOrientation then
		local rx, ry, rz = cframe:ToOrientation()
		local orientation = Vector3.new(rx, ry, rz)
		object.Orientation = orientation
		object.Rotation = orientation
	end
end

local function cloneTable(tbl)
	if type(tbl) ~= "table" then
		return tbl
	end

	local copy = {}
	for key, value in pairs(tbl) do
		copy[key] = cloneTable(value)
	end
	return copy
end

local function vectorDistanceSquared(a, b)
	if a == nil or b == nil then
		return math.huge
	end

	local av = Vector3.FromTable(a)
	local bv = Vector3.FromTable(b)
	local delta = av - bv
	return delta:MagnitudeSquared()
end

local function vector2DistanceSquared(a, b)
	if a == nil or b == nil then
		return math.huge
	end

	local av = Vector2.FromTable(a)
	local bv = Vector2.FromTable(b)
	local delta = av - bv
	return delta.X * delta.X + delta.Y * delta.Y
end

local function getAdapterByState(state)
	if type(state) ~= "table" or state.type == nil then
		return nil
	end

	return adapters[state.type]
end

local function isBasePart(object)
	return object ~= nil
		and (object.BaseClass == "BasePart" or object.ClassName == "Part" or object.ClassName == "MeshPart")
end

function StateRegistry.RegisterAdapter(name, adapter)
	adapters[name] = adapter
	if not table.find(adapterOrder, name) then
		table.insert(adapterOrder, name)
	end
end

function StateRegistry.ResolveAdapter(object)
	for _, name in ipairs(adapterOrder) do
		local adapter = adapters[name]
		if adapter and adapter.matches(object) then
			return adapter, name
		end
	end

	return nil
end

function StateRegistry.Capture(object)
	local adapter = StateRegistry.ResolveAdapter(object)
	if not adapter then
		return nil
	end

	return adapter.capture(object)
end

function StateRegistry.Apply(object, state)
	local adapter = StateRegistry.ResolveAdapter(object)
	if not adapter then
		return false
	end

	adapter.apply(object, state)
	return true
end

function StateRegistry.CloneState(state)
	return cloneTable(state)
end

function StateRegistry.StatesEqual(a, b)
	if a == nil or b == nil then
		return false
	end

	if a.type ~= b.type then
		return false
	end

	local adapter = getAdapterByState(a)
	if adapter and adapter.equals then
		return adapter.equals(a, b)
	end

	if a.id ~= b.id or a.ownerNetId ~= b.ownerNetId then
		return false
	end

	local aCF = CFrame.FromTable(a.cframe)
	local bCF = CFrame.FromTable(b.cframe)
	if not aCF:IsSameTransform(bCF, 0.02) then
		return false
	end

	if vectorDistanceSquared(a.linear, b.linear) > 0.01 then
		return false
	end

	if vectorDistanceSquared(a.angular, b.angular) > 0.01 then
		return false
	end

	return true
end

StateRegistry.RegisterAdapter("BasePart", {
	matches = function(object)
		return isBasePart(object)
	end,

	capture = function(object)
		local cframe = getSafeCFrame(object.CFrame)
		local linear = getSafeVector3(object.AssemblyLinearVelocity)
		local angular = getSafeVector3(object.AssemblyAngularVelocity)

		local authorityRoot = NetworkOwnership.GetAuthorityRoot(object)
		local owner = authorityRoot and authorityRoot.NetworkOwner or object.NetworkOwner
		local ownerNetId = owner and owner.NetworkId or nil

		return {
			id = object.NetworkId,
			type = "BasePart",
			cframe = cframe:ToTable(),
			linear = linear:ToTable(),
			angular = angular:ToTable(),
			ownerNetId = ownerNetId,
		}
	end,

	apply = function(object, state)
		if state.cframe then
			applyCFrameToObject(object, CFrame.FromTable(state.cframe))
		end
		if state.linear then
			local linear = Vector3.FromTable(state.linear)
			object.AssemblyLinearVelocity = linear
			object.Velocity = linear
		end
		if state.angular then
			object.AssemblyAngularVelocity = Vector3.FromTable(state.angular)
		end
	end,

	equals = function(a, b)
		if a.id ~= b.id or a.ownerNetId ~= b.ownerNetId then
			return false
		end

		local aCF = CFrame.FromTable(a.cframe)
		local bCF = CFrame.FromTable(b.cframe)
		if not aCF:IsSameTransform(bCF, 0.02) then
			return false
		end

		if vectorDistanceSquared(a.linear, b.linear) > 0.01 then
			return false
		end

		if vectorDistanceSquared(a.angular, b.angular) > 0.01 then
			return false
		end

		return true
	end,
})

StateRegistry.RegisterAdapter("NetworkAuthorityRoot", {
	matches = function(object)
		return object ~= nil and not isBasePart(object) and NetworkOwnership.IsStateAuthorityObject(object)
	end,

	capture = function(object)
		return {
			id = object.NetworkId,
			type = "NetworkAuthorityRoot",
			ownerNetId = object.NetworkOwner and object.NetworkOwner.NetworkId or nil,
		}
	end,

	apply = function(_object, _state) end,

	equals = function(a, b)
		return a.id == b.id and a.ownerNetId == b.ownerNetId
	end,
})

StateRegistry.RegisterAdapter("VectorForce", {
	matches = function(object)
		return object ~= nil and object.ClassName == "VectorForce"
	end,

	capture = function(object)
		local force = getSafeVector3(object.Force)

		return {
			id = object.NetworkId,
			type = "VectorForce",
			force = force:ToTable(),
		}
	end,

	apply = function(object, state)
		if state.force then
			object.Force = Vector3.FromTable(state.force)
		end
	end,

	equals = function(a, b)
		if a.id ~= b.id then
			return false
		end

		return vectorDistanceSquared(a.force, b.force) <= 0.01
	end,
})

StateRegistry.RegisterAdapter("LinearVelocity", {
	matches = function(object)
		return object ~= nil and object.ClassName == "LinearVelocity"
	end,

	capture = function(object)
		return {
			id = object.NetworkId,
			type = "LinearVelocity",
			enabled = object.Enabled == true,
			relativeTo = object.RelativeTo,
			mode = object.VelocityConstraintMode,
			vectorVelocity = getSafeVector3(object.VectorVelocity):ToTable(),
			lineDirection = getSafeVector3(object.LineDirection):ToTable(),
			lineVelocity = object.LineVelocity or 0,
			planeVelocity = getSafeVector2(object.PlaneVelocity):ToTable(),
			primaryTangentAxis = getSafeVector3(object.PrimaryTangentAxis):ToTable(),
			secondaryTangentAxis = getSafeVector3(object.SecondaryTangentAxis):ToTable(),
			forceLimitsEnabled = object.ForceLimitsEnabled == true,
			forceLimitMode = object.ForceLimitMode,
			maxForce = object.MaxForce or 0,
			maxAxesForce = getSafeVector3(object.MaxAxesForce):ToTable(),
			maxPlanarAxesForce = getSafeVector2(object.MaxPlanarAxesForce):ToTable(),
		}
	end,

	apply = function(object, state)
		object.Enabled = state.enabled == true
		if state.relativeTo ~= nil then
			object.RelativeTo = state.relativeTo
		end
		if state.mode ~= nil then
			object.VelocityConstraintMode = state.mode
		end
		if state.vectorVelocity then
			object.VectorVelocity = Vector3.FromTable(state.vectorVelocity)
		end
		if state.lineDirection then
			object.LineDirection = Vector3.FromTable(state.lineDirection)
		end
		if state.lineVelocity ~= nil then
			object.LineVelocity = state.lineVelocity
		end
		if state.planeVelocity then
			object.PlaneVelocity = Vector2.FromTable(state.planeVelocity)
		end
		if state.primaryTangentAxis then
			object.PrimaryTangentAxis = Vector3.FromTable(state.primaryTangentAxis)
		end
		if state.secondaryTangentAxis then
			object.SecondaryTangentAxis = Vector3.FromTable(state.secondaryTangentAxis)
		end
		if state.forceLimitsEnabled ~= nil then
			object.ForceLimitsEnabled = state.forceLimitsEnabled == true
		end
		if state.forceLimitMode ~= nil then
			object.ForceLimitMode = state.forceLimitMode
		end
		if state.maxForce ~= nil then
			object.MaxForce = state.maxForce
		end
		if state.maxAxesForce then
			object.MaxAxesForce = Vector3.FromTable(state.maxAxesForce)
		end
		if state.maxPlanarAxesForce then
			object.MaxPlanarAxesForce = Vector2.FromTable(state.maxPlanarAxesForce)
		end
	end,

	equals = function(a, b)
		if a.id ~= b.id then
			return false
		end

		return a.enabled == b.enabled
			and a.relativeTo == b.relativeTo
			and a.mode == b.mode
			and math.abs((a.lineVelocity or 0) - (b.lineVelocity or 0)) <= 0.001
			and math.abs((a.maxForce or 0) - (b.maxForce or 0)) <= 0.001
			and a.forceLimitsEnabled == b.forceLimitsEnabled
			and a.forceLimitMode == b.forceLimitMode
			and vectorDistanceSquared(a.vectorVelocity, b.vectorVelocity) <= 0.0001
			and vectorDistanceSquared(a.lineDirection, b.lineDirection) <= 0.0001
			and vectorDistanceSquared(a.primaryTangentAxis, b.primaryTangentAxis) <= 0.0001
			and vectorDistanceSquared(a.secondaryTangentAxis, b.secondaryTangentAxis) <= 0.0001
			and vectorDistanceSquared(a.maxAxesForce, b.maxAxesForce) <= 0.0001
			and vector2DistanceSquared(a.planeVelocity, b.planeVelocity) <= 0.0001
			and vector2DistanceSquared(a.maxPlanarAxesForce, b.maxPlanarAxesForce) <= 0.0001
	end,
})

StateRegistry.RegisterAdapter("BodyGyro", {
	matches = function(object)
		return object ~= nil and object.ClassName == "BodyGyro"
	end,

	capture = function(object)
		local target = getSafeCFrame(object.CFrame)

		return {
			id = object.NetworkId,
			type = "BodyGyro",
			target = target:ToTable(),
		}
	end,

	apply = function(object, state)
		if state.target then
			object.CFrame = CFrame.FromTable(state.target)
		end
	end,

	equals = function(a, b)
		if a.id ~= b.id then
			return false
		end

		local aTarget = CFrame.FromTable(a.target)
		local bTarget = CFrame.FromTable(b.target)
		return aTarget:IsSameTransform(bTarget, 0.02)
	end,
})

return StateRegistry
