--!strict
--!optimize 2
--!native

--[[
    raygizmo.luau
    Luau port of raygizmo.c by Claudio Z. (@cloudofoz), zlib license.

    Usage:
        local gizmo = require("./raygizmo")

        local t = gizmo.newTransform()
        t.translation = vector.create(0, 1, 0)

        -- inside BeginMode3D / EndMode3D each frame:
        local active = gizmo.DrawGizmo3D(gizmo.GIZMO_TRANSLATE + gizmo.GIZMO_ROTATE, t)
]]

local raylib = require("@raylib")
local lib = raylib.lib
local structs = raylib.structs

-- ============================================================
-- Types
-- ============================================================

-- Zune builtin vector: supports +, -, * natively. .x .y .z
type V3 = vector

-- Plain Luau table for quaternion (never passed to FFI directly)
type Quaternion = { x: number, y: number, z: number, w: number }

-- FFI struct buffers (returned from lib calls or structs:new)
type Buf = buffer

-- ============================================================
-- Bitwise helpers
-- ============================================================

local band = bit32.band
local bor = bit32.bor
local bnot = bit32.bnot
local rshift = bit32.rshift

-- ============================================================
-- Gizmo flags
-- ============================================================

local GIZMO_DISABLED = 0
local GIZMO_TRANSLATE = 1
local GIZMO_ROTATE = 2
local GIZMO_SCALE = 4
local GIZMO_LOCAL = 8
local GIZMO_VIEW = 16
local GIZMO_ALL = GIZMO_TRANSLATE + GIZMO_ROTATE + GIZMO_SCALE

-- ============================================================
-- Internal enums
-- ============================================================

local GZ_ACTIVE_X = 1
local GZ_ACTIVE_Y = 2
local GZ_ACTIVE_Z = 4
local GZ_ACTIVE_XYZ = 7

local GZ_ACTION_NONE = 0
local GZ_ACTION_TRANSLATE = 1
local GZ_ACTION_SCALE = 2
local GZ_ACTION_ROTATE = 3

local GZ_AXIS_X = 1
local GZ_AXIS_Y = 2
local GZ_AXIS_Z = 3
local GIZMO_AXIS_COUNT = 3

local RL_LINES = 1
local RL_TRIANGLES = 4
local RL_QUADS = 7

local MOUSE_BUTTON_LEFT = 0

-- ============================================================
-- Axis index helpers (1-indexed, wrapping 1→2→3→1)
-- ============================================================

local function nextAxis(i: number): number
	return (i % GIZMO_AXIS_COUNT) + 1
end
local function next2Axis(i: number): number
	return nextAxis(nextAxis(i))
end

-- ============================================================
-- Vector math
-- Zune vectors support: v1 + v2, v1 - v2, v * scalar, scalar * v
-- We only need dot, normalize, magnitude for the rest.
-- ============================================================

local function vDot(a: V3, b: V3): number
	return a.x * b.x + a.y * b.y + a.z * b.z
end

local function vLen(a: V3): number
	return math.sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
end

local function vNorm(a: V3): V3
	local len = vLen(a)
	if len == 0 then
		return vector.create(0, 0, 0)
	end
	return a * (1 / len)
end

local function vDist(a: V3, b: V3): number
	return vLen(a - b)
end

-- Project v onto `onto`
local function vProject(v: V3, onto: V3): V3
	local d = vDot(onto, onto)
	if d == 0 then
		return vector.create(0, 0, 0)
	end
	return onto * (vDot(v, onto) / d)
end

local function vAddScalar(a: V3, s: number): V3
	return vector.create(a.x + s, a.y + s, a.z + s)
end

-- ============================================================
-- Quaternion  (plain Luau table, never passed to FFI directly)
-- ============================================================

local function quatIdentity(): Quaternion
	return { x = 0, y = 0, z = 0, w = 1 }
end

local function quatMul(q1: Quaternion, q2: Quaternion): Quaternion
	return {
		x = q1.x * q2.w + q1.w * q2.x + q1.y * q2.z - q1.z * q2.y,
		y = q1.y * q2.w + q1.w * q2.y + q1.z * q2.x - q1.x * q2.z,
		z = q1.z * q2.w + q1.w * q2.z + q1.x * q2.y - q1.y * q2.x,
		w = q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z,
	}
end

local function quatFromAxisAngle(axis: V3, angle: number): Quaternion
	local s = math.sin(angle * 0.5)
	return { x = axis.x * s, y = axis.y * s, z = axis.z * s, w = math.cos(angle * 0.5) }
end

-- Rotate vector by unit quaternion (optimised sandwich product)
local function quatRotV3(q: Quaternion, v: V3): V3
	local qx, qy, qz = q.x, q.y, q.z
	local uvx = qy * v.z - qz * v.y
	local uvy = qz * v.x - qx * v.z
	local uvz = qx * v.y - qy * v.x
	local uuvx = qy * uvz - qz * uvy
	local uuvy = qz * uvx - qx * uvz
	local uuvz = qx * uvy - qy * uvx
	local tw = 2 * q.w
	return vector.create(v.x + tw * uvx + 2 * uuvx, v.y + tw * uvy + 2 * uuvy, v.z + tw * uvz + 2 * uuvz)
end

