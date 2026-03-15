local Client = {}

local kinet = require("@kinet")
type Client = typeof(kinet.Client)

local OPCODES = {
	CREATE = 1,
	REMOVE = 2,
	EDIT = 3,
}

function Client.init(context)
	local game = context.game
	local serializationService = context.SerializationService
	local networkService = context.NetworkService
	local Enum = require("@Enum")
	local kinet_client = kinet.Client :: Client

	local lookup = {}
	local userdata = serializationService.userdata

	for _, v in pairs(game:GetDescendants()) do
		lookup[v.UniqueId] = v
		log("[ClientReplicator] Created lookup pointer: " .. v.UniqueId .. " for ", v)
	end

	game.DescendantAdded:Connect(function(object)
		lookup[object.UniqueId] = object
		log("[ClientReplicator] Created lookup pointer: " .. object.UniqueId .. " for ", object)
	end)

	game.DescendantRemoving:Connect(function(object)
		lookup[object.UniqueId] = nil
		log("[ClientReplicator] Removed lookup pointer: " .. object.UniqueId .. " for ", object)
	end)

	kinet_client:OnRecieve(function(addr, data)
		if data.opcode == OPCODES.CREATE then
			local objects = data.objects
			local deserialized = serializationService.Deserialize(objects)
			if deserialized then
				print("Got data!")
				for _, object in pairs(deserialized) do
					print("Parenting", object)
					print("Id", object.UniqueId)
					print("Parent ID", object._parentID)
					if lookup[object.UniqueId] then
						print("Theres an already existing object with the same unique id!")
						print(object)
						continue
					end
					print("Object is very unique!")

					object.NetworkOwnerType = Enum.MachineNetworkOwner.Server.Value

					local parent = lookup[object._parentID]

					print("Found parent! ", parent)

					if parent then
						object.Parent = parent
						object._parentID = nil
					else
						object.Parent = game.Workspace
					end
				end
			end
		elseif data.opcode == OPCODES.EDIT then
			local object = lookup[data.object]

			iodebug(object)
			iodebug(data.object)
			if object then
				object[data.prop] = userdata.Decode(data.newval)
			end
		end
	end)

	repeat
		log("[Replicator Client] Waiting for authentication...")
		task.wait()
	until kinet_client.IsAuthenticated == true

	log("[Replicator Client] Authenticated")

	return {}
end

return Client
