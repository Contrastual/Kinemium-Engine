local process = zune.process
local fs = zune.fs
local io = zune.io
local serde = zune.serde

local logo = [[
            @@@@@@@@@@@@@@@@@@            
         @@@@@@   @    @   @@@@@@         
      @@@@    @            @    @@@@      
     @@@-@                      @-@@@     
   @@@                              @@@   
  @@@@======   @@@@    @@@@=========%@@@  
 @@@   -...= @@@@@@    @-.........-   @@@ 
@@@@@  =...:@@@@@@@    -..........=   @@@@
@@     =....@@@@@@@  .=:.....-....=     @@
@@     =....@@@@@@  ==......@@....=     @@
@@@    =....@@@@  --...--=@@@@....=    @@@
@      =....@@@@.::..:==  @@@@....=      @
@@@    =....@+.......=       @:...=    @@@
@@     =..............        =...=     @@
@@     =.............-==@@    =...=     @@
@@@@@  =-::::...::.......:@@@@=:::=  @@@@@
 @@@    ....===@@@@:......:@@ .....   @@@ 
  @@@=@        @@@@@@@@@@@@        @+@@@  
   @@@                              @@@   
    @@@@.@                      @.@@@@    
      @@@@    @            @    @@@@      
         @@@@@@   @    @   @@@@@@         
            @@@@@@@@@@@@@@@@@@                           
]]

local function io_start(msg, callback)
	while true do
		io.stdout:write(msg)

		local line = io.stdin:read()

		if line == nil then
			io.stdout:write("\n")
			break
		end

		line = line:gsub("[^%a]", "")
		if line ~= "" then
			callback(line)
		end
	end
end

local function fileExists(file)
	local f = fs.stat(file)
	if f.kind == "none" then
		return false
	else
		return true
	end
	return false
end

local function clone()
	print("UPDATER: Cloning repository...")
	local success, result = pcall(function()
		return process.run("git", {
			"clone",
			"--depth",
			"1",
			"--branch",
			"main",
			"https://github.com/Qquaded/Kinemium-Engine.git",
		})
	end)

	print("UPDATER: Finished cloning.")
	if not success then
		warn(result)
	end
end

local function update()
	local repoDir = "Kinemium-Engine"

	assert(fs.stat(repoDir .. "/.git").kind == "directory", "UPDATER: Not a git repository")

	print("UPDATER: Fetching latest changes from origin...")
	local fetch = process.run("git", { "fetch", "origin" }, { cwd = repoDir })
	if fetch.code ~= 0 then
		error("UPDATER: Failed to fetch from origin:\n" .. fetch.stderr)
	end

	print("UPDATER: Updating tracked files...")
	local checkout = process.run("git", { "checkout", "origin/main", "--", "." }, { cwd = repoDir })
	if checkout.code ~= 0 then
		error("UPDATER: Failed to update files:\n" .. checkout.stderr)
	end

	print("UPDATER: Finished updating repository.")
end

print(logo)
if not fileExists("./Kinemium-Engine") then
	io_start(
		"UPDATER: You don't seem to have the repository installed, Do you want to install it? (y/n) ",
		function(line)
			if line == "y" then
				clone()
				process.exit(0)
			else
				print("UPDATER: Cancelled.")
				process.exit(0)
			end
		end
	)
else
	io_start("UPDATER: Do you want to update the repository? (y/n) ", function(line)
		if line == "y" then
			update()
			process.exit(0)
		else
			print("UPDATER: Cancelled.")
			process.exit(0)
		end
	end)
end
