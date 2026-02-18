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

local dGeomClass = ffi.struct({
	{ bytes = ffi.types.i32 },
	{ collider = ffi.types.pointer },
	{ aabb = ffi.types.pointer },
	{ aabb_test = ffi.types.pointer },
	{ dtor = ffi.types.pointer },
})
export type dGeomClass = typeof(dGeomClass:new({}))

local dJointFeedback = ffi.struct({
	{ f1 = ffi.types.pointer },
	{ t1 = ffi.types.pointer },
	{ f2 = ffi.types.pointer },
	{ t2 = ffi.types.pointer },
})
export type dJointFeedback = typeof(dJointFeedback:new({}))

local dSurfaceParameters = ffi.struct({
	{ mode = ffi.types.i32 },
	{ mu = ffi.types.double },
	{ mu2 = ffi.types.double },
	{ rho = ffi.types.double },
	{ rho2 = ffi.types.double },
	{ rhoN = ffi.types.double },
	{ bounce = ffi.types.double },
	{ bounce_vel = ffi.types.double },
	{ soft_erp = ffi.types.double },
	{ soft_cfm = ffi.types.double },
	{ motion1 = ffi.types.double },
	{ motion2 = ffi.types.double },
	{ motionN = ffi.types.double },
	{ slip1 = ffi.types.double },
	{ slip2 = ffi.types.double },
	{ inward_force_limit = ffi.types.double },
})
export type dSurfaceParameters = typeof(dSurfaceParameters:new({}))

local dContactGeom = ffi.struct({
	{ pos = ffi.types.pointer },
	{ normal = ffi.types.pointer },
	{ depth = ffi.types.double },
	{ g1 = ffi.types.pointer },
	{ g2 = ffi.types.pointer },
	{ side1 = ffi.types.i32 },
	{ side2 = ffi.types.i32 },
})
export type dContactGeom = typeof(dContactGeom:new({}))

local dContact = ffi.struct({
	{ surface = dSurfaceParameters },
	{ geom = dContactGeom },
	{ fdir1 = ffi.types.pointer },
})
export type dContact = typeof(dContact:new({}))

local dWorldSteppingThreadingParameters = ffi.struct({
	{ param_set = ffi.types.pointer },
	{ world_islands_iteration_max_threads = ffi.types.pointer },
	{ island_stepping_max_threads = ffi.types.pointer },
	{ lcp_solving_max_threads = ffi.types.pointer },
})
export type dWorldSteppingThreadingParameters = typeof(dWorldSteppingThreadingParameters:new({}))

local dWorldStepReserveInfo = ffi.struct({
	{ struct_size = ffi.types.pointer },
	{ reserve_factor = ffi.types.float },
	{ reserve_minimum = ffi.types.pointer },
})
export type dWorldStepReserveInfo = typeof(dWorldStepReserveInfo:new({}))

local dWorldStepMemoryFunctionsInfo = ffi.struct({
	{ struct_size = ffi.types.pointer },
	{ alloc_block = ffi.types.pointer },
	{ shrink_block = ffi.types.pointer },
	{ free_block = ffi.types.pointer },
})
export type dWorldStepMemoryFunctionsInfo = typeof(dWorldStepMemoryFunctionsInfo:new({}))

local dWorldQuickStepIterationCount_DynamicAdjustmentStatistics = ffi.struct({
	{ struct_size = ffi.types.pointer },
	{ iteration_count = ffi.types.u32 },
	{ premature_exits = ffi.types.u32 },
	{ prolonged_execs = ffi.types.u32 },
	{ full_extra_execs = ffi.types.u32 },
})
export type dWorldQuickStepIterationCount_DynamicAdjustmentStatistics = typeof(dWorldQuickStepIterationCount_DynamicAdjustmentStatistics:new({}))

local dThreadedWaitTime = ffi.struct({
	{ wait_sec = ffi.types.pointer },
	{ wait_nsec = ffi.types.u64 },
})
export type dThreadedWaitTime = typeof(dThreadedWaitTime:new({}))

local dThreadingFunctionsInfo = ffi.struct({
	{ struct_size = ffi.types.pointer },
	{ alloc_mutex_group = ffi.types.pointer },
	{ free_mutex_group = ffi.types.pointer },
	{ lock_group_mutex = ffi.types.pointer },
	{ unlock_group_mutex = ffi.types.pointer },
	{ alloc_call_wait = ffi.types.pointer },
	{ reset_call_wait = ffi.types.pointer },
	{ free_call_wait = ffi.types.pointer },
	{ post_call = ffi.types.pointer },
	{ alter_call_dependencies_count = ffi.types.pointer },
	{ wait_call = ffi.types.pointer },
	{ retrieve_thread_count = ffi.types.pointer },
	{ preallocate_resources_for_calls = ffi.types.pointer },
})
export type dThreadingFunctionsInfo = typeof(dThreadingFunctionsInfo:new({}))

local dStopwatch = ffi.struct({
	{ time = ffi.types.double },
	{ cc = ffi.types.u64:array(2) },
})
export type dStopwatch = typeof(dStopwatch:new({}))

local structs = {
	dGeomClass = dGeomClass,
	dJointFeedback = dJointFeedback,
	dSurfaceParameters = dSurfaceParameters,
	dContactGeom = dContactGeom,
	dContact = dContact,
	dWorldSteppingThreadingParameters = dWorldSteppingThreadingParameters,
	dWorldStepReserveInfo = dWorldStepReserveInfo,
	dWorldStepMemoryFunctionsInfo = dWorldStepMemoryFunctionsInfo,
	dWorldQuickStepIterationCount_DynamicAdjustmentStatistics = dWorldQuickStepIterationCount_DynamicAdjustmentStatistics,
	dThreadedWaitTime = dThreadedWaitTime,
	dThreadingFunctionsInfo = dThreadingFunctionsInfo,
	dStopwatch = dStopwatch,
}

return structs