local UDim = require("@datatypes/UDim")
local Color3 = require("@datatypes/Color3")
local signal = require("@kinemium.signal")

export type Server = typeof(require("@KiNet").Server)
export type Client = typeof(require("@KiNet").Client)

local propTable = {}

return {
	class = "RemoteEvent",
	callback = function(instance, renderer, datamodel)
		local networkService = datamodel.NetworkService
		local SerializationService = datamodel.SerializationService
		local userdata = SerializationService.userdata

		local KiNet = networkService.KiNet
		local Server = KiNet.Server :: Server
		local Client = KiNet.Client :: Client

		local OnClientEvent = signal.new()
		local OnServerEvent = signal.new()
		local NewClient = signal.new()
		local OnClientDisconnect = signal.new()

		propTable.OnClientEvent = OnClientEvent
		propTable.OnServerEvent = OnServerEvent
		propTable.OnNewClient = NewClient
		propTable.OnClientDisconnect = OnClientDisconnect

		propTable.FireServer = function(...)
			if IsClient then
				local data = { ... }

				Client:Send(data)
			else
				error("FireServer can only be called on the client")
			end
		end

		propTable.FireAllClients = function(...)
			if IsServer then
				local data = { ... }

				Server:SendAll(data)
			else
				error("FireAllClients can only be called on the server")
			end
		end

		if IsServer then
			Server:OnRecieve(function(data)
				OnServerEvent:Fire(data)
			end)

			Server:OnNewClient(function(client)
				NewClient:Fire(client)
			end)

			Server:OnClientRemoved(function(client)
				OnClientDisconnect:Fire(client)
			end)
		end

		if IsClient then
			Client:OnRecieve(function(data)
				OnClientEvent:Fire(data)
			end)
		end

		instance:SetProperties(propTable)
		return instance
	end,
	inherit = function(tble)
		for prop, val in pairs(propTable) do
			tble[prop] = val
		end
	end,
}
