--!strict
--!optimize 2
--!native

local ffi = zune.ffi

-- Basic type aliases
local int = ffi.types.i32
local uint = ffi.types.u32
local bool = ffi.types.u8
local float = ffi.types.float
local double = ffi.types.double

local sail_compression_level = ffi.struct({
	{ min_level = ffi.types.double },
	{ max_level = ffi.types.double },
	{ default_level = ffi.types.double },
	{ step = ffi.types.double },
})
export type sail_compression_level = typeof(sail_compression_level:new({}))

local sail_hash_map = ffi.struct({
	{ buckets = ffi.types.pointer },
})
export type sail_hash_map = typeof(sail_hash_map:new({}))

local sail_iccp = ffi.struct({
	{ data = ffi.types.pointer },
	{ size = ffi.types.u64 },
})
export type sail_iccp = typeof(sail_iccp:new({}))

local sail_image = ffi.struct({
	{ pixels = ffi.types.pointer }, -- 8 bytes (offset 0)
	{ width = ffi.types.u32 }, -- 4 bytes (offset 8)
	{ height = ffi.types.u32 }, -- 4 bytes (offset 12)
	{ bytes_per_line = ffi.types.u32 }, -- 4 bytes (offset 16)
	{ _pad1 = ffi.types.u32 }, -- 4 bytes padding (offset 20)
	{ resolution = ffi.types.pointer }, -- 8 bytes (offset 24)
	{ pixel_format = ffi.types.i32 }, -- 4 bytes (offset 32)
	{ gamma = ffi.types.double }, -- 8 bytes (offset 36) -- wait, double needs 8-align
	{ delay = ffi.types.i32 }, -- 4 bytes
	{ _pad2 = ffi.types.u32 }, -- 4 bytes padding
	{ palette = ffi.types.pointer }, -- 8 bytes
	{ meta_data_node = ffi.types.pointer }, -- 8 bytes
	{ iccp = ffi.types.pointer }, -- 8 bytes
	{ source_image = ffi.types.pointer }, -- 8 bytes
})
export type sail_image = typeof(sail_image:new({}))

local sail_io = ffi.struct({
	{ features = ffi.types.i32 },
	{ stream = ffi.types.pointer },
	{ tolerant_read = ffi.types.pointer },
	{ strict_read = ffi.types.pointer },
	{ tolerant_write = ffi.types.pointer },
	{ strict_write = ffi.types.pointer },
	{ seek = ffi.types.pointer },
	{ tell = ffi.types.pointer },
	{ flush = ffi.types.pointer },
	{ close = ffi.types.pointer },
	{ eof = ffi.types.pointer },
	{ size = ffi.types.pointer },
})
export type sail_io = typeof(sail_io:new({}))

local linked_list_node = ffi.struct({
	{ value = ffi.types.pointer },
	{ next = ffi.types.pointer },
})
export type linked_list_node = typeof(linked_list_node:new({}))

local sail_load_features = ffi.struct({
	{ features = ffi.types.i32 },
	{ tuning = ffi.types.pointer },
})
export type sail_load_features = typeof(sail_load_features:new({}))

local sail_load_options = ffi.struct({
	{ options = ffi.types.i32 },
	{ tuning = ffi.types.pointer },
})
export type sail_load_options = typeof(sail_load_options:new({}))

local sail_meta_data = ffi.struct({
	{ key = ffi.types.pointer },
	{ key_unknown = ffi.types.pointer },
	{ value = ffi.types.pointer },
})
export type sail_meta_data = typeof(sail_meta_data:new({}))

local sail_meta_data_node = ffi.struct({
	{ meta_data = ffi.types.pointer },
	{ next = ffi.types.pointer },
})
export type sail_meta_data_node = typeof(sail_meta_data_node:new({}))

local sail_palette = ffi.struct({
	{ pixel_format = ffi.types.pointer },
	{ data = ffi.types.pointer },
	{ color_count = ffi.types.pointer },
})
export type sail_palette = typeof(sail_palette:new({}))

local sail_pixel3_uint8 = ffi.struct({
	{ component1 = ffi.types.u8 },
	{ component2 = ffi.types.u8 },
	{ component3 = ffi.types.u8 },
})
export type sail_pixel3_uint8 = typeof(sail_pixel3_uint8:new({}))

local sail_pixel4_uint8 = ffi.struct({
	{ component1 = ffi.types.u8 },
	{ component2 = ffi.types.u8 },
	{ component3 = ffi.types.u8 },
	{ component4 = ffi.types.u8 },
})
export type sail_pixel4_uint8 = typeof(sail_pixel4_uint8:new({}))

