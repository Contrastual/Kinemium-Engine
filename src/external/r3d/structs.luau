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

local R3D_AmbientMap = ffi.struct({
	{ flags = ffi.types.pointer },
	{ irradiance = ffi.types.u32 },
	{ prefilter = ffi.types.u32 },
})
export type R3D_AmbientMap = typeof(R3D_AmbientMap:new({}))

local R3D_AnimationTrack = ffi.struct({
	{ times = ffi.types.pointer },
	{ values = ffi.types.pointer },
	{ count = ffi.types.i32 },
})
export type R3D_AnimationTrack = typeof(R3D_AnimationTrack:new({}))

local R3D_AnimationChannel = ffi.struct({
	{ translation = R3D_AnimationTrack },
	{ rotation = R3D_AnimationTrack },
	{ scale = R3D_AnimationTrack },
	{ boneIndex = ffi.types.i32 },
})
export type R3D_AnimationChannel = typeof(R3D_AnimationChannel:new({}))

local R3D_Animation = ffi.struct({
	{ channels = ffi.types.pointer },
	{ channelCount = ffi.types.i32 },
	{ ticksPerSecond = ffi.types.float },
	{ duration = ffi.types.float },
	{ boneCount = ffi.types.i32 },
	{ name = ffi.types.i8:array(32) },
})
export type R3D_Animation = typeof(R3D_Animation:new({}))

local R3D_AnimationLib = ffi.struct({
	{ animations = ffi.types.pointer },
	{ count = ffi.types.i32 },
})
export type R3D_AnimationLib = typeof(R3D_AnimationLib:new({}))

local R3D_AnimationState = ffi.struct({
	{ currentTime = ffi.types.float },
	{ weight = ffi.types.float },
	{ speed = ffi.types.float },
	{ play = ffi.types.u8 },
	{ loop = ffi.types.u8 },
})
export type R3D_AnimationState = typeof(R3D_AnimationState:new({}))

local R3D_Cubemap = ffi.struct({
	{ texture = ffi.types.u32 },
	{ fbo = ffi.types.u32 },
	{ size = ffi.types.i32 },
})
export type R3D_Cubemap = typeof(R3D_Cubemap:new({}))

local R3D_CubemapSky = ffi.struct({
	{ skyTopColor = ffi.types.pointer },
	{ skyHorizonColor = ffi.types.pointer },
	{ skyHorizonCurve = ffi.types.float },
	{ skyEnergy = ffi.types.float },
	{ groundBottomColor = ffi.types.pointer },
	{ groundHorizonColor = ffi.types.pointer },
	{ groundHorizonCurve = ffi.types.float },
	{ groundEnergy = ffi.types.float },
	{ sunDirection = ffi.types.pointer },
	{ sunColor = ffi.types.pointer },
	{ sunSize = ffi.types.float },
	{ sunCurve = ffi.types.float },
	{ sunEnergy = ffi.types.float },
})
export type R3D_CubemapSky = typeof(R3D_CubemapSky:new({}))

local R3D_EnvBackground = ffi.struct({
	{ color = ffi.types.pointer },
	{ energy = ffi.types.float },
	{ skyBlur = ffi.types.float },
	{ sky = R3D_Cubemap },
	{ rotation = ffi.types.pointer },
})
export type R3D_EnvBackground = typeof(R3D_EnvBackground:new({}))

local R3D_EnvAmbient = ffi.struct({
	{ color = ffi.types.pointer },
	{ energy = ffi.types.float },
	{ map = R3D_AmbientMap },
})
export type R3D_EnvAmbient = typeof(R3D_EnvAmbient:new({}))

local R3D_EnvSSAO = ffi.struct({
	{ sampleCount = ffi.types.i32 },
	{ intensity = ffi.types.float },
	{ power = ffi.types.float },
	{ radius = ffi.types.float },
	{ bias = ffi.types.float },
	{ enabled = ffi.types.u8 },
})
export type R3D_EnvSSAO = typeof(R3D_EnvSSAO:new({}))

