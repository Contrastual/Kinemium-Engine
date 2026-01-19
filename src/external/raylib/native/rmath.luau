--!strict
--!optimize 2
--!native

local raylib = require("./raylib")
local structs = raylib.structs

local ffi = _G.zune.ffi
local float = ffi.types.float
local Vector3 = structs.Vector3
type Vector3 = raylib.Vector3
type Matrix = raylib.Matrix

type float = number

local function fn(returns: any, args: { any })
	return {
		returns = returns,
		args = args,
	}
end

local double = ffi.types.double
type double = number

export type Fns = {
	Vector3Distance: (v1: Vector3, v2: Vector3) -> float,
	MatrixInvert: (mat: Matrix) -> Matrix,
	MatrixMultiply: (left: Matrix, right: Matrix) -> Matrix,
	MatrixTranspose: (mat: Matrix) -> Matrix,
	MatrixPerspective: (fovy: double, aspect: double, near: double, far: double) -> Matrix,
	MatrixOrtho: (left: double, right: double, bottom: double, top: double, near: double, far: double) -> Matrix,
	MatrixLookAt: (eye: Vector3, target: Vector3, up: Vector3) -> Matrix,
	MatrixIdentity: () -> Matrix,
	MatrixFrustum: (left: double, right: double, bottom: double, top: double, near: double, far: double) -> Matrix,
}

return {
	defs = {
		Vector3Distance = fn(float, { Vector3, Vector3 }),
		MatrixInvert = fn(structs.Matrix, { structs.Matrix }),
		MatrixMultiply = fn(structs.Matrix, { structs.Matrix, structs.Matrix }),
		MatrixTranspose = fn(structs.Matrix, { structs.Matrix }),
		MatrixPerspective = fn(structs.Matrix, { double, double, double, double }),
		MatrixOrtho = fn(structs.Matrix, { double, double, double, double, double, double }),
		MatrixLookAt = fn(structs.Matrix, { Vector3, Vector3, Vector3 }),
		MatrixIdentity = fn(structs.Matrix, {}),
		MatrixFrustum = fn(structs.Matrix, { double, double, double, double, double, double }),
	},
}
