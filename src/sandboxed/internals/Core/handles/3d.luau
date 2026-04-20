-- devcell

local KinemiumFontService = game:GetService("KinemiumFontService")
local StudioThemeService = game:GetService("StudioThemeService")
local rlservice = game:GetService("KinemiumRaylib")
local raylib = require("@raylib")
local UserInputService = game:GetService("UserInputService")

if UserInputService:GetOS() == Enum.Platform.Linux then
	-- linux not supported Yet........................
	return
end

if FlagExists("cli") or FlagExists("headless") then
	return
end

local lib = raylib.lib
local const = raylib.const
local renderer = rlservice.GetRenderer()
local Selection = game:GetService("Selection")
local freecam = renderer.Freecam
local _focusTargetCF = nil
local vend = KinemiumFontService.GetDefaultFont()
local _focusAlpha = 0
local KinemiumIconLoader = game:GetService("KinemiumIconLoader")

ishared.Grid = 1
ishared.ForceMoveObject = true
ishared.RotationStep = 15

local aereon = require("@Aereon")
local Movement, Resize, Rotation = Instance.new("Handles"), Instance.new("Handles"), Instance.new("Handles")

Movement.Style = Enum.HandlesStyle.Movement
Resize.Style = Enum.HandlesStyle.Resize
Rotation.Style = Enum.HandlesStyle.Rotation

local MoveOffsets = {}
local MoveStartPivot = nil
local MoveDragging = false

local RotOffsets = {}
local RotStartPivot = nil
local RotDragging = false

local ScaleOffsets = {}
local ScaleStartPivot = nil
local ScaleDragging = false

local textbox = aereon.textbox(StudioThemeService.SelectedTheme, game)

local function snap(v)
	return math.round(v / ishared.Grid) * ishared.Grid
end

local function snapVec3(v)
	return Vector3.new(snap(v.X), snap(v.Y), snap(v.Z))
end

local function isModel(obj)
	return obj ~= nil and obj.ClassName == "Model"
end

local function getObjectPivot(obj)
	if obj == nil then
		return nil
	end
	if isModel(obj) then
		return obj:GetPivot()
	elseif obj.CFrame ~= nil then
		return obj.CFrame
	end
	return nil
end

local function setObjectCFrame(obj, cf)
	if obj == nil or cf == nil then
		return
	end
	if isModel(obj) then
		obj:PivotTo(cf)
	elseif obj.CFrame ~= nil then
		obj.CFrame = cf
	end
end

local function getObjectExtents(obj)
	if obj == nil then
		return Vector3.new(1, 1, 1)
	end
	if isModel(obj) then
		local s = obj:GetExtentsSize()
		return Vector3.new(math.max(s.X, 0.001), math.max(s.Y, 0.001), math.max(s.Z, 0.001))
	elseif obj.Size ~= nil then
		return obj.Size
	end
	return Vector3.new(1, 1, 1)
end

--

local function isMovable(object)
	return object:IsA("BasePart") or isModel(object) or object:GetMetadata("IsMovable")
end

local function getSelectionCenter()
	local selection = Selection:Get()
	if #selection == 0 then
		return nil
	end

	local sum = Vector3.zero
	local count = 0

	for _, obj in ipairs(selection) do
		local pivot = getObjectPivot(obj)
		if pivot ~= nil then
			sum += pivot.Position
			count += 1
		end
	end

	if count == 0 then
		return nil
	end
	return sum / count
end

local gridInput = textbox.new({
	multiline = false,
	placeholder = "1",
	fontSize = 16,
	font = vend,
	maxLength = 56,
	numeric = true,
	numericMin = 0,
	numericMax = 10000,
	numericPrecision = 1,
	showStepButtons = true,
	onChange = function(new)
		if tonumber(new) and tonumber(new) > 0 then
			ishared.Grid = tonumber(new)
		else
			ishared.Grid = 1
		end
	end,
})

local rotateGrid = textbox.new({
	multiline = false,
	placeholder = "15",
	fontSize = 16,
	font = vend,
	maxLength = 56,
	numeric = true,
	suffix = "°",
	numericMin = 0,
	numericMax = 10000,
	numericPrecision = 1,
	showStepButtons = true,
	onChange = function(new)
		if tonumber(new) and tonumber(new) > 0 then
			ishared.RotationStep = tonumber(new)
		else
			ishared.RotationStep = 15
		end
		if Rotation then
			Rotation.RotationSnap = ishared.RotationStep
		end
	end,
})

local gizmo = import("@gizmo")
local _flags = gizmo.Flags
Rotation.RotationSnap = ishared.RotationStep

--  Movement

