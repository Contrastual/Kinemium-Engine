return function(renderer, game, rl)
	local ki3d = require("@ki3d")
	local mesh = renderer.Mesh
	local shader = renderer.Shader
	local const = rl.const

	local glass = ki3d.filters.new("glass", {
		disableauto = true,
		shader = {
			vertex = "./src/assets/shaders/materials/glass.vs",
			fragment = "./src/assets/shaders/materials/glass.fs",
		},

		tint = { 0.7, 0.9, 1.0 },

		setuniforms = function(self, runtime)
			local shaderobj = runtime.shaderobj
			local position = renderer.Freecam.ToVectorShader()

			shader.SetShaderValueRaw(shaderobj, "tintColor", self.tint, const.ShaderUniformDataType.SHADER_UNIFORM_VEC3)
			shader.SetShaderValueRaw(shaderobj, "viewPos", position, const.ShaderUniformDataType.SHADER_UNIFORM_VEC3)
		end,
	})
	return glass
end
