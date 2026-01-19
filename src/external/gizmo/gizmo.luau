local platform = zune.platform
local ffi = zune.ffi

local void = ffi.types.void
local int = ffi.types.i32
local uint = ffi.types.u32
local bool = ffi.types.u8
local float = ffi.types.float
local cstring = ffi.types.pointer
local long = ffi.types.i64
local pointer = ffi.types.pointer
local FFIPointer = ffi.types.FFIPointer

type int = number
type uint = number
type bool = number
type float = number
type long = buffer
type double = number
type cstring = string | buffer | FFIPointer

local function fn(returns: any, args: { any })
	return { returns = returns, args = args }
end

local libLocation = "./src/external/raylib/native/bin/gizmo.dll"

if platform.cpu.arch == "x86_64" then
	if platform.os == "windows" then
		libLocation = "./src/external/raylib/native/bin/gizmo.dll"
	elseif platform.os == "linux" then
		libLocation = "./src/external/raylib/native/bin/gizmo.so"
	end
end

type Fns = {
	GizmoIdentity: () -> any,
	GizmoToMatrix: (transform: any) -> any,

	DrawGizmo3D: (flags: int, transform: FFIPointer) -> bool,

	-- Config
	SetGizmoRotateSpeed: (speed: float) -> (),
	GetGizmoRotateSpeed: () -> float,

	SetGizmoRotateSnapEnabled: (enabled: bool) -> (),
	GetGizmoRotateSnapEnabled: () -> bool,
	SetGizmoRotateSnapDegrees: (float) -> (),
	GetGizmoRotateSnapDegrees: () -> float,

	SetGizmoSize: (size: float) -> (),
	SetGizmoLineWidth: (width: float) -> (),
	SetGizmoColors: (x: any, y: any, z: any, center: any) -> (),
	SetGizmoGlobalAxis: (right: any, up: any, forward: any) -> (),
}

local defs = {
	GizmoIdentity = fn(pointer, {}),
	GizmoToMatrix = fn(pointer, { pointer }),

	DrawGizmo3D = fn(bool, { int, pointer }),

	SetGizmoRotateSpeed = fn(void, { float }),
	GetGizmoRotateSpeed = fn(float, {}),

	SetGizmoRotateSnapEnabled = fn(void, { bool }),
	GetGizmoRotateSnapEnabled = fn(bool, {}),
	SetGizmoRotateSnapDegrees = fn(void, { float }),
	GetGizmoRotateSnapDegrees = fn(float, {}),

	SetGizmoSize = fn(void, { float }),
	SetGizmoLineWidth = fn(void, { float }),
	SetGizmoColors = fn(void, { int, int, int, int }),
	SetGizmoGlobalAxis = fn(void, { pointer, pointer, pointer }),
}

local lib = ffi.dlopen(libLocation, defs) :: {
	GetSymbol: (self: FFILibrary, symbol: string) -> FFIPointer?,
} & Fns

return {
	Flags = {
		DISABLED = 0,
		TRANSLATE = bit32.lshift(1, 0),
		ROTATE = bit32.lshift(1, 1),
		SCALE = bit32.lshift(1, 2),

		LOCAL = bit32.lshift(1, 3),
		VIEW = bit32.lshift(1, 4),

		ALL = bit32.bor(bit32.lshift(1, 0), bit32.lshift(1, 1), bit32.lshift(1, 2)),
	},

	GizmoIdentity = lib.GizmoIdentity,
	GizmoToMatrix = lib.GizmoToMatrix,

	DrawGizmo3D = lib.DrawGizmo3D,

	SetGizmoRotateSpeed = lib.SetGizmoRotateSpeed,
	GetGizmoRotateSpeed = lib.GetGizmoRotateSpeed,

	SetGizmoRotateSnapEnabled = lib.SetGizmoRotateSnapEnabled,
	GetGizmoRotateSnapEnabled = function()
		return lib.GetGizmoRotateSnapEnabled() == 1
	end,
	SetGizmoRotateSnapDegrees = lib.SetGizmoRotateSnapDegrees,
	GetGizmoRotateSnapDegrees = lib.GetGizmoRotateSnapDegrees,

	SetGizmoSize = lib.SetGizmoSize,
	SetGizmoLineWidth = lib.SetGizmoLineWidth,
	SetGizmoColors = lib.SetGizmoColors,
	SetGizmoGlobalAxis = lib.SetGizmoGlobalAxis,
}
