local Instance = require("@Instance")
local signal = require("@Kinemium.signal")
local Region3int16 = require("@Region3int16")
local Color3 = require("@Color3")
local Enum = require("@Enummap")
local Vector3 = require("@Vector3")
local CFrame = require("@CFrame")
local raylib = require("@raylib")

local Terrain = Instance.new("Terrain")

local RL_LINES = 0x0001
local RL_TRIANGLES = 0x0004
local RL_QUADS = 0x0007

local materialColors = {
	grass = Color3.new(0, 1, 0),
	water = Color3.new(0, 0, 1),
}

export type Block = {
	density: number,
	material: string,
	color: typeof(Color3),
}

local EDGE_TABLE = {
	0x0,
	0x109,
	0x203,
	0x30a,
	0x406,
	0x50f,
	0x605,
	0x70c,
	0x80c,
	0x905,
	0xa0f,
	0xb06,
	0xc0a,
	0xd03,
	0xe09,
	0xf00,
	0x190,
	0x99,
	0x393,
	0x29a,
	0x596,
	0x49f,
	0x795,
	0x69c,
	0x99c,
	0x895,
	0xb9f,
	0xa96,
	0xd9a,
	0xc93,
	0xf99,
	0xe90,
	0x230,
	0x339,
	0x33,
	0x13a,
	0x636,
	0x73f,
	0x435,
	0x53c,
	0xa3c,
	0xb35,
	0x83f,
	0x936,
	0xe3a,
	0xf33,
	0xc39,
	0xd30,
	0x3a0,
	0x2a9,
	0x1a3,
	0xaa,
	0x7a6,
	0x6af,
	0x5a5,
	0x4ac,
	0xbac,
	0xaa5,
	0x9af,
	0x8a6,
	0xfaa,
	0xea3,
	0xda9,
	0xca0,
	0x460,
	0x569,
	0x663,
	0x76a,
	0x66,
	0x16f,
	0x265,
	0x36c,
	0xc6c,
	0xd65,
	0xe6f,
	0xf66,
	0x86a,
	0x963,
	0xa69,
	0xb60,
	0x5f0,
	0x4f9,
	0x7f3,
	0x6fa,
	0x1f6,
	0xff,
	0x3f5,
	0x2fc,
	0xdfc,
	0xcf5,
	0xfff,
	0xef6,
	0x9fa,
	0x8f3,
	0xbf9,
	0xaf0,
	0x650,
	0x759,
	0x453,
	0x55a,
	0x256,
	0x35f,
	0x55,
	0x15c,
	0xe5c,
	0xf55,
	0xc5f,
	0xd56,
	0xa5a,
	0xb53,
	0x859,
	0x950,
	0x7c0,
	0x6c9,
	0x5c3,
	0x4ca,
	0x3c6,
	0x2cf,
	0x1c5,
	0xcc,
	0xfcc,
	0xec5,
	0xdcf,
	0xcc6,
	0xbca,
	0xac3,
	0x9c9,
	0x8c0,
	0x8c0,
	0x9c9,
	0xac3,
	0xbca,
	0xcc6,
	0xdcf,
	0xec5,
	0xfcc,
	0xcc,
	0x1c5,
	0x2cf,
	0x3c6,
	0x4ca,
	0x5c3,
	0x6c9,
	0x7c0,
	0x950,
	0x859,
	0xb53,
	0xa5a,
	0xd56,
	0xc5f,
	0xf55,
	0xe5c,
	0x15c,
	0x55,
	0x35f,
	0x256,
	0x55a,
	0x453,
	0x759,
	0x650,
	0xaf0,
	0xbf9,
	0x8f3,
	0x9fa,
	0xef6,
	0xfff,
	0xcf5,
	0xdfc,
	0x2fc,
	0x3f5,
	0xff,
	0x1f6,
	0x6fa,
	0x7f3,
	0x4f9,
	0x5f0,
	0xb60,
	0xa69,
	0x963,
	0x86a,
	0xf66,
	0xe6f,
	0xd65,
	0xc6c,
	0x36c,
	0x265,
	0x16f,
	0x66,
	0x76a,
	0x663,
	0x569,
	0x460,
	0xca0,
	0xda9,
	0xea3,
	0xfaa,
	0x8a6,
	0x9af,
	0xaa5,
	0xbac,
	0x4ac,
	0x5a5,
	0x6af,
	0x7a6,
	0xaa,
	0x1a3,
	0x2a9,
	0x3a0,
	0xd30,
	0xc39,
	0xf33,
	0xe3a,
	0x936,
	0x83f,
	0xb35,
	0xa3c,
	0x53c,
	0x435,
	0x73f,
	0x636,
	0x13a,
	0x33,
	0x339,
	0x230,
	0xe90,
	0xf99,
	0xc93,
	0xd9a,
	0xa96,
	0xb9f,
	0x895,
	0x99c,
	0x69c,
	0x795,
	0x49f,
	0x596,
	0x29a,
	0x393,
	0x99,
	0x190,
	0xf00,
	0xe09,
	0xd03,
	0xc0a,
	0xb06,
	0xa0f,
	0x905,
	0x80c,
	0x70c,
	0x605,
	0x50f,
	0x406,
	0x30a,
	0x203,
	0x109,
	0x0,
}

