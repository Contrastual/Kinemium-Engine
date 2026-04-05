local Client = {}

local Protocol = require("../NetworkService/Protocol")
local Shared = require("./Shared")
local PredictionBuffer = require("./PredictionBuffer")
local CFrame = require("@CFrame")
local Vector3 = require("@Vector3")
local Enum = require("@EnumMap")
local InputActionService = require("../InputActionService/InputActionService")

function Client.init(context)
	local game = context.game
	local serializationService = context.SerializationService
	local networkService = context.NetworkService
	local stateRegistry = context.StateRegistry
	local networkOwnership = context.NetworkOwnership
	local userdata = serializationService.userdata
	local runService = game:GetService("RunService")

	-- Example: When receiving a Humanoid state, use StateRegistry.Apply
	-- (Replace old per-property application with atomic state)
	-- Usage in your network receive logic:
	-- if state and state.type == "Humanoid" then
	--   local humanoid = lookup[state.id] -- or however you resolve the object
	--   if humanoid then
	--     stateRegistry.Apply(humanoid, state)
	--   end
	-- end
	local lookup = {}
	local singletonByClass = {}
	local deferredReferencePatches = {}
	local remoteTargets = {}
	local pendingSnapshots = {} -- netId -> latest snapshot state received before the object existed in lookup
	local monitors = {}
	local mutedObjects = setmetatable({}, { __mode = "k" })
	local predictionBuffer = PredictionBuffer.new(128)
	local workspace = game:GetService("Workspace")
	local ownedStateSequence = 0
	local outboundOwnedPatchEntries = {}
	local lastNoOwnedStateLogTick = -math.huge
	local lastOwnedStateSendTick = -math.huge
	local lastOwnedStatesById = {}
	local terrain = game:GetService("Workspace"):FindFirstChild("Terrain")
	local humanoidRootDebugAt = {}
	local flushPendingSnapshot

	local function isHumanoidRootObject(object)
		if object == nil then
			return false
		end

		if object.GetAttribute and object:GetAttribute("__humanoidRigRoot") == true then
			return true
		end

		return object.Name == "HumanoidRootPart"
	end

	local function shouldLogHumanoidRoot(stage, object, interval)
		if not isHumanoidRootObject(object) then
			return false
		end

		local key = `{stage}:{object.NetworkId or "?"}`
		local now = os.clock()
		local minInterval = interval or 0.5
		if now - (humanoidRootDebugAt[key] or -math.huge) < minInterval then
			return false
		end

		humanoidRootDebugAt[key] = now
		return true
	end

	local function formatVector3(value)
		if type(value) ~= "table" or type(value.X) ~= "number" then
			return "nil"
		end

		return `({string.format("%.2f", value.X)}, {string.format("%.2f", value.Y)}, {string.format("%.2f", value.Z)})`
	end

	local function decodeStatePosition(state)
		if type(state) ~= "table" or type(state.cframe) ~= "table" then
			return nil
		end

		local ok, cframe = pcall(CFrame.FromTable, state.cframe)
		if not ok or cframe == nil then
			return nil
		end

		return cframe.Position
	end

	local function logHumanoidRootState(stage, object, state, extra)
		if not shouldLogHumanoidRoot(stage, object) then
			return
		end

		local owner = object.NetworkOwner and object.NetworkOwner.Name or "Server"
		local livePos = (object.CFrame and object.CFrame.Position) or object.Position
		local statePos = decodeStatePosition(state)
		print(
			`[HumanoidDebug][Client][{stage}] object={object.Name}#{object.NetworkId or "?"} owner={owner} live={formatVector3(
				livePos
			)} state={formatVector3(statePos)} {extra or ""}`
		)
	end

	local function applyInterpolatedBasePartTransform(object, cframe)
		if not object or not cframe then
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

	local function getTerrain()
		if not terrain or terrain.Parent == nil then
			terrain = game:GetService("Workspace"):FindFirstChild("Terrain")
		end

		return terrain
	end

	local coreServices = {
		["DataModel"] = game,
		["Workspace"] = game:GetService("Workspace"),
		["Players"] = game:GetService("Players"),
		["ReplicatedStorage"] = game:GetService("ReplicatedStorage"),
		["StarterGui"] = game:GetService("StarterGui"),
		["CoreGui"] = game:GetService("CoreGui"),
	}

	for className, service in pairs(coreServices) do
		singletonByClass[className] = service
	end

	lookup[0] = game
	lookup[1] = game:GetService("Workspace")
	lookup[2] = game:GetService("Players")
	lookup[3] = game:GetService("ReplicatedStorage")
	lookup[4] = game:GetService("StarterGui")
	lookup[5] = game:GetService("CoreGui")

	local function withMutedObject(object, callback)
		mutedObjects[object] = (mutedObjects[object] or 0) + 1

		local ok, result = pcall(callback)

		mutedObjects[object] -= 1
		if mutedObjects[object] <= 0 then
			mutedObjects[object] = nil
		end

		if not ok then
			error(result)
		end

		return result
	end

	local function injectRemoteEventHook(object)
		if object.ClassName ~= "RemoteEvent" then
			return
		end

		object:SetProperties({
			FireServer = function(self, ...)
				networkService:SendToServer(Protocol.Channels.Message, Protocol.Kinds.RemoteEvent, {
					object = self.NetworkId,
					args = table.pack(...),
				}, true)
			end,
		})
	end

	local function queueOwnedPatch(object, prop, value)
		local localPlayer = game.Players.LocalPlayer
		if not localPlayer or object.NetworkId == nil then
			return
		end
		if not networkOwnership.IsOwnedByPlayer(object, localPlayer) then
			return
		end
		if not networkOwnership.ShouldReplicateProperty(object, prop) then
			return
		end

		local encoded = Shared.EncodePropertyValue(userdata, value)
		if encoded == nil then
			return
		end

		outboundOwnedPatchEntries[object.NetworkId] = outboundOwnedPatchEntries[object.NetworkId] or {}
		outboundOwnedPatchEntries[object.NetworkId][prop] = encoded
	end

	local function monitorObject(object)
		if monitors[object] then
			return
		end

		monitors[object] = object.Changed:Connect(function(prop, value)
			if mutedObjects[object] then
				return
			end

			queueOwnedPatch(object, prop, value)
		end)
	end

	local function unmonitorObject(object)
		local connection = monitors[object]
		if connection then
			connection:Disconnect()
			monitors[object] = nil
		end
	end

	local function flushDeferredReferencePatches()
		if #deferredReferencePatches == 0 then
			return
		end

		local retry = {}
		for _, entry in ipairs(deferredReferencePatches) do
			local object = lookup[entry.object]
			if not object then
				table.insert(retry, entry)
				continue
			end

			local decoded, ok = Shared.DecodePropertyValue(userdata, lookup, entry.value)
			if not ok then
				table.insert(retry, entry)
				continue
			end

			withMutedObject(object, function()
				object[entry.prop] = decoded
			end)
		end

		deferredReferencePatches = retry
	end

	local function collectTreeEntries(rootObject)
		local entries = {}
		local stack = { rootObject }

		while #stack > 0 do
			local object = table.remove(stack)
			local netId = object._props and object._props.NetworkId or object.NetworkId

			if netId ~= nil then
				if lookup[netId] and lookup[netId] ~= object then
					return nil, netId
				end

				table.insert(entries, {
					object = object,
					netId = netId,
				})
			end

			for _, child in ipairs(object:GetChildren()) do
				table.insert(stack, child)
			end
		end

		return entries
	end

	local function reserveTreeEntries(entries)
		for _, entry in ipairs(entries) do
			if entry.object._props then
				entry.object._props.NetworkId = nil
				entry.object._props._parentID = nil
			end

			entry.object.NetworkId = entry.netId
			lookup[entry.netId] = entry.object
		end
	end

	local function assignCharacterToPlayer(player, character)
		if not player or not character or player.Character == character then
			return
		end

		local previous = player.Character
		if previous and previous ~= character and player.CharacterRemoving then
			player.CharacterRemoving:Fire(previous)
		end

		player.Character = character
		if player.CharacterAdded then
			player.CharacterAdded:Fire(character)
		end
	end

	local function findCharacterModelForPlayer(workspace, player)
		if not workspace or not player then
			return nil
		end

		for _, child in ipairs(workspace:GetChildren()) do
			if child.ClassName == "Model" and child.FindFirstChildOfClass then
				local humanoid = child:FindFirstChildOfClass("Humanoid")
				if humanoid then
					local uid = child.GetAttribute and child:GetAttribute("__characterUserId")
					if type(uid) == "number" and uid == player.UserId then
						return child
					end
				end
			end
		end

		local byName = workspace:FindFirstChild(player.Name)
		if byName and byName.ClassName == "Model" and byName.FindFirstChildOfClass then
			local humanoid = byName:FindFirstChildOfClass("Humanoid")
			if humanoid then
				return byName
			end
		end

		return nil
	end

	local function syncPlayerCharacterBindingForModel(model)
		if not model or model.ClassName ~= "Model" then
			return
		end

		local playersService = game:GetService("Players")
		local uid = model.GetAttribute and model:GetAttribute("__characterUserId")
		local player = nil
		if type(uid) == "number" then
			player = playersService:GetPlayerByUserId(uid)
		end
		if not player then
			player = playersService:GetPlayerByName(model.Name)
		end
		if not player then
			return
		end

		if not model.FindFirstChildOfClass or not model:FindFirstChildOfClass("Humanoid") then
			return
		end

		assignCharacterToPlayer(player, model)
	end

	local function syncPlayerCharacterBindingForPlayer(player)
		if not player then
			return
		end

		local workspace = game:GetService("Workspace")
		local character = findCharacterModelForPlayer(workspace, player)
		if character then
			assignCharacterToPlayer(player, character)
		end
	end

	local function handleCreate(serializedBuffer)
		local deserialized = serializationService.Deserialize(serializedBuffer)
		if not deserialized then
			return
		end

		local modelNames = {}
		for _, object in ipairs(deserialized) do
			if object.ClassName == "Model" then
				table.insert(modelNames, object.Name)
			end
		end

		print(
			`[Replicator][Client] Received create batch: objects={#deserialized}, bytes={buffer.len(serializedBuffer)}, models=[{table.concat(
				modelNames,
				", "
			)}]`
		)

		local deferred = {}
		for _, object in ipairs(deserialized) do
			local netId = object._props.NetworkId
			local parentNetId = object._props._parentID

			if netId == nil or lookup[netId] then
				continue
			end

			if object.ClassName == "Player" then
				local playersService = game:GetService("Players")
				local localPlayer = playersService.LocalPlayer
				if localPlayer and localPlayer.NetworkId == nil and localPlayer.Name == object.Name then
					localPlayer.NetworkId = netId
					localPlayer.UserId = object.UserId
					localPlayer.Parent = playersService
					lookup[netId] = localPlayer
					continue
				end

				local existingPlayer = playersService:GetPlayerByUserId(object.UserId)
					or playersService:GetPlayerByName(object.Name)
				if existingPlayer then
					existingPlayer.NetworkId = existingPlayer.NetworkId or netId
					existingPlayer.UserId = object.UserId
					existingPlayer.Name = object.Name
					existingPlayer.Parent = playersService
					lookup[netId] = existingPlayer
					continue
				end
			end

			local existing = singletonByClass[object.ClassName]
			if existing and existing.NetworkId == nil then
				existing.NetworkId = netId
				lookup[netId] = existing
				continue
			end

			local treeEntries, conflictingNetId = collectTreeEntries(object)
			if not treeEntries then
				warn(
					`[Replicator][Client] Skipping duplicate create tree for {object.ClassName}:{object.Name} because NetworkId {conflictingNetId} is already mapped`
				)
				continue
			end

			reserveTreeEntries(treeEntries)

			table.insert(deferred, {
				object = object,
				netId = netId,
				parentNetId = parentNetId,
			})
		end

		local function tryParent(entry)
			local parent = lookup[entry.parentNetId]
			if not parent then
				return false
			end

			entry.object.Parent = parent
			if entry.object.ClassName == "Player" then
				local registry = game:GetService("Players").Players
				if not table.find(registry, entry.object) then
					table.insert(registry, entry.object)
				end
				syncPlayerCharacterBindingForPlayer(entry.object)
			elseif entry.object.ClassName == "Model" then
				syncPlayerCharacterBindingForModel(entry.object)
			end
			return true
		end

		local retryQueue = {}
		for _, entry in ipairs(deferred) do
			if not tryParent(entry) then
				table.insert(retryQueue, entry)
			end
		end

		local attempts = 0
		local maxAttempts = math.max(1, #retryQueue * #retryQueue)
		while #retryQueue > 0 and attempts < maxAttempts do
			attempts += 1
			local entry = table.remove(retryQueue, 1)
			if not tryParent(entry) then
				table.insert(retryQueue, entry)
			end
		end

		for _, entry in ipairs(retryQueue) do
			entry.object.Parent = game.Workspace
		end

		-- Final sync pass: Player objects and character Models may both arrive in the
		-- same Create batch in unpredictable order. After all objects are parented
		-- we retry bindings so neither side misses the other.
		for _, entry in ipairs(deferred) do
			if entry.object.ClassName == "Player" then
				syncPlayerCharacterBindingForPlayer(entry.object)
			elseif entry.object.ClassName == "Model" then
				syncPlayerCharacterBindingForModel(entry.object)
			end
			-- Apply any snapshot state that arrived before this object was in lookup
			flushPendingSnapshot(entry.object)
		end

		flushDeferredReferencePatches()
	end

	local function applyPatchEntry(entry)
		local object = lookup[entry.object]
		if not object then
			for prop, encoded in pairs(entry.updates or {}) do
				table.insert(deferredReferencePatches, {
					object = entry.object,
					prop = prop,
					value = encoded,
				})
			end
			return
		end

		for prop, encoded in pairs(entry.updates or {}) do
			local decoded, ok = Shared.DecodePropertyValue(userdata, lookup, encoded)
			if not ok then
				table.insert(deferredReferencePatches, {
					object = entry.object,
					prop = prop,
					value = encoded,
				})
			else
				withMutedObject(object, function()
					object[prop] = decoded
				end)
			end
		end
	end

	local function reconcileLocalState(object, state, ackPredictedState)
		if object.Parent == nil or object.CFrame == nil or state.cframe == nil then
			return
		end

		local target = CFrame.FromTable(state.cframe)

		if ackPredictedState and ackPredictedState.cframe then
			local ok, predicted = pcall(CFrame.FromTable, ackPredictedState.cframe)
			if ok and predicted then
				local deltaFromPrediction = (target.Position - predicted.Position):Magnitude()
				if deltaFromPrediction < 0.2 then
					return
				end
			end
		end

		local liveDelta = (target.Position - object.CFrame.Position):Magnitude()

		if liveDelta > 0.05 then
			withMutedObject(object, function()
				stateRegistry.Apply(object, state)
			end)
		end
	end

	local function applyOwnershipState(object, state)
		if state.type ~= "BasePart" and state.type ~= "NetworkAuthorityRoot" then
			return
		end

		local owner = state.ownerNetId and lookup[state.ownerNetId] or nil
		withMutedObject(object, function()
			object.NetworkOwner = owner
			object.NetworkOwnerType = owner and Enum.MachineNetworkOwner.Client or Enum.MachineNetworkOwner.Server
		end)
	end

	-- Assign the forward-declared flushPendingSnapshot now that all its runtime
	-- dependencies (reconcileLocalState, applyOwnershipState) are in scope.
	local function applyBufferedSnapshot(object, state, ackPredictedState)
		local localPlayer = game.Players.LocalPlayer
		applyOwnershipState(object, state)
		if state.type == "BasePart" then
			if localPlayer and networkOwnership.IsOwnedReplicatedPhysicsPart(object, localPlayer) then
				reconcileLocalState(object, state, ackPredictedState)
			elseif not (localPlayer and networkOwnership.IsOwnedByPlayer(object, localPlayer)) then
				remoteTargets[state.id] = state
				withMutedObject(object, function()
					if state.linear then
						local linear = Vector3.FromTable(state.linear)
						object.AssemblyLinearVelocity = linear
						object.Velocity = linear
					end
					if state.angular then
						object.AssemblyAngularVelocity = Vector3.FromTable(state.angular)
					end
				end)
			end
		elseif state.type ~= "NetworkAuthorityRoot" then
			withMutedObject(object, function()
				stateRegistry.Apply(object, state)
			end)
		end
	end

	flushPendingSnapshot = function(object)
		if object.NetworkId == nil then
			return
		end
		local buffered = pendingSnapshots[object.NetworkId]
		if not buffered then
			return
		end
		pendingSnapshots[object.NetworkId] = nil
		applyBufferedSnapshot(object, buffered.state, buffered.ackPredictedState)
	end

	local function handleSnapshot(payload)
		local ackSequence = payload.lastProcessedOwnedStateSequence or 0
		local ackBatch = predictionBuffer.entries[ackSequence]
		local ackPredictedStates = {}
		if ackBatch then
			for _, predictedState in ipairs(ackBatch.states or {}) do
				ackPredictedStates[predictedState.id] = predictedState
			end
		end

		predictionBuffer:Acknowledge(ackSequence)

		for _, state in ipairs(payload.states or {}) do
			local object = lookup[state.id]
			if object then
				applyOwnershipState(object, state)
			end
		end

		local localPlayer = game.Players.LocalPlayer
		for _, state in ipairs(payload.states or {}) do
			local object = lookup[state.id]
			local ackPredictedState = ackPredictedStates[state.id]
			if not object then
				-- Object not yet in lookup (Create packet hasn't been processed yet).
				-- Buffer the latest state so it can be applied the moment the object arrives.
				pendingSnapshots[state.id] = { state = state, ackPredictedState = ackPredictedState }
				continue
			end

			logHumanoidRootState("snapshot-received", object, state, `ack={ackSequence}`)

			if state.type == "BasePart" then
				if localPlayer and networkOwnership.IsOwnedReplicatedPhysicsPart(object, localPlayer) then
					reconcileLocalState(object, state, ackPredictedState)
				elseif not (localPlayer and networkOwnership.IsOwnedByPlayer(object, localPlayer)) then
					remoteTargets[state.id] = state
					-- Apply velocity immediately so the Humanoid non-authoritative branch
					-- can read the correct speed for animation (walk/run/idle detection)
					withMutedObject(object, function()
						if state.linear then
							local linear = Vector3.FromTable(state.linear)
							object.AssemblyLinearVelocity = linear
							object.Velocity = linear
						end
						if state.angular then
							object.AssemblyAngularVelocity = Vector3.FromTable(state.angular)
						end
					end)
					logHumanoidRootState("remote-target-set", object, state, "")
				end
			elseif state.type ~= "NetworkAuthorityRoot" then
				withMutedObject(object, function()
					stateRegistry.Apply(object, state)
				end)
			end
		end
	end

	local function collectOwnedStates(localPlayer)
		local states = {}

		for _, object in pairs(lookup) do
			if
				object
				and object.Parent ~= nil
				and stateRegistry.ResolveAdapter(object)
				and not (object.GetAttribute and object:GetAttribute("__humanoidRigSkipOwnedState") == true)
				and networkOwnership.IsOwnedByPlayer(object, localPlayer)
			then
				local state = stateRegistry.Capture(object)
				if state then
					table.insert(states, state)
					logHumanoidRootState("capture-owned", object, state, `player={localPlayer.Name}`)
				end
			end
		end

		return states
	end

	local function shouldSendOwnedStates(tick, states)
		if tick - lastOwnedStateSendTick < (1 / 20) then
			return false
		end

		local changed = false
		local seen = {}
		for _, state in ipairs(states) do
			seen[state.id] = true
			local previous = lastOwnedStatesById[state.id]
			if not previous or not stateRegistry.StatesEqual(previous, state) then
				changed = true
			end
		end

		if not changed then
			for id in pairs(lastOwnedStatesById) do
				if not seen[id] then
					changed = true
					break
				end
			end
		end

		if not changed then
			return false
		end

		lastOwnedStatesById = {}
		for _, state in ipairs(states) do
			lastOwnedStatesById[state.id] = stateRegistry.CloneState(state)
		end
		lastOwnedStateSendTick = tick
		return true
	end

	local function flushOwnedPatchEntries()
		if next(outboundOwnedPatchEntries) == nil then
			return
		end

		local entries = {}
		for netId, updates in pairs(outboundOwnedPatchEntries) do
			table.insert(entries, {
				object = netId,
				updates = updates,
			})
		end

		outboundOwnedPatchEntries = {}
		networkService:SendToServer(Protocol.Channels.Input, Protocol.Kinds.OwnedPatchBatch, {
			entries = entries,
		}, true)
	end

	game.DescendantAdded:Connect(function(object)
		if object.NetworkId ~= nil then
			lookup[object.NetworkId] = object
		end
		flushPendingSnapshot(object)
		injectRemoteEventHook(object)
		monitorObject(object)
		flushDeferredReferencePatches()
	end)

	game.DescendantRemoving:Connect(function(object)
		if object.NetworkId ~= nil then
			lookup[object.NetworkId] = nil
			remoteTargets[object.NetworkId] = nil
			outboundOwnedPatchEntries[object.NetworkId] = nil
			pendingSnapshots[object.NetworkId] = nil
		end
		unmonitorObject(object)
	end)

	for _, object in ipairs(game:GetDescendants()) do
		injectRemoteEventHook(object)
		monitorObject(object)
	end

	networkService:RegisterMessageHandler(Protocol.Channels.Replication, Protocol.Kinds.Create, function(_, payload)
		handleCreate(payload.objects)
	end)

	networkService:RegisterMessageHandler(Protocol.Channels.Replication, Protocol.Kinds.Remove, function(_, payload)
		local object = lookup[payload.object]
		if object then
			lookup[payload.object] = nil
			remoteTargets[payload.object] = nil
			outboundOwnedPatchEntries[payload.object] = nil
			unmonitorObject(object)
			object:Destroy()
		end
	end)

	networkService:RegisterMessageHandler(Protocol.Channels.Replication, Protocol.Kinds.PatchBatch, function(_, payload)
		for _, entry in ipairs(payload.entries or {}) do
			applyPatchEntry(entry)
		end
		flushDeferredReferencePatches()
	end)

	networkService:RegisterMessageHandler(Protocol.Channels.Replication, Protocol.Kinds.Snapshot, function(_, payload)
		handleSnapshot(payload)
	end)

	networkService:RegisterMessageHandler(
		Protocol.Channels.Replication,
		Protocol.Kinds.TerrainSnapshot,
		function(_, payload)
			local terrainObject = getTerrain()
			if terrainObject and type(terrainObject.ApplyReplicationSnapshot) == "function" then
				terrainObject:ApplyReplicationSnapshot(payload)
			end
		end
	)

	networkService:RegisterMessageHandler(
		Protocol.Channels.Replication,
		Protocol.Kinds.TerrainChunkBatch,
		function(_, payload)
			local terrainObject = getTerrain()
			if terrainObject and type(terrainObject.ApplyReplicationChunkBatch) == "function" then
				terrainObject:ApplyReplicationChunkBatch(payload)
			end
		end
	)

	networkService:RegisterMessageHandler(Protocol.Channels.Message, Protocol.Kinds.RemoteEvent, function(_, payload)
		local object = lookup[payload.object]
		if not object or object.ClassName ~= "RemoteEvent" then
			return
		end

		local args = payload.args or {}
		object.OnClientEvent:Fire(table.unpack(args, 1, args.n or #args))
	end)

	runService:BindToSimulation(function(dt)
		if workspace.ServerAuthority and workspace.ServerAuthority.AuthorityMode == Enum.AuthorityMode.Server then
			local inputs = InputActionService:SampleLocalInputs()
			networkService:SendToServer(Protocol.Channels.Input, Protocol.Kinds.ControllerInput, {
				tick = runService:GetSimulationTick(),
				inputs = inputs,
			}, true)
		end
	end)

	networkService.Tick:Connect(function(tick)
		if not networkService.IsClientConnected then
			return
		end

		local localPlayer = game.Players.LocalPlayer
		if not localPlayer then
			return
		end

		local states = collectOwnedStates(localPlayer)
		if #states > 0 and shouldSendOwnedStates(tick, states) then
			ownedStateSequence += 1

			local payload = {
				sequence = ownedStateSequence,
				tick = tick,
				states = states,
			}

			predictionBuffer:Push(ownedStateSequence, payload)
			networkService:SendToServer(Protocol.Channels.Input, Protocol.Kinds.OwnedStateBatch, payload, false)
			if ownedStateSequence == 1 or ownedStateSequence % 30 == 0 then
				print(`[Replicator][Client] Sending owned state batch: sequence={ownedStateSequence}, count={#states}`)
			end
		elseif tick - lastNoOwnedStateLogTick >= 60 then
			lastNoOwnedStateLogTick = tick
			print(`[Replicator][Client] No owned state objects for {localPlayer.Name} at tick {tick}`)
		end

		flushOwnedPatchEntries()
	end)

	runService.RenderStepped:Connect(function(dt)
		local localPlayer = game.Players.LocalPlayer
		for netId, state in pairs(remoteTargets) do
			local object = lookup[netId]
			if not object or object.Parent == nil or object.CFrame == nil or state == nil or state.cframe == nil then
				remoteTargets[netId] = nil
				continue
			end

			if state.type ~= "BasePart" then
				remoteTargets[netId] = nil
				withMutedObject(object, function()
					stateRegistry.Apply(object, state)
				end)
				continue
			end

			if localPlayer and networkOwnership.IsOwnedByPlayer(object, localPlayer) then
				continue
			end

			withMutedObject(object, function()
				if object.Parent == nil or object.CFrame == nil then
					remoteTargets[netId] = nil
					return
				end

				local target = CFrame.FromTable(state.cframe)
				logHumanoidRootState("remote-target-step", object, state, `dt={string.format("%.3f", dt)}`)
				applyInterpolatedBasePartTransform(object, object.CFrame:Lerp(target, math.clamp(dt * 12, 0, 1)))
			end)
		end
	end)

	return {}
end

return Client
