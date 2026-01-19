local raylib = require("@raylib")
local lib = raylib.lib
local ki3d = {}
local utils = require("@bufferutils")

local shaders = {}
local filters = {}

export type KI3DShader = {
	name: string,
	vertex: string,
	fragment: string,
	shader: FFIPointer,
}

export type KI3DLight = {
	render: () -> ()?,
	range: number,
	color: { r: number, g: number, b: number },
	brightness: number,
	position: { x: number, y: number, z: number },
}

export type KI3DFilter = {
	shader: { vertex: string, fragment: string },
	render: () -> (),
}

local sceneRT
local outputRT
local inputRT
local normalRT
local depthRT

ki3d.color3 = function(x, y, z)
	return { r = x, g = y, b = z }
end

ki3d.vector3 = function(x, y, z)
	return { x = x, y = y, z = z }
end

ki3d.shaders = {
	new = function(name, data: KI3DShader)
		local object = data
		object.name = name
		object.shader = lib.LoadShader(object.vertex, object.fragment)
		shaders[name] = object
		return shaders[name]
	end,

	load = function(name)
		return shaders[name] :: KI3DShader
	end,
}

ki3d.filters = {
	new = function(name, data: KI3DFilter)
		local object = data
		object.name = name
		object.shader = lib.LoadShader(object.shader.vertex, object.shader.fragment)

		filters[name] = object
		return filters[name]
	end,

	load = function(name)
		return filters[name] :: KI3DFilter
	end,
}

ki3d.init = function(screenWidth, screenHeight)
	screenWidth = screenWidth or lib.GetScreenWidth()
	screenHeight = screenHeight or lib.GetScreenHeight()
	sceneRT = lib.LoadRenderTexture(screenWidth, screenHeight)
	normalRT = lib.LoadRenderTexture(screenWidth, screenHeight)
	depthRT = lib.LoadRenderTexture(screenWidth, screenHeight)
	outputRT = lib.LoadRenderTexture(screenWidth, screenHeight)
	inputRT = sceneRT
end

ki3d.Begin3D = function(self)
	if not sceneRT then
		return
	end
	lib.BeginTextureMode(sceneRT)
end

ki3d.End3D = function(self)
	if not sceneRT then
		return
	end
	lib.EndTextureMode()

	local screenWidth = lib.GetRenderWidth()
	local screenHeight = lib.GetRenderHeight()

	for _, filter in pairs(filters) do
		lib.BeginTextureMode(outputRT)
		lib.ClearBackground(raylib.const.BLANK)

		local runtime_lib = {
			lib = lib,
			structs = raylib.structs,
			const = raylib.const,

			texture = utils.extract.texture(inputRT),
			depth = utils.extract.depth(depthRT),
			normal = utils.extract.normal(normalRT),

			width = screenWidth,
			height = screenHeight,
			size = { x = 0, y = 0, width = screenWidth, height = -screenHeight },
			rect = raylib.structs.Rectangle,
		}

		filter:begin(runtime_lib)
		lib.DrawTextureRec(
			runtime_lib.texture,
			runtime_lib.rect:new(runtime_lib.size),
			vector.create(0, 0),
			raylib.const.WHITE
		)
		filter:finish(runtime_lib)

		lib.EndTextureMode()

		inputRT, outputRT = outputRT, inputRT
	end

	self.finalRT = sceneRT
end

ki3d.scene = sceneRT

ki3d.BeginNormals = function(normalShader)
	lib.BeginTextureMode(normalRT)
	lib.BeginShaderMode(normalShader)
end

ki3d.EndNormals = function()
	lib.EndShaderMode()
	lib.EndTextureMode()
end

ki3d.BeginDepth = function(depthShader)
	lib.BeginTextureMode(depthRT)
	lib.BeginShaderMode(depthShader)
end

ki3d.EndDepth = function()
	lib.EndShaderMode()
	lib.EndTextureMode()
end

ki3d.UpdateRenderTextures = function(screenWidth, screenHeight)
	sceneRT = lib.LoadRenderTexture(screenWidth, screenHeight)
	normalRT = lib.LoadRenderTexture(screenWidth, screenHeight)
	depthRT = lib.LoadRenderTexture(screenWidth, screenHeight)
	outputRT = lib.LoadRenderTexture(screenWidth, screenHeight)
end

ki3d.Draw = function(self, camera)
	if not self.finalRT then
		return
	end

	local screenWidth = lib.GetRenderWidth()
	local screenHeight = lib.GetRenderHeight()

	lib.ClearBackground(raylib.const.BLACK)
	lib.BeginBlendMode(raylib.const.BlendMode.BLEND_ALPHA)

	lib.DrawTextureRec(
		utils.extract.texture(self.finalRT),
		raylib.structs.Rectangle:new({ x = 0, y = 0, width = screenWidth, height = -screenHeight }),
		vector.create(0, 0),
		raylib.const.WHITE
	)
	lib.EndBlendMode()
end

return ki3d
