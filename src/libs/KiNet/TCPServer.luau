local tcpserver = {}

local net = zune.net
local platform = zune.platform
local Serializer = require("./Serializer")

tcpserver.OnRecieve = function(data, client) end
tcpserver.OnConnect = function(client) end

function tcpserver:Init(address, port)
	local server = net.createSocket(
		net.ADDRF.INET,
		bit32.bor(net.SOCKF.STREAM, if platform.os == "windows" then 0 else net.SOCKF.CLOEXEC),
		net.IPPROTO.TCP
	)
	local wrapper = {}

	server:bindIp(address, port)
	server:listen(128)

	function wrapper:Run(readUpTo)
		while true do
			local client = server:accept()
			zune.task.spawn(function()
				tcpserver.OnConnect(client)
				local data = client:recv(readUpTo or 8192)
				if data then
					local returned = tcpserver.OnRecieve(data, client)
					if returned then
						client:send(Serializer.Deserialize(returned))
					end
				end
				client:close()
			end)
		end
	end

	return wrapper
end

return tcpserver
