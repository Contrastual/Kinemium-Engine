-- devcell

local Impulse3D = {}

local body, physics, utility, joints =
	require("./body"), require("./physics"), require("./utility"), require("./joints")

Impulse3D.body = body
Impulse3D.physics = physics
Impulse3D.joints = joints
Impulse3D.utility = utility

function Impulse3D.Step(dt)
	physics.step(Impulse3D.body, Impulse3D.joints, dt)
end

export type Impulse3D = typeof(Impulse3D)

return Impulse3D :: Impulse3D