-- ============================================================
-- Matrix  (read from buffer, build via structs.Matrix:new)
--
-- Raylib column-major layout:
--   col0: m0  m1  m2  m3
--   col1: m4  m5  m6  m7
--   col2: m8  m9  m10 m11
--   col3: m12 m13 m14 m15
-- ============================================================

-- Pre-cache field offsets so we don't call :offset() every frame
local MO = {} :: { [string]: number }
do
	local M = structs.Matrix
	for _, f in { "m0", "m1", "m2", "m3", "m4", "m5", "m6", "m7", "m8", "m9", "m10", "m11", "m12", "m13", "m14", "m15" } do
		MO[f] = M:offset(f)
	end
end

local function mr(m: Buf, f: string): number
	return buffer.readf32(m, MO[f])
end

-- Build a Matrix buffer from 16 floats (col-major order, col by col)
local function matNew(
	m0: number,
	m1: number,
	m2: number,
	m3: number,
	m4: number,
	m5: number,
	m6: number,
	m7: number,
	m8: number,
	m9: number,
	m10: number,
	m11: number,
	m12: number,
	m13: number,
	m14: number,
	m15: number
): Buf
	return structs.Matrix:new({
		m0 = m0,
		m1 = m1,
		m2 = m2,
		m3 = m3,
		m4 = m4,
		m5 = m5,
		m6 = m6,
		m7 = m7,
		m8 = m8,
		m9 = m9,
		m10 = m10,
		m11 = m11,
		m12 = m12,
		m13 = m13,
		m14 = m14,
		m15 = m15,
	})
end

local function matMul(l: Buf, r: Buf): Buf
	local l0, l1, l2, l3 = mr(l, "m0"), mr(l, "m1"), mr(l, "m2"), mr(l, "m3")
	local l4, l5, l6, l7 = mr(l, "m4"), mr(l, "m5"), mr(l, "m6"), mr(l, "m7")
	local l8, l9, l10, l11 = mr(l, "m8"), mr(l, "m9"), mr(l, "m10"), mr(l, "m11")
	local l12, l13, l14, l15 = mr(l, "m12"), mr(l, "m13"), mr(l, "m14"), mr(l, "m15")
	local r0, r1, r2, r3 = mr(r, "m0"), mr(r, "m1"), mr(r, "m2"), mr(r, "m3")
	local r4, r5, r6, r7 = mr(r, "m4"), mr(r, "m5"), mr(r, "m6"), mr(r, "m7")
	local r8, r9, r10, r11 = mr(r, "m8"), mr(r, "m9"), mr(r, "m10"), mr(r, "m11")
	local r12, r13, r14, r15 = mr(r, "m12"), mr(r, "m13"), mr(r, "m14"), mr(r, "m15")
	return matNew(
		l0 * r0 + l4 * r1 + l8 * r2 + l12 * r3,
		l1 * r0 + l5 * r1 + l9 * r2 + l13 * r3,
		l2 * r0 + l6 * r1 + l10 * r2 + l14 * r3,
		l3 * r0 + l7 * r1 + l11 * r2 + l15 * r3,
		l0 * r4 + l4 * r5 + l8 * r6 + l12 * r7,
		l1 * r4 + l5 * r5 + l9 * r6 + l13 * r7,
		l2 * r4 + l6 * r5 + l10 * r6 + l14 * r7,
		l3 * r4 + l7 * r5 + l11 * r6 + l15 * r7,
		l0 * r8 + l4 * r9 + l8 * r10 + l12 * r11,
		l1 * r8 + l5 * r9 + l9 * r10 + l13 * r11,
		l2 * r8 + l6 * r9 + l10 * r10 + l14 * r11,
		l3 * r8 + l7 * r9 + l11 * r10 + l15 * r11,
		l0 * r12 + l4 * r13 + l8 * r14 + l12 * r15,
		l1 * r12 + l5 * r13 + l9 * r14 + l13 * r15,
		l2 * r12 + l6 * r13 + l10 * r14 + l14 * r15,
		l3 * r12 + l7 * r13 + l11 * r14 + l15 * r15
	)
end

