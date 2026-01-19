local Server = {}

local KiNet = require("@kinet")
local Enum = require("@EnumMap")
export type Server = typeof(KiNet.Server)

local OPCODES = {
	CREATE = 1,
	REMOVE = 2,
	EDIT = 3,
}

local last_value

function Server.init(context)
	local game = context.game
	local serializationService = context.SerializationService
	local networkService = context.NetworkService
	local server = networkService.KiNet.Server :: Server
	local signal = context.signal

	local lookup = {}
	local values = {}
	local userdata = serializationService.userdata

	local function replicate_client_create(object)
		server:SendAll({
			opcode = OPCODES.CREATE,
			objects = object,
		})
	end

	local function replicate_client_edit(object, prop, newval)
		local data = {
			opcode = OPCODES.EDIT,
			object = object.UniqueId,
			prop = prop,
			newval = newval,
		}
		print(data)
		server:SendAll(data)
	end

	for _, v in pairs(game:GetDescendants()) do
		lookup[v.UniqueId] = v
		log("[Replicator] Created lookup pointer: " .. v.UniqueId)
	end

	game.DescendantAdded:Connect(function(object)
		lookup[object.UniqueId] = object
		log("[Replicator] Created lookup pointer: " .. object.UniqueId)

		task.spawn(function()
			if object.CanReplicate == false then
				return
			end
			object._parentID = object.Parent.UniqueId
			local serialized = serializationService.SerializeInstancesAsync({ object })
			replicate_client_create(serialized)
			object._parentID = nil
		end)

		--[[
		object.Changed:Connect(function(prop, val)
			values[object.UniqueId] = values[object.UniqueId] or {}

			if values[object.UniqueId][prop] == val then
				return
			end

			values[object.UniqueId][prop] = val

			if val == last_value then
				return
			end


			last_value = val

			print(`object {object.Name}: {prop} = {tostring(val)}`)
			task.spawn(function()
				replicate_client_edit(object, prop, userdata.Encode(val))
			end)
		end)
		--]]
	end)

	game.DescendantRemoving:Connect(function(object)
		lookup[object.UniqueId] = nil
	end)

	server:OnNewClient(function(addr)
		log("[Replicator] New client connected, sending initial state")

		local batch = {}
		for id, obj in pairs(lookup) do
			if obj.CanReplicate == false then
				continue
			end
			obj._parentID = obj.Parent.UniqueId
			table.insert(batch, obj)
		end
		local serialized = serializationService.SerializeInstancesAsync(batch)
		replicate_client_create(serialized)
		table.clear(batch)
	end)
	return {}
end

return Server
