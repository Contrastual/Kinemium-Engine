local Instance = require("@Instance")
local PlaytestService = Instance.new("PlaytestService")
PlaytestService.ExplorerHidden = true

local function outputProcess(prefix, proc)
	local buffer = ""
	task.spawn(function()
		while true do
			local err = proc.stderr:read(1024)

			if err and #err > 0 then
				buffer ..= err

				while true do
					local lineEnd = string.find(buffer, "\n")

					if not lineEnd then
						break
					end

					local line = string.sub(buffer, 1, lineEnd - 1)
					buffer = string.sub(buffer, lineEnd + 1)

					if #line > 0 then
						print(prefix, line)
					end
				end
			end

			task.wait(0.01)
		end
	end)
end

local server_process: ProcessChild
local client_process: ProcessChild

PlaytestService.InitRenderer = function(renderer, renderer_signal, datamodel)
	PlaytestService:SetProperties({
		CreatePlaytestAsync = function()
			local Process = datamodel:GetService("Process")

			task.spawn(function()
				server_process = Process.CreateKinemiumServerProcess()
				outputProcess("[SERVER]", server_process)
			end)

			task.wait(2)

			task.spawn(function()
				client_process = Process.CreateKinemiumClientProcess()
				outputProcess("[CLIENT]", client_process)
			end)
		end,

		StopCurrentPlaytest = function()
			if client_process then
				client_process:kill()
			end
			if server_process then
				server_process:kill()
			end
		end,

		IsPlaytesting = true,
	})
end

return PlaytestService
