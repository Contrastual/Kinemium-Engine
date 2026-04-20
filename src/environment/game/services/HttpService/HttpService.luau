local Instance = require("@Instance")
local signal = require("@Kinemium.signal")
local net = zune.net

local HttpService = Instance.new("HttpService")
HttpService.ExplorerHidden = true

HttpService.InitRenderer = function(renderer, renderer_signal, game)
	HttpService.RequestStarted = signal.new()
	HttpService.RequestFinished = signal.new()
	HttpService.RequestFailed = signal.new()

	local JSON = zune.serde.json

	local function request(method, url, body, headers, opts)
		opts = opts or {}
		headers = headers or {}

		HttpService.RequestStarted:Fire({ Method = method, URL = url })

		local success, response = pcall(function()
			return net.http.request(url, {
				method = method,
				headers = headers,
				body = body,
				timeout = opts.Timeout,
				allow_redirects = opts.AllowRedirects,
			})
		end)

		if not success then
			HttpService.RequestFailed:Fire({ Method = method, URL = url, Error = response })
			print("HttpService Request Error: " .. tostring(response))
		end

		local res = {
			Body = response.body,
			StatusCode = response.status_code,
			StatusReason = response.status_reason,
			Headers = response.headers,
			Ok = response.ok,
		}

		HttpService.RequestFinished:Fire(res)
		return res
	end

	function HttpService:GetAsync(url, headers, opts)
		local res = request("GET", url, nil, headers, opts)
		return JSON.decode(res.Body), res
	end

	function HttpService:PostAsync(url, body, headers, opts)
		local res = request("POST", url, body, headers, opts)
		return JSON.decode(res.Body), res
	end

	function HttpService:JSONEncode(tbl)
		return JSON.encode(tbl)
	end

	function HttpService:JSONDecode(str)
		return JSON.decode(str)
	end

	function HttpService:GenerateGUID(curly)
		local function generateGUID(): string
			local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
			return template:gsub("[xy]", function(c)
				local r = math.random(0, 15)
				local v = c == "x" and r or (r % 4 + 8)
				return string.format("%x", v)
			end)
		end
		return generateGUID()
	end

	function HttpService:Websocket(opts, accepted)
		local host = opts.host

		local socketObject = {
			OnMessage = signal.new(),
			OnOpen = signal.new(),
			OnClose = signal.new(),
			OnError = signal.new(),
			OnAccept = signal.new(),
			Host = host,
		}

		local HttpWebSocketOptions = {
			headers = opts.headers,
			protocols = opts.protocols,
			timeout = opts.timeout,
			accept = function(self, request)
				socketObject.OnAccept:Fire(request)
			end,
			open = function(self)
				socketObject.OnOpen:Fire()
			end,
			close = function(self, close)
				socketObject.OnClose:Fire(close)
			end,
			message = function(self, message: string)
				socketObject.OnMessage:Fire(message)
			end,
		}

		local new = zune.net.http.websocket(host, HttpWebSocketOptions)

		function socketObject:Destroy(code)
			new:close(code)
		end

		function socketObject:isConnected()
			return new:isConnected()
		end

		function socketObject:Send()
			return new:isConnected()
		end
	end
end

return HttpService
