local TableEncoder = {}

--  Type tags
local TAG_NIL = 0
local TAG_BOOL_FALSE = 1
local TAG_BOOL_TRUE = 2
local TAG_FLOAT = 3 -- full f64
local TAG_INT_POS8 = 4 -- u8   (0–255)
local TAG_INT_POS16 = 5 -- u16  (256–65535)
local TAG_INT_POS32 = 6 -- u32  (65536–2^32-1)
local TAG_INT_NEG8 = 7 -- stored as u8  magnitude
local TAG_INT_NEG16 = 8 -- stored as u16 magnitude
local TAG_INT_NEG32 = 9 -- stored as u32 magnitude
local TAG_STR_SHORT = 10 -- length fits u8  (0–255)
local TAG_STR_LONG = 11 -- length fits u32
local TAG_TABLE = 12

--  Growable writer
-- Avoids a full pre-pass to calculate size.

local Writer = {}
Writer.__index = Writer

function Writer.new()
	local self = setmetatable({}, Writer)
	self.buf = buffer.create(256)
	self.size = 256
	self.offset = 0
	return self
end

function Writer:_ensure(bytes: number)
	local needed = self.offset + bytes
	if needed <= self.size then
		return
	end
	local newSize = self.size
	while newSize < needed do
		newSize *= 2
	end
	local newBuf = buffer.create(newSize)
	buffer.copy(newBuf, 0, self.buf, 0, self.offset)
	self.buf = newBuf
	self.size = newSize
end

function Writer:u8(v: number)
	self:_ensure(1)
	buffer.writeu8(self.buf, self.offset, v)
	self.offset += 1
end

function Writer:u16(v: number)
	self:_ensure(2)
	buffer.writeu16(self.buf, self.offset, v)
	self.offset += 2
end

function Writer:u32(v: number)
	self:_ensure(4)
	buffer.writeu32(self.buf, self.offset, v)
	self.offset += 4
end

function Writer:f64(v: number)
	self:_ensure(8)
	buffer.writef64(self.buf, self.offset, v)
	self.offset += 8
end

function Writer:str(v: string)
	local len = #v
	self:_ensure(len)
	buffer.writestring(self.buf, self.offset, v)
	self.offset += len
end

function Writer:bytes(v: buffer)
	local len = buffer.len(v)
	self:_ensure(len)
	buffer.copy(self.buf, self.offset, v, 0, len)
	self.offset += len
end

-- Returns a correctly-sized buffer copy.
function Writer:finish(): buffer
	local out = buffer.create(self.offset)
	buffer.copy(out, 0, self.buf, 0, self.offset)
	return out
end

--  Encoder

local encodeValue

local function encodeFragment(value: any, seen: { [any]: boolean }): (boolean, buffer?)
	local ok, result = pcall(function()
		local writer = Writer.new()
		encodeValue(writer, value, seen)
		return writer:finish()
	end)
	if ok then
		return true, result
	end
	return false, nil
end