local TRI_TABLE = {
	{},
	{ 0, 8, 3 },
	{ 0, 1, 9 },
	{ 1, 8, 3, 9, 8, 1 },
	{ 1, 2, 10 },
	{ 0, 8, 3, 1, 2, 10 },
	{ 9, 2, 10, 0, 2, 9 },
	{ 2, 8, 3, 2, 10, 8, 10, 9, 8 },
	{ 3, 11, 2 },
	{ 0, 11, 2, 8, 11, 0 },
	{ 1, 9, 0, 2, 3, 11 },
	{ 1, 11, 2, 1, 9, 11, 9, 8, 11 },
	{ 3, 10, 1, 11, 10, 3 },
	{ 0, 10, 1, 0, 8, 10, 8, 11, 10 },
	{ 3, 9, 0, 3, 11, 9, 11, 10, 9 },
	{ 9, 8, 10, 10, 8, 11 },
	{ 4, 7, 8 },
	{ 4, 3, 0, 7, 3, 4 },
	{ 0, 1, 9, 8, 4, 7 },
	{ 4, 1, 9, 4, 7, 1, 7, 3, 1 },
	{ 1, 2, 10, 8, 4, 7 },
	{ 3, 4, 7, 3, 0, 4, 1, 2, 10 },
	{ 9, 2, 10, 9, 0, 2, 8, 4, 7 },
	{ 2, 10, 9, 2, 9, 7, 2, 7, 3, 7, 9, 4 },
	{ 8, 4, 7, 3, 11, 2 },
	{ 11, 4, 7, 11, 2, 4, 2, 0, 4 },
	{ 9, 0, 1, 8, 4, 7, 2, 3, 11 },
	{ 4, 7, 11, 9, 4, 11, 9, 11, 2, 9, 2, 1 },
	{ 3, 10, 1, 3, 11, 10, 7, 8, 4 },
	{ 1, 11, 10, 1, 4, 11, 1, 0, 4, 7, 11, 4 },
	{ 4, 7, 8, 9, 0, 11, 9, 11, 10, 11, 0, 3 },
	{ 4, 7, 11, 4, 11, 9, 9, 11, 10 },
	{ 9, 5, 4 },
	{ 9, 5, 4, 0, 8, 3 },
	{ 0, 5, 4, 1, 5, 0 },
	{ 8, 5, 4, 8, 3, 5, 3, 1, 5 },
	{ 1, 2, 10, 9, 5, 4 },
	{ 3, 0, 8, 1, 2, 10, 4, 9, 5 },
	{ 5, 2, 10, 5, 4, 2, 4, 0, 2 },
	{ 2, 10, 5, 3, 2, 5, 3, 5, 4, 3, 4, 8 },
	{ 9, 5, 4, 2, 3, 11 },
	{ 0, 11, 2, 0, 8, 11, 4, 9, 5 },
	{ 0, 5, 4, 0, 1, 5, 2, 3, 11 },
	{ 2, 1, 5, 2, 5, 8, 2, 8, 11, 4, 8, 5 },
	{ 10, 3, 11, 10, 1, 3, 9, 5, 4 },
	{ 4, 9, 5, 0, 8, 1, 8, 10, 1, 8, 11, 10 },
	{ 5, 4, 0, 5, 0, 11, 5, 11, 10, 11, 0, 3 },
	{ 5, 4, 8, 5, 8, 10, 10, 8, 11 },
	{ 9, 7, 8, 5, 7, 9 },
	{ 9, 3, 0, 9, 5, 3, 5, 7, 3 },
	{ 0, 7, 8, 0, 1, 7, 1, 5, 7 },
	{ 1, 5, 3, 3, 5, 7 },
	{ 9, 7, 8, 9, 5, 7, 10, 1, 2 },
	{ 10, 1, 2, 9, 5, 0, 5, 3, 0, 5, 7, 3 },
	{ 8, 0, 2, 8, 2, 5, 8, 5, 7, 10, 5, 2 },
	{ 2, 10, 5, 2, 5, 3, 3, 5, 7 },
	{ 7, 9, 5, 7, 8, 9, 3, 11, 2 },
	{ 9, 5, 7, 9, 7, 2, 9, 2, 0, 2, 7, 11 },
	{ 2, 3, 11, 0, 1, 8, 1, 7, 8, 1, 5, 7 },
	{ 11, 2, 1, 11, 1, 7, 7, 1, 5 },
	{ 9, 5, 8, 8, 5, 7, 10, 1, 3, 10, 3, 11 },
	{ 5, 7, 0, 5, 0, 9, 7, 11, 0, 1, 0, 10, 11, 10, 0 },
	{ 11, 10, 0, 11, 0, 3, 10, 5, 0, 8, 0, 7, 5, 7, 0 },
	{ 11, 10, 5, 7, 11, 5 },
	{ 10, 6, 5 },
	{ 0, 8, 3, 5, 10, 6 },
	{ 9, 0, 1, 5, 10, 6 },
	{ 1, 8, 3, 1, 9, 8, 5, 10, 6 },
	{ 1, 6, 5, 2, 6, 1 },
	{ 1, 6, 5, 1, 2, 6, 3, 0, 8 },
	{ 9, 6, 5, 9, 0, 6, 0, 2, 6 },
	{ 5, 9, 8, 5, 8, 2, 5, 2, 6, 3, 2, 8 },
	{ 2, 3, 11, 10, 6, 5 },
	{ 11, 0, 8, 11, 2, 0, 10, 6, 5 },
	{ 0, 1, 9, 2, 3, 11, 5, 10, 6 },
	{ 5, 10, 6, 1, 9, 2, 9, 11, 2, 9, 8, 11 },
	{ 6, 3, 11, 6, 5, 3, 5, 1, 3 },
	{ 0, 8, 11, 0, 11, 5, 0, 5, 1, 5, 11, 6 },
	{ 3, 11, 6, 0, 3, 6, 0, 6, 5, 0, 5, 9 },
	{ 6, 5, 9, 6, 9, 11, 11, 9, 8 },
	{ 5, 10, 6, 4, 7, 8 },
	{ 4, 3, 0, 4, 7, 3, 6, 5, 10 },
	{ 1, 9, 0, 5, 10, 6, 8, 4, 7 },
	{ 10, 6, 5, 1, 9, 7, 1, 7, 3, 7, 9, 4 },
	{ 6, 1, 2, 6, 5, 1, 4, 7, 8 },
	{ 1, 2, 5, 5, 2, 6, 3, 0, 4, 3, 4, 7 },
	{ 8, 4, 7, 9, 0, 5, 0, 6, 5, 0, 2, 6 },
	{ 7, 3, 9, 7, 9, 4, 3, 2, 9, 5, 9, 6, 2, 6, 9 },
	{ 3, 11, 2, 7, 8, 4, 10, 6, 5 },
	{ 5, 10, 6, 4, 7, 2, 4, 2, 0, 2, 7, 11 },
	{ 0, 1, 9, 4, 7, 8, 2, 3, 11, 5, 10, 6 },
	{ 9, 2, 1, 9, 11, 2, 9, 4, 11, 7, 11, 4, 5, 10, 6 },
	{ 8, 4, 7, 3, 11, 5, 3, 5, 1, 5, 11, 6 },
	{ 5, 1, 11, 5, 11, 6, 1, 0, 11, 7, 11, 4, 0, 4, 11 },
	{ 0, 5, 9, 0, 6, 5, 0, 3, 6, 11, 6, 3, 8, 4, 7 },
	{ 6, 5, 9, 6, 9, 11, 4, 7, 9, 7, 11, 9 },
	{ 10, 4, 9, 6, 4, 10 },
	{ 4, 10, 6, 4, 9, 10, 0, 8, 3 },
	{ 10, 0, 1, 10, 6, 0, 6, 4, 0 },
	{ 8, 3, 1, 8, 1, 6, 8, 6, 4, 6, 1, 10 },
	{ 1, 4, 9, 1, 2, 4, 2, 6, 4 },
	{ 3, 0, 8, 1, 2, 9, 2, 4, 9, 2, 6, 4 },
	{ 0, 2, 4, 4, 2, 6 },
	{ 8, 3, 2, 8, 2, 4, 4, 2, 6 },
	{ 10, 4, 9, 10, 6, 4, 11, 2, 3 },
	{ 0, 8, 2, 2, 8, 11, 4, 9, 10, 4, 10, 6 },
	{ 3, 11, 2, 0, 1, 6, 0, 6, 4, 6, 1, 10 },
	{ 6, 4, 1, 6, 1, 10, 4, 8, 1, 2, 1, 11, 8, 11, 1 },
	{ 9, 6, 4, 9, 3, 6, 9, 1, 3, 11, 6, 3 },
	{ 8, 11, 1, 8, 1, 0, 11, 6, 1, 9, 1, 4, 6, 4, 1 },
	{ 3, 11, 6, 3, 6, 0, 0, 6, 4 },
	{ 6, 4, 8, 11, 6, 8 },
	{ 7, 10, 6, 7, 8, 10, 8, 9, 10 },
	{ 0, 7, 3, 0, 10, 7, 0, 9, 10, 6, 7, 10 },
	{ 10, 6, 7, 1, 10, 7, 1, 7, 8, 1, 8, 0 },
	{ 10, 6, 7, 10, 7, 1, 1, 7, 3 },
	{ 1, 2, 6, 1, 6, 8, 1, 8, 9, 8, 6, 7 },
	{ 2, 6, 9, 2, 9, 1, 6, 7, 9, 0, 9, 3, 7, 3, 9 },
	{ 7, 8, 0, 7, 0, 6, 6, 0, 2 },
	{ 7, 3, 2, 6, 7, 2 },
	{ 2, 3, 11, 10, 6, 8, 10, 8, 9, 8, 6, 7 },
	{ 2, 0, 7, 2, 7, 11, 0, 9, 7, 6, 7, 10, 9, 10, 7 },
	{ 1, 8, 0, 1, 7, 8, 1, 10, 7, 6, 7, 10, 2, 3, 11 },
	{ 11, 2, 1, 11, 1, 7, 10, 6, 1, 6, 7, 1 },
	{ 8, 9, 6, 8, 6, 7, 9, 1, 6, 11, 6, 3, 1, 3, 6 },
	{ 0, 9, 1, 11, 6, 7 },
	{ 7, 8, 0, 7, 0, 6, 3, 11, 0, 11, 6, 0 },
	{ 7, 11, 6 },
	{ 7, 6, 11 },
	{ 3, 0, 8, 11, 7, 6 },
	{ 0, 1, 9, 11, 7, 6 },
	{ 8, 1, 9, 8, 3, 1, 11, 7, 6 },
	{ 10, 1, 2, 6, 11, 7 },
	{ 1, 2, 10, 3, 0, 8, 6, 11, 7 },
	{ 2, 9, 0, 2, 10, 9, 6, 11, 7 },
	{ 6, 11, 7, 2, 10, 3, 10, 8, 3, 10, 9, 8 },
	{ 7, 2, 3, 6, 2, 7 },
	{ 7, 0, 8, 7, 6, 0, 6, 2, 0 },
	{ 2, 7, 6, 2, 3, 7, 0, 1, 9 },
	{ 1, 6, 2, 1, 8, 6, 1, 9, 8, 8, 7, 6 },
	{ 10, 7, 6, 10, 1, 7, 1, 3, 7 },
	{ 10, 7, 6, 1, 7, 10, 1, 8, 7, 1, 0, 8 },
	{ 0, 3, 7, 0, 7, 10, 0, 10, 9, 6, 10, 7 },
	{ 7, 6, 10, 7, 10, 8, 8, 10, 9 },
	{ 6, 8, 4, 11, 8, 6 },
	{ 3, 6, 11, 3, 0, 6, 0, 4, 6 },
	{ 8, 6, 11, 8, 4, 6, 9, 0, 1 },
	{ 9, 4, 6, 9, 6, 3, 9, 3, 1, 11, 3, 6 },
	{ 6, 8, 4, 6, 11, 8, 2, 10, 1 },
	{ 1, 2, 10, 3, 0, 11, 0, 6, 11, 0, 4, 6 },
	{ 4, 11, 8, 4, 6, 11, 0, 2, 9, 2, 10, 9 },
	{ 10, 9, 3, 10, 3, 2, 9, 4, 3, 11, 3, 6, 4, 6, 3 },
	{ 8, 2, 3, 8, 4, 2, 4, 6, 2 },
	{ 0, 4, 2, 4, 6, 2 },
	{ 1, 9, 0, 2, 3, 4, 2, 4, 6, 4, 3, 8 },
	{ 1, 9, 4, 1, 4, 2, 2, 4, 6 },
	{ 8, 1, 3, 8, 6, 1, 8, 4, 6, 6, 10, 1 },
	{ 10, 1, 0, 10, 0, 6, 6, 0, 4 },
	{ 4, 6, 3, 4, 3, 8, 6, 10, 3, 0, 3, 9, 10, 9, 3 },
	{ 10, 9, 4, 6, 10, 4 },
	{ 4, 9, 5, 7, 6, 11 },
	{ 0, 8, 3, 4, 9, 5, 11, 7, 6 },
	{ 5, 0, 1, 5, 4, 0, 7, 6, 11 },
	{ 11, 7, 6, 8, 3, 4, 3, 5, 4, 3, 1, 5 },
	{ 9, 5, 4, 10, 1, 2, 7, 6, 11 },
	{ 6, 11, 7, 1, 2, 10, 0, 8, 3, 4, 9, 5 },
	{ 7, 6, 11, 5, 4, 10, 4, 2, 10, 4, 0, 2 },
	{ 3, 4, 8, 3, 5, 4, 3, 2, 5, 10, 5, 2, 11, 7, 6 },
	{ 7, 2, 3, 7, 6, 2, 5, 4, 9 },
	{ 9, 5, 4, 0, 8, 6, 0, 6, 2, 6, 8, 7 },
	{ 3, 6, 2, 3, 7, 6, 1, 5, 0, 5, 4, 0 },
	{ 6, 2, 8, 6, 8, 7, 2, 1, 8, 4, 8, 5, 1, 5, 8 },
	{ 9, 5, 4, 10, 1, 6, 1, 7, 6, 1, 3, 7 },
	{ 1, 6, 10, 1, 7, 6, 1, 0, 7, 8, 7, 0, 9, 5, 4 },
	{ 4, 0, 10, 4, 10, 5, 0, 3, 10, 6, 10, 7, 3, 7, 10 },
	{ 7, 6, 10, 7, 10, 8, 5, 4, 10, 4, 8, 10 },
	{ 6, 9, 5, 6, 11, 9, 11, 8, 9 },
	{ 3, 6, 11, 0, 6, 3, 0, 5, 6, 0, 9, 5 },
	{ 0, 11, 8, 0, 5, 11, 0, 1, 5, 5, 6, 11 },
	{ 6, 11, 3, 6, 3, 5, 5, 3, 1 },
	{ 1, 2, 10, 9, 5, 11, 9, 11, 8, 11, 5, 6 },
	{ 0, 11, 3, 0, 6, 11, 0, 9, 6, 5, 6, 9, 1, 2, 10 },
	{ 11, 8, 5, 11, 5, 6, 8, 0, 5, 10, 5, 2, 0, 2, 5 },
	{ 6, 11, 3, 6, 3, 5, 2, 10, 3, 10, 5, 3 },
	{ 5, 8, 9, 5, 2, 8, 5, 6, 2, 3, 8, 2 },
	{ 9, 5, 6, 9, 6, 0, 0, 6, 2 },
	{ 1, 5, 8, 1, 8, 0, 5, 6, 8, 3, 8, 2, 6, 2, 8 },
	{ 1, 5, 6, 2, 1, 6 },
	{ 1, 3, 6, 1, 6, 10, 3, 8, 6, 5, 6, 9, 8, 9, 6 },
	{ 10, 1, 0, 10, 0, 6, 9, 5, 0, 5, 6, 0 },
	{ 0, 3, 8, 5, 6, 10 },
	{ 10, 5, 6 },
	{ 11, 5, 10, 7, 5, 11 },
	{ 11, 5, 10, 11, 7, 5, 8, 3, 0 },
	{ 5, 11, 7, 5, 10, 11, 1, 9, 0 },
	{ 10, 7, 5, 10, 11, 7, 9, 8, 1, 8, 3, 1 },
	{ 11, 1, 2, 11, 7, 1, 7, 5, 1 },
	{ 0, 8, 3, 1, 2, 7, 1, 7, 5, 7, 2, 11 },
	{ 9, 7, 5, 9, 2, 7, 9, 0, 2, 2, 11, 7 },
	{ 7, 5, 2, 7, 2, 11, 5, 9, 2, 3, 2, 8, 9, 8, 2 },
	{ 2, 5, 10, 2, 3, 5, 3, 7, 5 },
	{ 8, 2, 0, 8, 5, 2, 8, 7, 5, 10, 2, 5 },
	{ 9, 0, 1, 5, 10, 3, 5, 3, 7, 3, 10, 2 },
	{ 9, 8, 2, 9, 2, 1, 8, 7, 2, 10, 2, 5, 7, 5, 2 },
	{ 1, 3, 5, 3, 7, 5 },
	{ 0, 8, 7, 0, 7, 1, 1, 7, 5 },
	{ 9, 0, 3, 9, 3, 5, 5, 3, 7 },
	{ 9, 8, 7, 5, 9, 7 },
	{ 5, 8, 4, 5, 10, 8, 10, 11, 8 },
	{ 5, 0, 4, 5, 11, 0, 5, 10, 11, 11, 3, 0 },
	{ 0, 1, 9, 8, 4, 10, 8, 10, 11, 10, 4, 5 },
	{ 10, 11, 4, 10, 4, 5, 11, 3, 4, 9, 4, 1, 3, 1, 4 },
	{ 2, 5, 1, 2, 8, 5, 2, 11, 8, 4, 5, 8 },
	{ 0, 4, 11, 0, 11, 3, 4, 5, 11, 2, 11, 1, 5, 1, 11 },
	{ 0, 2, 5, 0, 5, 9, 2, 11, 5, 4, 5, 8, 11, 8, 5 },
	{ 9, 4, 5, 2, 11, 3 },
	{ 2, 5, 10, 3, 5, 2, 3, 4, 5, 3, 8, 4 },
	{ 5, 10, 2, 5, 2, 4, 4, 2, 0 },
	{ 3, 10, 2, 3, 5, 10, 3, 8, 5, 4, 5, 8, 0, 1, 9 },
	{ 5, 10, 2, 5, 2, 4, 1, 9, 2, 9, 4, 2 },
	{ 8, 4, 5, 8, 5, 3, 3, 5, 1 },
	{ 0, 4, 5, 1, 0, 5 },
	{ 8, 4, 5, 8, 5, 3, 9, 0, 5, 0, 3, 5 },
	{ 9, 4, 5 },
	{ 4, 11, 7, 4, 9, 11, 9, 10, 11 },
	{ 0, 8, 3, 4, 9, 7, 9, 11, 7, 9, 10, 11 },
	{ 1, 10, 11, 1, 11, 4, 1, 4, 0, 7, 4, 11 },
	{ 3, 1, 4, 3, 4, 8, 1, 10, 4, 7, 4, 11, 10, 11, 4 },
	{ 4, 11, 7, 9, 11, 4, 9, 2, 11, 9, 1, 2 },
	{ 9, 7, 4, 9, 11, 7, 9, 1, 11, 2, 11, 1, 0, 8, 3 },
	{ 11, 7, 4, 11, 4, 2, 2, 4, 0 },
	{ 11, 7, 4, 11, 4, 2, 8, 3, 4, 3, 2, 4 },
	{ 2, 9, 10, 2, 7, 9, 2, 3, 7, 7, 4, 9 },
	{ 9, 10, 7, 9, 7, 4, 10, 2, 7, 8, 7, 0, 2, 0, 7 },
	{ 3, 7, 10, 3, 10, 2, 7, 4, 10, 1, 10, 0, 4, 0, 10 },
	{ 1, 10, 2, 8, 7, 4 },
	{ 4, 9, 1, 4, 1, 7, 7, 1, 3 },
	{ 4, 9, 1, 4, 1, 7, 0, 8, 1, 8, 7, 1 },
	{ 4, 0, 3, 7, 4, 3 },
	{ 4, 8, 7 },
	{ 9, 10, 8, 10, 11, 8 },
	{ 3, 0, 9, 3, 9, 11, 11, 9, 10 },
	{ 0, 1, 10, 0, 10, 8, 8, 10, 11 },
	{ 3, 1, 10, 11, 3, 10 },
	{ 1, 2, 11, 1, 11, 9, 9, 11, 8 },
	{ 3, 0, 9, 3, 9, 11, 1, 2, 9, 2, 11, 9 },
	{ 0, 2, 11, 8, 0, 11 },
	{ 3, 2, 11 },
	{ 2, 3, 8, 2, 8, 10, 10, 8, 9 },
	{ 9, 10, 2, 0, 9, 2 },
	{ 2, 3, 8, 2, 8, 10, 0, 1, 8, 1, 10, 8 },
	{ 1, 10, 2 },
	{ 1, 3, 8, 9, 1, 8 },
	{ 0, 9, 1 },
	{ 0, 3, 8 },
	{},
}