local R3D_EnvSSIL = ffi.struct({
	{ sampleCount = ffi.types.i32 },
	{ sliceCount = ffi.types.i32 },
	{ sampleRadius = ffi.types.float },
	{ hitThickness = ffi.types.float },
	{ aoPower = ffi.types.float },
	{ energy = ffi.types.float },
	{ bounce = ffi.types.float },
	{ convergence = ffi.types.float },
	{ enabled = ffi.types.u8 },
})
export type R3D_EnvSSIL = typeof(R3D_EnvSSIL:new({}))

local R3D_EnvBloom = ffi.struct({
	{ mode = ffi.types.pointer },
	{ levels = ffi.types.float },
	{ intensity = ffi.types.float },
	{ threshold = ffi.types.float },
	{ softThreshold = ffi.types.float },
	{ filterRadius = ffi.types.float },
})
export type R3D_EnvBloom = typeof(R3D_EnvBloom:new({}))

local R3D_EnvSSR = ffi.struct({
	{ maxRaySteps = ffi.types.i32 },
	{ binarySearchSteps = ffi.types.i32 },
	{ rayMarchLength = ffi.types.float },
	{ depthThickness = ffi.types.float },
	{ depthTolerance = ffi.types.float },
	{ edgeFadeStart = ffi.types.float },
	{ edgeFadeEnd = ffi.types.float },
	{ enabled = ffi.types.u8 },
})
export type R3D_EnvSSR = typeof(R3D_EnvSSR:new({}))

local R3D_EnvFog = ffi.struct({
	{ mode = ffi.types.pointer },
	{ color = ffi.types.pointer },
	{ start = ffi.types.float },
	{ ["end"] = ffi.types.float },
	{ density = ffi.types.float },
	{ skyAffect = ffi.types.float },
})
export type R3D_EnvFog = typeof(R3D_EnvFog:new({}))

local R3D_EnvDoF = ffi.struct({
	{ mode = ffi.types.pointer },
	{ focusPoint = ffi.types.float },
	{ focusScale = ffi.types.float },
	{ maxBlurSize = ffi.types.float },
	{ debugMode = ffi.types.u8 },
})
export type R3D_EnvDoF = typeof(R3D_EnvDoF:new({}))

local R3D_EnvTonemap = ffi.struct({
	{ mode = ffi.types.pointer },
	{ exposure = ffi.types.float },
	{ white = ffi.types.float },
})
export type R3D_EnvTonemap = typeof(R3D_EnvTonemap:new({}))

local R3D_EnvColor = ffi.struct({
	{ brightness = ffi.types.float },
	{ contrast = ffi.types.float },
	{ saturation = ffi.types.float },
})
export type R3D_EnvColor = typeof(R3D_EnvColor:new({}))

local R3D_Environment = ffi.struct({
	{ background = R3D_EnvBackground },
	{ ambient = R3D_EnvAmbient },
	{ ssao = R3D_EnvSSAO },
	{ ssil = R3D_EnvSSIL },
	{ bloom = R3D_EnvBloom },
	{ ssr = R3D_EnvSSR },
	{ fog = R3D_EnvFog },
	{ dof = R3D_EnvDoF },
	{ tonemap = R3D_EnvTonemap },
	{ color = R3D_EnvColor },
})
export type R3D_Environment = typeof(R3D_Environment:new({}))

local R3D_AlbedoMap = ffi.struct({
	{ texture = ffi.types.pointer },
	{ color = ffi.types.pointer },
})
export type R3D_AlbedoMap = typeof(R3D_AlbedoMap:new({}))

local R3D_EmissionMap = ffi.struct({
	{ texture = ffi.types.pointer },
	{ color = ffi.types.pointer },
	{ energy = ffi.types.float },
})
export type R3D_EmissionMap = typeof(R3D_EmissionMap:new({}))

local R3D_NormalMap = ffi.struct({
	{ texture = ffi.types.pointer },
	{ scale = ffi.types.float },
})
export type R3D_NormalMap = typeof(R3D_NormalMap:new({}))

