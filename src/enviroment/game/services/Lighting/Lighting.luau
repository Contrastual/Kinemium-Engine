local Instance = require("@Instance")
local Vector3 = require("@Vector3")
local raylib = require("@raylib")
local const = raylib.const
local lib = raylib.lib
local rlstructs = raylib.structs
local Lighting = Instance.new("Lighting")
local Color3 = require("@Color3")
local PointLights = {}
local clouds = require("./clouds")
local r3d = require("@r3d")
local rlib = r3d.lib

local DAY_TOP = Color3.new(0.090196, 0.6, 0.839216)
local NIGHT_TOP = Color3.fromRGB(10, 15, 35)

function Lighting:AddPointLight(id, position, color, intensity, range)
	for _, obj in pairs(PointLights) do
		if obj.Id == id then
			obj.Position = position
			obj.Color = color
			obj.Intensity = intensity
			obj.Range = range

			return obj
		end
	end
	local light = {
		Id = id,
		Position = position,
		Color = color,
		Intensity = intensity,
		Range = range,
		Enabled = true,
	}
	table.insert(PointLights, light)
	return light
end

function Lighting:ClearLights()
	table.clear(PointLights)
end

function Lighting:RemovePointLight(light)
	for i, v in ipairs(PointLights) do
		if v == light then
			table.remove(PointLights, i)
			return
		end
	end
end

function Lighting:GetPointLights()
	return PointLights
end

function Lighting:ClearPointLights()
	table.clear(PointLights)
end

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

local function setSkyObject(r3d_sky)
	local environment: FFIPointer = rlib.R3D_GetEnvironment()

	local iden = lib.QuaternionIdentity()

	local envbackground = r3d.structs.R3D_EnvBackground:new({
		sky = r3d_sky,
		energy = 1.0,
		rotation = iden,
		skyBlur = 0,
	})

	local offset = r3d.structs.R3D_Environment:offset("background")
	environment:write(offset, envbackground, 0, r3d.structs.R3D_EnvBackground:size())

	rlib.R3D_SetEnvironment(environment)
end

local function loadSky(cubemapPath)
	local r3d_sky = rlib.R3D_LoadCubemap(cubemapPath, 5)
	setSkyObject(r3d_sky)
end

local function setAllEnvironmentEffects()
	local environment: FFIPointer = rlib.R3D_GetEnvironment()
	rlib.R3D_SetEnvironment(environment)
end

local function handleSky(skyObject, renderer)
	if skyObject.ClassName == "Sky" then
		loadSky(skyObject.Cubemap)
	end
end