local sail_pixel3_uint16 = ffi.struct({
	{ component1 = ffi.types.u16 },
	{ component2 = ffi.types.u16 },
	{ component3 = ffi.types.u16 },
})
export type sail_pixel3_uint16 = typeof(sail_pixel3_uint16:new({}))

local sail_pixel4_uint16 = ffi.struct({
	{ component1 = ffi.types.u16 },
	{ component2 = ffi.types.u16 },
	{ component3 = ffi.types.u16 },
	{ component4 = ffi.types.u16 },
})
export type sail_pixel4_uint16 = typeof(sail_pixel4_uint16:new({}))

local sail_pixel3_float = ffi.struct({
	{ component1 = ffi.types.float },
	{ component2 = ffi.types.float },
	{ component3 = ffi.types.float },
})
export type sail_pixel3_float = typeof(sail_pixel3_float:new({}))

local sail_pixel4_float = ffi.struct({
	{ component1 = ffi.types.float },
	{ component2 = ffi.types.float },
	{ component3 = ffi.types.float },
	{ component4 = ffi.types.float },
})
export type sail_pixel4_float = typeof(sail_pixel4_float:new({}))

local sail_resolution = ffi.struct({
	{ unit = ffi.types.pointer },
	{ x = ffi.types.double },
	{ y = ffi.types.double },
})
export type sail_resolution = typeof(sail_resolution:new({}))

local sail_save_features = ffi.struct({
	{ pixel_formats = ffi.types.pointer },
	{ pixel_formats_length = ffi.types.pointer },
	{ features = ffi.types.i32 },
	{ compressions = ffi.types.pointer },
	{ compressions_length = ffi.types.pointer },
	{ default_compression = ffi.types.pointer },
	{ compression_level = ffi.types.pointer },
	{ tuning = ffi.types.pointer },
})
export type sail_save_features = typeof(sail_save_features:new({}))

local sail_save_options = ffi.struct({
	{ options = ffi.types.i32 },
	{ compression = ffi.types.pointer },
	{ compression_level = ffi.types.double },
	{ tuning = ffi.types.pointer },
})
export type sail_save_options = typeof(sail_save_options:new({}))

local sail_source_image = ffi.struct({
	{ pixel_format = ffi.types.pointer },
	{ chroma_subsampling = ffi.types.pointer },
	{ orientation = ffi.types.pointer },
	{ compression = ffi.types.pointer },
	{ interlaced = ffi.types.u8 },
	{ special_properties = ffi.types.pointer },
})
export type sail_source_image = typeof(sail_source_image:new({}))

local sail_string_node = ffi.struct({
	{ string = ffi.types.pointer },
	{ next = ffi.types.pointer },
})
export type sail_string_node = typeof(sail_string_node:new({}))

local sail_variant = ffi.struct({
	{ type = ffi.types.pointer },
	{ value = ffi.types.pointer },
	{ size = ffi.types.u64 },
})
export type sail_variant = typeof(sail_variant:new({}))

local sail_variant_node = ffi.struct({
	{ variant = ffi.types.pointer },
	{ next = ffi.types.pointer },
})
export type sail_variant_node = typeof(sail_variant_node:new({}))

local structs = {
	sail_compression_level = sail_compression_level,
	sail_hash_map = sail_hash_map,
	sail_iccp = sail_iccp,
	sail_image = sail_image,
	sail_io = sail_io,
	linked_list_node = linked_list_node,
	sail_load_features = sail_load_features,
	sail_load_options = sail_load_options,
	sail_meta_data = sail_meta_data,
	sail_meta_data_node = sail_meta_data_node,
	sail_palette = sail_palette,
	sail_pixel3_uint8 = sail_pixel3_uint8,
	sail_pixel4_uint8 = sail_pixel4_uint8,
	sail_pixel3_uint16 = sail_pixel3_uint16,
	sail_pixel4_uint16 = sail_pixel4_uint16,
	sail_pixel3_float = sail_pixel3_float,
	sail_pixel4_float = sail_pixel4_float,
	sail_resolution = sail_resolution,
	sail_save_features = sail_save_features,
	sail_save_options = sail_save_options,
	sail_source_image = sail_source_image,
	sail_string_node = sail_string_node,
	sail_variant = sail_variant,
	sail_variant_node = sail_variant_node,
}

return structs