local _moveConnection = Movement.MouseDrag:Connect(function(newCF)
	if not ishared.ForceMoveObject then
		return
	end
	local selection = Selection:Get()
	if #selection == 0 then
		return
	end

	if not MoveDragging then
		MoveDragging = true
		MoveOffsets = {}

		local center = getSelectionCenter()
		MoveStartPivot = CFrame.new(center)

		for _, obj in ipairs(selection) do
			if isMovable(obj) then
				local pivot = getObjectPivot(obj)
				if pivot ~= nil then
					table.insert(MoveOffsets, {
						obj = obj,
						pos = MoveStartPivot:ToObjectSpace(pivot),
						size = getObjectExtents(obj),
					})
				end
			end
		end
	end

	local snappedPos = snapVec3(newCF.Position)
	local snappedPivot = CFrame.new(snappedPos) * (newCF - newCF.Position)

	for _, offset in ipairs(MoveOffsets) do
		local obj = offset.obj
		if obj and obj.Parent then
			local finalCF = snappedPivot * offset.pos
			setObjectCFrame(obj, finalCF)
		end
	end
end)

--  Rotation

local _rotationConnection = Rotation.MouseDrag:Connect(function(newCF)
	if not ishared.ForceMoveObject then
		return
	end
	local selection = Selection:Get()
	if #selection == 0 then
		return
	end

	if not RotDragging then
		RotDragging = true
		RotOffsets = {}

		local center = getSelectionCenter()
		RotStartPivot = CFrame.new(center)

		for _, obj in ipairs(selection) do
			if isMovable(obj) then
				local pivot = getObjectPivot(obj)
				if pivot ~= nil then
					table.insert(RotOffsets, {
						obj = obj,
						rel = RotStartPivot:ToObjectSpace(pivot),
					})
				end
			end
		end
	end

	-- Rotation is already snapped by the Handles gizmo
	local snappedCF = newCF

	for _, offset in ipairs(RotOffsets) do
		local obj = offset.obj
		if obj and obj.Parent then
			setObjectCFrame(obj, snappedCF * offset.rel)
		end
	end
end)

--  Scale / Resize

local _resizeConnection = Resize.MouseDrag:Connect(function(newCF, newSize)
	if not ishared.ForceMoveObject then
		return
	end
	local selection = Selection:Get()
	if #selection == 0 then
		return
	end

	if not ScaleDragging then
		ScaleDragging = true
		ScaleOffsets = {}

		local center = getSelectionCenter()
		ScaleStartPivot = CFrame.new(center)

		for _, obj in ipairs(selection) do
			if isMovable(obj) then
				local pivot = getObjectPivot(obj)
				if pivot ~= nil then
					local entry = {
						obj = obj,
						rel = ScaleStartPivot:ToObjectSpace(pivot),
						startSize = getObjectExtents(obj),
						lastScale = 1,
					}

					table.insert(ScaleOffsets, entry)
				end
			end
		end
	end

	local snappedSize = snapVec3(newSize)

	for _, offset in ipairs(ScaleOffsets) do
		local obj = offset.obj
		if obj and obj.Parent then
			if isModel(obj) then
				-- Compute a uniform target scale factor relative to drag-start size,
				-- then derive the per-frame delta so ScaleTo stays non-cumulative.
				local startSize = offset.startSize
				local avgStart = (startSize.X + startSize.Y + startSize.Z) / 3
				local avgNew = (snappedSize.X + snappedSize.Y + snappedSize.Z) / 3
				local targetScale = math.max(avgNew / avgStart, 0.001)
				local delta = targetScale / offset.lastScale
				obj:ScaleTo(delta)
				offset.lastScale = targetScale
				obj:PivotTo(newCF * offset.rel)
			else
				-- BasePart: apply size and position directly
				obj.Size = snappedSize
				obj.CFrame = newCF * offset.rel
			end
		end
	end
end)

local handlestype = "MOVEMENT"

-- Read Offsets:
-- 0, 4, 8 = Position (x,y,z) (Vector3)
-- 12, 16, 20, 24 = Rotation (x,y,z,w) (Quaternion)
-- 28, 32, 36 = Scale (x,y,z) (Vector3)

--  Selection signals

Selection.SelectionAdded:Connect(function(selected)
	Movement.Adornee = nil
	Resize.Adornee = nil
	Rotation.Adornee = nil

	MoveDragging = false
	RotDragging = false
	ScaleDragging = false
	MoveOffsets = {}
	RotOffsets = {}
	ScaleOffsets = {}

	if selected then
		if not isMovable(selected) then
			return
		end
		if handlestype == "MOVEMENT" then
			Movement.Adornee = selected
		elseif handlestype == "SCALE" then
			Resize.Adornee = selected
		elseif handlestype == "ROTATE" then
			Rotation.Adornee = selected
		end
	end
end)

local function updateAdornees()
	local selected = Selection:Get()[1]
	Movement.Adornee = nil
	Resize.Adornee = nil
	Rotation.Adornee = nil

	if selected and isMovable(selected) then
		if handlestype == "MOVEMENT" then
			Movement.Adornee = selected
		elseif handlestype == "SCALE" then
			Resize.Adornee = selected
		elseif handlestype == "ROTATE" then
			Rotation.Adornee = selected
		end
	end
