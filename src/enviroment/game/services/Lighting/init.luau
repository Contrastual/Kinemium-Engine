local Instance = require("@Instance")
local Color3 = require("@Color3")
local Vector3 = require("@Vector3")
local raylib = require("@raylib")
local const = raylib.const
local lib = raylib.lib
local Lighting = Instance.new("Lighting")

local Stars = {}

local STAR_COUNT = 3000
local STAR_RADIUS = 1000

for i = 1, STAR_COUNT do
	local z = math.random() * 2 - 1
	local theta = math.random() * math.pi * 2
	local r = math.sqrt(1 - z * z)

	table.insert(Stars, {
		pos = Vector3.new(r * math.cos(theta) * STAR_RADIUS, z * STAR_RADIUS, r * math.sin(theta) * STAR_RADIUS),
		size = math.random(),
	})
end

local function DrawStars(camera, intensity)
	local cameraPos = zune.mem.toVector3(camera, 0)

	lib.rlDisableDepthMask()
	lib.rlDisableBackfaceCulling()
	lib.rlSetBlendMode(1) -- alpha blend
	lib.rlDisableDepthTest()

	lib.rlPushMatrix()
	lib.rlTranslatef(cameraPos.X, cameraPos.Y, cameraPos.Z)

	lib.rlBegin(7) -- RL_QUADS
	lib.rlColor4ub(255, 255, 255, intensity)

	for _, star in ipairs(Stars) do
		local size = star.size
		lib.rlVertex3f(star.pos.X - size, star.pos.Y - size, star.pos.Z)
		lib.rlVertex3f(star.pos.X + size, star.pos.Y - size, star.pos.Z)
		lib.rlVertex3f(star.pos.X + size, star.pos.Y + size, star.pos.Z)
		lib.rlVertex3f(star.pos.X - size, star.pos.Y + size, star.pos.Z)
	end

	lib.rlEnd()
	lib.rlPopMatrix()

	lib.rlSetBlendMode(0)
	lib.rlEnableBackfaceCulling()
	lib.rlEnableDepthTest()
	lib.rlEnableDepthMask()
end

local function DrawCelestialBody(texture, direction, camera, distance, size)
	if not texture then
		return
	end

	local cameraPos = zune.mem.toVector3(camera, 0)
	local id = buffer.readi32(texture, 0)

	local sunPos = Vector3.new(
		cameraPos.X + direction.X * distance,
		cameraPos.Y + direction.Y * distance,
		cameraPos.Z + direction.Z * distance
	)

	lib.rlDisableDepthMask()
	lib.rlDisableBackfaceCulling()

	lib.rlSetBlendMode(1)

	lib.rlPushMatrix()
	lib.rlTranslatef(sunPos.X, sunPos.Y, sunPos.Z)

	local camToSun = Vector3.new(sunPos.X - cameraPos.X, sunPos.Y - cameraPos.Y, sunPos.Z - cameraPos.Z)

	local angle = math.atan2(camToSun.X, camToSun.Z) * 180 / math.pi
	lib.rlRotatef(angle, 0, 1, 0)

	local horizontalDist = math.sqrt(camToSun.X * camToSun.X + camToSun.Z * camToSun.Z)
	local pitchAngle = -math.atan2(camToSun.Y, horizontalDist) * 180 / math.pi
	lib.rlRotatef(pitchAngle, 1, 0, 0)

	lib.rlSetTexture(id)
	lib.rlBegin(7)
	lib.rlColor4ub(150, 150, 150, 255)

	lib.rlTexCoord2f(0, 0)
	lib.rlVertex3f(-size, -size, 0)

	lib.rlTexCoord2f(1, 0)
	lib.rlVertex3f(size, -size, 0)

	lib.rlTexCoord2f(1, 1)
	lib.rlVertex3f(size, size, 0)

	lib.rlTexCoord2f(0, 1)
	lib.rlVertex3f(-size, size, 0)

	lib.rlEnd()
	lib.rlSetTexture(0)

	lib.rlPopMatrix()

	lib.rlSetBlendMode(0)
	lib.rlEnableBackfaceCulling()
	lib.rlEnableDepthMask()
	--lib.rlEnableDepthTest()
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function lerpColor(c1, c2, t)
	return Color3.fromRGB(lerp(c1.R, c2.R, t), lerp(c1.G, c2.G, t), lerp(c1.B, c2.B, t))
end

local function getDayAlpha(clockTime)
	return (clockTime % 24) / 24
end

