-- devcell
local IsPlaytesting = false

local KinemiumIconLoader = game:GetService("KinemiumIconLoader")
local clients = {}
local playtestService = game:GetService("PlaytestService")

repeat
	task.wait()
until ishared.NewCategoryToolbar
local NewCategoryToolbar = ishared.NewCategoryToolbar

NewCategoryToolbar:Fire("Playtest", {
	elements = {
		{
			type = "ImageButton",
			text = "Playtest",
			callback = function()
				if IsPlaytesting then
					return
				end
				print("playtesting..")

				playtestService.CreatePlaytestAsync()
				IsPlaytesting = true
			end,
			hoverTransparency = 0.5,
			hoverColor = Color3.new(0, 0, 0),
			roundness = 0.2,
			texture = KinemiumIconLoader.ToTexture("src/assets/images/icons/vanilla3/general/32x/200/Play.png"),
		},
		{
			type = "ImageButton",

			callback = function()
				local playtestService = game:GetService("PlaytestService")

				if not IsPlaytesting then
					return
				end
				print("Stopping the simulation")

				playtestService.StopCurrentPlaytest()
				IsPlaytesting = false
			end,
			hoverTransparency = 0.5,
			text = "Stop",
			hoverColor = Color3.new(1, 0, 0),
			roundness = 0.2,
			texture = KinemiumIconLoader.ToTexture("src/assets/images/icons/vanilla3/general/32x/200/Stop.png"),
		},
		{
			type = "ImageButton",
			text = "New Client",
			callback = function()
				table.insert(
					clients,
					task.spawn(function()
						zune.process.create(zune.fs.getExePath(), {
							"run",
							"game",
							"--client",
							"--dhs",
						})
					end)
				)
			end,
			hoverTransparency = 0.5,
			hoverColor = Color3.new(0, 0, 0),
			roundness = 0.2,
			texture = KinemiumIconLoader.ToTexture("src/assets/images/icons/vanilla3/general/32x/100/Client.png"),
		},
		{
			type = "ImageButton",
			text = "Clear Clients",
			callback = function()
				for _, client in pairs(clients) do
					task.cancel(client)
				end
				clients = {}
			end,
			hoverTransparency = 0.5,
			hoverColor = Color3.new(0, 0, 0),
			roundness = 0.2,
			texture = KinemiumIconLoader.ToTexture(
				"src/assets/images/icons/vanilla3/general/32x/150/DeleteSelectedBreakpoints.png"
			),
		},
	},
})
