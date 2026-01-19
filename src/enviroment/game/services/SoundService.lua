local Instance = require("@Instance")
local signal = require("@Kinemium.signal")
local utils = require("@bufferutils")

local SoundService = Instance.new("SoundService")
SoundService.ExplorerHidden = true

local ffi = zune.ffi

SoundService.InitRenderer = function(renderer, renderer_signal, game) end

return SoundService