Terrain.InitRenderer = function(renderer, renderer_signal, datamodel)
	local workspace = datamodel:GetService("Workspace")
	local materials = workspace.materials
	local shader = renderer.defaultLitShader

	Terrain:SetProperties({
		Decoration = true,
		GrassLength = 1,

		MaterialColors = "",
		WaterColor = Color3.new(0, 0, 0),
		WaterReflectance = 0,
		WaterTransparency = 0,
		WaterWaveSize = 0,
		WaterWaveSpeed = 0,
		VoxelSize = 2,
		UseMarchingCubes = true,
		IsoLevel = 0.2,
		_blocks = {}, -- [x][y][z] = voxel
		_mesh = nil,
	})

	function Terrain:_getVoxel(x, y, z)
		Terrain._blocks[x] = Terrain._blocks[x] or {}
		Terrain._blocks[x][y] = Terrain._blocks[x][y] or {}
		return Terrain._blocks[x][y][z]
	end

	function Terrain:_getDensity(x, y, z)
		local xRow = Terrain._blocks[x]
		if not xRow then
			return 0
		end
		local yRow = xRow[y]
		if not yRow then
			return 0
		end
		local voxel = yRow[z]
		return voxel and voxel.density or 0
	end

	function Terrain:_addFace(vertices, indices, v1, v2, v3, v4, color)
		local base = #vertices

		table.insert(vertices, { v1, color })
		table.insert(vertices, { v2, color })
		table.insert(vertices, { v3, color })
		table.insert(vertices, { v4, color })

		table.insert(indices, base + 1)
		table.insert(indices, base + 2)
		table.insert(indices, base + 3)

		table.insert(indices, base + 1)
		table.insert(indices, base + 3)
		table.insert(indices, base + 4)
	end

	function Terrain:_interpolateVertex(p1, p2, v1, v2)
		local isoLevel = Terrain.IsoLevel
		local diff = v2 - v1

		if math.abs(isoLevel - v1) < 0.00001 then
			return p1
		end
		if math.abs(isoLevel - v2) < 0.00001 then
			return p2
		end
		if math.abs(diff) < 0.00001 then
			return p1
		end

		local mu = (isoLevel - v1) / diff
		return vector.create(p1.x + mu * (p2.x - p1.x), p1.y + mu * (p2.y - p1.y), p1.z + mu * (p2.z - p1.z))
	end

	function Terrain:_marchCube(x, y, z, vertices, indices)
		local vs = Terrain.VoxelSize
		local isoLevel = Terrain.IsoLevel -- Cache this
		local px, py, pz = x * vs, y * vs, z * vs

		local corners = {
			vector.create(px, py, pz),
			vector.create(px + vs, py, pz),
			vector.create(px + vs, py, pz + vs),
			vector.create(px, py, pz + vs),
			vector.create(px, py + vs, pz),
			vector.create(px + vs, py + vs, pz),
			vector.create(px + vs, py + vs, pz + vs),
			vector.create(px, py + vs, pz + vs),
		}

		local values = {
			Terrain:_getDensity(x, y, z),
			Terrain:_getDensity(x + 1, y, z),
			Terrain:_getDensity(x + 1, y, z + 1),
			Terrain:_getDensity(x, y, z + 1),
			Terrain:_getDensity(x, y + 1, z),
			Terrain:_getDensity(x + 1, y + 1, z),
			Terrain:_getDensity(x + 1, y + 1, z + 1),
			Terrain:_getDensity(x, y + 1, z + 1),
		}

		local cubeIndex = 0
		for i = 1, 8 do
			if values[i] > Terrain.IsoLevel then
				cubeIndex = cubeIndex + bit32.lshift(1, i - 1)
			end
		end

		if cubeIndex == 0 or cubeIndex == 255 then
			return
		end

		local block = Terrain:_getVoxel(x, y, z) or { color = Color3.new(0.5, 0.5, 0.5), material = "default" }
		local color = block.color

		local vertList = {}
		local edgeTable = EDGE_TABLE[cubeIndex + 1]

		local edges = {
			{ 1, 2 },
			{ 2, 3 },
			{ 3, 4 },
			{ 4, 1 }, -- bottom edges
			{ 5, 6 },
			{ 6, 7 },
			{ 7, 8 },
			{ 8, 5 }, -- top edges
			{ 1, 5 },
			{ 2, 6 },
			{ 3, 7 },
			{ 4, 8 }, -- vertical edges
		}

		for i = 0, 11 do
			if bit32.band(edgeTable, bit32.lshift(1, i)) ~= 0 then
				local edge = edges[i + 1]
				local v =
					Terrain:_interpolateVertex(corners[edge[1]], corners[edge[2]], values[edge[1]], values[edge[2]])
				vertList[i] = v
			end
		end

		local triTable = TRI_TABLE[cubeIndex + 1]
		local triCount = #triTable

		if triCount > 0 then
			local baseIdx = #vertices

			for i = 1, triCount do
				vertices[baseIdx + i] = { vertList[triTable[i]], color }
			end

			local indicesBase = #indices
			for i = 1, triCount, 3 do
				indices[indicesBase + i] = baseIdx + i
				indices[indicesBase + i + 1] = baseIdx + i + 1
				indices[indicesBase + i + 2] = baseIdx + i + 2
			end
		end
	end

	function Terrain:GenerateMesh()
		local vertices = {}
		local indices = {}

		if Terrain.UseMarchingCubes then
			local minX, maxX = math.huge, -math.huge
			local minY, maxY = math.huge, -math.huge
			local minZ, maxZ = math.huge, -math.huge

			for x, xRow in pairs(Terrain._blocks) do
				for y, yRow in pairs(xRow) do
					for z, _ in pairs(yRow) do
						minX, maxX = math.min(minX, x), math.max(maxX, x)
						minY, maxY = math.min(minY, y), math.max(maxY, y)
						minZ, maxZ = math.min(minZ, z), math.max(maxZ, z)
					end
				end
			end

			for x = minX, maxX do
				for y = minY, maxY do
					for z = minZ, maxZ do
						Terrain:_marchCube(x, y, z, vertices, indices)
					end
				end
			end
		else
			local vs = Terrain.VoxelSize

			local function isSolid(x, y, z)
				local v = Terrain:_getVoxel(x, y, z)
				return v and v.density > 0
			end

			for x, xRow in pairs(Terrain._blocks) do
				for y, yRow in pairs(xRow) do
					for z, block in pairs(yRow) do
						if block.density <= 0 then
							continue
						end

						local px = x * vs
						local py = y * vs
						local pz = z * vs

						local color = block.color:ToRaylib(0)
						if block.material == "water" then
							color = block.color:ToRaylib(0.5)
						end

						local function V(dx, dy, dz)
							return vector.create(px + dx * vs, py + dy * vs, pz + dz * vs)
						end

						-- +X
						if not isSolid(x + 1, y, z) then
							Terrain:_addFace(vertices, indices, V(1, 0, 0), V(1, 1, 0), V(1, 1, 1), V(1, 0, 1), color)
						end

						-- -X
						if not isSolid(x - 1, y, z) then
							Terrain:_addFace(vertices, indices, V(0, 0, 1), V(0, 1, 1), V(0, 1, 0), V(0, 0, 0), color)
						end

						-- +Y
						if not isSolid(x, y + 1, z) then
							Terrain:_addFace(vertices, indices, V(0, 1, 1), V(1, 1, 1), V(1, 1, 0), V(0, 1, 0), color)
						end

						-- -Y
						if not isSolid(x, y - 1, z) then
							Terrain:_addFace(vertices, indices, V(0, 0, 0), V(1, 0, 0), V(1, 0, 1), V(0, 0, 1), color)
						end

						-- +Z
						if not isSolid(x, y, z + 1) then
							Terrain:_addFace(vertices, indices, V(1, 0, 1), V(1, 1, 1), V(0, 1, 1), V(0, 0, 1), color)
						end

						-- -Z
						if not isSolid(x, y, z - 1) then
							Terrain:_addFace(vertices, indices, V(0, 0, 0), V(0, 1, 0), V(1, 1, 0), V(1, 0, 0), color)
						end
					end
				end
			end
		end

		Terrain._mesh = { vertices = vertices, indices = indices }
	end

	function Terrain:_setVoxel(x, y, z, voxel)
		Terrain._blocks[x] = Terrain._blocks[x] or {}
		Terrain._blocks[x][y] = Terrain._blocks[x][y] or {}
		Terrain._blocks[x][y][z] = voxel
	end

	function Terrain:FillBlock(minPos, maxPos, block)
		local filled = {}

		for x = minPos.X, maxPos.X do
			for y = minPos.Y, maxPos.Y do
				for z = minPos.Z, maxPos.Z do
					Terrain:_setVoxel(x, y, z, {
						density = block.density,
						material = block.material,
						color = block.color,
					})
					print("Filled voxel at", x, y, z)
				end
			end
		end
		Terrain:GenerateMesh()

		return filled
	end

	function Terrain:Fill(height)
		if Terrain.UseMarchingCubes then
			for x = -15, 15 do
				for z = -15, 15 do
					for y = -8, height + 5 do
						local noise = (math.sin(x * 0.1) * math.cos(z * 0.1) + math.sin(x * 0.05 + z * 0.05)) * 2
						local heightFactor = (height - y) / 5.0
						local density = heightFactor + noise * 0.3

						-- Clamp density between 0 and 1
						density = math.max(0, math.min(1, density))

						-- Determine material based on density and position
						local material = "Grass"
						local color = Color3.new(0, 1, 0)

						if y < height - 5 then
							material = "water"
							color = Color3.new(0, 0.23529411764705882, 1)
						end

						Terrain:_setVoxel(x, y, z, {
							density = density,
							material = material,
							color = color,
						})
					end
				end
			end
		else
			-- Original blocky fill
			for x = -32, 32 do
				for z = -32, 32 do
					for y = -8, height do
						local random = math.random()
						if random > 0.5 then
							Terrain:_setVoxel(x, y, z, {
								density = 1,
								material = "Grass",
								color = Color3.new(0, 1, 0),
							})
						else
							Terrain:_setVoxel(x, y, z, {
								density = 1,
								material = "water",
								color = Color3.new(0, 0.23529411764705882, 1),
							})
						end
					end
				end
			end
		end
		Terrain:GenerateMesh()
	end

	function Terrain:StartRendering()
		renderer.Pool.new("3d", function()
			if not Terrain._mesh then
				return
			end

			local verts = Terrain._mesh.vertices
			local inds = Terrain._mesh.indices
			local TexID = buffer.readu32(materials.grass.material, 0)
			raylib.lib.rlSetTexture(TexID)

			for i = 1, #inds, 3 do
				local a = verts[inds[i]]
				local b = verts[inds[i + 1]]
				local c = verts[inds[i + 2]]

				raylib.lib.rlBegin(0x0004) -- RL_TRIANGLES

				-- Vertex A
				raylib.lib.rlColor4f(a[2].R, a[2].G, a[2].B, 1.0)
				raylib.lib.rlTexCoord2f(0.0, 0.0)
				raylib.lib.rlVertex3f(a[1].x, a[1].y, a[1].z)

				-- Vertex B
				raylib.lib.rlColor4f(b[2].R, b[2].G, b[2].B, 1.0)
				raylib.lib.rlTexCoord2f(1.0, 0.0)
				raylib.lib.rlVertex3f(b[1].x, b[1].y, b[1].z)

				-- Vertex C
				raylib.lib.rlColor4f(c[2].R, c[2].G, c[2].B, 1.0)
				raylib.lib.rlTexCoord2f(0.5, 1.0)
				raylib.lib.rlVertex3f(c[1].x, c[1].y, c[1].z)

				raylib.lib.rlEnd()
			end

			raylib.lib.rlSetTexture(0)
		end)
	end

	Terrain:StartRendering()

	return Terrain
end

return Terrain
