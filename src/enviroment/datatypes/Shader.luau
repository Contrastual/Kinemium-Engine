local Shader = {}
Shader.__index = Shader

local raylib = require("@raylib")
local util = require("@kineshader")

function Shader.new(source)
	local self = setmetatable({}, Shader)

	self._vertex = source.vertex
	self._fragment = source.fragment
	self._shader = raylib.lib.LoadShader(source.vertex, source.fragment)
	return self
end

function Shader:SetUniform(name, value, isFloat: boolean)
	if self._shader then
		if type(value) == "number" then
			if isFloat then
				util.SetShaderValueRaw(
					self._shader,
					name,
					value,
					raylib.const.ShaderUniformDataType.SHADER_UNIFORM_FLOAT
				)
			else
				util.SetShaderValueRaw(self._shader, name, value, raylib.const.ShaderUniformDataType.SHADER_UNIFORM_INT)
			end
		elseif type(value) == "table" then
			if value.__type then
				if value.__type == "Vector3" then
					util.SetShaderValueRaw(
						self._shader,
						name,
						{ value.X, value.Y, value.Z },
						raylib.const.ShaderUniformDataType.SHADER_UNIFORM_VEC3
					)
				elseif value.__type == "CFrame" then
					util.SetShaderValueRaw(
						self._shader,
						name,
						{ value.Position.X, value.Position.Y, value.Position.Z },
						raylib.const.ShaderUniformDataType.SHADER_UNIFORM_VEC3
					)
				elseif value.__type == "Color3" then
					util.SetShaderValueRaw(
						self._shader,
						name,
						{ value.R, value.G, value.B },
						raylib.const.ShaderUniformDataType.SHADER_UNIFORM_VEC3
					)
				elseif value.__type == "Color4" then
					util.SetShaderValueRaw(
						self._shader,
						name,
						{ value.R, value.G, value.B, value.A },
						raylib.const.ShaderUniformDataType.SHADER_UNIFORM_VEC4
					)
				elseif value.__type == "Vector2" then
					util.SetShaderValueRaw(
						self._shader,
						name,
						{ value.X, value.Y },
						raylib.const.ShaderUniformDataType.SHADER_UNIFORM_VEC2
					)
				elseif value.__type == "UDim2" then
					util.SetShaderValueRaw(
						self._shader,
						name,
						{ value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset },
						raylib.const.ShaderUniformDataType.SHADER_UNIFORM_VEC4
					)
				elseif value.__type == "UDim" then
					util.SetShaderValueRaw(
						self._shader,
						name,
						{ value.Scale, value.Offset },
						raylib.const.ShaderUniformDataType.SHADER_UNIFORM_VEC2
					)
				end
			else
				local valueCount = #value
				if valueCount == 4 then
					util.SetShaderValueRaw(
						self._shader,
						name,
						value,
						raylib.const.ShaderUniformDataType.SHADER_UNIFORM_VEC4
					)
				elseif valueCount == 3 then
					util.SetShaderValueRaw(
						self._shader,
						name,
						value,
						raylib.const.ShaderUniformDataType.SHADER_UNIFORM_VEC3
					)
				elseif valueCount == 2 then
					util.SetShaderValueRaw(
						self._shader,
						name,
						value,
						raylib.const.ShaderUniformDataType.SHADER_UNIFORM_VEC2
					)
				end
			end
		end
	end
end

function Shader:GetUniformLoc(field)
	return raylib.lib.GetShaderLocation(self._shader, field)
end

return Shader
