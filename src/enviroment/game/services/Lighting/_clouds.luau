local clouds = {}
local raylib = require("@raylib")
local lib = raylib.lib
local const = raylib.const
local structs = raylib.structs
local kineshader = require("@kineshader")

function clouds.init()
	local mesh = lib.GenMeshPlane(10000, 10000, 1, 1)
	local cloudsShader = lib.LoadShader("./src/assets/shaders/clouds.vs", "./src/assets/shaders/clouds.fs")

	local model = lib.LoadModelFromMesh(mesh)
	local materialsPtr = zune.ffi.ptrFromAddress(zune.mem.slice(model, structs.Model:offset("materials"), 8))
	local shaderOffset = structs.Material:offset("shader")
	materialsPtr:write(shaderOffset, cloudsShader, 0, structs.Shader:size())

	return {
		render = function(cameraPos)
			kineshader.SetShaderValueRaw(
				cloudsShader,
				"time",
				lib.GetTime(),
				const.ShaderUniformDataType.SHADER_UNIFORM_FLOAT
			)

			kineshader.SetShaderValueRaw(
				cloudsShader,
				"resolution",
				{ lib.GetScreenWidth(), lib.GetScreenHeight() },
				const.ShaderUniformDataType.SHADER_UNIFORM_VEC2
			)

			lib.rlDisableBackfaceCulling()
			lib.rlSetBlendMode(const.BlendMode.BLEND_ALPHA)
			lib.rlDisableDepthMask()
			lib.DrawModel(model, vector.create(cameraPos.X, 300, cameraPos.Z), 1, const.WHITE)
			lib.rlEnableDepthMask()
			lib.rlEnableBackfaceCulling()
		end,
	}
end

return clouds
