local Vector2 = require("@Vector2")
local Vector3 = require("@Vector3")
local UDim2 = require("@UDim2")
local Enum = require("@EnumMap")
local raylib = require("@raylib")

local lib = raylib.lib
local const = raylib.const
local structs = raylib.structs

local propTable = {
	Name = "SurfaceGui",
	Enabled = true,
	Adornee = nil,
	Face = Enum.NormalId.Front,
	CanvasSize = Vector2.new(800, 600),
	PixelsPerStud = 50,
	SizingMode = Enum.SurfaceGuiSizingMode.FixedSize,
	AlwaysOnTop = false,
	LightInfluence = 1,
	Brightness = 1,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	ZOffset = 0,
	Size = UDim2.new(0, 800, 0, 600),
	RenderOffset = Vector2.new(0, 0),
	BaseClass = "UIContainer",
}

local function getAdornee(instance)
	if instance.Adornee then
		return instance.Adornee
	end
	return instance.Parent
end

local function getFaceSize(size, face)
	if face == Enum.NormalId.Front or face == Enum.NormalId.Back then
		return size.X, size.Y
	elseif face == Enum.NormalId.Left or face == Enum.NormalId.Right then
		return size.Z, size.Y
	elseif face == Enum.NormalId.Top or face == Enum.NormalId.Bottom then
		return size.X, size.Z
	end
	return 1, 1
end

local function getFaceCorners(cf, size, face)
	local hX = size.X * 0.5
	local hY = size.Y * 0.5
	local hZ = size.Z * 0.5
	local pad = 0.005

	if face == Enum.NormalId.Front then
		return cf * Vector3.new(-hX, hY, -hZ - pad),
			cf * Vector3.new(hX, hY, -hZ - pad),
			cf * Vector3.new(hX, -hY, -hZ - pad),
			cf * Vector3.new(-hX, -hY, -hZ - pad)
	elseif face == Enum.NormalId.Back then
		return cf * Vector3.new(hX, hY, hZ + pad),
			cf * Vector3.new(-hX, hY, hZ + pad),
			cf * Vector3.new(-hX, -hY, hZ + pad),
			cf * Vector3.new(hX, -hY, hZ + pad)
	elseif face == Enum.NormalId.Left then
		return cf * Vector3.new(-hX - pad, hY, hZ),
			cf * Vector3.new(-hX - pad, hY, -hZ),
			cf * Vector3.new(-hX - pad, -hY, -hZ),
			cf * Vector3.new(-hX - pad, -hY, hZ)
	elseif face == Enum.NormalId.Right then
		return cf * Vector3.new(hX + pad, hY, -hZ),
			cf * Vector3.new(hX + pad, hY, hZ),
			cf * Vector3.new(hX + pad, -hY, hZ),
			cf * Vector3.new(hX + pad, -hY, -hZ)
	elseif face == Enum.NormalId.Top then
		return cf * Vector3.new(-hX, hY + pad, -hZ),
			cf * Vector3.new(hX, hY + pad, -hZ),
			cf * Vector3.new(hX, hY + pad, hZ),
			cf * Vector3.new(-hX, hY + pad, hZ)
	elseif face == Enum.NormalId.Bottom then
		return cf * Vector3.new(-hX, -hY - pad, hZ),
			cf * Vector3.new(hX, -hY - pad, hZ),
			cf * Vector3.new(hX, -hY - pad, -hZ),
			cf * Vector3.new(-hX, -hY - pad, -hZ)
	end
	return Vector3.new(0, 0, 0), Vector3.new(0, 0, 0), Vector3.new(0, 0, 0), Vector3.new(0, 0, 0)
end