local R3D_OrmMap = ffi.struct({
	{ texture = ffi.types.pointer },
	{ occlusion = ffi.types.float },
	{ roughness = ffi.types.float },
	{ metalness = ffi.types.float },
})
export type R3D_OrmMap = typeof(R3D_OrmMap:new({}))

local R3D_Material = ffi.struct({
	{ albedo = R3D_AlbedoMap },
	{ emission = R3D_EmissionMap },
	{ normal = R3D_NormalMap },
	{ orm = R3D_OrmMap },
	{ transparencyMode = ffi.types.pointer },
	{ billboardMode = ffi.types.pointer },
	{ blendMode = ffi.types.pointer },
	{ cullMode = ffi.types.pointer },
	{ uvOffset = ffi.types.pointer },
	{ uvScale = ffi.types.pointer },
	{ alphaCutoff = ffi.types.float },
})
export type R3D_Material = typeof(R3D_Material:new({}))

local R3D_Mesh = ffi.struct({
	{ ebo = ffi.types.pointer },
	{ indexCount = ffi.types.pointer },
	{ allocIndexCount = ffi.types.pointer },
	{ shadowCastMode = ffi.types.pointer },
	{ primitiveType = ffi.types.pointer },
	{ usage = ffi.types.pointer },
	{ layerMask = ffi.types.pointer },
	{ aabb = ffi.types.pointer },
})
export type R3D_Mesh = typeof(R3D_Mesh:new({}))

local R3D_Vertex = ffi.struct({
	{ position = ffi.types.pointer },
	{ texcoord = ffi.types.pointer },
	{ normal = ffi.types.pointer },
	{ color = ffi.types.pointer },
	{ tangent = ffi.types.pointer },
	{ boneIds = ffi.types.i32:array(4) },
	{ weights = ffi.types.float:array(4) },
})
export type R3D_Vertex = typeof(R3D_Vertex:new({}))

local R3D_MeshData = ffi.struct({
	{ vertices = ffi.types.pointer },
	{ indices = ffi.types.pointer },
	{ vertexCount = ffi.types.i32 },
	{ indexCount = ffi.types.i32 },
})
export type R3D_MeshData = typeof(R3D_MeshData:new({}))

local R3D_BoneInfo = ffi.struct({
	{ name = ffi.types.i8:array(32) },
	{ parent = ffi.types.i32 },
})
export type R3D_BoneInfo = typeof(R3D_BoneInfo:new({}))

local structs = {
	R3D_AmbientMap = R3D_AmbientMap,
	R3D_AnimationTrack = R3D_AnimationTrack,
	R3D_AnimationChannel = R3D_AnimationChannel,
	R3D_Animation = R3D_Animation,
	R3D_AnimationLib = R3D_AnimationLib,
	R3D_AnimationState = R3D_AnimationState,
	R3D_Cubemap = R3D_Cubemap,
	R3D_CubemapSky = R3D_CubemapSky,
	R3D_EnvBackground = R3D_EnvBackground,
	R3D_EnvAmbient = R3D_EnvAmbient,
	R3D_EnvSSAO = R3D_EnvSSAO,
	R3D_EnvSSIL = R3D_EnvSSIL,
	R3D_EnvBloom = R3D_EnvBloom,
	R3D_EnvSSR = R3D_EnvSSR,
	R3D_EnvFog = R3D_EnvFog,
	R3D_EnvDoF = R3D_EnvDoF,
	R3D_EnvTonemap = R3D_EnvTonemap,
	R3D_EnvColor = R3D_EnvColor,
	R3D_Environment = R3D_Environment,
	R3D_AlbedoMap = R3D_AlbedoMap,
	R3D_EmissionMap = R3D_EmissionMap,
	R3D_NormalMap = R3D_NormalMap,
	R3D_OrmMap = R3D_OrmMap,
	R3D_Material = R3D_Material,
	R3D_Mesh = R3D_Mesh,
	R3D_Vertex = R3D_Vertex,
	R3D_MeshData = R3D_MeshData,
	R3D_Model = R3D_Model,
	R3D_BoneInfo = R3D_BoneInfo,
}

return structs
