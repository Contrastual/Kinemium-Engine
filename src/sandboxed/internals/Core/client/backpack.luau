local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

repeat
	task.wait()
until CoreGui:FindFirstChild("KinemiumCoreGui")

repeat
	task.wait()
until ishared.ReactPointer

if not RunService:IsClient() then
	return
end

local screenGui = CoreGui.KinemiumCoreGui
local manager = ishared.ReactPointer

local function runtime(key, fallback)
	local value = manager:get("#runtime", key)
	if value == nil then
		return fallback
	end
	return value
end

local function bindRuntime(object, props)
	for property, key in pairs(props) do
		manager:bind(object, property, "#runtime." .. key)
	end
end

local function bindCorner(corner, radiusKey)
	radiusKey = radiusKey or "corner"
	bindRuntime(corner, {
		CornerRadius = radiusKey,
		TopLeftRadius = radiusKey,
		TopRightRadius = radiusKey,
		BottomLeftRadius = radiusKey,
		BottomRightRadius = radiusKey,
	})
end

local function springTarget(object, props)
	Spring.target(object, runtime("damping", 2), runtime("frequency", 5), props)
end

local slotCount = 0

local BackpackObject = Instance.new("Backpack")
BackpackObject.Parent = Player

local BackpackGui = Instance.new("Frame")
BackpackGui.AnchorPoint = Vector2.new(0.5, 1)
BackpackGui.Position = UDim2.new(0.5, 0, 1, -10)
BackpackGui.BackgroundColor3 = Color3.new(0, 0, 0)
BackpackGui.BackgroundTransparency = 1
BackpackGui.Size = UDim2.new(0, 70, 0, 70)
BackpackGui.Name = "BackpackGui"
BackpackGui.Parent = screenGui
bindRuntime(BackpackGui, {
	BackgroundColor3 = "background",
})

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.FillDirection = Enum.FillDirection.Horizontal
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.Parent = BackpackGui

local shadow = Instance.new("UIShadow")
shadow.Transparency = 1
shadow.Parent = BackpackGui
bindRuntime(shadow, {
	Color = "shadow",
})

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 15)
corner.Parent = BackpackGui
bindCorner(corner, "corner")

local function updateBackpackSize()
	local count = #BackpackGui:GetChildren() - 3 -- ignore layout + shadow + squircle
	local slotSize = 50
	local padding = UIListLayout.Padding.Offset

	local width = count * slotSize + math.max(0, count - 1) * padding

	springTarget(BackpackGui, {
		Size = UDim2.new(0, width + 20, 0, slotSize + 20),
	})

	if slotCount > 0 then
		springTarget(BackpackGui, {
			BackgroundTransparency = runtime("bgtransparency", 0.3),
		})

		springTarget(shadow, {
			Transparency = runtime("shadowtransparency", 0.9),
		})
	else
		springTarget(BackpackGui, {
			BackgroundTransparency = 1,
		})

		springTarget(shadow, {
			Transparency = 1,
		})
	end
end

local function createSlot()
	local slot = Instance.new("Frame")
	slot.Size = UDim2.new(0, 50, 0, 50)
	slot.BackgroundColor3 = Color3.new(0, 0, 0)
	slot.BackgroundTransparency = 0.5
	slot.Parent = BackpackGui
	slotCount += 1
	bindRuntime(slot, {
		BackgroundColor3 = "secondarybackground",
		BackgroundTransparency = "bgtransparency",
	})

	updateBackpackSize()

	local UICorner = Instance.new("UICorner")
	UICorner.CornerRadius = UDim.new(0, 15)
	UICorner.Parent = slot
	bindCorner(UICorner, "corner")

	local slotNumber = Instance.new("TextLabel")
	slotNumber.Text = tostring(slotCount)
	slotNumber.Size = UDim2.new(0, 20, 0, 20)
	slotNumber.BackgroundTransparency = 1
	slotNumber.TextSize = 11
	slotNumber.TextColor3 = Color3.new(1, 1, 1)
	slotNumber.Parent = slot
	bindRuntime(slotNumber, {
		TextColor3 = "text",
		Font = "font",
	})

	return slot
end

BackpackObject.ChildAdded:Connect(function(child)
	if child:IsA("Tool") then
		createSlot()
	end
end)

BackpackObject.ChildRemoved:Connect(function(child)
	if child:IsA("Tool") then
		slotCount = math.max(0, slotCount - 1)
		updateBackpackSize()
	end
end)

manager:subscribe("#runtime", "bgtransparency", updateBackpackSize)
manager:subscribe("#runtime", "shadowtransparency", updateBackpackSize)
manager:subscribe("#runtime", "damping", updateBackpackSize)
manager:subscribe("#runtime", "frequency", updateBackpackSize)