return {
	class = "SurfaceGui",

	callback = function(instance, renderer, datamodel)
		instance:SetProperties(propTable)

		if _G.IsHeadless or not renderer then
			return instance
		end

		local rtx = nil
		local render2dId = nil
		local render3dId = nil

		local function updateTextureSize()
			local w, h = 800, 600
			if instance.SizingMode == Enum.SurfaceGuiSizingMode.FixedSize then
				w = math.max(1, math.floor(instance.CanvasSize.X or 800))
				h = math.max(1, math.floor(instance.CanvasSize.Y or 600))
			elseif instance.SizingMode == Enum.SurfaceGuiSizingMode.PixelsPerStud then
				local adornee = getAdornee(instance)
				if adornee and adornee.Size then
					local fw, fh = getFaceSize(adornee.Size, instance.Face)
					w = math.max(1, math.floor(fw * (instance.PixelsPerStud or 50)))
					h = math.max(1, math.floor(fh * (instance.PixelsPerStud or 50)))
				end
			end

			local tex = zune.mem.slice(rtx, structs.RenderTexture:offset("texture"), structs.Texture:size())
			local texW = buffer.readi32(tex, 4)
			local texH = buffer.readi32(tex, 8)
			if not rtx or texW ~= w or texH ~= h then
				if rtx then
					lib.UnloadRenderTexture(rtx)
				end
				rtx = lib.LoadRenderTexture(w, h)
				lib.SetTextureFilter(tex, const.TextureFilter.TEXTURE_FILTER_TRILINEAR)
				lib.SetTextureWrap(tex, const.TextureWrap.TEXTURE_WRAP_CLAMP)
			end

			instance.Size = UDim2.new(0, w, 0, h)
			return w, h
		end

		updateTextureSize()

		render2dId = renderer.Pool.new("2d", function()
			if not instance.Enabled then
				return
			end

			updateTextureSize()

			lib.BeginTextureMode(rtx)
			lib.ClearBackground(const.BLANK)

			for _, child in pairs(instance:GetChildren()) do
				if child.render then
					child.render(lib, child, lib.GetFrameTime(), structs, renderer, datamodel)
				end
			end

			lib.EndTextureMode()
		end)

		render3dId = renderer.Pool.new("3d", function()
			if not instance.Enabled or not rtx then
				return
			end

			local adornee = getAdornee(instance)
			if not adornee or not adornee.CFrame or not adornee.Size then
				return
			end

			local tl, tr, br, bl = getFaceCorners(adornee.CFrame, adornee.Size, instance.Face)

			local tex = zune.mem.slice(rtx, structs.RenderTexture:offset("texture"), structs.Texture:size())
			local texId = buffer.readu32(tex, 0)

			if instance.AlwaysOnTop then
				lib.rlDisableDepthTest()
			end

			lib.rlSetTexture(texId)
			lib.rlBegin(7) -- GL_QUADS

			lib.rlColor4ub(255, 255, 255, 255)

			-- Render texture coordinates need Y flip usually
			lib.rlTexCoord2f(0, 1)
			lib.rlVertex3f(tl.X, tl.Y, tl.Z)

			lib.rlTexCoord2f(0, 0)
			lib.rlVertex3f(bl.X, bl.Y, bl.Z)

			lib.rlTexCoord2f(1, 0)
			lib.rlVertex3f(br.X, br.Y, br.Z)

			lib.rlTexCoord2f(1, 1)
			lib.rlVertex3f(tr.X, tr.Y, tr.Z)

			lib.rlEnd()
			lib.rlSetTexture(0)

			if instance.AlwaysOnTop then
				lib.rlEnableDepthTest()
			end
		end)

		instance.Changed:Connect(function(prop)
			if prop == "Enabled" then
				if instance.Enabled then
					updateTextureSize()
				end
			elseif
				prop == "Adornee"
				or prop == "Face"
				or prop == "CanvasSize"
				or prop == "PixelsPerStud"
				or prop == "SizingMode"
			then
				updateTextureSize()
			end
		end)

		instance.Destroying:Connect(function()
			if render2dId then
				renderer.Pool.Destroy(render2dId)
			end
			if render3dId then
				renderer.Pool.Destroy(render3dId)
			end
			if rtx then
				lib.UnloadRenderTexture(rtx)
				rtx = nil
			end
		end)

		-- Expose a method for children to get the relative mouse position on this SurfaceGui
		instance.GetRelativeMousePosition = function()
			local adornee = getAdornee(instance)
			if not adornee or not adornee.CFrame or not adornee.Size then
				return nil
			end

			local camera = datamodel and datamodel.Workspace and datamodel.Workspace.Camera
			if not camera or not camera._raylibcam then
				return nil
			end

			local rayInfo = require("../../../modules/raycast"):GetMouseRay(camera._raylibcam)
			local ray = rayInfo.ray

			local tl, tr, br, bl = getFaceCorners(adornee.CFrame, adornee.Size, instance.Face)

			-- Ray-plane intersection
			local normal = (tr - tl):Cross(bl - tl):Unit()
			local collision = lib.GetRayCollisionPlane(ray, tl, normal)

			if collision.hit == 1 then
				-- Check if within bounds and convert to UV
				local p = Vector3.new(collision.point.x, collision.point.y, collision.point.z)
				local v = p - tl
				local xDir = (tr - tl)
				local yDir = (bl - tl)
				local xSize = xDir:Magnitude()
				local ySize = yDir:Magnitude()

				if xSize > 0 and ySize > 0 then
					local x = v:Dot(xDir:Unit()) / xSize
					local y = v:Dot(yDir:Unit()) / ySize

					if x >= 0 and x <= 1 and y >= 0 and y <= 1 then
						return Vector2.new(x * instance.CanvasSize.X, y * instance.CanvasSize.Y)
					end
				end
			end
			return nil
		end

		return instance
	end,

	inherit = function(tble)
		for prop, val in pairs(propTable) do
			tble[prop] = val
		end
	end,
}
