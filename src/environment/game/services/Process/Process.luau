local Instance = require("@Instance")
local signal = require("@Kinemium.signal")

local zpross = zune.process

local Process = Instance.new("Process")
Process.ExplorerHidden = true

Process.InitRenderer = function(renderer, renderer_signal)
	Process:SetProperties({
		CreateKinemiumClientProcess = function(flags: { string })
			local info = {
				"run",
				"game",
				"--client",
				"--username",
				"Dev",
			}

			if flags then
				for _, flag in ipairs(flags) do
					table.insert(info, flag)
				end
			end

			local process = zune.process.create(zune.fs.getExePath(), info, {
				opts = { stdin = "inherit", stdout = "inherit", stderr = "inherit" },
			})
			return process
		end,

		CreateKinemiumClientProcessEx = function(username, ip, port)
			local info = {
				"run",
				"game",
				"--client",
				"--username",
				username,
				"--address",
				ip,
				"--port",
				tostring(port),
			}
			local process = zune.process.create(zune.fs.getExePath(), info, {
				opts = { stdin = "inherit", stdout = "inherit", stderr = "inherit" },
			})
			return process
		end,

		CreateKinemiumServerProcessEx = function(ip, port)
			-- example zune run game --server --port 1234 --address 0.0.0.0
			local info = {
				"run",
				"game",
				"--server",
				"--port",
				tostring(port),
				"--address",
				ip,
			}

			local process = zune.process.create(zune.fs.getExePath(), info, {
				opts = { stdin = "inherit", stdout = "inherit", stderr = "inherit" },
			})
			return process
		end,

		CreateKinemiumServerProcess = function(flags: { string })
			local info = {
				"run",
				"game",
				"--server",
			}

			if flags then
				for _, flag in ipairs(flags) do
					table.insert(info, flag)
				end
			end

			local process = zune.process.create(zune.fs.getExePath(), info, {
				opts = { stdin = "inherit", stdout = "inherit", stderr = "inherit" },
			})
			return process
		end,
	})
end
return Process
