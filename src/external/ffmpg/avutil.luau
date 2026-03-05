--!strict
--!optimize 2
--!native

local ffi = zune.ffi

-- Struct definitions (ordered by dependencies)
-- NOTE: Some structs may have FIXME comments for array sizes that need manual definition

local AVAmbientViewingEnvironment = ffi.struct({
	{ ambient_illuminance = ffi.types.pointer },
	{ ambient_light_x = ffi.types.pointer },
	{ ambient_light_y = ffi.types.pointer },
})
export type AVAmbientViewingEnvironment = typeof(AVAmbientViewingEnvironment:new({}))

local AVBlowfish = ffi.struct({
	-- FIXME: Array size needs manual definition: 16 + 2
	-- { p = ffi.types.u32:array(16 + 2) },
})
export type AVBlowfish = typeof(AVBlowfish:new({}))

local name = ffi.struct({
	-- FIXME: Array size needs manual definition: size - sizeof(struct ff_pad_helper_##name)
	-- { reserved_padding = ffi.types.i8:array(size - sizeof(struct ff_pad_helper_##name)) },
})
export type name = typeof(name:new({}))

local AVBufferRef = ffi.struct({
	{ size = ffi.types.u64 },
})
export type AVBufferRef = typeof(AVBufferRef:new({}))

local AVChannelCustom = ffi.struct({
	{ id = ffi.types.pointer },
	{ name = ffi.types.i8:array(16) },
})
export type AVChannelCustom = typeof(AVChannelCustom:new({}))
local AVPrimaryCoefficients = ffi.struct({
	{ x = ffi.types.pointer },
	{ y = ffi.types.pointer },
	{ z = ffi.types.pointer },
})
export type AVPrimaryCoefficients = typeof(AVPrimaryCoefficients:new({}))

local AVColorPrimariesDesc = ffi.struct({
	{ wp = ffi.types.pointer },
	{ prim = AVPrimaryCoefficients },
})
export type AVColorPrimariesDesc = typeof(AVColorPrimariesDesc:new({}))

local AVDES = ffi.struct({
	{ triple_des = ffi.types.i32 },
})
export type AVDES = typeof(AVDES:new({}))

local AVDetectionBBox = ffi.struct({
	{ x = ffi.types.i32 },
	{ y = ffi.types.i32 },
	{ w = ffi.types.i32 },
	{ h = ffi.types.i32 },
	{ detect_label = ffi.types.i8:array(64) },
	{ detect_confidence = ffi.types.pointer },
	{ classify_count = ffi.types.u32 },
	{ classify_confidences = ffi.types.pointer:array(4) },
})
export type AVDetectionBBox = typeof(AVDetectionBBox:new({}))

local AVDetectionBBoxHeader = ffi.struct({
	{ source = ffi.types.i8:array(256) },
	{ nb_bboxes = ffi.types.u32 },
	{ bboxes_offset = ffi.types.u64 },
	{ bbox_size = ffi.types.u64 },
})
export type AVDetectionBBoxHeader = typeof(AVDetectionBBoxHeader:new({}))

local AVDOVIDecoderConfigurationRecord = ffi.struct({
	{ dv_version_major = ffi.types.u8 },
	{ dv_version_minor = ffi.types.u8 },
	{ dv_profile = ffi.types.u8 },
	{ dv_level = ffi.types.u8 },
	{ rpu_present_flag = ffi.types.u8 },
	{ el_present_flag = ffi.types.u8 },
	{ bl_present_flag = ffi.types.u8 },
	{ dv_bl_signal_compatibility_id = ffi.types.u8 },
	{ dv_md_compression = ffi.types.u8 },
})
export type AVDOVIDecoderConfigurationRecord = typeof(AVDOVIDecoderConfigurationRecord:new({}))

local AVDOVIRpuDataHeader = ffi.struct({
	{ rpu_type = ffi.types.u8 },
	{ rpu_format = ffi.types.u16 },
	{ vdr_rpu_profile = ffi.types.u8 },
	{ vdr_rpu_level = ffi.types.u8 },
	{ chroma_resampling_explicit_filter_flag = ffi.types.u8 },
	{ coef_data_type = ffi.types.u8 },
	{ coef_log2_denom = ffi.types.u8 },
	{ vdr_rpu_normalized_idc = ffi.types.u8 },
	{ bl_video_full_range_flag = ffi.types.u8 },
	{ bl_bit_depth = ffi.types.u8 },
	{ el_bit_depth = ffi.types.u8 },
	{ vdr_bit_depth = ffi.types.u8 },
	{ spatial_resampling_filter_flag = ffi.types.u8 },
	{ el_spatial_resampling_filter_flag = ffi.types.u8 },
	{ disable_residual_flag = ffi.types.u8 },
	{ ext_mapping_idc_0_4 = ffi.types.u8 },
	{ ext_mapping_idc_5_7 = ffi.types.u8 },
})
export type AVDOVIRpuDataHeader = typeof(AVDOVIRpuDataHeader:new({}))

local AVDOVIReshapingCurve = ffi.struct({
	{ num_pivots = ffi.types.u8 },
	-- FIXME: Array size needs manual definition: 8 + 1
	-- { pivots = ffi.types.u16:array(8 + 1) },
	{ mapping_idc = ffi.types.pointer:array(8) },
	{ poly_order = ffi.types.u8:array(8) },
	{ mmr_order = ffi.types.u8:array(8) },
	{ mmr_constant = ffi.types.i64:array(8) },
})
export type AVDOVIReshapingCurve = typeof(AVDOVIReshapingCurve:new({}))

local AVDOVINLQParams = ffi.struct({
	{ nlq_offset = ffi.types.u16 },
	{ vdr_in_max = ffi.types.u64 },
	{ linear_deadzone_slope = ffi.types.u64 },
	{ linear_deadzone_threshold = ffi.types.u64 },
})
export type AVDOVINLQParams = typeof(AVDOVINLQParams:new({}))

local AVDOVIDataMapping = ffi.struct({
	{ vdr_rpu_id = ffi.types.u8 },
	{ mapping_color_space = ffi.types.u8 },
	{ mapping_chroma_format_idc = ffi.types.u8 },
	{ curves = AVDOVIReshapingCurve:array(3) },
	{ nlq_method_idc = ffi.types.pointer },
	{ num_x_partitions = ffi.types.u32 },
	{ num_y_partitions = ffi.types.u32 },
	{ nlq = AVDOVINLQParams:array(3) },
	{ nlq_pivots = ffi.types.u16:array(2) },
})
export type AVDOVIDataMapping = typeof(AVDOVIDataMapping:new({}))

local AVDOVIColorMetadata = ffi.struct({
	{ dm_metadata_id = ffi.types.u8 },
	{ scene_refresh_flag = ffi.types.u8 },
	{ ycc_to_rgb_matrix = ffi.types.pointer:array(9) },
	{ ycc_to_rgb_offset = ffi.types.pointer:array(3) },
	{ rgb_to_lms_matrix = ffi.types.pointer:array(9) },
	{ signal_eotf = ffi.types.u16 },
	{ signal_eotf_param0 = ffi.types.u16 },
	{ signal_eotf_param1 = ffi.types.u16 },
	{ signal_eotf_param2 = ffi.types.u32 },
	{ signal_bit_depth = ffi.types.u8 },
	{ signal_color_space = ffi.types.u8 },
	{ signal_chroma_format = ffi.types.u8 },
	{ signal_full_range_flag = ffi.types.u8 },
	{ source_min_pq = ffi.types.u16 },
	{ source_max_pq = ffi.types.u16 },
	{ source_diagonal = ffi.types.u16 },
})
export type AVDOVIColorMetadata = typeof(AVDOVIColorMetadata:new({}))

local AVDOVIDmLevel1 = ffi.struct({
	{ min_pq = ffi.types.u16 },
	{ max_pq = ffi.types.u16 },
	{ avg_pq = ffi.types.u16 },
})
export type AVDOVIDmLevel1 = typeof(AVDOVIDmLevel1:new({}))

local AVDOVIDmLevel2 = ffi.struct({
	{ target_max_pq = ffi.types.u16 },
	{ trim_slope = ffi.types.u16 },
	{ trim_offset = ffi.types.u16 },
	{ trim_power = ffi.types.u16 },
	{ trim_chroma_weight = ffi.types.u16 },
	{ trim_saturation_gain = ffi.types.u16 },
	{ ms_weight = ffi.types.i16 },
})
export type AVDOVIDmLevel2 = typeof(AVDOVIDmLevel2:new({}))

local AVDOVIDmLevel3 = ffi.struct({
	{ min_pq_offset = ffi.types.u16 },
	{ max_pq_offset = ffi.types.u16 },
	{ avg_pq_offset = ffi.types.u16 },
})
export type AVDOVIDmLevel3 = typeof(AVDOVIDmLevel3:new({}))

local AVDOVIDmLevel4 = ffi.struct({
	{ anchor_pq = ffi.types.u16 },
	{ anchor_power = ffi.types.u16 },
})
export type AVDOVIDmLevel4 = typeof(AVDOVIDmLevel4:new({}))

local AVDOVIDmLevel5 = ffi.struct({
	{ left_offset = ffi.types.u16 },
	{ right_offset = ffi.types.u16 },
	{ top_offset = ffi.types.u16 },
	{ bottom_offset = ffi.types.u16 },
})
export type AVDOVIDmLevel5 = typeof(AVDOVIDmLevel5:new({}))

local AVDOVIDmLevel6 = ffi.struct({
	{ max_luminance = ffi.types.u16 },
	{ min_luminance = ffi.types.u16 },
	{ max_cll = ffi.types.u16 },
	{ max_fall = ffi.types.u16 },
})
export type AVDOVIDmLevel6 = typeof(AVDOVIDmLevel6:new({}))

local AVDOVIDmLevel8 = ffi.struct({
	{ target_display_index = ffi.types.u8 },
	{ trim_slope = ffi.types.u16 },
	{ trim_offset = ffi.types.u16 },
	{ trim_power = ffi.types.u16 },
	{ trim_chroma_weight = ffi.types.u16 },
	{ trim_saturation_gain = ffi.types.u16 },
	{ ms_weight = ffi.types.u16 },
	{ target_mid_contrast = ffi.types.u16 },
	{ clip_trim = ffi.types.u16 },
	{ saturation_vector_field = ffi.types.u8:array(6) },
	{ hue_vector_field = ffi.types.u8:array(6) },
})
export type AVDOVIDmLevel8 = typeof(AVDOVIDmLevel8:new({}))

local AVDOVIDmLevel9 = ffi.struct({
	{ source_primary_index = ffi.types.u8 },
	{ source_display_primaries = ffi.types.pointer },
})
export type AVDOVIDmLevel9 = typeof(AVDOVIDmLevel9:new({}))

local AVDOVIDmLevel10 = ffi.struct({
	{ target_display_index = ffi.types.u8 },
	{ target_max_pq = ffi.types.u16 },
	{ target_min_pq = ffi.types.u16 },
	{ target_primary_index = ffi.types.u8 },
	{ target_display_primaries = ffi.types.pointer },
})
export type AVDOVIDmLevel10 = typeof(AVDOVIDmLevel10:new({}))

local AVDOVIDmLevel11 = ffi.struct({
	{ content_type = ffi.types.u8 },
	{ whitepoint = ffi.types.u8 },
	{ reference_mode_flag = ffi.types.u8 },
	{ sharpness = ffi.types.u8 },
	{ noise_reduction = ffi.types.u8 },
	{ mpeg_noise_reduction = ffi.types.u8 },
	{ frame_rate_conversion = ffi.types.u8 },
	{ brightness = ffi.types.u8 },
	{ color = ffi.types.u8 },
})
export type AVDOVIDmLevel11 = typeof(AVDOVIDmLevel11:new({}))

local AVDOVIDmLevel254 = ffi.struct({
	{ dm_mode = ffi.types.u8 },
	{ dm_version_index = ffi.types.u8 },
})
export type AVDOVIDmLevel254 = typeof(AVDOVIDmLevel254:new({}))

local AVDOVIDmLevel255 = ffi.struct({
	{ dm_run_mode = ffi.types.u8 },
	{ dm_run_version = ffi.types.u8 },
	{ dm_debug = ffi.types.u8:array(4) },
})
export type AVDOVIDmLevel255 = typeof(AVDOVIDmLevel255:new({}))

local AVDOVIMetadata = ffi.struct({
	{ header_offset = ffi.types.u64 },
	{ mapping_offset = ffi.types.u64 },
	{ color_offset = ffi.types.u64 },
	{ ext_block_offset = ffi.types.u64 },
	{ ext_block_size = ffi.types.u64 },
	{ num_ext_blocks = ffi.types.i32 },
})
export type AVDOVIMetadata = typeof(AVDOVIMetadata:new({}))

local AVDownmixInfo = ffi.struct({
	{ preferred_downmix_type = ffi.types.pointer },
	{ center_mix_level = ffi.types.double },
	{ center_mix_level_ltrt = ffi.types.double },
	{ surround_mix_level = ffi.types.double },
	{ surround_mix_level_ltrt = ffi.types.double },
	{ lfe_mix_level = ffi.types.double },
})
export type AVDownmixInfo = typeof(AVDownmixInfo:new({}))

local AVSubsampleEncryptionInfo = ffi.struct({
	{ bytes_of_clear_data = ffi.types.i32 },
	{ bytes_of_protected_data = ffi.types.i32 },
})
export type AVSubsampleEncryptionInfo = typeof(AVSubsampleEncryptionInfo:new({}))

local AVEncryptionInfo = ffi.struct({
	{ scheme = ffi.types.u32 },
	{ crypt_byte_block = ffi.types.u32 },
	{ skip_byte_block = ffi.types.u32 },
	{ key_id_size = ffi.types.u32 },
	{ iv_size = ffi.types.u32 },
	{ subsample_count = ffi.types.u32 },
})
export type AVEncryptionInfo = typeof(AVEncryptionInfo:new({}))

local AVEncryptionInitInfo = ffi.struct({
	{ system_id = ffi.types.pointer },
	{ system_id_size = ffi.types.u32 },
	{ num_key_ids = ffi.types.u32 },
	{ key_id_size = ffi.types.u32 },
	{ data = ffi.types.pointer },
	{ data_size = ffi.types.u32 },
})
export type AVEncryptionInitInfo = typeof(AVEncryptionInitInfo:new({}))

local AVTaskCallbacks = ffi.struct({
	{ local_context_size = ffi.types.i32 },
})
export type AVTaskCallbacks = typeof(AVTaskCallbacks:new({}))

local AVFilmGrainAOMParams = ffi.struct({
	{ num_y_points = ffi.types.i32 },
	{ chroma_scaling_from_luma = ffi.types.i32 },
	{ num_uv_points = ffi.types.i32:array(2) },
	{ scaling_shift = ffi.types.i32 },
	{ ar_coeff_lag = ffi.types.i32 },
	{ ar_coeffs_y = ffi.types.i8:array(24) },
	{ ar_coeff_shift = ffi.types.i32 },
	{ grain_scale_shift = ffi.types.i32 },
	{ uv_mult = ffi.types.i32:array(2) },
	{ uv_mult_luma = ffi.types.i32:array(2) },
	{ uv_offset = ffi.types.i32:array(2) },
	{ overlap_flag = ffi.types.i32 },
	{ limit_output_range = ffi.types.i32 },
})
export type AVFilmGrainAOMParams = typeof(AVFilmGrainAOMParams:new({}))

local AVFilmGrainH274Params = ffi.struct({
	{ model_id = ffi.types.i32 },
	{ blending_mode_id = ffi.types.i32 },
	{ log2_scale_factor = ffi.types.i32 },
	{ component_model_present = ffi.types.i32:array(3) },
	{ num_intensity_intervals = ffi.types.u16:array(3) },
	{ num_model_values = ffi.types.u8:array(3) },
})
export type AVFilmGrainH274Params = typeof(AVFilmGrainH274Params:new({}))

local codec = ffi.struct({
	{ type = ffi.types.pointer },
	{ seed = ffi.types.u64 },
	{ color_range = ffi.types.pointer },
	{ color_primaries = ffi.types.pointer },
	{ color_trc = ffi.types.pointer },
	{ color_space = ffi.types.pointer },
	{ bit_depth_luma = ffi.types.i32 },
	{ bit_depth_chroma = ffi.types.i32 },
	{ aom = AVFilmGrainAOMParams },
	{ h274 = AVFilmGrainH274Params },
})
export type codec = typeof(codec:new({}))

local AVFrameSideData = ffi.struct({
	{ type = ffi.types.pointer },
	{ size = ffi.types.u64 },
})
export type AVFrameSideData = typeof(AVFrameSideData:new({}))

local AVSideDataDescriptor = ffi.struct({
	{ props = ffi.types.pointer },
})
export type AVSideDataDescriptor = typeof(AVSideDataDescriptor:new({}))

local AVRegionOfInterest = ffi.struct({
	{ self_size = ffi.types.u32 },
	{ top = ffi.types.i32 },
	{ bottom = ffi.types.i32 },
	{ left = ffi.types.i32 },
	{ right = ffi.types.i32 },
	{ qoffset = ffi.types.pointer },
})
export type AVRegionOfInterest = typeof(AVRegionOfInterest:new({}))

local AVFrame = ffi.struct({
	{ linesize = ffi.types.i32:array(8) },
	{ nb_samples = ffi.types.i32 },
	{ format = ffi.types.i32 },
	{ pict_type = ffi.types.pointer },
	{ sample_aspect_ratio = ffi.types.pointer },
	{ pts = ffi.types.i64 },

	{ pkt_dts = ffi.types.i64 },
	{ time_base = ffi.types.pointer },
	{ quality = ffi.types.i32 },
	{ repeat_pict = ffi.types.i32 },
	{ sample_rate = ffi.types.i32 },
	{ nb_extended_buf = ffi.types.i32 },
	{ nb_side_data = ffi.types.i32 },
	{ flags = ffi.types.i32 },
	{ color_range = ffi.types.pointer },
	{ color_primaries = ffi.types.pointer },
	{ color_trc = ffi.types.pointer },
	{ colorspace = ffi.types.pointer },
	{ chroma_location = ffi.types.pointer },
	{ best_effort_timestamp = ffi.types.i64 },
	{ decode_error_flags = ffi.types.i32 },
	{ crop_top = ffi.types.u64 },
	{ crop_bottom = ffi.types.u64 },
	{ crop_left = ffi.types.u64 },
	{ crop_right = ffi.types.u64 },
	{ ch_layout = ffi.types.pointer },
	{ duration = ffi.types.i64 },
})
export type AVFrame = typeof(AVFrame:new({}))

local AVHDRPlusPercentile = ffi.struct({
	{ percentage = ffi.types.u8 },
	{ percentile = ffi.types.pointer },
})
export type AVHDRPlusPercentile = typeof(AVHDRPlusPercentile:new({}))

local AVHDRPlusColorTransformParams = ffi.struct({
	{ window_upper_left_corner_x = ffi.types.pointer },
	{ window_upper_left_corner_y = ffi.types.pointer },
	{ window_lower_right_corner_x = ffi.types.pointer },
	{ window_lower_right_corner_y = ffi.types.pointer },
	{ center_of_ellipse_x = ffi.types.u16 },
	{ center_of_ellipse_y = ffi.types.u16 },
	{ rotation_angle = ffi.types.u8 },
	{ semimajor_axis_internal_ellipse = ffi.types.u16 },
	{ semimajor_axis_external_ellipse = ffi.types.u16 },
	{ semiminor_axis_external_ellipse = ffi.types.u16 },
	{ overlap_process_option = ffi.types.pointer },
	{ maxscl = ffi.types.pointer:array(3) },
	{ average_maxrgb = ffi.types.pointer },
	{ num_distribution_maxrgb_percentiles = ffi.types.u8 },
	{ distribution_maxrgb = AVHDRPlusPercentile:array(15) },
	{ fraction_bright_pixels = ffi.types.pointer },
	{ tone_mapping_flag = ffi.types.u8 },
	{ knee_point_x = ffi.types.pointer },
	{ knee_point_y = ffi.types.pointer },
	{ num_bezier_curve_anchors = ffi.types.u8 },
	{ bezier_curve_anchors = ffi.types.pointer:array(15) },
	{ color_saturation_mapping_flag = ffi.types.u8 },
	{ color_saturation_weight = ffi.types.pointer },
})
export type AVHDRPlusColorTransformParams = typeof(AVHDRPlusColorTransformParams:new({}))

local AVDynamicHDRPlus = ffi.struct({
	{ itu_t_t35_country_code = ffi.types.u8 },
	{ application_version = ffi.types.u8 },
	{ num_windows = ffi.types.u8 },
	{ params = AVHDRPlusColorTransformParams:array(3) },
	{ targeted_system_display_maximum_luminance = ffi.types.pointer },
	{ targeted_system_display_actual_peak_luminance_flag = ffi.types.u8 },
	{ num_rows_targeted_system_display_actual_peak_luminance = ffi.types.u8 },
	{ num_cols_targeted_system_display_actual_peak_luminance = ffi.types.u8 },
	{ mastering_display_actual_peak_luminance_flag = ffi.types.u8 },
	{ num_rows_mastering_display_actual_peak_luminance = ffi.types.u8 },
	{ num_cols_mastering_display_actual_peak_luminance = ffi.types.u8 },
})
export type AVDynamicHDRPlus = typeof(AVDynamicHDRPlus:new({}))

local AVHDRVivid3SplineParams = ffi.struct({
	{ th_mode = ffi.types.i32 },
	{ th_enable_mb = ffi.types.pointer },
	{ th_enable = ffi.types.pointer },
	{ th_delta1 = ffi.types.pointer },
	{ th_delta2 = ffi.types.pointer },
	{ enable_strength = ffi.types.pointer },
})
export type AVHDRVivid3SplineParams = typeof(AVHDRVivid3SplineParams:new({}))

local AVHDRVividColorToneMappingParams = ffi.struct({
	{ targeted_system_display_maximum_luminance = ffi.types.pointer },
	{ base_enable_flag = ffi.types.i32 },
	{ base_param_m_p = ffi.types.pointer },
	{ base_param_m_m = ffi.types.pointer },
	{ base_param_m_a = ffi.types.pointer },
	{ base_param_m_b = ffi.types.pointer },
	{ base_param_m_n = ffi.types.pointer },
	{ base_param_k1 = ffi.types.i32 },
	{ base_param_k2 = ffi.types.i32 },
	{ base_param_k3 = ffi.types.i32 },
	{ base_param_Delta_enable_mode = ffi.types.i32 },
	{ base_param_Delta = ffi.types.pointer },
	{ three_Spline_enable_flag = ffi.types.i32 },
	{ three_Spline_num = ffi.types.i32 },
	{ three_spline = AVHDRVivid3SplineParams:array(2) },
})
export type AVHDRVividColorToneMappingParams = typeof(AVHDRVividColorToneMappingParams:new({}))

local AVHDRVividColorTransformParams = ffi.struct({
	{ minimum_maxrgb = ffi.types.pointer },
	{ average_maxrgb = ffi.types.pointer },
	{ variance_maxrgb = ffi.types.pointer },
	{ maximum_maxrgb = ffi.types.pointer },
	{ tone_mapping_mode_flag = ffi.types.i32 },
	{ tone_mapping_param_num = ffi.types.i32 },
	{ tm_params = AVHDRVividColorToneMappingParams:array(2) },
	{ color_saturation_mapping_flag = ffi.types.i32 },
	{ color_saturation_num = ffi.types.i32 },
	{ color_saturation_gain = ffi.types.pointer:array(8) },
})
export type AVHDRVividColorTransformParams = typeof(AVHDRVividColorTransformParams:new({}))

local AVDynamicHDRVivid = ffi.struct({
	{ system_start_code = ffi.types.u8 },
	{ num_windows = ffi.types.u8 },
	{ params = AVHDRVividColorTransformParams:array(3) },
})
export type AVDynamicHDRVivid = typeof(AVDynamicHDRVivid:new({}))

local AVHWDeviceContext = ffi.struct({
	{ type = ffi.types.pointer },
})
export type AVHWDeviceContext = typeof(AVHWDeviceContext:new({}))

local AVHWFramesContext = ffi.struct({
	{ initial_pool_size = ffi.types.i32 },
	{ format = ffi.types.pointer },
	{ sw_format = ffi.types.pointer },
})
export type AVHWFramesContext = typeof(AVHWFramesContext:new({}))

local AVHWFramesConstraints = ffi.struct({
	{ min_width = ffi.types.i32 },
	{ min_height = ffi.types.i32 },
	{ max_width = ffi.types.i32 },
	{ max_height = ffi.types.i32 },
})
export type AVHWFramesConstraints = typeof(AVHWFramesConstraints:new({}))

local AVAMFDeviceContext = ffi.struct({
	{ library = ffi.types.pointer },
	{ version = ffi.types.i64 },
	{ memory_type = ffi.types.pointer },
})
export type AVAMFDeviceContext = typeof(AVAMFDeviceContext:new({}))

local AVCUDADeviceContext = ffi.struct({
	{ cuda_ctx = ffi.types.pointer },
	{ stream = ffi.types.pointer },
})
export type AVCUDADeviceContext = typeof(AVCUDADeviceContext:new({}))

local AVD3D11FrameDescriptor = ffi.struct({
	{ index = ffi.types.pointer },
})
export type AVD3D11FrameDescriptor = typeof(AVD3D11FrameDescriptor:new({}))

local AVD3D11VAFramesContext = ffi.struct({
	{ BindFlags = ffi.types.pointer },
	{ MiscFlags = ffi.types.pointer },
})
export type AVD3D11VAFramesContext = typeof(AVD3D11VAFramesContext:new({}))

local AVD3D12VASyncContext = ffi.struct({
	{ event = ffi.types.pointer },
	{ fence_value = ffi.types.u64 },
})
export type AVD3D12VASyncContext = typeof(AVD3D12VASyncContext:new({}))

local AVD3D12VAFrame = ffi.struct({
	{ sync_ctx = AVD3D12VASyncContext },
})
export type AVD3D12VAFrame = typeof(AVD3D12VAFrame:new({}))

local AVD3D12VAFramesContext = ffi.struct({
	{ format = ffi.types.pointer },
	{ flags = ffi.types.pointer },
})
export type AVD3D12VAFramesContext = typeof(AVD3D12VAFramesContext:new({}))

local AVDRMObjectDescriptor = ffi.struct({
	{ fd = ffi.types.i32 },
	{ size = ffi.types.u64 },
	{ format_modifier = ffi.types.u64 },
})
export type AVDRMObjectDescriptor = typeof(AVDRMObjectDescriptor:new({}))

local AVDRMPlaneDescriptor = ffi.struct({
	{ object_index = ffi.types.i32 },
	{ offset = ffi.types.pointer },
	{ pitch = ffi.types.pointer },
})
export type AVDRMPlaneDescriptor = typeof(AVDRMPlaneDescriptor:new({}))

local AVDRMLayerDescriptor = ffi.struct({
	{ format = ffi.types.u32 },
	{ nb_planes = ffi.types.i32 },
	-- FIXME: Array size needs manual definition: AV_DRM_MAX_PLANES
	-- { planes = AVDRMPlaneDescriptor:array(AV_DRM_MAX_PLANES) },
})
export type AVDRMLayerDescriptor = typeof(AVDRMLayerDescriptor:new({}))

local AVDRMFrameDescriptor = ffi.struct({
	{ nb_objects = ffi.types.i32 },
	-- FIXME: Array size needs manual definition: AV_DRM_MAX_PLANES
	-- { objects = AVDRMObjectDescriptor:array(AV_DRM_MAX_PLANES) },
	{ nb_layers = ffi.types.i32 },
	-- FIXME: Array size needs manual definition: AV_DRM_MAX_PLANES
	-- { layers = AVDRMLayerDescriptor:array(AV_DRM_MAX_PLANES) },
})
export type AVDRMFrameDescriptor = typeof(AVDRMFrameDescriptor:new({}))

local AVDRMDeviceContext = ffi.struct({
	{ fd = ffi.types.i32 },
})
export type AVDRMDeviceContext = typeof(AVDRMDeviceContext:new({}))

local AVDXVA2FramesContext = ffi.struct({
	{ surface_type = ffi.types.pointer },
	{ nb_surfaces = ffi.types.i32 },
})
export type AVDXVA2FramesContext = typeof(AVDXVA2FramesContext:new({}))

local AVMediaCodecDeviceContext = ffi.struct({
	{ create_window = ffi.types.i32 },
})
export type AVMediaCodecDeviceContext = typeof(AVMediaCodecDeviceContext:new({}))

local AVOpenCLFrameDescriptor = ffi.struct({
	{ nb_planes = ffi.types.i32 },
	-- FIXME: Array size needs manual definition: AV_NUM_DATA_POINTERS
	-- { planes = ffi.types.pointer:array(AV_NUM_DATA_POINTERS) },
})
export type AVOpenCLFrameDescriptor = typeof(AVOpenCLFrameDescriptor:new({}))

local AVOpenCLDeviceContext = ffi.struct({
	{ device_id = ffi.types.pointer },
	{ context = ffi.types.pointer },
	{ command_queue = ffi.types.pointer },
})
export type AVOpenCLDeviceContext = typeof(AVOpenCLDeviceContext:new({}))

local AVOpenCLFramesContext = ffi.struct({
	{ command_queue = ffi.types.pointer },
})
export type AVOpenCLFramesContext = typeof(AVOpenCLFramesContext:new({}))

local AVQSVDeviceContext = ffi.struct({
	{ session = ffi.types.pointer },
})
export type AVQSVDeviceContext = typeof(AVQSVDeviceContext:new({}))

local AVQSVFramesContext = ffi.struct({
	{ nb_surfaces = ffi.types.i32 },
	{ frame_type = ffi.types.i32 },
})
export type AVQSVFramesContext = typeof(AVQSVFramesContext:new({}))

local AVVAAPIDeviceContext = ffi.struct({
	{ display = ffi.types.pointer },
	{ driver_quirks = ffi.types.i32 },
})
export type AVVAAPIDeviceContext = typeof(AVVAAPIDeviceContext:new({}))

local AVVAAPIFramesContext = ffi.struct({
	{ nb_attributes = ffi.types.i32 },
	{ nb_surfaces = ffi.types.i32 },
})
export type AVVAAPIFramesContext = typeof(AVVAAPIFramesContext:new({}))

local AVVAAPIHWConfig = ffi.struct({
	{ config_id = ffi.types.pointer },
})
export type AVVAAPIHWConfig = typeof(AVVAAPIHWConfig:new({}))

local AVVDPAUDeviceContext = ffi.struct({
	{ device = ffi.types.pointer },
})
export type AVVDPAUDeviceContext = typeof(AVVDPAUDeviceContext:new({}))

local AVVTFramesContext = ffi.struct({
	{ color_range = ffi.types.pointer },
})
export type AVVTFramesContext = typeof(AVVTFramesContext:new({}))

local AVVulkanDeviceQueueFamily = ffi.struct({
	{ idx = ffi.types.i32 },
	{ num = ffi.types.i32 },
	{ flags = ffi.types.pointer },
	{ video_caps = ffi.types.pointer },
})
export type AVVulkanDeviceQueueFamily = typeof(AVVulkanDeviceQueueFamily:new({}))

local AVVulkanDeviceContext = ffi.struct({
	{ get_proc_addr = ffi.types.pointer },
	{ inst = ffi.types.pointer },
	{ phys_dev = ffi.types.pointer },
	{ act_dev = ffi.types.pointer },
	{ device_features = ffi.types.pointer },
	{ nb_enabled_inst_extensions = ffi.types.i32 },
	{ nb_enabled_dev_extensions = ffi.types.i32 },
	{ queue_family_index = ffi.types.i32 },
	{ nb_graphics_queues = ffi.types.i32 },
	{ queue_family_tx_index = ffi.types.i32 },
	{ nb_tx_queues = ffi.types.i32 },
	{ queue_family_comp_index = ffi.types.i32 },
	{ nb_comp_queues = ffi.types.i32 },
	{ queue_family_encode_index = ffi.types.i32 },
	{ nb_encode_queues = ffi.types.i32 },
	{ queue_family_decode_index = ffi.types.i32 },
	{ nb_decode_queues = ffi.types.i32 },
	{ qf = AVVulkanDeviceQueueFamily:array(64) },
	{ nb_qf = ffi.types.i32 },
})
export type AVVulkanDeviceContext = typeof(AVVulkanDeviceContext:new({}))

local AVVulkanFramesContext = ffi.struct({
	{ tiling = ffi.types.pointer },
	{ usage = ffi.types.pointer },
	{ flags = ffi.types.pointer },
	{ img_flags = ffi.types.pointer },
	-- FIXME: Array size needs manual definition: AV_NUM_DATA_POINTERS
	-- { format = ffi.types.pointer:array(AV_NUM_DATA_POINTERS) },
	{ nb_layers = ffi.types.i32 },
})
export type AVVulkanFramesContext = typeof(AVVulkanFramesContext:new({}))

local AVIAMFMixGain = ffi.struct({
	{ subblock_duration = ffi.types.i32 },
	{ animation_type = ffi.types.pointer },
	{ start_point_value = ffi.types.pointer },
	{ end_point_value = ffi.types.pointer },
	{ control_point_value = ffi.types.pointer },
	{ control_point_relative_time = ffi.types.pointer },
})
export type AVIAMFMixGain = typeof(AVIAMFMixGain:new({}))

local AVIAMFDemixingInfo = ffi.struct({
	{ subblock_duration = ffi.types.i32 },
	{ dmixp_mode = ffi.types.i32 },
})
export type AVIAMFDemixingInfo = typeof(AVIAMFDemixingInfo:new({}))

local AVIAMFReconGain = ffi.struct({
	{ subblock_duration = ffi.types.i32 },
})
export type AVIAMFReconGain = typeof(AVIAMFReconGain:new({}))

local AVIAMFParamDefinition = ffi.struct({
	{ subblocks_offset = ffi.types.u64 },
	{ subblock_size = ffi.types.u64 },
	{ nb_subblocks = ffi.types.i32 },
	{ type = ffi.types.pointer },
	{ parameter_id = ffi.types.i32 },
	{ parameter_rate = ffi.types.i32 },
	{ duration = ffi.types.i32 },
	{ constant_subblock_duration = ffi.types.i32 },
})
export type AVIAMFParamDefinition = typeof(AVIAMFParamDefinition:new({}))

local AVIAMFLayer = ffi.struct({
	{ ch_layout = ffi.types.pointer },
	{ flags = ffi.types.i32 },
	{ output_gain_flags = ffi.types.i32 },
	{ output_gain = ffi.types.pointer },
	{ ambisonics_mode = ffi.types.pointer },
})
export type AVIAMFLayer = typeof(AVIAMFLayer:new({}))

local AVIAMFAudioElement = ffi.struct({
	{ nb_layers = ffi.types.i32 },
	{ audio_element_type = ffi.types.pointer },
	{ default_w = ffi.types.i32 },
})
export type AVIAMFAudioElement = typeof(AVIAMFAudioElement:new({}))

local AVIAMFSubmixElement = ffi.struct({
	{ audio_element_id = ffi.types.i32 },
	{ default_mix_gain = ffi.types.pointer },
	{ headphones_rendering_mode = ffi.types.pointer },
})
export type AVIAMFSubmixElement = typeof(AVIAMFSubmixElement:new({}))

local AVIAMFSubmixLayout = ffi.struct({
	{ layout_type = ffi.types.pointer },
	{ sound_system = ffi.types.pointer },
	{ integrated_loudness = ffi.types.pointer },
	{ digital_peak = ffi.types.pointer },
	{ true_peak = ffi.types.pointer },
	{ dialogue_anchored_loudness = ffi.types.pointer },
	{ album_anchored_loudness = ffi.types.pointer },
})
export type AVIAMFSubmixLayout = typeof(AVIAMFSubmixLayout:new({}))

local AVIAMFSubmix = ffi.struct({
	{ nb_elements = ffi.types.i32 },
	{ nb_layouts = ffi.types.i32 },
	{ default_mix_gain = ffi.types.pointer },
})
export type AVIAMFSubmix = typeof(AVIAMFSubmix:new({}))

local AVIAMFMixPresentation = ffi.struct({
	{ nb_submixes = ffi.types.i32 },
})
export type AVIAMFMixPresentation = typeof(AVIAMFMixPresentation:new({}))

local AVLFG = ffi.struct({
	{ state = ffi.types.i32:array(64) },
	{ index = ffi.types.i32 },
})
export type AVLFG = typeof(AVLFG:new({}))

local AVClass = ffi.struct({
	{ class_name = ffi.types.pointer },
	{ version = ffi.types.i32 },
	{ log_level_offset_offset = ffi.types.i32 },
	{ parent_log_context_offset = ffi.types.i32 },
	{ category = ffi.types.pointer },
	{ state_flags_offset = ffi.types.i32 },
})
export type AVClass = typeof(AVClass:new({}))

local AVMasteringDisplayMetadata = ffi.struct({
	{ white_point = ffi.types.pointer:array(2) },
	{ min_luminance = ffi.types.pointer },
	{ max_luminance = ffi.types.pointer },
	{ has_primaries = ffi.types.i32 },
	{ has_luminance = ffi.types.i32 },
})
export type AVMasteringDisplayMetadata = typeof(AVMasteringDisplayMetadata:new({}))

local AVContentLightMetadata = ffi.struct({
	{ MaxCLL = ffi.types.pointer },
	{ MaxFALL = ffi.types.pointer },
})
export type AVContentLightMetadata = typeof(AVContentLightMetadata:new({}))

local AVMotionVector = ffi.struct({
	{ source = ffi.types.i32 },
	{ flags = ffi.types.u64 },
	{ motion_scale = ffi.types.u16 },
})
export type AVMotionVector = typeof(AVMotionVector:new({}))

local AVOptionArrayDef = ffi.struct({
	{ size_min = ffi.types.pointer },
	{ size_max = ffi.types.pointer },
	{ sep = ffi.types.i8 },
})
export type AVOptionArrayDef = typeof(AVOptionArrayDef:new({}))

local default_val = ffi.struct({
	{ offset = ffi.types.i32 },
	{ type = ffi.types.pointer },
	{ i64 = ffi.types.i64 },
	{ dbl = ffi.types.double },
	{ q = ffi.types.pointer },
})
export type default_val = typeof(default_val:new({}))

local AVOptionRange = ffi.struct({
	{ is_range = ffi.types.i32 },
})
export type AVOptionRange = typeof(AVOptionRange:new({}))

local AVOptionRanges = ffi.struct({
	{ nb_ranges = ffi.types.i32 },
	{ nb_components = ffi.types.i32 },
})
export type AVOptionRanges = typeof(AVOptionRanges:new({}))

local AVComponentDescriptor = ffi.struct({
	{ plane = ffi.types.i32 },
	{ step = ffi.types.i32 },
	{ offset = ffi.types.i32 },
	{ shift = ffi.types.i32 },
	{ depth = ffi.types.i32 },
})
export type AVComponentDescriptor = typeof(AVComponentDescriptor:new({}))

local AVPixFmtDescriptor = ffi.struct({
	{ nb_components = ffi.types.u8 },
	{ log2_chroma_w = ffi.types.u8 },
	{ log2_chroma_h = ffi.types.u8 },
	{ flags = ffi.types.u64 },
	{ comp = AVComponentDescriptor:array(4) },
})
export type AVPixFmtDescriptor = typeof(AVPixFmtDescriptor:new({}))

local AVRational = ffi.struct({
	{ num = ffi.types.i32 },
	{ den = ffi.types.i32 },
})
export type AVRational = typeof(AVRational:new({}))

local AVRC4 = ffi.struct({
	{ state = ffi.types.u8:array(256) },
})
export type AVRC4 = typeof(AVRC4:new({}))

local AVReplayGain = ffi.struct({
	{ track_gain = ffi.types.i32 },
	{ track_peak = ffi.types.u32 },
	{ album_gain = ffi.types.i32 },
	{ album_peak = ffi.types.u32 },
})
export type AVReplayGain = typeof(AVReplayGain:new({}))

local AVSphericalMapping = ffi.struct({
	{ projection = ffi.types.pointer },
	{ yaw = ffi.types.i32 },
	{ pitch = ffi.types.i32 },
	{ roll = ffi.types.i32 },
	{ bound_left = ffi.types.u32 },
	{ bound_top = ffi.types.u32 },
	{ bound_right = ffi.types.u32 },
	{ bound_bottom = ffi.types.u32 },
	{ padding = ffi.types.u32 },
})
export type AVSphericalMapping = typeof(AVSphericalMapping:new({}))

local AVStereo3D = ffi.struct({
	{ type = ffi.types.pointer },
	{ flags = ffi.types.i32 },
	{ view = ffi.types.pointer },
	{ primary_eye = ffi.types.pointer },
	{ baseline = ffi.types.u32 },
	{ horizontal_disparity_adjustment = ffi.types.pointer },
	{ horizontal_field_of_view = ffi.types.pointer },
})
export type AVStereo3D = typeof(AVStereo3D:new({}))

local AV3DReferenceDisplaysInfo = ffi.struct({
	{ prec_ref_display_width = ffi.types.u8 },
	{ ref_viewing_distance_flag = ffi.types.u8 },
	{ prec_ref_viewing_dist = ffi.types.u8 },
	{ num_ref_displays = ffi.types.u8 },
	{ entries_offset = ffi.types.u64 },
	{ entry_size = ffi.types.u64 },
})
export type AV3DReferenceDisplaysInfo = typeof(AV3DReferenceDisplaysInfo:new({}))

local AV3DReferenceDisplay = ffi.struct({
	{ left_view_id = ffi.types.u16 },
	{ right_view_id = ffi.types.u16 },
	{ exponent_ref_display_width = ffi.types.u8 },
	{ mantissa_ref_display_width = ffi.types.u8 },
	{ exponent_ref_viewing_distance = ffi.types.u8 },
	{ mantissa_ref_viewing_distance = ffi.types.u8 },
	{ additional_shift_present_flag = ffi.types.u8 },
	{ num_sample_shift = ffi.types.i16 },
})
export type AV3DReferenceDisplay = typeof(AV3DReferenceDisplay:new({}))

local AVTimecode = ffi.struct({
	{ start = ffi.types.i32 },
	{ flags = ffi.types.u32 },
	{ rate = ffi.types.pointer },
	{ fps = ffi.types.pointer },
})
export type AVTimecode = typeof(AVTimecode:new({}))

local AVVideoEncParams = ffi.struct({
	{ nb_blocks = ffi.types.i32 },
	{ blocks_offset = ffi.types.u64 },
	{ block_size = ffi.types.u64 },
	{ type = ffi.types.pointer },
	{ qp = ffi.types.i32 },
})
export type AVVideoEncParams = typeof(AVVideoEncParams:new({}))

local AVVideoBlockParams = ffi.struct({
	{ delta_qp = ffi.types.i32 },
})
export type AVVideoBlockParams = typeof(AVVideoBlockParams:new({}))

local AVVideoHint = ffi.struct({
	{ nb_rects = ffi.types.u64 },
	{ rect_offset = ffi.types.u64 },
	{ rect_size = ffi.types.u64 },
	{ type = ffi.types.pointer },
})
export type AVVideoHint = typeof(AVVideoHint:new({}))

local AVXTEA = ffi.struct({
	{ key = ffi.types.u32:array(16) },
})
export type AVXTEA = typeof(AVXTEA:new({}))

-- Function definitions
local funcs = {
	av_aes_init = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32, ffi.types.i32 },
	},
	av_aes_crypt = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u8, ffi.types.pointer, ffi.types.i32, ffi.types.u8, ffi.types.i32 },
	},
	av_aes_ctr_init = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer } },
	av_aes_ctr_free = { returns = ffi.types.void, args = { ffi.types.pointer } },
	av_aes_ctr_crypt = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u8, ffi.types.pointer, ffi.types.i32 },
	},
	av_aes_ctr_get_iv = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	av_aes_ctr_set_random_iv = { returns = ffi.types.void, args = { ffi.types.pointer } },
	av_aes_ctr_set_iv = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.pointer } },
	av_aes_ctr_set_full_iv = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.pointer } },
	av_aes_ctr_increment_iv = { returns = ffi.types.void, args = { ffi.types.pointer } },
	av_audio_fifo_free = { returns = ffi.types.void, args = { ffi.types.pointer } },
	av_audio_fifo_realloc = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.i32 } },
	av_audio_fifo_write = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 } },
	av_audio_fifo_peek = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 } },
	av_audio_fifo_peek_at = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32, ffi.types.i32 },
	},
	av_audio_fifo_read = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 } },
	av_audio_fifo_drain = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.i32 } },
	av_audio_fifo_reset = { returns = ffi.types.void, args = { ffi.types.pointer } },
	av_audio_fifo_size = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_audio_fifo_space = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_assert0_fpu = { returns = ffi.types.void, args = {} },
	av_match_name = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer } },
	av_escape = {
		returns = ffi.types.i32,
		args = { ffi.types.i8, ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.i32 },
	},
	av_utf8_decode = {
		returns = ffi.types.i32,
		args = { ffi.types.i32, ffi.types.pointer, ffi.types.pointer, ffi.types.u32 },
	},
	av_match_list = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i8 } },
	avutil_version = { returns = ffi.types.pointer, args = {} },
	av_get_picture_type_char = { returns = ffi.types.i8, args = { ffi.types.pointer } },
	av_get_time_base_q = { returns = ffi.types.pointer, args = {} },
	av_base64_decode = { returns = ffi.types.i32, args = { ffi.types.u8, ffi.types.pointer, ffi.types.i32 } },
	av_blowfish_init = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 } },
	av_blowfish_crypt_ecb = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u32, ffi.types.u32, ffi.types.i32 },
	},
	av_blowfish_crypt = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u8, ffi.types.pointer, ffi.types.i32, ffi.types.u8, ffi.types.i32 },
	},
	av_bprint_init = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer } },
	av_bprint_init_for_buffer = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.i8, ffi.types.pointer },
	},
	av_vbprintf = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer } },
	av_bprint_chars = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.i8, ffi.types.pointer } },
	av_bprint_append_data = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
	av_bprint_strftime = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
	av_bprint_get_buffer = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u8, ffi.types.pointer },
	},
	av_bprint_clear = { returns = ffi.types.void, args = { ffi.types.pointer } },
	av_bprint_finalize = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.i8 } },
	av_bprint_escape = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.i32 },
	},
	av_buffer_default_free = { returns = ffi.types.void, args = { ffi.types.u8 } },
	av_buffer_unref = { returns = ffi.types.void, args = { ffi.types.pointer } },
	av_buffer_is_writable = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_buffer_get_ref_count = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_buffer_make_writable = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_buffer_realloc = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.u64 } },
	av_buffer_replace = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer } },
	av_buffer_pool_uninit = { returns = ffi.types.void, args = { ffi.types.pointer } },
	av_camellia_init = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 } },
	av_camellia_crypt = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u8, ffi.types.pointer, ffi.types.i32, ffi.types.pointer, ffi.types.i32 },
	},
	av_cast5_init = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 } },
	av_cast5_crypt = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u8, ffi.types.pointer, ffi.types.i32, ffi.types.i32 },
	},
	av_cast5_crypt2 = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u8, ffi.types.pointer, ffi.types.i32, ffi.types.u8, ffi.types.i32 },
	},
	av_channel_name = { returns = ffi.types.i32, args = { ffi.types.i8, ffi.types.u64, ffi.types.pointer } },
	av_channel_name_bprint = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.pointer } },
	av_channel_description = { returns = ffi.types.i32, args = { ffi.types.i8, ffi.types.u64, ffi.types.pointer } },
	av_channel_description_bprint = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.pointer } },
	av_channel_from_string = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	av_channel_layout_custom_init = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.i32 } },
	av_channel_layout_from_mask = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.u64 } },
	av_channel_layout_from_string = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer } },
	av_channel_layout_default = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.i32 } },
	av_channel_layout_uninit = { returns = ffi.types.void, args = { ffi.types.pointer } },
	av_channel_layout_copy = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer } },
	av_channel_layout_describe = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.i8, ffi.types.u64 } },
	av_channel_layout_describe_bprint = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer } },
	av_channel_layout_channel_from_index = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.u32 } },
	av_channel_layout_index_from_channel = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer } },
	av_channel_layout_index_from_string = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer } },
	av_channel_layout_channel_from_string = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.pointer },
	},
	av_channel_layout_subset = { returns = ffi.types.u64, args = { ffi.types.pointer, ffi.types.u64 } },
	av_channel_layout_check = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_channel_layout_compare = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer } },
	av_channel_layout_ambisonic_order = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_channel_layout_retype = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 },
	},
	av_log2 = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	av_log2_16bit = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	av_container_fifo_free = { returns = ffi.types.void, args = { ffi.types.pointer } },
	av_container_fifo_write = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer },
	},
	av_container_fifo_read = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer },
	},
	av_container_fifo_peek = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.u64 } },
	av_container_fifo_drain = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.u64 } },
	av_container_fifo_can_read = { returns = ffi.types.u64, args = { ffi.types.pointer } },
	av_get_cpu_flags = { returns = ffi.types.i32, args = {} },
	av_force_cpu_flags = { returns = ffi.types.void, args = { ffi.types.i32 } },
	av_parse_cpu_caps = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer } },
	av_cpu_count = { returns = ffi.types.i32, args = {} },
	av_cpu_force_count = { returns = ffi.types.void, args = { ffi.types.i32 } },
	av_cpu_max_align = { returns = ffi.types.u64, args = {} },
	av_crc_init = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.i32, ffi.types.i32, ffi.types.u32, ffi.types.i32 },
	},
	av_csp_primaries_id_from_desc = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	av_csp_approximate_trc_gamma = { returns = ffi.types.double, args = { ffi.types.pointer } },
	av_csp_trc_func_from_id = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	av_csp_trc_func_inv_from_id = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	av_csp_itu_eotf = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	av_csp_itu_eotf_inv = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	av_des_init = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32, ffi.types.i32 },
	},
	av_des_crypt = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u8, ffi.types.pointer, ffi.types.i32, ffi.types.u8, ffi.types.i32 },
	},
	av_des_mac = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u8, ffi.types.pointer, ffi.types.i32 },
	},
	av_dict_count = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_dict_set = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.i32 },
	},
	av_dict_set_int = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i64, ffi.types.i32 },
	},
	av_dict_parse_string = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.i32 },
	},
	av_dict_copy = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 } },
	av_dict_free = { returns = ffi.types.void, args = { ffi.types.pointer } },
	av_dict_get_string = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.i8, ffi.types.pointer, ffi.types.pointer },
	},
	av_display_rotation_get = { returns = ffi.types.double, args = { ffi.types.pointer } },
	av_display_rotation_set = { returns = ffi.types.void, args = { ffi.types.i32, ffi.types.double } },
	av_display_matrix_flip = { returns = ffi.types.void, args = { ffi.types.i32, ffi.types.i32, ffi.types.i32 } },
	av_encryption_info_free = { returns = ffi.types.void, args = { ffi.types.pointer } },
	av_encryption_init_info_free = { returns = ffi.types.void, args = { ffi.types.pointer } },
	av_strerror = { returns = ffi.types.i32, args = { ffi.types.i32, ffi.types.i8, ffi.types.u64 } },
	av_expr_eval = { returns = ffi.types.double, args = { ffi.types.pointer, ffi.types.pointer } },
	av_expr_count_vars = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 } },
	av_expr_count_func = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32, ffi.types.i32 },
	},
	av_expr_free = { returns = ffi.types.void, args = { ffi.types.pointer } },
	av_strtod = { returns = ffi.types.double, args = { ffi.types.pointer, ffi.types.i8 } },
	av_executor_alloc = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.i32 } },
	av_executor_free = { returns = ffi.types.void, args = { ffi.types.pointer } },
	av_executor_execute = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.pointer } },
	av_fifo_elem_size = { returns = ffi.types.u64, args = { ffi.types.pointer } },
	av_fifo_auto_grow_limit = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.u64 } },
	av_fifo_can_read = { returns = ffi.types.u64, args = { ffi.types.pointer } },
	av_fifo_can_write = { returns = ffi.types.u64, args = { ffi.types.pointer } },
	av_fifo_grow2 = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.u64 } },
	av_fifo_write = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u64 } },
	av_fifo_write_from_cb = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u64 },
	},
	av_fifo_read = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.u64 } },
	av_fifo_read_to_cb = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u64 },
	},
	av_fifo_peek = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.u64, ffi.types.u64 },
	},
	av_fifo_peek_to_cb = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u64, ffi.types.u64 },
	},
	av_fifo_drain2 = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.u64 } },
	av_fifo_reset2 = { returns = ffi.types.void, args = { ffi.types.pointer } },
	av_fifo_freep2 = { returns = ffi.types.void, args = { ffi.types.pointer } },
	av_file_map = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.u8, ffi.types.u64, ffi.types.i32 },
	},
	av_file_unmap = { returns = ffi.types.void, args = { ffi.types.u8, ffi.types.u64 } },
	av_frame_free = { returns = ffi.types.void, args = { ffi.types.pointer } },
	av_frame_ref = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer } },
	av_frame_replace = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer } },
	av_frame_unref = { returns = ffi.types.void, args = { ffi.types.pointer } },
	av_frame_move_ref = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.pointer } },
	av_frame_get_buffer = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.i32 } },
	av_frame_is_writable = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_frame_make_writable = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_frame_copy = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer } },
	av_frame_copy_props = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer } },
	av_frame_remove_side_data = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.pointer } },
	av_frame_apply_cropping = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.i32 } },
	av_frame_side_data_free = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.i32 } },
	av_frame_side_data_clone = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.i32, ffi.types.pointer, ffi.types.u32 },
	},
	av_frame_side_data_remove = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.i32, ffi.types.pointer },
	},
	av_frame_side_data_remove_by_props = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.i32, ffi.types.i32 },
	},
	av_hash_alloc = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer } },
	av_hash_get_size = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_hash_init = { returns = ffi.types.void, args = { ffi.types.pointer } },
	av_hash_update = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u64 } },
	av_hash_final = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.u8 } },
	av_hash_final_bin = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.u8, ffi.types.i32 } },
	av_hash_final_hex = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.u8, ffi.types.i32 } },
	av_hash_final_b64 = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.u8, ffi.types.i32 } },
	av_hash_freep = { returns = ffi.types.void, args = { ffi.types.pointer } },
	av_dynamic_hdr_plus_from_t35 = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u64 },
	},
	av_dynamic_hdr_plus_to_t35 = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.u8, ffi.types.u64 } },
	av_hmac_free = { returns = ffi.types.void, args = { ffi.types.pointer } },
	av_hmac_init = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u32 } },
	av_hmac_update = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u32 } },
	av_hmac_final = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.u8, ffi.types.u32 } },
	av_hmac_calc = {
		returns = ffi.types.i32,
		args = {
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.u32,
			ffi.types.pointer,
			ffi.types.u32,
			ffi.types.u8,
			ffi.types.u32,
		},
	},
	av_hwdevice_find_type_by_name = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	av_hwdevice_iterate_types = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	av_hwdevice_ctx_init = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_hwdevice_ctx_create = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.i32 },
	},
	av_hwdevice_ctx_create_derived = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.i32 },
	},
	av_hwdevice_ctx_create_derived_opts = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.i32 },
	},
	av_hwframe_ctx_init = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_hwframe_get_buffer = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 } },
	av_hwframe_transfer_data = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 },
	},
	av_frame_alloc = { returns = ffi.types.pointer, args = {} },
	av_hwframe_transfer_get_formats = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.i32 },
	},
	av_hwframe_constraints_free = { returns = ffi.types.void, args = { ffi.types.pointer } },
	av_hwframe_map = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 } },
	av_hwframe_ctx_create_derived = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.i32 },
	},
	av_av_to_amf_format = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	av_amf_to_av_format = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	av_iamf_audio_element_free = { returns = ffi.types.void, args = { ffi.types.pointer } },
	av_iamf_mix_presentation_free = { returns = ffi.types.void, args = { ffi.types.pointer } },
	av_image_fill_max_pixsteps = {
		returns = ffi.types.void,
		args = { ffi.types.i32, ffi.types.i32, ffi.types.pointer },
	},
	av_image_get_linesize = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.i32, ffi.types.i32 } },
	av_image_fill_linesizes = { returns = ffi.types.i32, args = { ffi.types.i32, ffi.types.pointer, ffi.types.i32 } },
	av_image_fill_plane_sizes = {
		returns = ffi.types.i32,
		args = { ffi.types.u64, ffi.types.pointer, ffi.types.i32, ffi.types.pointer },
	},
	av_image_fill_pointers = {
		returns = ffi.types.i32,
		args = { ffi.types.u8, ffi.types.pointer, ffi.types.i32, ffi.types.u8, ffi.types.pointer },
	},
	av_image_alloc = {
		returns = ffi.types.i32,
		args = { ffi.types.u8, ffi.types.i32, ffi.types.i32, ffi.types.i32, ffi.types.pointer, ffi.types.i32 },
	},
	av_image_copy_plane = {
		returns = ffi.types.void,
		args = { ffi.types.u8, ffi.types.i32, ffi.types.pointer, ffi.types.i32, ffi.types.i32, ffi.types.i32 },
	},
	av_image_copy_plane_uc_from = {
		returns = ffi.types.void,
		args = {
			ffi.types.u8,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.i32,
		},
	},
	av_image_copy = {
		returns = ffi.types.void,
		args = {
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.i32,
			ffi.types.i32,
		},
	},
	av_image_copy_uc_from = {
		returns = ffi.types.void,
		args = {
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.i32,
			ffi.types.i32,
		},
	},
	av_image_fill_arrays = {
		returns = ffi.types.i32,
		args = {
			ffi.types.u8,
			ffi.types.i32,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.i32,
			ffi.types.i32,
			ffi.types.i32,
		},
	},
	av_image_get_buffer_size = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.i32, ffi.types.i32, ffi.types.i32 },
	},
	av_image_copy_to_buffer = {
		returns = ffi.types.i32,
		args = {
			ffi.types.u8,
			ffi.types.i32,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.i32,
			ffi.types.i32,
			ffi.types.i32,
		},
	},
	av_image_check_size = {
		returns = ffi.types.i32,
		args = { ffi.types.u32, ffi.types.u32, ffi.types.i32 },
	},
	av_image_check_size2 = {
		returns = ffi.types.i32,
		args = { ffi.types.u32, ffi.types.u32, ffi.types.i64, ffi.types.pointer, ffi.types.i32 },
	},
	av_image_check_sar = { returns = ffi.types.i32, args = { ffi.types.u32, ffi.types.u32, ffi.types.pointer } },
	av_image_fill_black = {
		returns = ffi.types.i32,
		args = {
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.i32,
			ffi.types.i32,
		},
	},
	av_image_fill_color = {
		returns = ffi.types.i32,
		args = {
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.i32,
			ffi.types.i32,
			ffi.types.i32,
		},
	},
	av_lfg_init = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.u32 } },
	av_lfg_init_from_data = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u32 } },
	av_bmg_get = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.double } },
	av_vlog = {
		returns = ffi.types.void,
		args = { ffi.types.i32, ffi.types.pointer, ffi.types.pointer },
	},
	av_log_get_level = { returns = ffi.types.i32, args = {} },
	av_log_set_level = { returns = ffi.types.void, args = { ffi.types.i32 } },
	av_log_default_callback = {
		returns = ffi.types.void,
		args = { ffi.types.i32, ffi.types.pointer, ffi.types.pointer },
	},
	av_default_item_name = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	av_default_get_category = { returns = ffi.types.pointer, args = {} },
	av_log_format_line = {
		returns = ffi.types.void,
		args = {
			ffi.types.i32,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.i8,
			ffi.types.i32,
			ffi.types.i32,
		},
	},
	av_log_format_line2 = {
		returns = ffi.types.i32,
		args = {
			ffi.types.i32,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.i8,
			ffi.types.i32,
			ffi.types.i32,
		},
	},
	av_log_set_flags = { returns = ffi.types.void, args = { ffi.types.i32 } },
	av_log_get_flags = { returns = ffi.types.i32, args = {} },
	av_lzo1x_decode = {
		returns = ffi.types.i32,
		args = { ffi.types.i32, ffi.types.pointer, ffi.types.i32 },
	},
	av_gcd = { returns = ffi.types.pointer, args = { ffi.types.i64, ffi.types.i64 } },
	av_compare_ts = {
		returns = ffi.types.i32,
		args = { ffi.types.i64, ffi.types.pointer, ffi.types.i64, ffi.types.pointer },
	},
	av_compare_mod = { returns = ffi.types.i64, args = { ffi.types.u64, ffi.types.u64, ffi.types.u64 } },
	av_rescale_delta = {
		returns = ffi.types.i64,
		args = { ffi.types.pointer, ffi.types.i64, ffi.types.pointer, ffi.types.i32, ffi.types.i64, ffi.types.pointer },
	},
	av_add_stable = {
		returns = ffi.types.i64,
		args = { ffi.types.pointer, ffi.types.i64, ffi.types.pointer, ffi.types.i64 },
	},
	av_bessel_i0 = { returns = ffi.types.double, args = { ffi.types.double } },
	av_md5_init = { returns = ffi.types.void, args = { ffi.types.pointer } },
	av_md5_update = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u64 } },
	av_md5_final = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.u8 } },
	av_md5_sum = { returns = ffi.types.void, args = { ffi.types.u8, ffi.types.pointer, ffi.types.u64 } },
	av_fast_malloc = { returns = ffi.types.void, args = { ffi.types.u32, ffi.types.u64 } },
	av_fast_mallocz = { returns = ffi.types.void, args = { ffi.types.u32, ffi.types.u64 } },
	av_free = { returns = ffi.types.void, args = {} },
	av_freep = { returns = ffi.types.void, args = {} },
	av_memcpy_backptr = { returns = ffi.types.void, args = { ffi.types.u8, ffi.types.i32, ffi.types.i32 } },
	av_size_mult = { returns = ffi.types.i32, args = { ffi.types.u64, ffi.types.u64, ffi.types.u64 } },
	av_max_alloc = { returns = ffi.types.void, args = { ffi.types.u64 } },
	av_murmur3_init_seeded = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.u64 } },
	av_murmur3_init = { returns = ffi.types.void, args = { ffi.types.pointer } },
	av_murmur3_update = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u64 } },
	av_murmur3_final = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.u8 } },
	av_opt_set_defaults = { returns = ffi.types.void, args = {} },
	av_opt_set_defaults2 = { returns = ffi.types.void, args = { ffi.types.i32, ffi.types.i32 } },
	av_opt_free = { returns = ffi.types.void, args = {} },
	av_opt_show2 = { returns = ffi.types.i32, args = { ffi.types.i32, ffi.types.i32 } },
	av_opt_get_key_value = {
		returns = ffi.types.i32,
		args = {
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.i8,
			ffi.types.i8,
		},
	},
	av_set_options_string = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
	av_opt_set_from_string = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
	av_opt_set_dict = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_opt_set_dict2 = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.i32 } },
	av_opt_copy = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_opt_set = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 },
	},
	av_opt_set_int = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.i64, ffi.types.i32 },
	},
	av_opt_set_double = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.double, ffi.types.i32 },
	},
	av_opt_set_q = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 },
	},
	av_opt_set_bin = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32, ffi.types.i32 },
	},
	av_opt_set_image_size = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.i32, ffi.types.i32, ffi.types.i32 },
	},
	av_opt_set_pixel_fmt = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 },
	},
	av_opt_set_sample_fmt = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 },
	},
	av_opt_set_video_rate = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 },
	},
	av_opt_set_chlayout = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 },
	},
	av_opt_set_dict_val = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 },
	},
	av_opt_set_array = {
		returns = ffi.types.i32,
		args = {
			ffi.types.pointer,
			ffi.types.i32,
			ffi.types.u32,
			ffi.types.u32,
			ffi.types.pointer,
			ffi.types.pointer,
		},
	},
	av_opt_get = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.i32, ffi.types.u8 } },
	av_opt_get_int = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.i32, ffi.types.i64 },
	},
	av_opt_get_double = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.i32, ffi.types.double },
	},
	av_opt_get_q = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.i32, ffi.types.pointer },
	},
	av_opt_get_image_size = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.i32, ffi.types.i32, ffi.types.i32 },
	},
	av_opt_get_pixel_fmt = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.i32, ffi.types.pointer },
	},
	av_opt_get_sample_fmt = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.i32, ffi.types.pointer },
	},
	av_opt_get_video_rate = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.i32, ffi.types.pointer },
	},
	av_opt_get_chlayout = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.i32, ffi.types.pointer },
	},
	av_opt_get_dict_val = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.i32, ffi.types.pointer },
	},
	av_opt_get_array_size = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.i32, ffi.types.u32 },
	},
	av_opt_get_array = {
		returns = ffi.types.i32,
		args = {
			ffi.types.pointer,
			ffi.types.i32,
			ffi.types.u32,
			ffi.types.u32,
			ffi.types.pointer,
		},
	},
	av_opt_eval_flags = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 },
	},
	av_opt_eval_int = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 },
	},
	av_opt_eval_uint = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
	av_opt_eval_int64 = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i64 },
	},
	av_opt_eval_float = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.float },
	},
	av_opt_eval_double = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.double },
	},
	av_opt_eval_q = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
	av_opt_is_set_to_default = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_opt_is_set_to_default_by_name = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.i32 },
	},
	av_opt_flag_is_set = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer } },
	av_opt_serialize = {
		returns = ffi.types.i32,
		args = { ffi.types.i32, ffi.types.i32, ffi.types.i8, ffi.types.pointer, ffi.types.pointer },
	},
	av_opt_freep_ranges = { returns = ffi.types.void, args = { ffi.types.pointer } },
	av_opt_query_ranges = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 },
	},
	av_opt_query_ranges_default = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 },
	},
	av_parse_ratio = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32, ffi.types.i32 },
	},
	av_parse_video_size = { returns = ffi.types.i32, args = { ffi.types.i32, ffi.types.i32, ffi.types.pointer } },
	av_parse_video_rate = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer } },
	av_parse_color = {
		returns = ffi.types.i32,
		args = { ffi.types.u8, ffi.types.pointer, ffi.types.i32 },
	},
	av_parse_time = { returns = ffi.types.i32, args = { ffi.types.i64, ffi.types.pointer, ffi.types.i32 } },
	av_find_info_tag = {
		returns = ffi.types.i32,
		args = { ffi.types.i8, ffi.types.i32, ffi.types.pointer, ffi.types.pointer },
	},
	av_timegm = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	av_get_bits_per_pixel = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_get_padded_bits_per_pixel = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_pix_fmt_desc_get_id = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	av_pix_fmt_get_chroma_sub_sample = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.i32, ffi.types.i32 },
	},
	av_pix_fmt_count_planes = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_color_range_from_name = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_color_primaries_from_name = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_color_transfer_from_name = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_color_space_from_name = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_chroma_location_from_name = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_chroma_location_enum_to_pos = {
		returns = ffi.types.i32,
		args = { ffi.types.i32, ffi.types.i32, ffi.types.pointer },
	},
	av_chroma_location_pos_to_enum = { returns = ffi.types.pointer, args = { ffi.types.i32, ffi.types.i32 } },
	av_get_pix_fmt = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	av_read_image_line2 = {
		returns = ffi.types.void,
		args = {
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.i32,
			ffi.types.i32,
			ffi.types.i32,
			ffi.types.i32,
			ffi.types.i32,
			ffi.types.i32,
		},
	},
	av_read_image_line = {
		returns = ffi.types.void,
		args = {
			ffi.types.u16,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.i32,
			ffi.types.i32,
			ffi.types.i32,
			ffi.types.i32,
			ffi.types.i32,
		},
	},
	av_write_image_line2 = {
		returns = ffi.types.void,
		args = {
			ffi.types.pointer,
			ffi.types.u8,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.i32,
			ffi.types.i32,
			ffi.types.i32,
			ffi.types.i32,
			ffi.types.i32,
		},
	},
	av_write_image_line = {
		returns = ffi.types.void,
		args = {
			ffi.types.pointer,
			ffi.types.u8,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.i32,
			ffi.types.i32,
			ffi.types.i32,
			ffi.types.i32,
		},
	},
	av_pix_fmt_swap_endianness = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	av_get_pix_fmt_loss = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 } },
	av_find_best_pix_fmt_of_2 = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.i32, ffi.types.i32 },
	},
	av_pixelutils_get_sad_fn = {
		returns = ffi.types.pointer,
		args = { ffi.types.i32, ffi.types.i32, ffi.types.i32 },
	},
	av_get_random_seed = { returns = ffi.types.u32, args = {} },
	av_random_bytes = { returns = ffi.types.i32, args = { ffi.types.u8, ffi.types.u64 } },
	av_reduce = {
		returns = ffi.types.i32,
		args = { ffi.types.i32, ffi.types.i32, ffi.types.i64, ffi.types.i64, ffi.types.i64 },
	},
	av_nearer_q = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer } },
	av_find_nearest_q_idx = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer } },
	av_q2intfloat = { returns = ffi.types.u32, args = { ffi.types.pointer } },
	av_gcd_q = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32, ffi.types.pointer },
	},
	av_rc4_init = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32, ffi.types.i32 },
	},
	av_rc4_crypt = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u8, ffi.types.pointer, ffi.types.i32, ffi.types.u8, ffi.types.i32 },
	},

	av_refstruct_unref = { returns = ffi.types.void, args = {} },
	av_refstruct_replace = { returns = ffi.types.void, args = { ffi.types.pointer } },
	av_refstruct_exclusive = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_ripemd_init = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.i32 } },
	av_ripemd_update = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u64 } },
	av_ripemd_final = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.u8 } },
	av_get_sample_fmt = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	av_get_alt_sample_fmt = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.i32 } },
	av_get_packed_sample_fmt = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	av_get_planar_sample_fmt = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	av_get_bytes_per_sample = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_sample_fmt_is_planar = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_samples_get_buffer_size = {
		returns = ffi.types.i32,
		args = { ffi.types.i32, ffi.types.i32, ffi.types.i32, ffi.types.pointer, ffi.types.i32 },
	},
	av_samples_fill_arrays = {
		returns = ffi.types.i32,
		args = {
			ffi.types.u8,
			ffi.types.i32,
			ffi.types.pointer,
			ffi.types.i32,
			ffi.types.i32,
			ffi.types.pointer,
			ffi.types.i32,
		},
	},
	av_samples_alloc = {
		returns = ffi.types.i32,
		args = { ffi.types.u8, ffi.types.i32, ffi.types.i32, ffi.types.i32, ffi.types.pointer, ffi.types.i32 },
	},
	av_samples_alloc_array_and_samples = {
		returns = ffi.types.i32,
		args = { ffi.types.u8, ffi.types.i32, ffi.types.i32, ffi.types.i32, ffi.types.pointer, ffi.types.i32 },
	},
	av_samples_copy = {
		returns = ffi.types.i32,
		args = {
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.i32,
			ffi.types.i32,
			ffi.types.i32,
			ffi.types.i32,
			ffi.types.pointer,
		},
	},
	av_samples_set_silence = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.i32, ffi.types.i32, ffi.types.i32, ffi.types.pointer },
	},
	av_sha_init = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.i32 } },
	av_sha_update = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u64 } },
	av_sha_final = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.u8 } },
	av_sha512_init = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.i32 } },
	av_sha512_update = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u64 } },
	av_sha512_final = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.u8 } },
	av_spherical_tile_bounds = {
		returns = ffi.types.void,
		args = {
			ffi.types.pointer,
			ffi.types.u64,
			ffi.types.u64,
			ffi.types.u64,
			ffi.types.u64,
			ffi.types.u64,
			ffi.types.u64,
		},
	},
	av_spherical_from_name = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_stereo3d_from_name = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_stereo3d_view_from_name = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_stereo3d_primary_eye_from_name = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_tea_init = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 } },
	av_tea_crypt = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u8, ffi.types.pointer, ffi.types.i32, ffi.types.u8, ffi.types.i32 },
	},
	av_thread_message_queue_alloc = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
	av_thread_message_queue_free = { returns = ffi.types.void, args = { ffi.types.pointer } },
	av_thread_message_queue_send = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer },
	},
	av_thread_message_queue_recv = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer },
	},
	av_thread_message_queue_set_err_send = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.i32 } },
	av_thread_message_queue_set_err_recv = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.i32 } },
	av_thread_message_queue_nb_elems = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_thread_message_flush = { returns = ffi.types.void, args = { ffi.types.pointer } },
	av_gettime = { returns = ffi.types.i64, args = {} },
	av_gettime_relative = { returns = ffi.types.i64, args = {} },
	av_gettime_relative_is_monotonic = { returns = ffi.types.i32, args = {} },
	av_usleep = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	av_timecode_adjust_ntsc_framenum2 = { returns = ffi.types.i32, args = { ffi.types.i32, ffi.types.i32 } },
	av_timecode_get_smpte_from_framenum = { returns = ffi.types.u32, args = { ffi.types.pointer, ffi.types.i32 } },
	av_timecode_get_smpte = {
		returns = ffi.types.u32,
		args = { ffi.types.pointer, ffi.types.i32, ffi.types.i32, ffi.types.i32, ffi.types.i32, ffi.types.i32 },
	},
	av_timecode_init = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32, ffi.types.i32 },
	},
	av_timecode_init_from_components = {
		returns = ffi.types.i32,
		args = {
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.i32,
			ffi.types.i32,
			ffi.types.i32,
			ffi.types.i32,
			ffi.types.i32,
		},
	},
	av_timecode_init_from_string = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
	av_timecode_check_frame_rate = { returns = ffi.types.i32, args = { ffi.types.pointer } },

	av_ts_make_time_string2 = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
	av_tree_destroy = { returns = ffi.types.void, args = { ffi.types.pointer } },
	av_twofish_init = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 } },
	av_twofish_crypt = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u8, ffi.types.pointer, ffi.types.i32, ffi.types.pointer, ffi.types.i32 },
	},
	av_tx_init = {
		returns = ffi.types.i32,
		args = {
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.i32,
			ffi.types.i32,
			ffi.types.pointer,
			ffi.types.u64,
		},
	},
	av_tx_uninit = { returns = ffi.types.void, args = { ffi.types.pointer } },
	av_uuid_parse = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer } },
	av_uuid_urn_parse = { returns = ffi.types.i32, args = { ffi.types.pointer, ffi.types.pointer } },
	av_uuid_parse_range = {
		returns = ffi.types.i32,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
	av_uuid_unparse = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.i8 } },
	av_video_enc_params_create_side_data = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.u32 },
	},
	av_xtea_init = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.pointer } },
	av_xtea_le_init = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.pointer } },
	av_xtea_crypt = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u8, ffi.types.pointer, ffi.types.i32, ffi.types.u8, ffi.types.i32 },
	},
	av_xtea_le_crypt = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.u8, ffi.types.pointer, ffi.types.i32, ffi.types.u8, ffi.types.i32 },
	},
}

