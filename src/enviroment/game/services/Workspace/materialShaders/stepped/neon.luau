return function(renderer, game, rl)
	local ki3d = require("@ki3d")
	local mesh = renderer.Mesh
	local shader = renderer.Shader
	local const = rl.const

	local neon = ki3d.filters.new("neon", {
		disableauto = true,
		shader = {
			vertex = nil,
			fragment = "./src/assets/shaders/materials/neon.fs",
		},

		setuniforms = function(self, runtime) end,
	})
	return neon
end
