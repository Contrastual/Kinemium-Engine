--[[
local Video = {}
Video.__index = Video
Video.ClassName = "Video"

local ffmpg = require("@ffmpg")
local structs = ffmpg.structs
local avformat = ffmpg.avformat
local avcodec = ffmpg.avcodec
local swscale = ffmpg.swscale
local avutil = ffmpg.avutil
local ffi = zune.ffi
local mem = zune.mem

function Video.new(url, length, framerate)
	assert(type(url) == "string", "Video URL must be a string")

	length = length or 0
	framerate = framerate or 30

	local self = setmetatable({}, Video)

	-- Allocate space for AVFormatContext**
	local mainPtr = ffi.alloc(ffi.types.pointer:size())

	-- Open video file
	local ret = avformat.avformat_open_input(mainPtr, url, nil, nil)
	if ret < 0 then
		ffi.free(mainPtr)
		print("Failed to open video: " .. url .. " (print code: " .. ret .. ")")
	end

	-- Get the AVFormatContext*
	local formatContextPtr = mainPtr:readptr(0)

	-- Retrieve stream information
	ret = avformat.avformat_find_stream_info(formatContextPtr, nil)
	if ret < 0 then
		avformat.avformat_close_input(mainPtr)
		ffi.free(mainPtr)
		print("Failed to find stream info (print code: " .. ret .. ")")
	end

	-- Find the best video stream
	local videoStreamIndex = avformat.av_find_best_stream(formatContextPtr, avutil.AVMEDIA_TYPE_VIDEO, -1, -1, nil, 0)

	if videoStreamIndex < 0 then
		avformat.avformat_close_input(mainPtr)
		ffi.free(mainPtr)
		print("No video stream found in: " .. url)
	end

	-- Read streams pointer and get the video stream
	local streamsPtr = formatContextPtr:readptr(48) -- streams at offset 48
	local videoStreamPtr = streamsPtr:readptr(videoStreamIndex * ffi.types.pointer:size())

	local codecParamsPtr = videoStreamPtr:readptr(16)
	local codecId = codecParamsPtr:readi32(4)

	-- Find the decoder for this codec
	local decoderPtr = avcodec.avcodec_find_decoder(codecId)
	if decoderPtr == nil or decoderPtr:readptr(0) == nil then
		avformat.avformat_close_input(mainPtr)
		ffi.free(mainPtr)
		print("Failed to find decoder for codec")
	end

	local codecContextPtr = avcodec.avcodec_alloc_context3(decoderPtr)
	if codecContextPtr == nil or codecContextPtr:readptr(0) == nil then
		avformat.avformat_close_input(mainPtr)
		ffi.free(mainPtr)
		print("Failed to allocate codec context")
	end

	ret = avcodec.avcodec_parameters_to_context(codecContextPtr, codecParamsPtr)
	if ret < 0 then
		avcodec.avcodec_free_context(codecContextPtr)
		avformat.avformat_close_input(mainPtr)
		ffi.free(mainPtr)
		print("Failed to copy codec parameters (print code: " .. ret .. ")")
	end

	ret = avcodec.avcodec_open2(codecContextPtr, decoderPtr, nil)
	if ret < 0 then
		avcodec.avcodec_free_context(codecContextPtr)
		avformat.avformat_close_input(mainPtr)
		ffi.free(mainPtr)
		print("Failed to open codec (print code: " .. ret .. ")")
	end

	local packetPtr = avcodec.av_packet_alloc()
	local framePtr = avutil.av_frame_alloc()

	if packetPtr == nil or framePtr == nil then
		if framePtr then
			avutil.av_frame_free(framePtr)
		end
		if packetPtr then
			avcodec.av_packet_free(packetPtr)
		end
		avcodec.avcodec_free_context(codecContextPtr)
		avformat.avformat_close_input(mainPtr)
		ffi.free(mainPtr)
		print("Failed to allocate packet or frame")
	end

	local width = codecParamsPtr:readi32(structs.AVCodecParameters:offset("width")) -- width offset
	local height = codecParamsPtr:readi32(structs.AVCodecParameters:offset("height")) -- height offset

	self._ffmpg_formatContext = formatContextPtr
	self._ffmpg_mainPtr = mainPtr
	self._ffmpg_videoStream = videoStreamPtr
	self._ffmpg_codecParams = codecParamsPtr
	self._ffmpg_codecContext = codecContextPtr
	self._ffmpg_packet = packetPtr
	self._ffmpg_frame = framePtr
	self._ffmpg_videoStreamIndex = videoStreamIndex
	self._ffmpg_bit_rate = codecParamsPtr:readi32(structs.AVCodecParameters:offset("bit_rate"))
	self._ffmpg_fps = codecParamsPtr:readi32(structs.AVCodecParameters:offset("framerate"))

	self.Width = width
	self.Height = height
	self.Url = url
	self.Length = length
	self.Framerate = framerate

	print(self)

	return self
end

function Video:Clone()
	return Video.new(self.Url, self.Length, self.Framerate)
end

function Video:Equals(other)
	return getmetatable(other) == Video
		and self.Url == other.Url
		and self.Length == other.Length
		and self.Framerate == other.Framerate
end

function Video:__tostring()
	return string.format("Video(%s, Length=%d, FPS=%d)", self.Url, self.Length, self.Framerate)
end

function Video:Play()
	if not self._ffmpg_codecContext then
		warn("Video not properly initialized")
		return false
	end

	self._isPlaying = true
	self._currentTime = 0
	self._lastFrameTime = os.clock()

	return true
end

function Video:Pause()
	self._isPlaying = false
end

function Video:Stop()
	self._isPlaying = false
	self._currentTime = 0
	self._isEnded = false
end

function Video:Seek(seconds)
	if not self._ffmpg_formatContext or not self._ffmpg_videoStreamIndex then
		return false
	end

	seconds = math.clamp(seconds, 0, self.Length)

	-- Calculate timestamp in stream time base
	local streamsPtr = self._ffmpg_formatContext:readptr(48)
	local videoStreamPtr = streamsPtr:readptr(self._ffmpg_videoStreamIndex * ffi.types.pointer:size())
	local timeBasePtr = videoStreamPtr:readptr(24)
	local durationPtr = videoStreamPtr:readptr(40)

	local timeBaseNum = timeBasePtr:readi32(0)
	local timeBaseDen = timeBasePtr:readi32(4)
	local duration = durationPtr:readi64(0)

	local timestamp = seconds * timeBaseDen / timeBaseNum
	local ret = avformat.av_seek_frame(self._ffmpg_mainPtr, self._ffmpg_videoStreamIndex, timestamp, 0)

	if ret >= 0 then
		-- Flush codec buffers after seek
		avcodec.avcodec_flush_buffers(self._ffmpg_codecContext)
		self._currentTime = seconds
		self._isEnded = false
		return true
	end

	return false
end

function Video:Update(deltaTime)
	if not self._isPlaying or self._isEnded then
		return nil
	end

	self._currentTime = self._currentTime + deltaTime

	if self._currentTime >= self.Length then
		self._isPlaying = false
		self._isEnded = true
		return nil
	end

	-- Decode a frame at current time
	return self:_decodeFrameAtTime(self._currentTime)
end

function Video:_decodeFrameAtTime(seconds)
	-- Simple implementation: decode until we reach the desired timestamp
	local targetPts = seconds * self.Framerate
	local bestFrame = nil

	while true do
		local ret = avformat.av_read_frame(self._ffmpg_formatContext, self._ffmpg_packet)
		if ret < 0 then
			-- End of file or error
			break
		end

		local streamIndex = self._ffmpg_packet:readi32(12)

		if streamIndex == self._ffmpg_videoStreamIndex then
			-- Send packet to decoder
			ret = avcodec.avcodec_send_packet(self._ffmpg_codecContext, self._ffmpg_packet)
			if ret < 0 then
				avcodec.av_packet_unref(self._ffmpg_packet)
				break
			end

			-- Receive frame
			ret = avcodec.avcodec_receive_frame(self._ffmpg_codecContext, self._ffmpg_frame)
			if ret < 0 then
				avcodec.av_packet_unref(self._ffmpg_packet)
				break
			end

			local pts = self._ffmpg_frame:readi64(0)

			if pts >= targetPts then
				bestFrame = self._ffmpg_frame
				break
			end
		end

		avcodec.av_packet_unref(self._ffmpg_packet)
	end

	return bestFrame
end

function Video:GetCurrentFrame()
	return self:_decodeFrameAtTime(self._currentTime)
end

function Video:GetFrameAtTime(seconds)
	local frame = math.clamp(math.floor(seconds * self.Framerate), 0, self.Length * self.Framerate)
	return frame
end

function Video:GetPixelData()
	-- Returns raw pixel data and size for rendering
	-- User should implement their own texture update using this data
	local frame = self:_decodeFrameAtTime(self._currentTime)
	if not frame then
		return nil, 0
	end

	local dataPtr = frame:readptr(32) -- data[0] pointer at offset 32
	if not dataPtr or dataPtr:readptr(0) == nil then
		return nil, 0
	end

	local pixelData = dataPtr:readptr(0)
	local size = self.Width * self.Height * 4 -- RGBA

	return pixelData, size
end

function Video:GetFrameData()
	-- Returns the decoded AVFrame pointer
	return self:_decodeFrameAtTime(self._currentTime)
end

function Video:Destroy()
	if self._ffmpg_mainPtr then
		print("Cleaning up video resources")
		avformat.avformat_close_input(self._ffmpg_mainPtr)
		ffi.free(self._ffmpg_mainPtr)
		self._ffmpg_mainPtr = nil
		self._ffmpg_formatContext = nil
		self._ffmpg_videoStream = nil
		self._ffmpg_codecParams = nil
	end
end

function Video:IsPlaying()
	return self._isPlaying == true
end

function Video:IsEnded()
	return self._isEnded == true
end

function Video:GetCurrentTime()
	return self._currentTime or 0
end

function Video:GetDuration()
	return self.Length
end

setmetatable(Video, {
	__call = function(_, ...)
		return Video.new(...)
	end,
})
--]]
return {}
