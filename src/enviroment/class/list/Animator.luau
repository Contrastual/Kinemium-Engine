local signal = require("@Kinemium.signal")

local function copy(tbl)
	local out = {}
	for k, v in pairs(tbl or {}) do
		out[k] = v
	end
	return out
end

local function mergePose(basePose, layerPose)
	if type(layerPose) ~= "table" then
		return basePose
	end

	for bindingName, bindingPose in pairs(layerPose) do
		if type(bindingPose) == "table" and type(bindingPose.ToTable) ~= "function" then
			local target = basePose[bindingName]
			if type(target) ~= "table" or type(target.ToTable) == "function" then
				target = {}
				basePose[bindingName] = target
			end
			for segmentName, segmentPose in pairs(bindingPose) do
				target[segmentName] = segmentPose
			end
		else
			basePose[bindingName] = bindingPose
		end
	end

	return basePose
end

local propTable = {
	Name = "Animator",
	Clock = 0,
	SpeedScale = 1,
	UseDefaultAnimations = true,
	PoseLayers = {},
	PoseProvider = nil,
	DefaultProvider = nil,
	State = {},
	AnimationPlayed = signal.new(),
}

return {
	class = "Animator",
	callback = function(instance)
		instance:SetProperties(propTable)

		function instance:SetPoseProvider(provider)
			instance.PoseProvider = provider
		end

		function instance:AddPoseLayer(name, layer)
			local layers = copy(instance.PoseLayers)
			layers[name] = layer
			instance.PoseLayers = layers
		end

		function instance:RemovePoseLayer(name)
			local layers = copy(instance.PoseLayers)
			layers[name] = nil
			instance.PoseLayers = layers
		end

		function instance:SetDefaultProvider(provider)
			instance.DefaultProvider = provider
		end

		function instance:ResetClock(value)
			instance.Clock = value or 0
		end

		function instance:Advance(dt)
			dt = type(dt) == "number" and dt or 0
			local newClock = (instance.Clock or 0) + dt * (instance.SpeedScale or 1)
			instance.Clock = newClock
			return newClock
		end

		function instance:SetStateValue(key, value)
			local stateTable = copy(instance.State)
			stateTable[key] = value
			instance.State = stateTable
		end

		function instance:GetStateValue(key)
			local stateTable = instance.State or {}
			return stateTable[key]
		end

		function instance:GetPose(target, context)
			local pose = {}

			local defaultProvider = instance.DefaultProvider
			if instance.UseDefaultAnimations ~= false and type(defaultProvider) == "function" then
				pose = mergePose(pose, defaultProvider(instance, target, context))
			end

			local provider = instance.PoseProvider
			if type(provider) == "function" then
				pose = mergePose(pose, provider(instance, target, context))
			end

			for _, layer in pairs(instance.PoseLayers or {}) do
				if type(layer) == "function" then
					pose = mergePose(pose, layer(instance, target, context))
				elseif type(layer) == "table" then
					pose = mergePose(pose, layer)
				end
			end

			return pose
		end

		function instance:StepAnimation(target, context)
			local runtimeContext
			if type(context) == "table" then
				runtimeContext = copy(context)
			else
				runtimeContext = {}
			end

			if runtimeContext.advanceClock ~= false then
				instance:Advance(runtimeContext.dt or 0)
			end

			if runtimeContext.clock == nil then
				runtimeContext.clock = instance.Clock
			end
			runtimeContext.animatorState = instance.State

			local pose = instance:GetPose(target, runtimeContext)
			instance.AnimationPlayed:Fire(target, runtimeContext, pose)
			return pose
		end

		return instance
	end,
	inherit = function(tble)
		for prop, val in pairs(propTable) do
			tble[prop] = val
		end
	end,
}
