local Instance = require("@Instance")
local signal = require("@Kinemium.signal")
local Region3int16 = require("@Region3int16")
local Color3 = require("@Color3")
local Enum = require("@Enummap")
local Vector3int16 = require("@Vector3int16")
local CFrame = require("@CFrame")

local Terrain = Instance.new("Terrain")

Terrain.InitRenderer = function(renderer, renderer_signal)
	local CHUNK_SIZE = 16

	local function worldToChunk(x, y, z)
		return math.floor(x / CHUNK_SIZE), math.floor(y / CHUNK_SIZE), math.floor(z / CHUNK_SIZE)
	end

	local function chunkKey(cx, cy, cz)
		return cx .. "," .. cy .. "," .. cz
	end

	Terrain:SetProperties({
		Decoration = true,
		GrassLength = 1,

		MaterialColors = "",
		MaxExtents = Region3int16.new(Vector3int16.new(-512, -128, -512), Vector3int16.new(512, 256, 512)),
		WaterColor = Color3.new(0, 0, 0),
		WaterReflectance = 0,
		WaterTransparency = 0,
		WaterWaveSize = 0,
		WaterWaveSpeed = 0,
		_chunks = {},
	})

	local function newChunk(cx, cy, cz)
		local key = chunkKey(cx, cy, cz)

		local chunk = {
			cx = cx,
			cy = cy,
			cz = cz,
			voxels = {}, -- 3D table [x][y][z]
			mesh = nil,
			dirty = true,
		}

		Terrain._chunks[key] = chunk
		return chunk
	end

	function Terrain:_setVoxel(wx, wy, wz, material, occupancy)
		local cx, cy, cz = worldToChunk(wx, wy, wz)
		local key = chunkKey(cx, cy, cz)

		local chunk = Terrain._chunks[key] or newChunk(cx, cy, cz)

		local lx = wx - cx * CHUNK_SIZE
		local ly = wy - cy * CHUNK_SIZE
		local lz = wz - cz * CHUNK_SIZE

		chunk.voxels[lx] = chunk.voxels[lx] or {}
		chunk.voxels[lx][ly] = chunk.voxels[lx][ly] or {}

		chunk.voxels[lx][ly][lz] = {
			material = material,
			occupancy = occupancy,
		}

		chunk.dirty = true
	end

	function Terrain:StartRendering()
		renderer.Add3DStack(function()
			for _, chunk in pairs(Terrain._chunks) do
				if chunk.mesh then
					chunk.mesh:Draw()
				end
			end
		end)
	end

	return Terrain
end

return Terrain
