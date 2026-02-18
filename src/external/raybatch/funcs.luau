local ffi = zune.ffi

-- Type aliases for FFI
type int = number
type float = number
type bool = boolean
type cstring = string
type FFIPointer = typeof(ffi.types.pointer)

-- Import struct types
local structs = require("./structs")
type RB_Batch = structs.RB_Batch
type RB_Instance = structs.RB_Instance

export type Fns = {
	RB_AddInstance: (
		batch: RB_Batch,
		position: FFIPointer,
		scale: FFIPointer,
		rotation: FFIPointer,
		color: FFIPointer
	) -> bool,
	RB_AddInstanceMatrix: (batch: RB_Batch, transform: FFIPointer, color: FFIPointer) -> (),
	RB_ClearBatch: (batch: RB_Batch) -> (),
	RB_DestroyBatch: (batch: RB_Batch) -> (),
	RB_DrawBatch: (batch: RB_Batch, texture: FFIPointer, material: FFIPointer) -> (),
	RB_GetInstanceCount: (batch: RB_Batch) -> int,
	RB_IsDirty: (batch: RB_Batch) -> bool,
	RB_UpdateBatch: (batch: RB_Batch) -> (),
	RB_CreateBatch: (mesh: FFIPointer, shader: FFIPointer, maxInstances: int) -> RB_Batch,
}

local funcs = {
	RB_AddInstance = {
		returns = ffi.types.u8,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
	RB_AddInstanceMatrix = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
	RB_CreateBatch = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.i32 },
	},
	RB_DrawBatchInstanced = {
		returns = ffi.types.void,
		args = { ffi.types.pointer, ffi.types.pointer },
	},
	RB_ClearBatch = { returns = ffi.types.void, args = { ffi.types.pointer } },
	RB_UpdateBatch = { returns = ffi.types.void, args = { ffi.types.pointer } },
	RB_DrawBatch = { returns = ffi.types.void, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer } },
	RB_GetInstanceCount = { returns = ffi.types.i32, args = { ffi.types.pointer } },
	RB_IsDirty = { returns = ffi.types.u8, args = { ffi.types.pointer } },
	RB_DestroyBatch = { returns = ffi.types.void, args = { ffi.types.pointer } },
}

return funcs
