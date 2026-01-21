local bufferUtils = {}

local raylib = require("@raylib")
local box2d = require("@box2d")
local box2d_structs = box2d.structs
local const, structs, lib = raylib.const, raylib.structs, raylib.lib

-- Unsigned integers
function bufferUtils:u8(number)
	local buf = buffer.create(1)
	buffer.writeu8(buf, 0, number)
	return buf
end

function bufferUtils:u16(number)
	local buf = buffer.create(2)
	buffer.writeu16(buf, 0, number)
	return buf
end

function bufferUtils:u32(number)
	local buf = buffer.create(4)
	buffer.writeu32(buf, 0, number)
	return buf
end

-- Signed integers
function bufferUtils:i8(number)
	local buf = buffer.create(1)
	buffer.writei8(buf, 0, number)
	return buf
end

function bufferUtils:i16(number)
	local buf = buffer.create(2)
	buffer.writei16(buf, 0, number)
	return buf
end

function bufferUtils:i32(number)
	local buf = buffer.create(4)
	buffer.writei32(buf, 0, number)
	return buf
end

-- Floating point
function bufferUtils:float(number)
	local buf = buffer.create(4)
	buffer.writef32(buf, 0, number)
	return buf
end

function bufferUtils:double(number)
	local buf = buffer.create(8)
	buffer.writef64(buf, 0, number)
	return buf
end

-- Vectors
function bufferUtils:vector2_32(x, y)
	local buf = buffer.create(8)
	buffer.writef32(buf, 0, x)
	buffer.writef32(buf, 4, y)
	return buf
end

function bufferUtils:vector3_32(x, y, z)
	local buf = buffer.create(12)
	buffer.writef32(buf, 0, x)
	buffer.writef32(buf, 4, y)
	buffer.writef32(buf, 8, z)
	return buf
end

--Textures
bufferUtils.extract = {}

function bufferUtils:readi32(ptr)
	return ptr:readi32(0)
end

function bufferUtils:readhexa(ptr)
	local v = tostring(ptr)

	local hex = v:match("0x[%da-fA-F]+")
	if not hex then
		return nil
	end

	return tonumber(hex, 16)
end

function bufferUtils:fcall(func, expected)
	local result = func()
	local read = bufferUtils:readhexa(result)
	if read ~= expected then
		error("Expected " .. expected .. " but got " .. read .. " in FFI call\nOriginal string " .. tostring(result))
	end
	return result
end

function bufferUtils.extract.texture(v)
	local texture = zune.mem.slice(v, structs.RenderTexture:offset("texture"), structs.Texture:size())
	return texture
end

function bufferUtils.extract.maps(model, texture)
	local materials = zune.ffi.ptrFromAddress(zune.mem.slice(model, structs.Model:offset("materials"), 8))

	local maps = materials:readptr(structs.Material:offset("maps"))
	return maps
end

function bufferUtils.extract.material_shader(mainstruct, v)
	local Shader = zune.mem.slice(v, mainstruct:offset("shader"), structs.Shader:size())

	return Shader
end

function bufferUtils.extract.box2d_body_position(object, mainstruct)
	local pos = zune.mem.slice(object, mainstruct:offset("position"), box2d_structs.b2Vec2:size())
	return pos
end

function bufferUtils.extract.mesh_from_model(object)
	local meshes_ptr = zune.ffi.ptrFromAddress(zune.mem.slice(object, structs.Model:offset("meshes"), 8))
	local mesh_0_buf = meshes_ptr:read(0, buffer.create(structs.Mesh:size()), 0, structs.Mesh:size())
	return mesh_0_buf
end

function bufferUtils.extract.set(object, value, struct)
	object:write(0, value, 0, struct:size())
end

function bufferUtils.extract.setModelTexture(maps, texture)
	maps:write(0, texture, 0, structs.Texture:size())
end

-- quaternions

function bufferUtils.EulerDegToQuaternion(euler: any): (number, number, number, number)
    local rx = math.rad(euler.X)
    local ry = math.rad(euler.Y)
    local rz = math.rad(euler.Z)

    local cx, sx = math.cos(rx * 0.5), math.sin(rx * 0.5)
    local cy, sy = math.cos(ry * 0.5), math.sin(ry * 0.5)
    local cz, sz = math.cos(rz * 0.5), math.sin(rz * 0.5)

    local w = cz * cy * cx + sz * sy * sx
    local x = cz * cy * sx - sz * sy * cx
    local y = cz * sy * cx + sz * cy * sx
    local z = sz * cy * cx - cz * sy * sx

    local len = math.sqrt(x*x + y*y + z*z + w*w)
    if len > 0 then
        x, y, z, w = x/len, y/len, z/len, w/len
    else
        x, y, z, w = 0, 0, 0, 1
    end
	
    return x, y, z, w
end

function bufferUtils.EulerToAxisAngle(eulerDeg)
	local qx,qy,qz,qw = bufferUtils.EulerDegToQuaternion(eulerDeg)

    qw = math.max(-1, math.min(1, qw))
    local angleRad = 2 * math.acos(qw)

    local s2 = 1 - qw * qw
    if s2 < 1e-12 then
        return vector.create(1, 0, 0), 0
    end

    local s = math.sqrt(s2)
    local ax, ay, az = qx / s, qy / s, qz / s

    local alen = math.sqrt(ax*ax + ay*ay + az*az)
    if alen == 0 then
        return vector.create(1, 0, 0), 0
    end
    ax, ay, az = ax/alen, ay/alen, az/alen

    return vector.create(ax, ay, az), math.deg(angleRad)
end

return bufferUtils
