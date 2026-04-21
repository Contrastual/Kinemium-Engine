local CFrame = require("@CFrame")
local Vector3 = require("@Vector3")

local HumanoidStateAdapter = {}

local function vecEqual(a, b, threshold)
	if a == nil and b == nil then
		return true
	end
	if a == nil or b == nil then
		return false
	end
	local av = Vector3.FromTable(a)
	local bv = Vector3.FromTable(b)
	return (av - bv):MagnitudeSquared() <= (threshold or 0.01)
end

function HumanoidStateAdapter.matches(object)
	return object and (object.class == "Humanoid" or object.ClassName == "Humanoid")
end

function HumanoidStateAdapter.capture(humanoid)
	return {
		type = "Humanoid",
		id = humanoid.NetworkId,
		stance = humanoid.Stance or "default",
		state = humanoid.State or 0,
		sprinting = humanoid.Sprinting == true,
		crouching = humanoid.Crouching == true,
		velocity = humanoid.MoveVelocity and humanoid.MoveVelocity:ToTable() or nil,
		facingDir = humanoid.FacingDirection and humanoid.FacingDirection:ToTable() or nil,
	}
end

function HumanoidStateAdapter.apply(humanoid, state)
	if state.stance ~= nil then
		humanoid.Stance = state.stance
	end
	if state.state ~= nil then
		humanoid.State = state.state
	end
	if state.sprinting ~= nil then
		humanoid.Sprinting = state.sprinting
	end
	if state.crouching ~= nil then
		humanoid.Crouching = state.crouching
	end
	if state.velocity then
		humanoid.MoveVelocity = Vector3.FromTable(state.velocity)
	end
	if state.facingDir then
		humanoid.FacingDirection = Vector3.FromTable(state.facingDir)
	end
end

function HumanoidStateAdapter.equals(a, b)
	if a.id ~= b.id then
		return false
	end
	if a.stance ~= b.stance then
		return false
	end
	if a.state ~= b.state then
		return false
	end
	if a.sprinting ~= b.sprinting then
		return false
	end
	if a.crouching ~= b.crouching then
		return false
	end
	if not vecEqual(a.velocity, b.velocity, 0.25) then
		return false
	end
	if not vecEqual(a.facingDir, b.facingDir, 0.001) then
		return false
	end
	return true
end

return HumanoidStateAdapter
