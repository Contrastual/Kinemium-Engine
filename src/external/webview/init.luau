--!strict
--!optimize 2
-- Made by FFIGen (Kinemium)

local dll = "./src/external/webview/bin/"
local zembed = require("@zembed")
if zembed.IsEmbedded() then
	dll = "./"
end
local ffi = zune.ffi

local structs = require("./webview/structs")
local funcs = require("./webview/funcs")
local constants = require("./webview/constants")

local libname = "webview." .. ffi.suffix

local webview: funcs.Fns = ffi.dlopen(dll .. libname, funcs)

return {
	lib = webview,
	structs = structs,
	constants = constants,
}