local structs = {
	AVAmbientViewingEnvironment = AVAmbientViewingEnvironment,
	AVBlowfish = AVBlowfish,
	name = name,
	AVBufferRef = AVBufferRef,
	AVChannelCustom = AVChannelCustom,
	u = u,
	AVColorPrimariesDesc = AVColorPrimariesDesc,
	AVDES = AVDES,
	AVDetectionBBox = AVDetectionBBox,
	AVDetectionBBoxHeader = AVDetectionBBoxHeader,
	AVDOVIDecoderConfigurationRecord = AVDOVIDecoderConfigurationRecord,
	AVDOVIRpuDataHeader = AVDOVIRpuDataHeader,
	AVDOVIReshapingCurve = AVDOVIReshapingCurve,
	AVDOVINLQParams = AVDOVINLQParams,
	AVDOVIDataMapping = AVDOVIDataMapping,
	AVDOVIColorMetadata = AVDOVIColorMetadata,
	AVDOVIDmLevel1 = AVDOVIDmLevel1,
	AVDOVIDmLevel2 = AVDOVIDmLevel2,
	AVDOVIDmLevel3 = AVDOVIDmLevel3,
	AVDOVIDmLevel4 = AVDOVIDmLevel4,
	AVDOVIDmLevel5 = AVDOVIDmLevel5,
	AVDOVIDmLevel6 = AVDOVIDmLevel6,
	AVDOVIDmLevel8 = AVDOVIDmLevel8,
	AVDOVIDmLevel9 = AVDOVIDmLevel9,
	AVDOVIDmLevel10 = AVDOVIDmLevel10,
	AVDOVIDmLevel11 = AVDOVIDmLevel11,
	AVDOVIDmLevel254 = AVDOVIDmLevel254,
	AVDOVIDmLevel255 = AVDOVIDmLevel255,
	AVDOVIMetadata = AVDOVIMetadata,
	AVDownmixInfo = AVDownmixInfo,
	AVSubsampleEncryptionInfo = AVSubsampleEncryptionInfo,
	AVEncryptionInfo = AVEncryptionInfo,
	AVEncryptionInitInfo = AVEncryptionInitInfo,
	AVTaskCallbacks = AVTaskCallbacks,
	AVFilmGrainAOMParams = AVFilmGrainAOMParams,
	AVFilmGrainH274Params = AVFilmGrainH274Params,
	codec = codec,
	AVFrameSideData = AVFrameSideData,
	AVSideDataDescriptor = AVSideDataDescriptor,
	AVRegionOfInterest = AVRegionOfInterest,
	AVFrame = AVFrame,
	AVHDRPlusPercentile = AVHDRPlusPercentile,
	AVHDRPlusColorTransformParams = AVHDRPlusColorTransformParams,
	AVDynamicHDRPlus = AVDynamicHDRPlus,
	AVHDRVivid3SplineParams = AVHDRVivid3SplineParams,
	AVHDRVividColorToneMappingParams = AVHDRVividColorToneMappingParams,
	AVHDRVividColorTransformParams = AVHDRVividColorTransformParams,
	AVDynamicHDRVivid = AVDynamicHDRVivid,
	AVHWDeviceContext = AVHWDeviceContext,
	AVHWFramesContext = AVHWFramesContext,
	AVHWFramesConstraints = AVHWFramesConstraints,
	AVAMFDeviceContext = AVAMFDeviceContext,
	AVCUDADeviceContext = AVCUDADeviceContext,
	AVD3D11FrameDescriptor = AVD3D11FrameDescriptor,
	AVD3D11VAFramesContext = AVD3D11VAFramesContext,
	AVD3D12VASyncContext = AVD3D12VASyncContext,
	AVD3D12VAFrame = AVD3D12VAFrame,
	AVD3D12VAFramesContext = AVD3D12VAFramesContext,
	AVDRMObjectDescriptor = AVDRMObjectDescriptor,
	AVDRMPlaneDescriptor = AVDRMPlaneDescriptor,
	AVDRMLayerDescriptor = AVDRMLayerDescriptor,
	AVDRMFrameDescriptor = AVDRMFrameDescriptor,
	AVDRMDeviceContext = AVDRMDeviceContext,
	AVDXVA2FramesContext = AVDXVA2FramesContext,
	AVMediaCodecDeviceContext = AVMediaCodecDeviceContext,
	AVOpenCLFrameDescriptor = AVOpenCLFrameDescriptor,
	AVOpenCLDeviceContext = AVOpenCLDeviceContext,
	AVOpenCLFramesContext = AVOpenCLFramesContext,
	AVQSVDeviceContext = AVQSVDeviceContext,
	AVQSVFramesContext = AVQSVFramesContext,
	AVVAAPIDeviceContext = AVVAAPIDeviceContext,
	AVVAAPIFramesContext = AVVAAPIFramesContext,
	AVVAAPIHWConfig = AVVAAPIHWConfig,
	AVVDPAUDeviceContext = AVVDPAUDeviceContext,
	AVVTFramesContext = AVVTFramesContext,
	AVVulkanDeviceQueueFamily = AVVulkanDeviceQueueFamily,
	AVVulkanDeviceContext = AVVulkanDeviceContext,
	AVVulkanFramesContext = AVVulkanFramesContext,
	AVIAMFMixGain = AVIAMFMixGain,
	AVIAMFDemixingInfo = AVIAMFDemixingInfo,
	AVIAMFReconGain = AVIAMFReconGain,
	AVIAMFParamDefinition = AVIAMFParamDefinition,
	AVIAMFLayer = AVIAMFLayer,
	AVIAMFAudioElement = AVIAMFAudioElement,
	AVIAMFSubmixElement = AVIAMFSubmixElement,
	AVIAMFSubmixLayout = AVIAMFSubmixLayout,
	AVIAMFSubmix = AVIAMFSubmix,
	AVIAMFMixPresentation = AVIAMFMixPresentation,
	AVLFG = AVLFG,
	AVClass = AVClass,
	AVMasteringDisplayMetadata = AVMasteringDisplayMetadata,
	AVContentLightMetadata = AVContentLightMetadata,
	AVMotionVector = AVMotionVector,
	AVOptionArrayDef = AVOptionArrayDef,
	default_val = default_val,
	AVOptionRange = AVOptionRange,
	AVOptionRanges = AVOptionRanges,
	AVComponentDescriptor = AVComponentDescriptor,
	AVPixFmtDescriptor = AVPixFmtDescriptor,
	AVRational = AVRational,
	AVRC4 = AVRC4,
	AVReplayGain = AVReplayGain,
	AVSphericalMapping = AVSphericalMapping,
	AVStereo3D = AVStereo3D,
	AV3DReferenceDisplaysInfo = AV3DReferenceDisplaysInfo,
	AV3DReferenceDisplay = AV3DReferenceDisplay,
	AVTimecode = AVTimecode,
	AVVideoEncParams = AVVideoEncParams,
	AVVideoBlockParams = AVVideoBlockParams,
	AVVideoHint = AVVideoHint,
	AVXTEA = AVXTEA,
}

return { funcs = funcs, structs = structs }
