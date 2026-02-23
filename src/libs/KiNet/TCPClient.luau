local tcpclient = {}

local net = zune.net
local platform = zune.platform

local Serializer = require("./Serializer")

tcpclient.OnRecieve = function(data) end

function tcpclient:Init(address, port)
	local client = net.createSocket(
		net.ADDRF.INET,
		bit32.bor(net.SOCKF.STREAM, if zune.platform.os == "windows" then 0 else net.SOCKF.CLOEXEC),
		net.IPPROTO.TCP
	)
	local wrapper = {}

	client:connect(address, port)

	function wrapper:Send(data)
		client:send(Serializer.Serialize(data))
	end

	function wrapper:Run(readUpTo)
		repeat
			local ok, data = pcall(client.recv, client, readUpTo or 8192)
			if not ok then
				if data == "EOF" or data == "ConnectionResetByPeer" then
					break
				end
				error(data)
			end
			if data and #data > 0 then
				tcpclient.OnRecieve(Serializer.Deserialize(data))
			end
		until false
		client:close()
	end

	return wrapper
end

return tcpclient
