local process = zune.process
local fs = zune.fs
local io = zune.io
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

local DEFAULT_BRANCH = "main"

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

local function io_input(msg, callback)
	io.stdout:write(msg)
	local line = io.stdin:read()
	if line == nil then
		io.stdout:write("\n")
		return
	end
	line = line:match("^%s*(.-)%s*$") -- trim whitespace
	callback(line)
end

local function fileExists(file)
	local f = fs.stat(file)
	if f.kind == "none" then
		return false
	end
	return true
end

local function clone(branch)
	branch = branch or DEFAULT_BRANCH
	print("UPDATER: Cloning repository (branch: " .. branch .. ")...")
	local success, result = pcall(function()
		local proc = process.create("git", {
			"clone",
			"--progress",
			"--depth",
			"1",
			"--branch",
			branch,
			"https://github.com/Qquaded/Kinemium-Engine.git",
		}, { stdout = io.stdout, stderr = io.stderr })
		proc:wait()
		return proc
	end)
	print("UPDATER: Finished cloning.")
	if not success then
		error(result)
	end
end

local function update(branch)
	branch = branch or DEFAULT_BRANCH
	local repoDir = "./"
	assert(fs.stat(repoDir .. ".git").kind == "directory", "UPDATER: Not a git repository")
	print("UPDATER: Fetching latest changes from origin...")
	local fetch = process.run("git", { "fetch", "origin" }, { cwd = repoDir })
	if fetch.code ~= 0 then
		error("UPDATER: Failed to fetch from origin:\n" .. fetch.stderr)
	end
	print("UPDATER: Updating tracked files (branch: " .. branch .. ")...")
	local checkout = process.run("git", { "checkout", "origin/" .. branch, "--", "." }, { cwd = repoDir })
	if checkout.code ~= 0 then
		error("UPDATER: Failed to update files:\n" .. checkout.stderr)
	end
	print("UPDATER: Finished updating repository.")
end

local function ask_branch(default, callback)
	io_input("UPDATER: Branch to use? (leave blank for '" .. default .. "'): ", function(line)
		local branch = (line ~= "" and line) or default
		callback(branch)
	end)
end

print(logo)

local branch_override = nil
local args = process.args or {}
for i, v in ipairs(args) do
	if v == "--branch" and args[i + 1] then
		branch_override = args[i + 1]
	end
end

if not fileExists("../Kinemium-Engine") then
	io_start(
		"UPDATER: You don't seem to have the repository installed. Do you want to install it? (y/n) ",
		function(line)
			if line == "y" then
				if branch_override then
					clone(branch_override)
				else
					ask_branch(DEFAULT_BRANCH, function(branch)
						clone(branch)
					end)
				end
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
			if branch_override then
				update(branch_override)
			else
				ask_branch(DEFAULT_BRANCH, function(branch)
					update(branch)
				end)
			end
			process.exit(0)
		else
			print("UPDATER: Cancelled.")
			process.exit(0)
		end
	end)
end
