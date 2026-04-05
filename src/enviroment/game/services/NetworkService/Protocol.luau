local Protocol = {}

Protocol.MAGIC = "kinetica_net_v2"

Protocol.Channels = {
	Control = "control",
	Replication = "replication",
	Input = "input",
	Message = "message",
}

Protocol.Kinds = {
	PlayerProfile = "player_profile",
	PlayerJoined = "player_joined",
	PlayerLeft = "player_left",
	Create = "create",
	Remove = "remove",
	PatchBatch = "patch_batch",
	Snapshot = "snapshot",
	TerrainSnapshot = "terrain_snapshot",
	TerrainChunkBatch = "terrain_chunk_batch",
	RemoteEvent = "remote_event",
	ControllerInput = "controller_input",
	OwnedStateBatch = "owned_state_batch",
	OwnedPatchBatch = "owned_patch_batch",
	OwnershipImpact = "ownership_impact",
}

function Protocol.MakeEnvelope(channel, kind, payload, tick)
	return {
		__network = Protocol.MAGIC,
		channel = channel,
		kind = kind,
		tick = tick,
		payload = payload,
	}
end

function Protocol.IsEnvelope(packet)
	return type(packet) == "table" and packet.__network == Protocol.MAGIC and packet.channel ~= nil and packet.kind ~= nil
end

return Protocol
