local Instance = require("@Instance")
local signal = require("@Kinemium.signal")
local Color3 = require("@Color3")

local befProps = {}

local PlaytestService = Instance.new("PlaytestService")
PlaytestService.ExplorerHidden = true

PlaytestService.InitRenderer = function(renderer, renderer_signal, datamodel)
	PlaytestService:SetProperties({
		CreatePlaytestAsync = function()
			local ScriptRunnerService = datamodel:GetService("ScriptRunnerService")
			local workspace = datamodel.Workspace

			for _, v in pairs(workspace:GetDescendants()) do
				befProps[v.UniqueId] = v._props
			end

			PlaytestService.IsPlaytesting = true
			ScriptRunnerService.Clear()

			for _, script in pairs(datamodel:GetDescendants()) do
				if script:IsA("Script") then
					ScriptRunnerService.RunScript(script)
				end
			end
		end,

		StopCurrentPlaytest = function()
			local workspace = datamodel.Workspace

			local ScriptRunnerService = datamodel:GetService("ScriptRunnerService")
			PlaytestService.IsPlaytesting = false

			for _, v in pairs(workspace:GetDescendants()) do
				if befProps[v.UniqueId] then
					for propName, propValue in pairs(befProps[v.UniqueId]) do
						v[propName] = propValue
					end
				end
			end

			ScriptRunnerService.Clear()
		end,

		IsPlaytesting = false,
	})
end

PlaytestService.GetToolbarCategory = function(renderer, renderer_signal, datamodel)
	local toggle = true

	local Category = {
		elements = {
			{
				type = "ImageButton",
				text = "Playtest",
				callback = function(object)
					if toggle == true then
						PlaytestService.CreatePlaytestAsync()
					else
						PlaytestService.StopCurrentPlaytest()
					end
				end,
				hoverTransparency = 0.5,
				hoverColor = Color3.new(0, 0, 0),
				roundness = 0.2,
				--texture = PlayIcon,
			},
		},
	}

	return Category
end

return PlaytestService
