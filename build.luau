--!strict
local fs = zune.fs
local process = zune.process

local function build()
	local sArgs = {
		"-s",
		"src/main.lua",
		"src/enviroment/*",
		"src/enviroment/class/**",
		"src/enviroment/classlibs/**",
		"src/enviroment/datatypes/**",
		"src/enviroment/libraries/**",

		"src/enviroment/game/services/Workspace/**",
		"src/enviroment/game/services/*/*",
		"src/enviroment/game/*",
		"src/enviroment/game/runtime/*",

		"src/modules/**/*.lua*",
		"src/renderer/**/*.lua*",
		"src/sandboxed/**",
		"src/runtime/**/*.lua*",
		"src/external/**/*.lua*",
		"src/objects/**",
		"src/libs/**",
		"src/**",
		"src/external/signal.lua",
	}

	local args = {
		"bundle",
		"--compression=zstd",
		"-f",
		"./**/.luaurc",
		"src/assets/**",
		"src/assets/images/**",
		"src/assets/icon/**",
		"src/assets/materials/**",
		"src/assets/meshes/**",
		"src/assets/fonts/**",
		"src/assets/sky/**",
		"src/projects.toml",
		"src/assets/sounds/**",
		"src/assets/videos/**",
	}

	for _, line in pairs(sArgs) do
		table.insert(args, line)
	end
	table.insert(args, "--out=./build/KinemiumRuntime.exe")

	local res = process.run(fs.getExePath(), args)
	print("Successfully built")

	if not res.ok then
		error(`\n- {res.stderr}`)
	end
end

build()
