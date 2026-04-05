local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

if RunService:IsServer() then
	return
end

local menuActive = false
local main_signal = Signal.new()

ishared.EscapeMenu_Signal = main_signal

local transparencySpring = Spring.new(2, 5, "Number", 0.3)
transparencySpring:Play()

local transparencyMenuSpring = Spring.new(2, 5, "Number", 0.3)
transparencyMenuSpring:Play()

local backgroundTransparencySpring = Spring.new(2, 5, "Number", 1)
backgroundTransparencySpring:Play()

local Player = game:GetService("Players").LocalPlayer

local Gui = Instance.new("ScreenGui")
Gui.Name = "KinemiumCoreGui"
Gui.Parent = Player.PlayerGui

local backgroundFrame = Instance.new("Frame")
backgroundFrame.Name = "Background"
backgroundFrame.BackgroundColor3 = Color3.new(0, 0, 0)
backgroundFrame.BackgroundTransparency = 1
backgroundFrame.Size = UDim2.new(1, 0, 1, 0)
backgroundFrame.ZIndex = -1
backgroundFrame.Parent = Gui

local Menu = Instance.new("Frame")
Menu.Name = "Menu"
Menu.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
Menu.Position = UDim2.new(0.5, 0, 0, 0)
Menu.AnchorPoint = Vector2.new(0.5, 0)
Menu.BackgroundTransparency = 0.3
Menu.Size = UDim2.new(0.3, 0, 0, 60)
Menu.Visible = false
Menu.Parent = Gui

local tabs = Instance.new("UITabs")
tabs.Tabs = {}
tabs.ActiveIndex = 1
tabs.BackgroundTransparency = 1
tabs.BackgroundColor3 = Color3.new(0, 0, 0)
tabs.TextSize = 20
tabs.Position = UDim2.new(0.5, 0, 0.5, 0)
tabs.AnchorPoint = Vector2.new(0.5, 0.5)
tabs.Size = UDim2.new(0.94, 0, 0.85, 0)
tabs.ActiveColor3 = Color3.new(1, 1, 1)
tabs.Parent = Menu

tabs:GetPropertyChangedSignal("ActiveIndex"):Connect(function()
	local tabName = tabs.Tabs[tabs.ActiveIndex]
	Routes.handle("/" .. string.lower(tabName))
end)

local shadow2 = Instance.new("UIShadow")
shadow2.Transparency = 0.9
shadow2.Parent = Menu

local squircle2 = Instance.new("UISquircle")
squircle2.CornerRadius = UDim.new(0, 0)
squircle2.Exponent = 1
squircle2.BottomRightRadius = UDim.new(1, 0)
squircle2.BottomLeftRadius = UDim.new(1, 0)
squircle2.Parent = Menu

local OpenMenuButton = Instance.new("TextButton")
OpenMenuButton.Text = ""
OpenMenuButton.TextTransparency = 1
OpenMenuButton.AutoButtonColor = false
OpenMenuButton.BackgroundColor3 = Color3.new(0, 0, 0)
OpenMenuButton.BackgroundTransparency = 0.3
OpenMenuButton.ZIndex = 10
OpenMenuButton.Size = UDim2.new(0, 70, 0, 70)
OpenMenuButton.Parent = Gui

local shadow = Instance.new("UIShadow")
shadow.Transparency = 0.9
shadow.Parent = OpenMenuButton

local squircle = Instance.new("UISquircle")
squircle.CornerRadius = UDim.new(0, 0)
squircle.Exponent = 1
squircle.BottomRightRadius = UDim.new(1, 0)
squircle.Parent = OpenMenuButton

local Icon = Instance.new("ImageLabel")
Icon.Image = "./src/assets/images/kinemium/Core.png"
Icon.AnchorPoint = Vector2.new(0.5, 0.5)
Icon.Position = UDim2.new(0.5, 0, 0.5, 0)
Icon.Size = UDim2.new(0.8, 0, 0.8, 0)
Icon.BackgroundTransparency = 1
Icon.Parent = OpenMenuButton

local function OpenMenu()
	Routes.handle("/" .. string.lower(tabs.ActiveTab))

	Icon.Image = "./src/assets/images/burger.png"

	Spring.target(Icon, 0.5, 10, {
		Size = UDim2.new(0.6, 0, 0.6, 0),
		ImageColor3 = Color3.new(0, 0, 0),
	})

	Spring.target(OpenMenuButton, 2, 5, {
		BackgroundColor3 = Color3.new(1, 1, 1),
		Size = UDim2.new(0, 50, 0, 50),
	})

	transparencyMenuSpring:set(0.5)
	backgroundTransparencySpring:set(0.5)
	Menu.Visible = true
end