local function DrawNightSky(camera, night)
	if night <= 0.001 then
		return
	end

	local cameraPos = zune.mem.toVector3(camera, 0)
	local size = 300

	lib.rlDisableDepthMask()
	lib.rlDisableBackfaceCulling()
	lib.rlPushMatrix()
	lib.rlTranslatef(cameraPos.X, cameraPos.Y, cameraPos.Z)
	lib.rlBegin(7)

	-- Define cube faces as tables of 4 vertices
	local faces = {
		-- {v0, v1, v2, v3} each vertex is a Vector3
		{
			Vector3.new(-size, size, -size),
			Vector3.new(size, size, -size),
			Vector3.new(size, size, size),
			Vector3.new(-size, size, size),
		}, -- top
		{
			Vector3.new(-size, -size, -size),
			Vector3.new(size, -size, -size),
			Vector3.new(size, -size, size),
			Vector3.new(-size, -size, size),
		}, -- bottom
		{
			Vector3.new(size, -size, -size),
			Vector3.new(size, size, -size),
			Vector3.new(size, size, size),
			Vector3.new(size, -size, size),
		}, -- +X
		{
			Vector3.new(-size, -size, -size),
			Vector3.new(-size, size, -size),
			Vector3.new(-size, size, size),
			Vector3.new(-size, -size, size),
		}, -- -X
		{
			Vector3.new(-size, -size, size),
			Vector3.new(-size, size, size),
			Vector3.new(size, size, size),
			Vector3.new(size, -size, size),
		}, -- +Z
		{
			Vector3.new(-size, -size, -size),
			Vector3.new(-size, size, -size),
			Vector3.new(size, size, -size),
			Vector3.new(size, -size, -size),
		}, -- -Z
	}

	-- Night-to-horizon gradient
	local topColor = Color3.fromRGB(20, 25, 45)
	local bottomColor = Color3.fromRGB(5, 5, 10)

	for _, face in ipairs(faces) do
		for i, vert in ipairs(face) do
			-- Vertices with Y > 0 are "top", Y < 0 are "bottom"
			local t = (vert.Y + size) / (2 * size) -- 0 at bottom, 1 at top
			local color = lerpColor(bottomColor, topColor, t * night)
			lib.rlColor4ub(color.R, color.G, color.B, 255)
			lib.rlVertex3f(vert.X, vert.Y, vert.Z)
		end
	end

	lib.rlEnd()
	lib.rlPopMatrix()
	lib.rlEnableBackfaceCulling()
	lib.rlEnableDepthMask()
end

function Lighting:GetSunDirection()
	local time = self.ClockTime
	local latitude = math.rad(self.GeographicLatitude)
	local declination = math.rad(23.45 * math.sin(math.rad(360 * (284 + time * 15) / 365)))
	local hourAngle = math.rad(15 * (time - 12))

	local elevation = math.asin(
		math.sin(latitude) * math.sin(declination) + math.cos(latitude) * math.cos(declination) * math.cos(hourAngle)
	)
	local azimuth = math.atan2(
		math.sin(hourAngle),
		math.cos(hourAngle) * math.sin(latitude) - math.tan(declination) * math.cos(latitude)
	)

	return Vector3.new(
		math.cos(azimuth) * math.cos(elevation),
		math.sin(elevation),
		math.sin(azimuth) * math.cos(elevation)
	)
end

local function handleSky(skyObject, renderer)
	if skyObject.ClassName == "Sky" then
		local skybox = renderer.skybox
		local cubemapPaths

		if skyObject.Cubemap ~= "" then
			skybox.Load(skyObject.Cubemap)
		else
			cubemapPaths = {
				skyObject.SkyboxRt, -- +X
				skyObject.SkyboxLf, -- -X
				skyObject.SkyboxUp, -- +Y
				skyObject.SkyboxDn, -- -Y
				skyObject.SkyboxFt, -- +Z
				skyObject.SkyboxBk, -- -Z
			}

			local cubemap = skybox.FromCubemap(cubemapPaths)
			if not cubemap then
				return
			end
			skybox.Unload()
			skybox.Load(cubemap)
		end

		print("Reinitialized sky with new Skybox skyObject")
	end
end

Lighting.InitRenderer = function(renderer, renderer_signal, datamodel)
	if _G.IsHeadless then
		return
	end
	local sunTexture = lib.LoadTexture("./src/assets/sky/default/sun.png")
	local moonTexture = lib.LoadTexture("./src/assets/sky/default/moon.png")

	renderer.skybox.Load()

	Lighting:SetProperties({
		Ambient = Color3.fromRGB(128, 128, 128),
		Brightness = 2.0,
		ColorShift_Top = Color3.fromRGB(255, 255, 255),
		ColorShift_Bottom = Color3.fromRGB(0, 0, 0),
		OutdoorAmbient = Color3.fromRGB(128, 128, 128),
		GlobalShadows = true,
		ClockTime = 14.0,
		GeographicLatitude = 0.0,
		EnableDayCycle = false,
	})

	renderer_signal:Connect(function(route, dt)
		if route == "PreGuiRender" then
			local blurEffect = Lighting:FindFirstChildOfClass("BlurEffect")

			if blurEffect then
				renderer.blur.blurRadius = blurEffect.Size
				renderer.blur:DrawFullBlur(const.WHITE)
			end
		end
	end)

	Lighting.ChildAdded:Connect(function(child)
		handleSky(child, renderer)
	end)

	renderer.Before3DRender(function()
		local camera = renderer.camera

		local sunDir = Lighting:GetSunDirection()
		local moonDir = Vector3.new(-sunDir.X, -sunDir.Y, -sunDir.Z) -- Moon opposite to sun

		local t = getDayAlpha(Lighting.ClockTime)
		local night = 1 - math.clamp(math.sin(t * math.pi * 2), 0, 1)
		local daylight = math.clamp(math.sin(t * math.pi * 2), 0, 1)

		renderer.skybox.Draw(camera, 50)

		Lighting.Ambient = lerpColor(
			Color3.fromRGB(20, 20, 40), -- night
			Color3.fromRGB(130, 130, 130), -- day
			daylight
		)

		Lighting.OutdoorAmbient = Lighting.Ambient
		Lighting.Brightness = lerp(0.2, 2.0, daylight)

		if sunDir.Y > 0 then
			DrawCelestialBody(sunTexture, sunDir, camera, 450, 50)
		end

		if moonDir.Y > 0 then
			DrawNightSky(camera, night)
			DrawCelestialBody(moonTexture, moonDir, camera, 450, 50)
			DrawStars(camera, math.floor(255 * night))
		end

		if Lighting.EnableDayCycle then
			Lighting.ClockTime += 0.001
		end
	end)
end

return Lighting