local function matInvert(m: Buf): Buf
	local a00, a01, a02, a03 = mr(m, "m0"), mr(m, "m1"), mr(m, "m2"), mr(m, "m3")
	local a10, a11, a12, a13 = mr(m, "m4"), mr(m, "m5"), mr(m, "m6"), mr(m, "m7")
	local a20, a21, a22, a23 = mr(m, "m8"), mr(m, "m9"), mr(m, "m10"), mr(m, "m11")
	local a30, a31, a32, a33 = mr(m, "m12"), mr(m, "m13"), mr(m, "m14"), mr(m, "m15")

	local b00 = a00 * a11 - a01 * a10
	local b01 = a00 * a12 - a02 * a10
	local b02 = a00 * a13 - a03 * a10
	local b03 = a01 * a12 - a02 * a11
	local b04 = a01 * a13 - a03 * a11
	local b05 = a02 * a13 - a03 * a12
	local b06 = a20 * a31 - a21 * a30
	local b07 = a20 * a32 - a22 * a30
	local b08 = a20 * a33 - a23 * a30
	local b09 = a21 * a32 - a22 * a31
	local b10 = a21 * a33 - a23 * a31
	local b11 = a22 * a33 - a23 * a32

	local det = b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06
	if det == 0 then
		return matNew(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
	end
	local i = 1 / det
	return matNew(
		(a11 * b11 - a12 * b10 + a13 * b09) * i,
		(-a01 * b11 + a02 * b10 - a03 * b09) * i,
		(a31 * b05 - a32 * b04 + a33 * b03) * i,
		(-a21 * b05 + a22 * b04 - a23 * b03) * i,
		(-a10 * b11 + a12 * b08 - a13 * b07) * i,
		(a00 * b11 - a02 * b08 + a03 * b07) * i,
		(-a30 * b05 + a32 * b02 - a33 * b01) * i,
		(a20 * b05 - a22 * b02 + a23 * b01) * i,
		(a10 * b10 - a11 * b08 + a13 * b06) * i,
		(-a00 * b10 + a01 * b08 - a03 * b06) * i,
		(a30 * b04 - a31 * b02 + a33 * b00) * i,
		(-a20 * b04 + a21 * b02 - a23 * b00) * i,
		(-a10 * b09 + a11 * b07 - a12 * b06) * i,
		(a00 * b09 - a01 * b07 + a02 * b06) * i,
		(-a30 * b03 + a31 * b01 - a32 * b00) * i,
		(a20 * b03 - a21 * b01 + a22 * b00) * i
	)
end

-- ============================================================
-- Screen → World
-- ============================================================

local function v3Unproject(src: V3, inv: Buf): V3
	local qx = mr(inv, "m0") * src.x + mr(inv, "m4") * src.y + mr(inv, "m8") * src.z + mr(inv, "m12")
	local qy = mr(inv, "m1") * src.x + mr(inv, "m5") * src.y + mr(inv, "m9") * src.z + mr(inv, "m13")
	local qz = mr(inv, "m2") * src.x + mr(inv, "m6") * src.y + mr(inv, "m10") * src.z + mr(inv, "m14")
	local qw = mr(inv, "m3") * src.x + mr(inv, "m7") * src.y + mr(inv, "m11") * src.z + mr(inv, "m15")
	return vector.create(qx / qw, qy / qw, qz / qw)
end

-- Returns {position: V3, direction: V3} as plain table — no Ray buffer needed internally
local function screenToRay(sx: number, sy: number, inv: Buf, rw: number, rh: number)
	local dx = 2 * sx / rw - 1
	local dy = -2 * sy / rh + 1
	local near = v3Unproject(vector.create(dx, dy, 0), inv)
	local far = v3Unproject(vector.create(dx, dy, 1), inv)
	local cam = v3Unproject(vector.create(dx, dy, -1), inv)
	return cam, vNorm(far - near)
end

-- ============================================================
-- Collision helpers
-- Raylib's GetRayCollision* take Ray buffers and return RayCollision buffers.
-- We build minimal Ray buffers inline using structs.Ray:new.
-- ============================================================

local RAY_POS_OFS = structs.Ray:offset("position")
local RAY_DIR_OFS = structs.Ray:offset("direction")
local RC_HIT_OFS = structs.RayCollision:offset("hit")

local function makeRayBuf(pos: V3, dir: V3): Buf
	-- structs:new accepts vector for vector3 fields
	return structs.Ray:new({ position = pos, direction = dir })
end

local function rcHit(col: Buf): boolean
	return buffer.readu8(col, RC_HIT_OFS) ~= 0
end

local function hitSphere(pos: V3, dir: V3, center: V3, radius: number): boolean
	return rcHit(lib.GetRayCollisionSphere(makeRayBuf(pos, dir), center, radius))
end

local function hitBox(pos: V3, dir: V3, minv: V3, maxv: V3): boolean
	local box = structs.BoundingBox:new({ min = minv, max = maxv })
	return rcHit(lib.GetRayCollisionBox(makeRayBuf(pos, dir), box))
end

local function hitQuad(pos: V3, dir: V3, a: V3, b: V3, c: V3, d: V3): boolean
	return rcHit(lib.GetRayCollisionQuad(makeRayBuf(pos, dir), a, b, c, d))
end

-- ============================================================
-- Color (plain table — converted to buffer only when passed to lib)
-- ============================================================

type Color = { r: number, g: number, b: number, a: number }

local function mkCol(r: number, g: number, b: number, a: number): Color
	return { r = r, g = g, b = b, a = a }
end

local function colBuf(c: Color): Buf
	return structs.Color:new({ r = c.r, g = c.g, b = c.b, a = c.a })
end

-- ============================================================
-- GizmoTransform  (plain Luau table, no FFI)
-- ============================================================

export type GizmoTransform = {
	translation: V3,
	rotation: Quaternion,
	scale: V3,
	id: number,
}

local _nextId = 0
local function newTransform(): GizmoTransform
	_nextId += 1
	return {
		translation = vector.create(0, 0, 0),
		rotation = quatIdentity(),
		scale = vector.create(1, 1, 1),
		id = _nextId,
	}
end

-- ============================================================
-- Global gizmo state
-- ============================================================

type AxisCfg = { normal: V3, color: Color }

type GizmoGlobals = {
	axisCfg: { AxisCfg },
	gizmoSize: number,
	lineWidth: number,
	trArrowWidthFactor: number,
	trArrowLengthFactor: number,
	trPlaneOffsetFactor: number,
	trPlaneSizeFactor: number,
	trCircleRadiusFactor: number,
	trCircleColor: Color,
	curAction: number,
	activeAxis: number,
	activeTransformId: number,
	activeTransform: GizmoTransform?,
	startTranslation: V3,
	startRotation: Quaternion,
	startScale: V3,
	startWorldMouse: V3,
}

local GIZMO: GizmoGlobals = {
	axisCfg = {
		{ normal = vector.create(1, 0, 0), color = mkCol(229, 72, 91, 255) },
		{ normal = vector.create(0, 1, 0), color = mkCol(131, 205, 56, 255) },
		{ normal = vector.create(0, 0, 1), color = mkCol(69, 138, 242, 255) },
	},
	gizmoSize = 1.5,
	lineWidth = 2.5,
	trArrowLengthFactor = 0.15,
	trArrowWidthFactor = 0.10,
	trPlaneOffsetFactor = 0.30,
	trPlaneSizeFactor = 0.15,
	trCircleRadiusFactor = 0.10,
	trCircleColor = mkCol(255, 255, 255, 200),
	curAction = GZ_ACTION_NONE,
	activeAxis = 0,
	activeTransformId = -1,
	activeTransform = nil,
	startTranslation = vector.create(0, 0, 0),
	startRotation = quatIdentity(),
	startScale = vector.create(1, 1, 1),
	startWorldMouse = vector.create(0, 0, 0),
}

-- ============================================================
-- Per-frame working data
-- ============================================================

type GizmoData = {
	invViewProj: Buf,
	transformId: number,
	axis: { V3 },
	gizmoSize: number,
	camPos: V3,
	right: V3,
	up: V3,
	forward: V3,
	flags: number,
}

-- ============================================================
-- Predicates
-- ============================================================

local function isAxisActive(axis: number): boolean
	return rshift(GIZMO.activeAxis, axis - 1) % 2 == 1
end

local function isGizmoTransforming(): boolean
	return GIZMO.curAction ~= GZ_ACTION_NONE
end

local function isThisTransforming(data: GizmoData): boolean
	return isGizmoTransforming() and data.transformId == GIZMO.activeTransformId
end

local function isScaling(): boolean
	return GIZMO.curAction == GZ_ACTION_SCALE
end
local function isTranslating(): boolean
	return GIZMO.curAction == GZ_ACTION_TRANSLATE
end
local function isRotating(): boolean
	return GIZMO.curAction == GZ_ACTION_ROTATE
end

-- ============================================================
-- Axis orientation
-- ============================================================

local function computeAxisOrientation(data: GizmoData, transform: GizmoTransform)
	local flags = data.flags
	if band(flags, GIZMO_SCALE) ~= 0 then
		flags = bor(band(flags, bnot(GIZMO_VIEW)), GIZMO_LOCAL)
	end
	if band(flags, GIZMO_VIEW) ~= 0 then
		data.axis[GZ_AXIS_X] = data.right
		data.axis[GZ_AXIS_Y] = data.up
		data.axis[GZ_AXIS_Z] = data.forward
	else
		data.axis[GZ_AXIS_X] = GIZMO.axisCfg[GZ_AXIS_X].normal
		data.axis[GZ_AXIS_Y] = GIZMO.axisCfg[GZ_AXIS_Y].normal
		data.axis[GZ_AXIS_Z] = GIZMO.axisCfg[GZ_AXIS_Z].normal
		if band(flags, GIZMO_LOCAL) ~= 0 then
			for i = 1, GIZMO_AXIS_COUNT do
				data.axis[i] = vNorm(quatRotV3(transform.rotation, data.axis[i]))
			end
		end
	end
end

-- ============================================================
-- World mouse
-- ============================================================

local function getWorldMouse(data: GizmoData, transform: GizmoTransform): V3
	local dist = vDist(data.camPos, transform.translation)
	local mp = lib.GetMousePosition()
	local rpos, rdir = screenToRay(mp.x, mp.y, data.invViewProj, lib.GetRenderWidth(), lib.GetRenderHeight())
	return rpos + rdir * dist
end

-- ============================================================
-- Drawing  (all FFI via dot notation, Color built inline)
-- ============================================================

local function vtx(p: V3)
	lib.rlVertex3f(p.x, p.y, p.z)
end

local function col4(c: Color)
	lib.rlColor4ub(c.r, c.g, c.b, c.a)
end

local function drawLine3D(from: V3, to: V3, c: Color)
	-- DrawLine3D takes Vector3 structs — pass native vectors directly
	lib.DrawLine3D(from, to, colBuf(c))
end

-- ============================================================
-- DrawGizmoCube  (scale handle)
-- ============================================================

local function drawGizmoCube(data: GizmoData, transform: GizmoTransform, axis: number)
	if isThisTransforming(data) and (not isAxisActive(axis) or not isScaling()) then
		return
	end

	local both = band(data.flags, GIZMO_SCALE) ~= 0 and band(data.flags, GIZMO_TRANSLATE) ~= 0
	local gs = both and data.gizmoSize * 0.5 or data.gizmoSize

	local dir = data.axis[axis]
	local endPos = transform.translation + dir * (gs * (1 - GIZMO.trArrowWidthFactor))
	drawLine3D(transform.translation, endPos, GIZMO.axisCfg[axis].color)

	local bs = data.gizmoSize * GIZMO.trArrowWidthFactor
	local d1 = data.axis[nextAxis(axis)] * bs
	local d2 = data.axis[next2Axis(axis)] * bs
	local dep = dir * bs
	local c = GIZMO.axisCfg[axis].color

	local a = endPos - d1 * 0.5 - d2 * 0.5
	local b = a + d1
	local cc = b + d2
	local d = a + d2
	local e = a + dep
	local f = b + dep
	local g = cc + dep
	local h = d + dep

	lib.rlBegin(RL_QUADS)
	col4(c)
	vtx(a)
	vtx(b)
	vtx(cc)
	vtx(d)
	vtx(e)
	vtx(f)
	vtx(g)
	vtx(h)
	vtx(a)
	vtx(e)
	vtx(f)
	vtx(d)
	vtx(b)
	vtx(f)
	vtx(g)
	vtx(cc)
	vtx(a)
	vtx(b)
	vtx(f)
	vtx(e)
	vtx(cc)
	vtx(g)
	vtx(h)
	vtx(d)
	lib.rlEnd()
end

-- ============================================================
-- DrawGizmoPlane  (two-axis quad)
-- ============================================================

local function drawGizmoPlane(data: GizmoData, transform: GizmoTransform, index: number)
	if isThisTransforming(data) then
		return
	end

	local dir1 = data.axis[nextAxis(index)]
	local dir2 = data.axis[next2Axis(index)]
	local c = GIZMO.axisCfg[index].color
	local ofs = GIZMO.trPlaneOffsetFactor * data.gizmoSize
	local sz = GIZMO.trPlaneSizeFactor * data.gizmoSize

	local a = transform.translation + dir1 * ofs + dir2 * ofs
	local b = a + dir1 * sz
	local cc = b + dir2 * sz
	local d = a + dir2 * sz

	lib.rlBegin(RL_QUADS)
	lib.rlColor4ub(c.r, c.g, c.b, math.floor(c.a * 0.5))
	vtx(a)
	vtx(b)
	vtx(cc)
	vtx(d)
	lib.rlEnd()

	lib.rlBegin(RL_LINES)
	col4(c)
	vtx(a)
	vtx(b)
	vtx(b)
	vtx(cc)
	vtx(cc)
	vtx(d)
	vtx(d)
	vtx(a)
	lib.rlEnd()
end

-- ============================================================
-- DrawGizmoArrow  (translate handle)
-- ============================================================

local function drawGizmoArrow(data: GizmoData, transform: GizmoTransform, axis: number)
	if isThisTransforming(data) and (not isAxisActive(axis) or not isTranslating()) then
		return
	end

	local dir = data.axis[axis]
	local endPos = transform.translation + dir * (data.gizmoSize * (1 - GIZMO.trArrowLengthFactor))

	if band(data.flags, GIZMO_SCALE) == 0 then
		drawLine3D(transform.translation, endPos, GIZMO.axisCfg[axis].color)
	end

	local al = data.gizmoSize * GIZMO.trArrowLengthFactor
	local aw = data.gizmoSize * GIZMO.trArrowWidthFactor
	local d1 = data.axis[nextAxis(axis)] * aw
	local d2 = data.axis[next2Axis(axis)] * aw
	local tip = endPos + dir * al
	local a = endPos - d1 * 0.5 - d2 * 0.5
	local b = a + d1
	local cc = b + d2
	local d = a + d2

	lib.rlBegin(RL_TRIANGLES)
	col4(GIZMO.axisCfg[axis].color)
	vtx(a)
	vtx(b)
	vtx(cc)
	vtx(a)
	vtx(cc)
	vtx(d)
	vtx(a)
	vtx(tip)
	vtx(b)
	vtx(b)
	vtx(tip)
	vtx(cc)
	vtx(cc)
	vtx(tip)
	vtx(d)
	vtx(d)
	vtx(tip)
	vtx(a)
	lib.rlEnd()
end

-- ============================================================
-- DrawGizmoCenter  (XYZ-all billboard ring)
-- ============================================================

local function drawGizmoCenter(data: GizmoData, transform: GizmoTransform)
	local o = transform.translation
	local radius = data.gizmoSize * GIZMO.trCircleRadiusFactor
	local step = 15
	local stepR = math.rad(step)

	lib.rlPushMatrix()
	lib.rlTranslatef(o.x, o.y, o.z)
	lib.rlBegin(RL_LINES)
	col4(GIZMO.trCircleColor)

	for deg = 0, 359, step do
		local a0 = math.rad(deg)
		local a1 = a0 + stepR
		local function rv(a: number)
			local s, cc = math.sin(a) * radius, math.cos(a) * radius
			lib.rlVertex3f(
				data.right.x * s + data.up.x * cc,
				data.right.y * s + data.up.y * cc,
				data.right.z * s + data.up.z * cc
			)
		end
		rv(a0)
		rv(a1)
	end
	lib.rlEnd()
	lib.rlPopMatrix()
end

-- ============================================================
-- DrawGizmoCircle  (rotate ring)
-- ============================================================

local function drawGizmoCircle(data: GizmoData, transform: GizmoTransform, axis: number)
	if isThisTransforming(data) and (not isAxisActive(axis) or not isRotating()) then
		return
	end

	local o = transform.translation
	local dir1 = data.axis[nextAxis(axis)]
	local dir2 = data.axis[next2Axis(axis)]
	local radius = data.gizmoSize
	local step = 10
	local stepR = math.rad(step)

	lib.rlPushMatrix()
	lib.rlTranslatef(o.x, o.y, o.z)
	lib.rlBegin(RL_LINES)
	col4(GIZMO.axisCfg[axis].color)

	for deg = 0, 359, step do
		local a0 = math.rad(deg)
		local a1 = a0 + stepR
		local p0 = dir1 * (math.sin(a0) * radius) + dir2 * (math.cos(a0) * radius)
		local p1 = dir1 * (math.sin(a1) * radius) + dir2 * (math.cos(a1) * radius)
		lib.rlVertex3f(p0.x, p0.y, p0.z)
		lib.rlVertex3f(p1.x, p1.y, p1.z)
	end
	lib.rlEnd()
	lib.rlPopMatrix()
end

-- ============================================================
-- Ray intersection checks
-- ============================================================

-- OBB check: transform ray into object space, axis-aligned box test
local function checkOBB(data: GizmoData, rpos: V3, rdir: V3, center: V3, half: V3): boolean
	local oLocal = rpos - center
	local lpos = vector.create(
		vDot(oLocal, data.axis[GZ_AXIS_X]),
		vDot(oLocal, data.axis[GZ_AXIS_Y]),
		vDot(oLocal, data.axis[GZ_AXIS_Z])
	)
	local ldir = vector.create(
		vDot(rdir, data.axis[GZ_AXIS_X]),
		vDot(rdir, data.axis[GZ_AXIS_Y]),
		vDot(rdir, data.axis[GZ_AXIS_Z])
	)
	return hitBox(lpos, ldir, vector.create(-half.x, -half.y, -half.z), half)
end

local function checkAxisHit(
	data: GizmoData,
	transform: GizmoTransform,
	axis: number,
	rpos: V3,
	rdir: V3,
	typeFlag: number
): boolean
	local hw = data.gizmoSize * GIZMO.trArrowWidthFactor * 0.5
	local hd = { hw, hw, hw }
	hd[axis] = data.gizmoSize * 0.5
	if typeFlag == GIZMO_SCALE and band(data.flags, GIZMO_SCALE) ~= 0 and band(data.flags, GIZMO_TRANSLATE) ~= 0 then
		hd[axis] *= 0.5
	end
	local center = transform.translation + data.axis[axis] * hd[axis]
	return checkOBB(data, rpos, rdir, center, vector.create(hd[1], hd[2], hd[3]))
end

local function checkPlaneHit(data: GizmoData, transform: GizmoTransform, index: number, rpos: V3, rdir: V3): boolean
	local dir1 = data.axis[nextAxis(index)]
	local dir2 = data.axis[next2Axis(index)]
	local ofs = GIZMO.trPlaneOffsetFactor * data.gizmoSize
	local sz = GIZMO.trPlaneSizeFactor * data.gizmoSize
	local a = transform.translation + dir1 * ofs + dir2 * ofs
	local b = a + dir1 * sz
	local cc = b + dir2 * sz
	local d = a + dir2 * sz
	return hitQuad(rpos, rdir, a, b, cc, d)
end

local function checkCircleHit(data: GizmoData, transform: GizmoTransform, index: number, rpos: V3, rdir: V3): boolean
	local o = transform.translation
	local dir1 = data.axis[nextAxis(index)]
	local dir2 = data.axis[next2Axis(index)]
	local radius = data.gizmoSize
	local step = 10
	local sphereR = radius * math.sin(math.rad(step) * 0.5)
	for deg = 0, 359, step do
		local a = math.rad(deg)
		local p = o + dir1 * (math.sin(a) * radius) + dir2 * (math.cos(a) * radius)
		if hitSphere(rpos, rdir, p, sphereR) then
			return true
		end
	end
	return false
end

local function checkCenterHit(data: GizmoData, transform: GizmoTransform, rpos: V3, rdir: V3): boolean
	return hitSphere(rpos, rdir, transform.translation, data.gizmoSize * GIZMO.trCircleRadiusFactor)
end

-- ============================================================
-- Input handling
-- ============================================================

local HIT_TO_AXIS = {
	[0] = GZ_ACTIVE_X,
	[1] = GZ_ACTIVE_Y,
	[2] = GZ_ACTIVE_Z,
	[3] = bor(GZ_ACTIVE_Y, GZ_ACTIVE_Z),
	[4] = bor(GZ_ACTIVE_X, GZ_ACTIVE_Z),
	[5] = bor(GZ_ACTIVE_X, GZ_ACTIVE_Y),
	[6] = GZ_ACTIVE_XYZ,
}

local function gizmoHandleInput(data: GizmoData, transform: GizmoTransform)
	local action = GIZMO.curAction
	local at = GIZMO.activeTransform

	if action ~= GZ_ACTION_NONE then
		if lib.IsMouseButtonDown(MOUSE_BUTTON_LEFT) == 0 then
			GIZMO.curAction = GZ_ACTION_NONE
			GIZMO.activeAxis = 0
			GIZMO.activeTransform = nil
			GIZMO.activeTransformId = -1
		end

		if at == nil then
			return
		end

		local endMouse = getWorldMouse(data, transform)
		local pVec = endMouse - GIZMO.startWorldMouse

		if action == GZ_ACTION_TRANSLATE then
			at.translation = GIZMO.startTranslation
			if GIZMO.activeAxis == GZ_ACTIVE_XYZ then
				at.translation = at.translation + vProject(pVec, data.right) + vProject(pVec, data.up)
			else
				if band(GIZMO.activeAxis, GZ_ACTIVE_X) ~= 0 then
					at.translation = at.translation + vProject(pVec, data.axis[GZ_AXIS_X])
				end
				if band(GIZMO.activeAxis, GZ_ACTIVE_Y) ~= 0 then
					at.translation = at.translation + vProject(pVec, data.axis[GZ_AXIS_Y])
				end
				if band(GIZMO.activeAxis, GZ_ACTIVE_Z) ~= 0 then
					at.translation = at.translation + vProject(pVec, data.axis[GZ_AXIS_Z])
				end
			end
		elseif action == GZ_ACTION_SCALE then
			at.scale = GIZMO.startScale
			if GIZMO.activeAxis == GZ_ACTIVE_XYZ then
				local delta = vDot(pVec, GIZMO.axisCfg[GZ_AXIS_X].normal)
				at.scale = vAddScalar(at.scale, delta)
			else
				if band(GIZMO.activeAxis, GZ_ACTIVE_X) ~= 0 then
					local prj = vProject(pVec, GIZMO.axisCfg[GZ_AXIS_X].normal)
					at.scale = at.scale + prj
				end
				if band(GIZMO.activeAxis, GZ_ACTIVE_Y) ~= 0 then
					local prj = vProject(pVec, GIZMO.axisCfg[GZ_AXIS_Y].normal)
					at.scale = at.scale + prj
				end
				if band(GIZMO.activeAxis, GZ_ACTIVE_Z) ~= 0 then
					local prj = vProject(pVec, GIZMO.axisCfg[GZ_AXIS_Z].normal)
					at.scale = at.scale + prj
				end
			end
		elseif action == GZ_ACTION_ROTATE then
			at.rotation = GIZMO.startRotation
			local delta = math.clamp(vDot(pVec, data.right + data.up), -2 * math.pi, 2 * math.pi)
			if band(GIZMO.activeAxis, GZ_ACTIVE_X) ~= 0 then
				at.rotation = quatMul(quatFromAxisAngle(data.axis[GZ_AXIS_X], delta), at.rotation)
			end
			if band(GIZMO.activeAxis, GZ_ACTIVE_Y) ~= 0 then
				at.rotation = quatMul(quatFromAxisAngle(data.axis[GZ_AXIS_Y], delta), at.rotation)
			end
			if band(GIZMO.activeAxis, GZ_ACTIVE_Z) ~= 0 then
				at.rotation = quatMul(quatFromAxisAngle(data.axis[GZ_AXIS_Z], delta), at.rotation)
			end
			GIZMO.startRotation = at.rotation
			GIZMO.startWorldMouse = endMouse
		end
	else
		if lib.IsMouseButtonPressed(MOUSE_BUTTON_LEFT) == 0 then
			return
		end

		local mp = lib.GetMousePosition()
		local sx = mp.x
		local sy = mp.y
		local rpos, rdir = screenToRay(sx, sy, data.invViewProj, lib.GetRenderWidth(), lib.GetRenderHeight())

		local hit = -1
		local hitAction = GZ_ACTION_NONE

		for k = 0, 1 do
			local gFlag = if k == 0 then GIZMO_SCALE else GIZMO_TRANSLATE
			local gAct = if k == 0 then GZ_ACTION_SCALE else GZ_ACTION_TRANSLATE
			if band(data.flags, gFlag) ~= 0 then
				if checkCenterHit(data, transform, rpos, rdir) then
					hit = 6
					hitAction = gAct
					break
				end
				for i = 1, GIZMO_AXIS_COUNT do
					if checkAxisHit(data, transform, i, rpos, rdir, gFlag) then
						hit = i - 1
						hitAction = gAct
						break
					end
					if checkPlaneHit(data, transform, i, rpos, rdir) then
						hit = 3 + (i - 1)
						local combined = band(data.flags, GIZMO_SCALE) ~= 0 and band(data.flags, GIZMO_TRANSLATE) ~= 0
						hitAction = combined and GZ_ACTION_TRANSLATE or gAct
						break
					end
				end
			end
			if hit ~= -1 then
				break
			end
		end

		if hit == -1 and band(data.flags, GIZMO_ROTATE) ~= 0 then
			for i = 1, GIZMO_AXIS_COUNT do
				if checkCircleHit(data, transform, i, rpos, rdir) then
					hit = i - 1
					hitAction = GZ_ACTION_ROTATE
					break
				end
			end
		end

		if hit >= 0 then
			GIZMO.activeAxis = HIT_TO_AXIS[hit] or 0
			GIZMO.activeTransformId = transform.id
			GIZMO.activeTransform = transform
			GIZMO.startTranslation = transform.translation
			GIZMO.startRotation = transform.rotation
			GIZMO.startScale = transform.scale
			GIZMO.startWorldMouse = getWorldMouse(data, transform)
			GIZMO.curAction = hitAction
		end
	end
end

-- ============================================================
-- Public API
-- ============================================================

--[[
    DrawGizmo3D(flags, transform) -> boolean

    Call once per GizmoTransform per frame, inside BeginMode3D / EndMode3D.

    flags     : combine GIZMO_TRANSLATE / GIZMO_ROTATE / GIZMO_SCALE /
                GIZMO_LOCAL / GIZMO_VIEW with +
    transform : GizmoTransform from newTransform()
    Returns true while this transform is being dragged.
]]
local function DrawGizmo3D(flags: number, transform: GizmoTransform, camPos): boolean
	if flags == GIZMO_DISABLED then
		return false
	end

	local matProj = lib.rlGetMatrixProjection()
	local matView = lib.rlGetMatrixModelview()
	local invView = matInvert(matView)
	local invProj = matInvert(matProj)

	local data: GizmoData = {
		invViewProj = matMul(invProj, invView),
		transformId = transform.id,
		axis = { vector.create(1, 0, 0), vector.create(0, 1, 0), vector.create(0, 0, 1) },
		camPos = camPos,
		right = vector.create(mr(matView, "m0"), mr(matView, "m4"), mr(matView, "m8")),
		up = vector.create(mr(matView, "m1"), mr(matView, "m5"), mr(matView, "m9")),
		forward = vector.create(0, 0, 0),
		gizmoSize = 0,
		flags = flags,
	}
	data.forward = vNorm(data.camPos - transform.translation)
	data.gizmoSize = GIZMO.gizmoSize * vDist(data.camPos, transform.translation) * 0.1

	computeAxisOrientation(data, transform)

	lib.rlDrawRenderBatchActive()
	local prevLW = lib.rlGetLineWidth()
	lib.rlSetLineWidth(GIZMO.lineWidth)
	lib.rlDisableBackfaceCulling()
	lib.rlDisableDepthTest()
	lib.rlDisableDepthMask()

	for i = 1, GIZMO_AXIS_COUNT do
		if band(flags, GIZMO_TRANSLATE) ~= 0 then
			drawGizmoArrow(data, transform, i)
		end
		if band(flags, GIZMO_SCALE) ~= 0 then
			drawGizmoCube(data, transform, i)
		end
		if band(flags, bor(GIZMO_SCALE, GIZMO_TRANSLATE)) ~= 0 then
			drawGizmoPlane(data, transform, i)
		end
		if band(flags, GIZMO_ROTATE) ~= 0 then
			drawGizmoCircle(data, transform, i)
		end
	end
	if band(flags, bor(GIZMO_SCALE, GIZMO_TRANSLATE)) ~= 0 then
		drawGizmoCenter(data, transform)
	end

	lib.rlDrawRenderBatchActive()
	lib.rlSetLineWidth(prevLW)
	lib.rlEnableBackfaceCulling()
	lib.rlEnableDepthTest()
	lib.rlEnableDepthMask()

	if not isGizmoTransforming() or transform.id == GIZMO.activeTransformId then
		gizmoHandleInput(data, transform)
	end

	return isThisTransforming(data)
end

--[[
    GizmoToMatrix(transform) -> buffer (Matrix)

    Converts a GizmoTransform to a raylib column-major Matrix buffer.
]]
local function GizmoToMatrix(transform: GizmoTransform): Buf
	local q = transform.rotation
	local x2, y2, z2 = q.x + q.x, q.y + q.y, q.z + q.z
	local xx, yy, zz = q.x * x2, q.y * y2, q.z * z2
	local xy, xz, yz = q.x * y2, q.x * z2, q.y * z2
	local wx, wy, wz = q.w * x2, q.w * y2, q.w * z2
	local s = transform.scale
	local t = transform.translation
	return matNew(
		-- col 0: right * sx
		(1 - (yy + zz)) * s.x,
		(xy + wz) * s.x,
		(xz - wy) * s.x,
		0,
		-- col 1: up * sy
		(xy - wz) * s.y,
		(1 - (xx + zz)) * s.y,
		(yz + wx) * s.y,
		0,
		-- col 2: forward * sz
		(xz + wy) * s.z,
		(yz - wx) * s.z,
		(1 - (xx + yy)) * s.z,
		0,
		-- col 3: translation
		t.x,
		t.y,
		t.z,
		1
	)
end

-- Configuration

local function SetGizmoSize(size: number)
	GIZMO.gizmoSize = math.max(0, size)
end

local function SetGizmoLineWidth(width: number)
	GIZMO.lineWidth = math.max(0, width)
end

local function SetGizmoColors(x: Color, y: Color, z: Color, center: Color)
	GIZMO.axisCfg[GZ_AXIS_X].color = x
	GIZMO.axisCfg[GZ_AXIS_Y].color = y
	GIZMO.axisCfg[GZ_AXIS_Z].color = z
	GIZMO.trCircleColor = center
end

local function SetGizmoGlobalAxis(right: V3, up: V3, fwd: V3)
	GIZMO.axisCfg[GZ_AXIS_X].normal = vNorm(right)
	GIZMO.axisCfg[GZ_AXIS_Y].normal = vNorm(up)
	GIZMO.axisCfg[GZ_AXIS_Z].normal = vNorm(fwd)
end

-- ============================================================
-- Module
-- ============================================================

return {
	GIZMO_DISABLED = GIZMO_DISABLED,
	GIZMO_TRANSLATE = GIZMO_TRANSLATE,
	GIZMO_ROTATE = GIZMO_ROTATE,
	GIZMO_SCALE = GIZMO_SCALE,
	GIZMO_LOCAL = GIZMO_LOCAL,
	GIZMO_VIEW = GIZMO_VIEW,
	GIZMO_ALL = GIZMO_ALL,

	newTransform = newTransform,
	DrawGizmo3D = DrawGizmo3D,
	GizmoToMatrix = GizmoToMatrix,
	SetGizmoSize = SetGizmoSize,
	SetGizmoLineWidth = SetGizmoLineWidth,
	SetGizmoColors = SetGizmoColors,
	SetGizmoGlobalAxis = SetGizmoGlobalAxis,
}