local function CloseMenu()
	Routes.deselect()
	Menu.Visible = false
	Icon.Image = "./src/assets/images/kinemium/Core.png"

	Spring.target(Icon, 0.5, 10, {
		Size = UDim2.new(0.8, 0, 0.8, 0),
		ImageColor3 = Color3.new(1, 1, 1),
	})

	Spring.target(OpenMenuButton, 2, 5, {
		BackgroundColor3 = Color3.new(0, 0, 0),
		Size = UDim2.new(0, 70, 0, 70),
	})
	transparencyMenuSpring:set(0.3)
	backgroundTransparencySpring:set(1)
end

local function createWindow(title, callback)
	local window = Instance.new("CanvasGroup")
	window.Name = title
	window.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	window.Position = UDim2.new(0.5, 0, 0.6, 0)
	window.AnchorPoint = Vector2.new(0.5, 0.5)
	window.BackgroundTransparency = 0.2
	window.Size = UDim2.new(0.5, 0, 0.6, 0)
	window.Visible = false
	window.Parent = Gui

	local window_squircle = Instance.new("UISquircle")
	window_squircle.CornerRadius = UDim.new(0, 0)
	window_squircle.Exponent = 1
	window_squircle.BottomRightRadius = UDim.new(0.03, 0)
	window_squircle.BottomLeftRadius = UDim.new(0.03, 0)
	window_squircle.TopLeftRadius = UDim.new(0.03, 0)
	window_squircle.TopRightRadius = UDim.new(0.03, 0)
	window_squircle.Parent = window

	local window_shadow = Instance.new("UIShadow")
	window_shadow.Transparency = 0.5
	window_shadow.Blur = 10
	window_shadow.Parent = window

	local window_list = Instance.new("UIListLayout")
	window_list.Padding = UDim.new(0, 10)
	window_list.FillDirection = Enum.FillDirection.Vertical
	window_list.Parent = window

	local window_title = Instance.new("TextLabel")
	window_title.Text = title
	window_title.TextColor3 = Color3.new(1, 1, 1)
	window_title.BackgroundTransparency = 1
	window_title.TextXAlignment = Enum.TextXAlignment.Left
	window_title.TextSize = 30
	window_title.Size = UDim2.new(1, -20, 0, 40)
	window_title.Parent = window

	local window_padding = Instance.new("UIPadding")
	window_padding.Padding = UDim2.new(0, 10, 0, 10)
	window_padding.Parent = window

	Routes.add(`/{string.lower(title)}`, function()
		window.Visible = true
		Spring.target(window, 2, 5, {
			Position = UDim2.new(0.5, 0, 0.5, 0),
			GroupTransparency = 0,
			BackgroundTransparency = 0.3,
		})

		return function()
			task.spawn(function()
				Spring.target(window, 1, 5, {
					GroupTransparency = 1,
					BackgroundTransparency = 1,
					Position = UDim2.new(0.5, 0, 0.6, 0),
				})
				task.wait(0.1)
				window.Visible = false
			end)
		end
	end)

	if callback then
		callback(window)
	end

	return window
end

Routes.deselect()

OpenMenuButton.MouseEnter:Connect(function()
	transparencySpring:set(0.5)
end)

OpenMenuButton.MouseLeave:Connect(function()
	transparencySpring:set(0.3)
end)

OpenMenuButton.MouseButton1Click:Connect(function(a0: InputObject)
	menuActive = not menuActive
	if menuActive then
		OpenMenu()
	else
		CloseMenu()
	end
end)

Menu.MouseEnter:Connect(function()
	transparencyMenuSpring:set(0.5)
end)

Menu.MouseLeave:Connect(function()
	transparencyMenuSpring:set(0.3)
end)

RunService.Heartbeat:Connect(function(dt)
	Spring.stepTargets(dt)

	if UserInputService:IsKeyReleased(Enum.KeyCode.Escape) then
		menuActive = not menuActive
		if menuActive then
			OpenMenu()
		else
			CloseMenu()
		end
	end
	backgroundFrame.BackgroundTransparency = backgroundTransparencySpring:step(dt)
	Menu.BackgroundTransparency = transparencyMenuSpring:step(dt)
	OpenMenuButton.BackgroundTransparency = transparencySpring:step(dt)
end)

main_signal:Connect(function(message, param, cb)
	if message == "OpenMenu" then
		menuActive = true
		OpenMenu()
	elseif message == "CloseMenu" then
		menuActive = false
		CloseMenu()
	elseif message == "ToggleMenu" then
		menuActive = not menuActive
		if menuActive then
			OpenMenu()
		else
			CloseMenu()
		end
	elseif message == "OpenRoute" then
		Routes.handle("/" .. param)
	elseif message == "CloseRoute" then
		Routes.deselect()
	elseif message == "MakeWindow" then
		createWindow(param, cb)
		table.insert(tabs.Tabs, param)
	end
end)
