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
local renderer = rlservice.renderer
local Selection = game:GetService("Selection")
local freecam = renderer.Freecam
local _focusTargetCF = nil
local vend = KinemiumFontService.GetDefaultFont()
local _focusAlpha = 0
local KinemiumIconLoader = game:GetService("KinemiumIconLoader")
local grid = 1
local rotationStep = 15
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
	return math.round(v / grid) * grid
end

local function snapVec3(v)
	return Vector3.new(snap(v.X), snap(v.Y), snap(v.Z))
end

local function isMovable(object)
	return object:IsA("BasePart") or object:GetMetadata("IsMovable")
end

local function getSelectionCenter()
	local selection = Selection:Get()
	if #selection == 0 then
		return nil
	end

	local sum = Vector3.zero
	local count = 0

	for _, obj in ipairs(selection) do
		if obj.BaseClass == "BasePart" then
			sum += obj.CFrame.Position
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
			grid = tonumber(new)
		else
			grid = 1
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
			rotationStep = tonumber(new)
		else
			rotationStep = 15
		end
		if Rotation then
			Rotation.RotationSnap = rotationStep
		end
	end,
})

local gizmo = import("@gizmo")
local _flags = gizmo.Flags
Rotation.RotationSnap = rotationStep

local _moveConnection = Movement.MouseDrag:Connect(function(newCF)
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
				table.insert(
					MoveOffsets,
					{ obj = obj, pos = MoveStartPivot:ToObjectSpace(obj.CFrame), size = obj.Size }
				)
			end
		end
	end

	local snappedPos = snapVec3(newCF.Position)
	local snappedPivot = CFrame.new(snappedPos) * (newCF - newCF.Position)

	for _, offset in ipairs(MoveOffsets) do
		local part = offset.obj
		if part and part.Parent then
			local finalCF = snappedPivot * offset.pos
			if part.CFrame then
				part.CFrame = finalCF
			end
		end
	end
end)

local _rotationConnection = Rotation.MouseDrag:Connect(function(newCF)
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
				table.insert(RotOffsets, { obj = obj, rel = RotStartPivot:ToObjectSpace(obj.CFrame) })
			end
		end
	end

	-- Rotation is already snapped by Handles/gizmo
	local snappedCF = newCF

	for _, offset in ipairs(RotOffsets) do
		local part = offset.obj
		if part and part.Parent then
			part.CFrame = snappedCF * offset.rel
		end
	end
end)

local _resizeConnection = Resize.MouseDrag:Connect(function(newCF, newSize)
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
				table.insert(ScaleOffsets, {
					obj = obj,
					rel = ScaleStartPivot:ToObjectSpace(obj.CFrame),
					startSize = obj.Size,
				})
			end
		end
	end

	local snappedSize = snapVec3(newSize)

	for _, offset in ipairs(ScaleOffsets) do
		local part = offset.obj
		if part and part.Parent then
			-- Apply scale to individual part size
			part.Size = snappedSize
			-- Update position to keep group relative
			part.CFrame = newCF * offset.rel
		end
	end
end)

local handlestype = "MOVEMENT"

-- Read Offsets:
-- 0, 4, 8 = Position (x,y,z) (Vector3)
-- 12, 16, 20, 24 = Rotation (x,y,z,w) (Quaternion)
-- 28, 32, 36 = Scale (x,y,z) (Vector3)

-- Signal connections

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

local function Focus()
	local selected = Selection:Get()[1]
	local padding = 20

	local partPos = selected.CFrame.Position
	local camCF = freecam.GetCFrame()

	local dir = (camCF.Position - partPos)
	if dir:Magnitude() < 1e-4 then
		dir = Vector3.new(0, 0, -1)
	else
		dir = dir:Unit()
	end

	local newCamPos = partPos + dir * padding
	_focusTargetCF = CFrame.lookAt(newCamPos, partPos)
	_focusAlpha = 0
end

renderer.Pool.new("gizmo", function()
	Movement.render(Movement, renderer, game)
	Resize.render(Resize, renderer, game)
	Rotation.render(Rotation, renderer, game)

	local selection = Selection:Get()
	local selected = selection[1]

	-- Reset dragging states if mouse is up
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
		elseif handlestype == "SCALE" then
			-- No per-frame connection needed anymore
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
		MoveOffsets = {}
		RotOffsets = {}
	end
	if _focusTargetCF then
		local _camCF = freecam.GetCFrame()

		_focusAlpha = math.min(_focusAlpha + 0.08, 1) -- speed (0.08 slower, 0.2 faster)
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

-- Toolbar functionality
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
			texture = KinemiumIconLoader.ToTexture("./src/assets/images/icons/Move.svg"),
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
			texture = KinemiumIconLoader.ToTexture("./src/assets/images/icons/Rotate.svg"),
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
			texture = KinemiumIconLoader.ToTexture("./src/assets/images/icons/Size.svg"),
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

				local textboxWidth = 60 -- small width for numbers
				local textboxHeight = height -- keep full rectangle height
				local textboxX = x + width - textboxWidth - 10 -- right edge with 10px padding
				local textboxY = y -- top aligned

				-- both textboxes occupy the same vertical space
				gridInput:drawWithExtras(textboxX, textboxY, textboxWidth, textboxHeight)
				rotateGrid:drawWithExtras(textboxX + textboxWidth + 2, textboxY, textboxWidth, textboxHeight)
			end,
		},
	},
})
