local ffi = zune.ffi

-- Type aliases for FFI
type int = number
type float = number
type bool = boolean
type cstring = string
type FFIPointer = typeof(ffi.types.pointer)

-- Import struct types
local structs = require("./structs")
type sail_conversion_options = structs.sail_conversion_options

export type Fns = {
	sail_alloc_conversion_options: (options: FFIPointer) -> FFIPointer,
	sail_can_convert: (input_pixel_format: FFIPointer, output_pixel_format: FFIPointer) -> bool,
	sail_closest_pixel_format: (
		input_pixel_format: FFIPointer,
		pixel_formats: FFIPointer,
		pixel_formats_length: int
	) -> FFIPointer,
	sail_closest_pixel_format_from_save_features: (
		input_pixel_format: FFIPointer,
		save_features: FFIPointer
	) -> FFIPointer,
	sail_convert_image: (image: FFIPointer, output_pixel_format: FFIPointer, image_output: FFIPointer) -> FFIPointer,
	sail_convert_image_for_saving: (
		image: FFIPointer,
		save_features: FFIPointer,
		image_output: FFIPointer
	) -> FFIPointer,
	sail_convert_image_for_saving_with_options: (
		image: FFIPointer,
		save_features: FFIPointer,
		options: FFIPointer,
		image_output: FFIPointer
	) -> FFIPointer,
	sail_convert_image_with_options: (
		image: FFIPointer,
		output_pixel_format: FFIPointer,
		options: FFIPointer,
		image_output: FFIPointer
	) -> FFIPointer,
	sail_destroy_conversion_options: (options: FFIPointer) -> (),
	sail_quantize_image: (
		source_image: FFIPointer,
		output_pixel_format: FFIPointer,
		dither: bool,
		target_image: FFIPointer
	) -> FFIPointer,
	sail_rotate_image: (image: FFIPointer, angle: FFIPointer, image_output: FFIPointer) -> FFIPointer,
	sail_rotate_image_180_inplace: (image: FFIPointer) -> FFIPointer,
	sail_scale_image: (
		image: FFIPointer,
		new_width: FFIPointer,
		new_height: FFIPointer,
		algorithm: FFIPointer,
		image_output: FFIPointer
	) -> FFIPointer,
	sail_scaling_to_swscale_flags: (algorithm: FFIPointer) -> int,
	sail_to_av_pixel_format: (sail_pix_fmt: FFIPointer) -> FFIPointer,
	sail_try_fast_conversion: (
		image_input: FFIPointer,
		image_output: FFIPointer,
		output_pixel_format: FFIPointer
	) -> bool,
	sail_try_swscale_conversion: (
		image_input: FFIPointer,
		image_output: FFIPointer,
		output_pixel_format: FFIPointer
	) -> bool,
	sail_update_image: (image: FFIPointer, output_pixel_format: FFIPointer) -> FFIPointer,
	sail_update_image_with_options: (
		image: FFIPointer,
		output_pixel_format: FFIPointer,
		options: FFIPointer
	) -> FFIPointer,
}

local funcs = {
	sail_alloc_conversion_options = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	sail_destroy_conversion_options = { returns = ffi.types.void, args = { ffi.types.pointer } },
	sail_convert_image = {
		returns = ffi.types.u32,
		args = { ffi.types.pointer, ffi.types.i32, ffi.types.pointer },
	},
	sail_convert_image_with_options = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
	sail_update_image = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.pointer } },
	sail_update_image_with_options = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
	sail_can_convert = { returns = ffi.types.u8, args = { ffi.types.pointer, ffi.types.pointer } },
	sail_closest_pixel_format = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u64 },
	},
	sail_closest_pixel_format_from_save_features = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.pointer },
	},
	sail_convert_image_for_saving = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
	sail_convert_image_for_saving_with_options = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},

	sail_quantize_image = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u8, ffi.types.pointer },
	},
	sail_rotate_image = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
	sail_rotate_image_180_inplace = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	sail_scale_image = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.i32, ffi.types.i32, ffi.types.pointer, ffi.types.pointer },
	},
}

return funcs
