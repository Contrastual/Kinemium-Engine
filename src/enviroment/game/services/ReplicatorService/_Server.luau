local Server = {}

local Protocol = require("../NetworkService/Protocol")
local Shared = require("./Shared")
local OwnedStateAntiCheat = require("./OwnedStateAntiCheat")
local CFrame = require("@CFrame")
local InputActionService = require("../InputActionService/InputActionService")

local MAX_TERRAIN_RELIABLE_MESSAGES_PER_TICK = 2
local OWNERSHIP_REBALANCE_INTERVAL = 0.2

local function packArgs(...)
	return table.pack(...)
end

function Server.init(context)
	local game = context.game
	local serializationService = context.SerializationService
	local networkService = context.NetworkService
	local stateRegistry = context.StateRegistry
	local networkOwnership = context.NetworkOwnership
	local userdata = serializationService.userdata
	local runService = game:GetService("RunService")

	-- Example: When replicating a Humanoid, use StateRegistry.Capture
	-- (Replace old per-property replication with atomic state)
	-- Usage in your tick/update/replication logic:
	-- for _, object in pairs(trackedStateObjects) do
	--   if object.class == "Humanoid" or object.ClassName == "Humanoid" then
	--     local state = stateRegistry.Capture(object)
	--     -- send 'state' over the network
	--   end
	-- end
	local lookup = {}
	local monitors = {}
	local trackedStateObjects = {}
	local dirtyPatches = {}
	local snapshotCacheByClient = {}
	local terrainQueueByClient = {}
	local ownershipRoots = {}
	local ownershipStateByRoot = setmetatable({}, { __mode = "k" })
	local workspace = game.Workspace or game:GetService("Workspace")
	local terrain = workspace and workspace:FindFirstChild("Terrain")
	local humanoidRootDebugAt = {}

	local function isHumanoidRootObject(object)
		if type(object) ~= "table" then
			return false
		end

		local ok, result = pcall(function()
			return object.GetAttribute and object:GetAttribute("__humanoidRigRoot") == true
		end)
		if ok and result then
			return true
		end

		local okName, name = pcall(function()
			return object.Name
		end)
		return okName and name == "HumanoidRootPart"
	end

	local function shouldLogHumanoidRoot(stage, sessionKey, object, interval)
		if not isHumanoidRootObject(object) then
			return false
		end

		local key = `{stage}:{sessionKey or "global"}:{object.NetworkId or "?"}`
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

	local function logHumanoidRootState(stage, sessionKey, object, state, extra)
		if not shouldLogHumanoidRoot(stage, sessionKey, object) then
			return
		end

		local owner = object.NetworkOwner and object.NetworkOwner.Name or "Server"
		local livePos = object.CFrame and object.CFrame.Position or object.Position
		local statePos = decodeStatePosition(state)
		print(
			`[HumanoidDebug][Server][{stage}] session={sessionKey or "global"} object={object.Name}#{object.NetworkId or "?"} owner={owner} live={formatVector3(
				livePos
			)} state={formatVector3(statePos)} {extra or ""}`
		)
	end

	local function getOwnershipState(root)
		local state = ownershipStateByRoot[root]
		if not state then
			state = {}
			ownershipStateByRoot[root] = state
		end

		return state
	end

	local function markOwnershipCooldown(root, duration, blockedUserId)
		if not root then
			return
		end

		local now = os.clock()
		local state = getOwnershipState(root)
		local lockDuration = math.max(duration or 0, 0)
		state.cooldownUntil = math.max(state.cooldownUntil or 0, now + lockDuration)
		if blockedUserId ~= nil then
			state.blockedUserId = blockedUserId
			state.blockedUntil = math.max(state.blockedUntil or 0, now + math.max(lockDuration, 3))
		end
	end

	local antiCheat = OwnedStateAntiCheat.new({
		NetworkService = networkService,
		NetworkOwnership = networkOwnership,
		OnOwnershipRevoked = function(session, root)
			markOwnershipCooldown(root, 3, session and session.userId or nil)
		end,
	})

	local function getTerrain()
		if not terrain or terrain.Parent == nil then
			terrain = game:GetService("Workspace"):FindFirstChild("Terrain")
		end

		return terrain
	end

	local function getTerrainQueue(session)
		if not session or not session.key then
			return nil
		end

		local queue = terrainQueueByClient[session.key]
		if not queue then
			queue = {
				items = {},
				head = 1,
				tail = 0,
			}
			terrainQueueByClient[session.key] = queue
		end

		return queue
	end

	local function clearTerrainQueue(session)
		if session and session.key then
			terrainQueueByClient[session.key] = nil
		end
	end

	local function enqueueTerrainPayload(session, kind, payload)
		local queue = getTerrainQueue(session)
		if not queue then
			return
		end

		queue.tail += 1
		queue.items[queue.tail] = {
			kind = kind,
			payload = payload,
		}
	end

	local function enqueueTerrainPayloadForSessions(kind, payload)
		for _, session in ipairs(networkService:GetSessions()) do
			enqueueTerrainPayload(session, kind, payload)
		end
	end

	local function flushTerrainQueues()
		for _, session in ipairs(networkService:GetSessions()) do
			local queue = terrainQueueByClient[session.key]
			if not queue then
				continue
			end

			local sent = 0
			while sent < MAX_TERRAIN_RELIABLE_MESSAGES_PER_TICK and queue.head <= queue.tail do
				local item = queue.items[queue.head]
				queue.items[queue.head] = nil
				queue.head += 1
				sent += 1

				if item then
					networkService:SendToClient(session, Protocol.Channels.Replication, item.kind, item.payload, true)
				end
			end

			if queue.head > queue.tail then
				terrainQueueByClient[session.key] = nil
			end
		end
	end

	local nextNetId = 100

	local function assignNetworkId(object)
		if object.NetworkId ~= nil then
			return
		end

		if object.ClassName == "DataModel" then
			object.NetworkId = 0
		elseif object.ClassName == "Workspace" then
			object.NetworkId = 1
		elseif object.ClassName == "Players" then
			object.NetworkId = 2
		elseif object.ClassName == "ReplicatedStorage" then
			object.NetworkId = 3
		elseif object.ClassName == "StarterGui" then
			object.NetworkId = 4
		elseif object.ClassName == "CoreGui" then
			object.NetworkId = 5
		else
			object.NetworkId = nextNetId
			nextNetId += 1
		end
	end

	local function visitTree(root, callback)
		callback(root)
		for _, descendant in ipairs(root:GetDescendants()) do
			callback(descendant)
		end
	end

	local function trackObject(object)
		assignNetworkId(object)
		lookup[object.NetworkId] = object
		if stateRegistry.ResolveAdapter(object) then
			trackedStateObjects[object.NetworkId] = object
		end
	end

	local function untrackObject(object)
		if object.NetworkId ~= nil then
			lookup[object.NetworkId] = nil
			trackedStateObjects[object.NetworkId] = nil
		end
	end

	local function registerOwnershipRoot(object)
		local root, controller = networkOwnership.GetControllerRoot(object)
		if root ~= nil and controller ~= nil then
			ownershipRoots[root] = true
		end
	end

	local function unregisterOwnershipRoot(object)
		if object == nil then
			return
		end

		ownershipRoots[object] = nil
		ownershipStateByRoot[object] = nil

		local root = networkOwnership.GetAuthorityRoot(object)
		if root ~= nil and root ~= object and networkOwnership.GetController(root) == nil then
			ownershipRoots[root] = nil
			ownershipStateByRoot[root] = nil
		end
	end

	local function encodePropertyValue(value)
		return Shared.EncodePropertyValue(userdata, value)
	end

	local function queuePatch(object, prop, value)
		if object.NetworkId == nil or object.CanReplicate == false then
			return
		end
		if not Shared.ShouldReplicateProperty(prop) then
			return
		end

		local encoded = encodePropertyValue(value)
		if encoded == nil then
			return
		end

		dirtyPatches[object.NetworkId] = dirtyPatches[object.NetworkId] or {}
		dirtyPatches[object.NetworkId][prop] = encoded
	end

	local function monitor(object)
		if monitors[object] then
			return
		end

		monitors[object] = object.Changed:Connect(function(prop, value)
			queuePatch(object, prop, value)
		end)
	end

	local function serializeObjects(objects)
		local stamped = {}
		local function stamp(object)
			if stamped[object] then
				return
			end
			stamped[object] = true
			object._props.NetworkId = object.NetworkId
			object._props._parentID = object.Parent and object.Parent.NetworkId
		end

		for _, object in ipairs(objects) do
			visitTree(object, stamp)
		end

		local serialized = serializationService.SerializeInstancesAsync(objects)

		for object in pairs(stamped) do
			object._props.NetworkId = nil
			object._props._parentID = nil
		end

		return serialized
	end

	local function collectSerializableRoots(roots)
		local serializable = {}
		local seen = {}

		for _, root in ipairs(roots) do
			if root and not seen[root] and root.CanReplicate ~= false then
				seen[root] = true
				table.insert(serializable, root)
			end
		end

		return serializable
	end

	local function collectReferencePatchEntries(roots)
		local entries = {}
		local seen = {}

		local function collect(object)
			if seen[object] then
				return
			end
			seen[object] = true

			if object.NetworkId == nil or object.CanReplicate == false then
				return
			end

			local updates = {}
			for prop, value in pairs(object._props) do
				if prop ~= "Parent" and Shared.IsInstanceReference(value) then
					updates[prop] = encodePropertyValue(value)
				end
			end

			if next(updates) ~= nil then
				table.insert(entries, {
					object = object.NetworkId,
					updates = updates,
				})
			end
		end

		for _, root in ipairs(roots) do
			visitTree(root, collect)
		end

		return entries
	end

	local function sendPatchEntries(recipient, entries)
		if #entries == 0 then
			return
		end

		if recipient then
			networkService:SendToClient(recipient, Protocol.Channels.Replication, Protocol.Kinds.PatchBatch, {
				entries = entries,
			}, true)
		else
			networkService:Broadcast(Protocol.Channels.Replication, Protocol.Kinds.PatchBatch, {
				entries = entries,
			}, true)
		end
	end

	local function sendCreate(recipient, roots)
		local serializable = collectSerializableRoots(roots)
		if #serializable == 0 then
			return
		end

		local serialized = serializeObjects(serializable)
		local payload = { objects = serialized }
		local recipientLabel = recipient and (recipient.key or (recipient.address .. ":" .. recipient.port))
			or "broadcast"
		local rootNames = {}
		for _, object in ipairs(serializable) do
			table.insert(rootNames, `{object.ClassName}:{object.Name}`)
		end

		print(
			`[Replicator][Server] Create -> {recipientLabel}: objects={#serializable}, bytes={buffer.len(serialized)}, names=[{table.concat(
				rootNames,
				", "
			)}]`
		)

		if recipient then
			networkService:SendToClient(recipient, Protocol.Channels.Replication, Protocol.Kinds.Create, payload, true)
		else
			networkService:Broadcast(Protocol.Channels.Replication, Protocol.Kinds.Create, payload, true)
		end

		sendPatchEntries(recipient, collectReferencePatchEntries(serializable))
	end

	local function collectInitialRoots()
		local roots = {}
		local seen = {}

		local function addRoot(object)
			if not object or object.CanReplicate == false or object.NetworkId == nil or seen[object] then
				return
			end
			seen[object] = true
			table.insert(roots, object)
		end

		-- Include every top-level Workspace instance that contains replicated descendants (nested rigs, synced folders).
		local workspaceInst = game:GetService("Workspace")
		if workspaceInst then
			for _, object in ipairs(workspaceInst:GetDescendants()) do
				if object.CanReplicate == false or object.NetworkId == nil then
					continue
				end
				local ancestor = object
				while ancestor.Parent and ancestor.Parent ~= workspaceInst do
					ancestor = ancestor.Parent
				end
				if ancestor.Parent == workspaceInst then
					addRoot(ancestor)
				end
			end
		end

		local singletonIds = {
			[0] = true,
			[1] = true,
			[2] = true,
			[3] = true,
			[4] = true,
			[5] = true,
		}

		for _, object in ipairs(game:GetDescendants()) do
			if object.CanReplicate == false or object.NetworkId == nil then
				continue
			end

			local parent = object.Parent
			if parent and singletonIds[parent.NetworkId] then
				addRoot(object)
			end
		end

		return roots
	end

	local function sendRemove(netId)
		networkService:Broadcast(Protocol.Channels.Replication, Protocol.Kinds.Remove, {
			object = netId,
		}, true)
	end

	local function sendTerrainSnapshot(recipient)
		local terrainObject = getTerrain()
		if not terrainObject then
			return
		end

		local batches
		if type(terrainObject.ExportReplicationSnapshotBatches) == "function" then
			batches = terrainObject:ExportReplicationSnapshotBatches()
		elseif type(terrainObject.ExportReplicationSnapshot) == "function" then
			batches = { terrainObject:ExportReplicationSnapshot() }
		end
		if not batches then
			return
		end

		for _, payload in ipairs(batches) do
			enqueueTerrainPayload(recipient, Protocol.Kinds.TerrainSnapshot, payload)
		end
	end

	local function injectRemoteEventHooks(object)
		if object.ClassName ~= "RemoteEvent" then
			return
		end

		object:SetProperties({
			FireClient = function(self, player, ...)
				local session = networkService:GetSessionByUserId(player.UserId)
				if not session then
					return
				end

				networkService:SendToClient(session, Protocol.Channels.Message, Protocol.Kinds.RemoteEvent, {
					object = self.NetworkId,
					args = packArgs(...),
				}, true)
			end,
			FireAllClients = function(self, ...)
				networkService:Broadcast(Protocol.Channels.Message, Protocol.Kinds.RemoteEvent, {
					object = self.NetworkId,
					args = packArgs(...),
				}, true)
			end,
		})
	end

	local function applyOwnedPatchBatch(session, payload)
		for _, entry in ipairs(payload.entries or {}) do
			local object = lookup[entry.object]
			if not object or object.Parent == nil then
				continue
			end
			if not networkOwnership.IsOwnedByPlayer(object, session.player) then
				continue
			end

			for prop, encoded in pairs(entry.updates or {}) do
				if not networkOwnership.ShouldReplicateProperty(object, prop) then
					continue
				end

				local decoded, ok = Shared.DecodePropertyValue(userdata, lookup, encoded)
				if ok then
					object[prop] = decoded
				end
			end
		end
	end

	for _, object in ipairs(game:GetDescendants()) do
		trackObject(object)
		registerOwnershipRoot(object)
		monitor(object)
		injectRemoteEventHooks(object)
	end

	game.DescendantAdded:Connect(function(object)
		trackObject(object)
		if object.ClassName == "NetworkController" and object.Parent then
			trackObject(object.Parent)
		end
		registerOwnershipRoot(object)
		monitor(object)
		injectRemoteEventHooks(object)

		task.spawn(function()
			sendCreate(nil, { object })
		end)
	end)

	game.DescendantRemoving:Connect(function(object)
		if object.NetworkId == nil then
			return
		end

		unregisterOwnershipRoot(object)
		untrackObject(object)
		sendRemove(object.NetworkId)
	end)

	networkService.ClientConnected:Connect(function(session)
		snapshotCacheByClient[session.key] = nil
		clearTerrainQueue(session)
		print(`[Replicator][Server] Client connected {session.key}, initial roots pending`)
		sendCreate(session, collectInitialRoots())
		sendTerrainSnapshot(session)
	end)

	networkService.ClientRemoved:Connect(function(session)
		snapshotCacheByClient[session.key] = nil
		clearTerrainQueue(session)
		antiCheat:ClearSession(session)

		for root in pairs(ownershipRoots) do
			local owner = root and root.NetworkOwner or nil
			if owner and owner.UserId == session.userId then
				networkOwnership.ClearOwner(root)
				markOwnershipCooldown(root, 0.75, session.userId)
			end
		end
	end)

	networkService:RegisterMessageHandler(
		Protocol.Channels.Input,
		Protocol.Kinds.OwnedStateBatch,
		function(session, payload)
			if not session or not session.player then
				return
			end

			local sequence = payload.sequence or 0
			if sequence <= (session.lastOwnedStateSequence or 0) then
				return
			end

			if sequence == 1 or sequence % 30 == 0 then
				print(
					`[Replicator][Server] Received owned state batch from {session.player.Name}: sequence={sequence}, count={#(payload.states or {})}`
				)
			end

			session.lastOwnedStateSequence = sequence
			session.pendingOwnedStateBatch = payload
		end
	)

	networkService:RegisterMessageHandler(
		Protocol.Channels.Input,
		Protocol.Kinds.OwnedPatchBatch,
		function(session, payload)
			if not session or not session.player then
				return
			end

			applyOwnedPatchBatch(session, payload)
		end
	)

	networkService:RegisterMessageHandler(
		Protocol.Channels.Message,
		Protocol.Kinds.RemoteEvent,
		function(session, payload)
			local object = lookup[payload.object]
			if not object or object.ClassName ~= "RemoteEvent" then
				return
			end

			local player = session and session.player or nil
			local args = payload.args or {}
			object.OnServerEvent:Fire(player, table.unpack(args, 1, args.n or #args))
		end
	)

	networkService:RegisterMessageHandler(
		Protocol.Channels.Input,
		Protocol.Kinds.ControllerInput,
		function(session, payload)
			if not session then
				return
			end
			session.inputBuffer = session.inputBuffer or {}
			local tick = payload.tick
			if tick then
				session.inputBuffer[tick] = payload.inputs
			end

			local currentTick = runService:GetSimulationTick()
			for t in pairs(session.inputBuffer) do
				if t < currentTick - 120 then
					session.inputBuffer[t] = nil
				end
			end
		end
	)

	local SERVER_INPUT_ACTIONS = { "MoveX", "MoveZ", "Jump", "Sprint", "Crouch" }

	runService:BindToSimulation(function(dt)
		local currentTick = runService:GetSimulationTick()
		local workspace = game:GetService("Workspace")
		if not (workspace.ServerAuthority and workspace.ServerAuthority.AuthorityMode == Enum.AuthorityMode.Server) then
			return
		end

		for _, session in ipairs(networkService:GetSessions()) do
			local player = session.player
			if not player then
				continue
			end
			for _, actionName in ipairs(SERVER_INPUT_ACTIONS) do
				InputActionService:SetActionValue(actionName, player, 0)
			end
			if session.inputBuffer and session.inputBuffer[currentTick] then
				local inputs = session.inputBuffer[currentTick]
				for actionName, value in pairs(inputs) do
					InputActionService:SetActionValue(actionName, player, value)
				end
			end
		end
	end)

	local function flushDirtyPatches()
		if next(dirtyPatches) == nil then
			return
		end

		local entries = {}
		for netId, updates in pairs(dirtyPatches) do
			table.insert(entries, {
				object = netId,
				updates = updates,
			})
		end

		dirtyPatches = {}
		sendPatchEntries(nil, entries)
	end

	local function flushTerrainChunkUpdates()
		local terrainObject = getTerrain()
		if not terrainObject then
			return
		end

		local batches
		if type(terrainObject.ConsumeReplicationChunkUpdateBatches) == "function" then
			batches = terrainObject:ConsumeReplicationChunkUpdateBatches()
		elseif type(terrainObject.ConsumeReplicationChunkUpdates) == "function" then
			local payload = terrainObject:ConsumeReplicationChunkUpdates()
			if payload then
				batches = { payload }
			end
		end
		if not batches then
			return
		end

		for _, payload in ipairs(batches) do
			if #(payload.chunks or {}) > 0 or payload.reset == true then
				enqueueTerrainPayloadForSessions(Protocol.Kinds.TerrainChunkBatch, payload)
			end
		end
	end

	local function applyPendingOwnedStateBatches()
		for _, session in ipairs(networkService:GetSessions()) do
			local payload = session.pendingOwnedStateBatch
			if not session.player or not payload then
				continue
			end

			for _, state in ipairs(payload.states or {}) do
				local object = lookup[state.id]
				if not object or object.Parent == nil then
					continue
				end
				if not stateRegistry.ResolveAdapter(object) then
					continue
				end
				if not networkOwnership.IsOwnedByPlayer(object, session.player) then
					continue
				end
				if not antiCheat:ValidateOwnedState(session, payload, object, state) then
					continue
				end

				logHumanoidRootState(
					"apply-owned-before",
					session.key,
					object,
					state,
					`sequence={payload.sequence or 0}`
				)
				stateRegistry.Apply(object, state)
				logHumanoidRootState(
					"apply-owned-after",
					session.key,
					object,
					state,
					`sequence={payload.sequence or 0}`
				)
			end

			if payload.sequence == 1 or payload.sequence % 30 == 0 then
				print(
					`[Replicator][Server] Applied owned state batch from {session.player.Name}: sequence={payload.sequence}, count={#(payload.states or {})}`
				)
			end

			session.lastAppliedOwnedStateSequence = payload.sequence or session.lastAppliedOwnedStateSequence or 0
			session.pendingOwnedStateBatch = nil
		end
	end

	local function getPlayerDistanceToRoot(root, player)
		local rootPosition = networkOwnership.GetWorldPosition(root)
		local playerPosition = networkOwnership.GetPlayerFocusPosition(player)
		if not rootPosition or not playerPosition then
			return math.huge
		end

		return (rootPosition - playerPosition):Magnitude()
	end

	local function findBestOwnershipCandidate(root, now)
		local bestPlayer = nil
		local bestDistance = math.huge
		local state = getOwnershipState(root)

		for _, session in ipairs(networkService:GetSessions()) do
			local player = session.player
			if player and player.Parent ~= nil then
				if not (state.blockedUserId == player.UserId and now < (state.blockedUntil or 0)) then
					local distance = getPlayerDistanceToRoot(root, player)
					if distance < bestDistance then
						bestDistance = distance
						bestPlayer = player
					end
				end
			end
		end

		return bestPlayer, bestDistance
	end

	local function assignOwnership(root, newOwner, now)
		local state = getOwnershipState(root)
		local changed = root.NetworkOwner ~= newOwner
		if changed then
			networkOwnership.SetOwner(root, newOwner)
			state.lastTransferAt = now
			if newOwner then
				state.lastOwnerUserId = newOwner.UserId
			else
				state.lastOwnerUserId = nil
			end
		end
		state.cooldownUntil = math.max(state.cooldownUntil or 0, now)
		return changed
	end

	local function rebalanceOwnership(now)
		for root in pairs(ownershipRoots) do
			if root == nil or root.Parent == nil then
				unregisterOwnershipRoot(root)
				continue
			end

			local resolvedRoot, controller = networkOwnership.GetControllerRoot(root)
			if resolvedRoot ~= root or controller == nil then
				unregisterOwnershipRoot(root)
				continue
			end

			local state = getOwnershipState(root)
			local currentOwner = root.NetworkOwner
			local currentSession = currentOwner and networkService:GetSessionByUserId(currentOwner.UserId) or nil
			local config = networkOwnership.GetAutoOwnershipConfig(root, controller)

			if not networkOwnership.CanAutoAssignOwnership(root, controller) then
				if currentOwner ~= nil then
					assignOwnership(root, nil, now)
				end
				continue
			end

			local speed = networkOwnership.GetLinearSpeed(root)
			local currentDistance = currentOwner and getPlayerDistanceToRoot(root, currentOwner) or math.huge
			local currentOwnerValid = currentOwner ~= nil
				and currentSession ~= nil
				and currentDistance <= config.releaseRadius

			if currentOwnerValid then
				continue
			end

			if now < (state.cooldownUntil or 0) then
				continue
			end

			local bestPlayer, bestDistance = findBestOwnershipCandidate(root, now)
			local canClaim = bestPlayer ~= nil and bestDistance <= config.ownershipRadius

			if currentOwner ~= nil and currentSession ~= nil then
				if canClaim and bestPlayer ~= currentOwner and bestDistance + config.stealMargin < currentDistance then
					assignOwnership(root, bestPlayer, now)
					state.cooldownUntil = now + config.transferCooldown
				elseif currentDistance > config.releaseRadius then
					if canClaim then
						assignOwnership(root, bestPlayer, now)
					else
						assignOwnership(root, nil, now)
					end
					state.cooldownUntil = now + config.transferCooldown
				end
				continue
			end

			if speed < config.velocityThreshold then
				if currentOwner ~= nil and currentSession == nil then
					assignOwnership(root, nil, now)
					state.cooldownUntil = now + config.transferCooldown
				end
				continue
			end

			if canClaim then
				assignOwnership(root, bestPlayer, now)
				state.cooldownUntil = now + config.transferCooldown
			elseif currentOwner ~= nil then
				assignOwnership(root, nil, now)
				state.cooldownUntil = now + config.transferCooldown
			end
		end
	end

	local function flushSnapshots(tick)
		for _, session in ipairs(networkService:GetSessions()) do
			local cache = snapshotCacheByClient[session.key]
			if not cache then
				cache = {
					states = {},
					lastAck = -1,
				}
				snapshotCacheByClient[session.key] = cache
			end

			local changedStates = {}

			for netId, object in pairs(trackedStateObjects) do
				if object.CanReplicate == false or object.Parent == nil then
					continue
				end

				local state = stateRegistry.Capture(object)
				if not state then
					continue
				end

				local previous = cache.states[netId]
				if not previous or not stateRegistry.StatesEqual(previous, state) then
					cache.states[netId] = stateRegistry.CloneState(state)
					table.insert(changedStates, state)
					logHumanoidRootState("snapshot-queued", session.key, object, state, `tick={tick}`)
				end
			end

			local lastAck = session.lastAppliedOwnedStateSequence or 0
			if #changedStates > 0 or cache.lastAck ~= lastAck then
				cache.lastAck = lastAck
				networkService:SendToClient(session, Protocol.Channels.Replication, Protocol.Kinds.Snapshot, {
					tick = tick,
					lastProcessedOwnedStateSequence = lastAck,
					states = changedStates,
				}, true)
			end
		end
	end

	networkService.Tick:Connect(function(tick)
		if tick % math.max(math.floor((networkService.TickRate or 30) * OWNERSHIP_REBALANCE_INTERVAL), 1) == 0 then
			rebalanceOwnership(os.clock())
		end
		applyPendingOwnedStateBatches()
		flushDirtyPatches()
		flushTerrainChunkUpdates()
		flushTerrainQueues()
		flushSnapshots(tick)
	end)

	return {}
end

return Server