Lighting.InitRenderer = function(renderer, renderer_signal, datamodel)
	if _G.IsHeadless then
		return
	end

	Lighting:SetProperties({
		Ambient = Color3.new(1, 1, 1),
		Brightness = 2.0,
		ColorShift_Top = Color3.fromRGB(255, 255, 255),
		ColorShift_Bottom = Color3.fromRGB(0, 0, 0),
		OutdoorAmbient = Color3.fromRGB(128, 128, 128),
		GlobalShadows = true,
		ClockTime = 14.0,
		GeographicLatitude = 0.0,
		EnableDayCycle = false,

		GetDaylight = function()
			local t = getDayAlpha(Lighting.ClockTime)
			return t
		end,
	})

	local sunDirection = Lighting:GetSunDirection()

	local skyObject = r3d.structs.R3D_ProceduralSky:new({
		sunEnergy = 2,
		sunSize = 0.1,
		sunColor = Color3.new(1, 1, 1):ToRaylib(0),
		sunDirection = sunDirection:ToZuneVector(),
		skyEnergy = 1,

		groundHorizonCurve = 0.5,
		groundHorizonColor = Color3.new(1, 1, 1):ToRaylib(0),
		groundEnergy = 1,
		groundBottomColor = Color3.new(0.7, 0.7, 0.7):ToRaylib(0),

		skyHorizonCurve = 0.2,
		skyTopColor = Color3.new(0.090196, 0.6, 0.839216):ToRaylib(0),
		skyHorizonColor = Color3.new(1, 1, 1):ToRaylib(0),
	})

	if zune.platform.os == "linux" then 
		loadSky("./src/assets/sky/test/images/sky.png")
	else
		local cubemapSky = rlib.R3D_GenProceduralSky(1024, skyObject)
		setSkyObject(cubemapSky)
	end
	setAllEnvironmentEffects()

	local light = rlib.R3D_CreateLight(0) -- R3D_LIGHT_DIR
	rlib.R3D_SetLightDirection(light, vector.create(-1, -1, -1))
	rlib.R3D_SetLightColor(light, raylib.const.WHITE)
	rlib.R3D_SetLightEnergy(light, 1.0)
	rlib.R3D_SetLightActive(light, true)
	rlib.R3D_EnableShadow(light)

	local effectToEnvMap = {
		SSAOEffect = { offset = "ssao", struct = r3d.structs.R3D_EnvSSAO },
		BloomEffect = { offset = "bloom", struct = r3d.structs.R3D_EnvBloom },
		SSGIEffect = { offset = "ssgi", struct = r3d.structs.R3D_EnvSSGI },
		SSILEffect = { offset = "ssil", struct = r3d.structs.R3D_EnvSSIL },
		SSREffect = { offset = "ssr", struct = r3d.structs.R3D_EnvSSR },
		DOFEffect = { offset = "dof", struct = r3d.structs.R3D_EnvDoF },
		FogEffect = { offset = "fog", struct = r3d.structs.R3D_EnvFog },
		TonemapEffect = { offset = "tonemap", struct = r3d.structs.R3D_EnvTonemap },
		ColorEffect = { offset = "color", struct = r3d.structs.R3D_EnvColor },
	}

	local function applyEffectToEnv(effect)
		local map = effectToEnvMap[effect.ClassName]
		if map and effect._r3deffect then
			local envType = r3d.structs.R3D_Environment
			local environment: FFIPointer = rlib.R3D_GetEnvironment()
			environment:write(envType:offset(map.offset), effect._r3deffect, 0, map.struct:size())
		end
	end

	local function handleLightingChild(child)
		if effectToEnvMap[child.ClassName] then
			applyEffectToEnv(child)
			child.Changed:Connect(function()
				applyEffectToEnv(child)
			end)
		end
		handleSky(child, renderer)
	end

	renderer_signal:Connect(function(route, dt)
		if route == "RenderStepped" then
			if Lighting.EnableDayCycle == true then
				Lighting.ClockTime += 0.005

				local sunY = -Lighting:GetSunDirection().Y
				local daylight = math.clamp((sunY + 0.1) / 0.6, 0, 1)

				local skyTop = NIGHT_TOP:Lerp(DAY_TOP, daylight)
				local horizonDay = Color3.new(1, 1, 1)
				local groundDay = Color3.new(1, 1, 1)

				local skyHorizon = Color3.new(0, 0, 0):Lerp(horizonDay, daylight)
				local groundHorizon = Color3.new(0, 0, 0):Lerp(groundDay, daylight)

				buffer.copy(skyObject, r3d.structs.R3D_ProceduralSky:offset("skyTopColor"), skyTop:ToRaylib(0))

				buffer.copy(skyObject, r3d.structs.R3D_ProceduralSky:offset("skyHorizonColor"), skyHorizon:ToRaylib(0))

				buffer.copy(
					skyObject,
					r3d.structs.R3D_ProceduralSky:offset("groundHorizonColor"),
					groundHorizon:ToRaylib(0)
				)

				buffer.copy(
					skyObject,
					r3d.structs.R3D_ProceduralSky:offset("sunDirection"),
					Lighting:GetSunDirection():ToBuffer()
				)

				rlib.R3D_UpdateProceduralSky(cubemapSky, skyObject)
			end
			local blurEffect = Lighting:FindFirstChildOfClass("BlurEffect")

			if blurEffect then
				renderer.Blur.blurRadius = blurEffect.Size
				renderer.Blur:DrawFullBlur(const.WHITE)
			end
		end
	end)

	Lighting.ChildAdded:Connect(handleLightingChild)
end

return Lighting