end

--  Focus

local function Focus()
	local selected = Selection:Get()[1]
	if not selected then
		return
	end
	local padding = 20

	-- Works for both BaseParts (via CFrame.Position) and Models (via GetPivot)
	local pivot = getObjectPivot(selected)
	if not pivot then
		return
	end
	local partPos = pivot.Position

	local camCF = freecam.GetCFrame()
	local dir = camCF.Position - partPos
	if dir:Magnitude() < 1e-4 then
		dir = Vector3.new(0, 0, -1)
	else
		dir = dir:Unit()
	end

	local newCamPos = partPos + dir * padding
	_focusTargetCF = CFrame.lookAt(newCamPos, partPos)
	_focusAlpha = 0
end

--  Render loop

renderer.Pool.new("gizmo", function()
	Movement.render(Movement, renderer, game)
	Resize.render(Resize, renderer, game)
	Rotation.render(Rotation, renderer, game)

	local selection = Selection:Get()
	local selected = selection[1]

	-- Reset dragging states when mouse is released
	if lib.IsMouseButtonDown(const.MouseButton.MOUSE_BUTTON_LEFT) == 0 then
		MoveDragging = false
		RotDragging = false
		ScaleDragging = false
	end

	if selected then
		if not isMovable(selected) then
			return
		end

		if handlestype == "MOVEMENT" then
			if not Movement.Transform then
				return
			end
		end

		if lib.IsKeyDown(const.KeyboardKey.KEY_F) == 1 then
			Focus()
		end

		if lib.IsKeyPressed(const.KeyboardKey.KEY_Z) == 1 then
			local center = getSelectionCenter()
			if center then
				local camCF = freecam.GetCFrame()
				local dir = (center - camCF.Position):Unit()
				local zoomAmount = 10

				if lib.IsKeyDown(const.KeyboardKey.KEY_LEFT_CONTROL) == 1 then
					zoomAmount = -zoomAmount
				end

				local newPos = camCF.Position + dir * zoomAmount
				_focusTargetCF = CFrame.lookAt(newPos, center)
				_focusAlpha = 0
			end
		end

		if lib.IsKeyPressed(const.KeyboardKey.KEY_HOME) == 1 then
			freecam.SetCFrame(CFrame.new(Vector3.new(0, 20, 40), Vector3.zero))
		end
	else
		MoveDragging = false
		RotDragging = false
		ScaleDragging = false
		MoveOffsets = {}
		RotOffsets = {}
		ScaleOffsets = {}
	end

	if _focusTargetCF then
		_focusAlpha = math.min(_focusAlpha + 0.08, 1)
		freecam.SetCFrame(_focusTargetCF)

		if _focusAlpha >= 1 then
			_focusTargetCF = nil
		end
	end
end)

game.EngineSignal:Connect(function(Route)
	if Route == "CameraFocus" then
		Focus()
	end
end)

--  Toolbar

repeat
	task.wait()
until ishared.NewCategoryToolbar
local NewCategoryToolbar = ishared.NewCategoryToolbar

NewCategoryToolbar:Fire("Tools", {
	elements = {
		{
			type = "ImageButton",
			text = "Move",
			callback = function()
				handlestype = "MOVEMENT"
				updateAdornees()
			end,
			hoverTransparency = 0.5,
			hoverColor = Color3.new(0, 0, 0),
			roundness = 0.2,
			texture = KinemiumIconLoader.ToTexture("./src/assets/images/icons/Move.png"),
		},
		{
			type = "ImageButton",
			callback = function()
				handlestype = "ROTATE"
				updateAdornees()
			end,
			hoverTransparency = 0.5,
			text = "Rotate",
			hoverColor = Color3.new(0, 0, 0),
			roundness = 0.2,
			texture = KinemiumIconLoader.ToTexture("./src/assets/images/icons/Rotate.png"),
		},
		{
			type = "ImageButton",
			text = "Resize",
			callback = function()
				handlestype = "SCALE"
				updateAdornees()
			end,
			hoverTransparency = 0.5,
			hoverColor = Color3.new(0, 0, 0),
			roundness = 0.2,
			texture = KinemiumIconLoader.ToTexture("./src/assets/images/icons/Size.png"),
		},
		{
			type = "Separator",
		},
		{
			type = "Custom",
			width = 250,
			render = function(arect, data)
				local x, y = data.x, data.y
				local width, height = data.width, data.height + 25

				lib.DrawRectangle(x, y, width, height, raylib.const.WHITE)

				local textboxWidth = 60
				local textboxHeight = height
				local textboxX = x + width - textboxWidth - 10
				local textboxY = y

				gridInput:drawWithExtras(textboxX, textboxY, textboxWidth, textboxHeight)
				rotateGrid:drawWithExtras(textboxX + textboxWidth + 2, textboxY, textboxWidth, textboxHeight)
			end,
		},
	},
})