encodeValue = function(w: typeof(Writer.new()), value: any, seen: { [any]: boolean })
	local t = typeof(value)

	if value == nil then
		w:u8(TAG_NIL)
	elseif t == "boolean" then
		w:u8(value and TAG_BOOL_TRUE or TAG_BOOL_FALSE)
	elseif t == "number" then
		if value % 1 == 0 then
			if value >= 0 then
				if value <= 0xFF then
					w:u8(TAG_INT_POS8)
					w:u8(value)
				elseif value <= 0xFFFF then
					w:u8(TAG_INT_POS16)
					w:u16(value)
				elseif value <= 0xFFFFFFFF then
					w:u8(TAG_INT_POS32)
					w:u32(value)
				else
					w:u8(TAG_FLOAT)
					w:f64(value)
				end
			else
				local mag = -value
				if mag <= 0xFF then
					w:u8(TAG_INT_NEG8)
					w:u8(mag)
				elseif mag <= 0xFFFF then
					w:u8(TAG_INT_NEG16)
					w:u16(mag)
				elseif mag <= 0xFFFFFFFF then
					w:u8(TAG_INT_NEG32)
					w:u32(mag)
				else
					w:u8(TAG_FLOAT)
					w:f64(value)
				end
			end
		else
			w:u8(TAG_FLOAT)
			w:f64(value)
		end
	elseif t == "string" then
		local len = #value
		if len <= 0xFF then
			w:u8(TAG_STR_SHORT)
			w:u8(len)
		else
			w:u8(TAG_STR_LONG)
			w:u32(len)
		end
		w:str(value)
	elseif t == "table" then
		if seen[value] then
			w:u8(TAG_NIL)
			return
		end
		seen[value] = true

		w:u8(TAG_TABLE)

		local arrayLen = #value
		w:u32(arrayLen)
		for i = 1, arrayLen do
			encodeValue(w, value[i], seen)
		end

		local hashPairs: { { any } } = {}
		for k, v in pairs(value) do
			local isArrayKey = type(k) == "number" and k >= 1 and k <= arrayLen and k % 1 == 0
			if not isArrayKey and v ~= nil then
				local keyOk, keyEncoded = encodeFragment(k, seen)
				local valueOk, valueEncoded = encodeFragment(v, seen)
				if keyOk and valueOk and keyEncoded and valueEncoded then
					hashPairs[#hashPairs + 1] = { keyEncoded, valueEncoded }
				end
			end
		end

		w:u32(#hashPairs)
		for _, pair in ipairs(hashPairs) do
			w:bytes(pair[1])
			w:bytes(pair[2])
		end

		seen[value] = nil -- allow the same table to appear in separate branches
	elseif t == "function" then
		w:u8(TAG_NIL)
	else
		w:u8(TAG_NIL)
	end
end

--  Decoder

local function ensureAvailable(buf: buffer, offset: number, needed: number)
	local length = buffer.len(buf)
	if offset < 0 or offset + needed > length then
		error(("Buffer underflow while decoding at offset %d (need %d bytes, len %d)"):format(offset, needed, length))
	end
end

local function isValidKey(key: any): boolean
	if key == nil then
		return false
	end
	if type(key) == "number" and key ~= key then
		return false
	end
	return true
end

local function decodeValue(buf: buffer, offset: number): (any, number)
	ensureAvailable(buf, offset, 1)
	local tag = buffer.readu8(buf, offset)
	offset += 1
	if tag == TAG_NIL then
		return nil, offset
	elseif tag == TAG_BOOL_FALSE then
		return false, offset
	elseif tag == TAG_BOOL_TRUE then
		return true, offset
	elseif tag == TAG_FLOAT then
		ensureAvailable(buf, offset, 8)
		return buffer.readf64(buf, offset), offset + 8
	elseif tag == TAG_INT_POS8 then
		ensureAvailable(buf, offset, 1)
		return buffer.readu8(buf, offset), offset + 1
	elseif tag == TAG_INT_POS16 then
		ensureAvailable(buf, offset, 2)
		return buffer.readu16(buf, offset), offset + 2
	elseif tag == TAG_INT_POS32 then
		ensureAvailable(buf, offset, 4)
		return buffer.readu32(buf, offset), offset + 4
	elseif tag == TAG_INT_NEG8 then
		ensureAvailable(buf, offset, 1)
		return -buffer.readu8(buf, offset), offset + 1
	elseif tag == TAG_INT_NEG16 then
		ensureAvailable(buf, offset, 2)
		return -buffer.readu16(buf, offset), offset + 2
	elseif tag == TAG_INT_NEG32 then
		ensureAvailable(buf, offset, 4)
		return -buffer.readu32(buf, offset), offset + 4
	elseif tag == TAG_STR_SHORT then
		ensureAvailable(buf, offset, 1)
		local len = buffer.readu8(buf, offset)
		offset += 1
		ensureAvailable(buf, offset, len)
		return buffer.readstring(buf, offset, len), offset + len
	elseif tag == TAG_STR_LONG then
		ensureAvailable(buf, offset, 4)
		local len = buffer.readu32(buf, offset)
		offset += 4
		ensureAvailable(buf, offset, len)
		return buffer.readstring(buf, offset, len), offset + len
	elseif tag == TAG_TABLE then
		local t = {}

		ensureAvailable(buf, offset, 4)
		local arrayLen = buffer.readu32(buf, offset)
		offset += 4
		for i = 1, arrayLen do
			local v
			v, offset = decodeValue(buf, offset)
			t[i] = v
		end

		ensureAvailable(buf, offset, 4)
		local hashCount = buffer.readu32(buf, offset)
		offset += 4
		for _ = 1, hashCount do
			local k, v
			k, offset = decodeValue(buf, offset)
			v, offset = decodeValue(buf, offset)
			if isValidKey(k) then
				t[k] = v
			end
		end

		return t, offset
	else
		error("Invalid tag: " .. tag)
	end
end

--  Public API

function TableEncoder.encode(value: any): buffer
	local w = Writer.new()
	encodeValue(w, value, {})
	return w:finish()
end

function TableEncoder.decode(buf: buffer): any
	local value, offset = decodeValue(buf, 0)
	local length = buffer.len(buf)
	if offset ~= length then
		error(("Trailing bytes after decode: consumed %d of %d"):format(offset, length))
	end
	return value
end

return TableEncoder
