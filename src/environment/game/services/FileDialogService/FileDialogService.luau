local Instance = require("@Instance")
local BufferUtils = require("@bufferutils")

local FileDialogService = Instance.new("FileDialogService")
FileDialogService.ExplorerHidden = true

local ffi = zune.ffi

FileDialogService.InitRenderer = function(renderer, renderer_signal)
	local nfd = require("@nfd")
	local lib = nfd.lib

	lib.NFD_Init()

	FileDialogService:SetProperties({
		RequestFile = function(filters)
			local outPath = ffi.alloc(ffi.types.pointer:size())
			local success: FFIPointer = lib.NFD_OpenDialogN(outPath, nil, nil, nil)
			local code = BufferUtils:readhexa(success)
			if code == 2 then
				return ""
			end
			return BufferUtils.string.ReadOSBased(outPath)
		end,

		RequestFolder = function(filters)
			local outPath = ffi.alloc(ffi.types.pointer:size())
			local success: FFIPointer = lib.NFD_PickFolderN(outPath, nil)
			local code = BufferUtils:readhexa(success)
			if code == 2 then
				return ""
			end
			return BufferUtils.string.ReadOSBased(outPath)
		end,

		RequestSaveFile = function(defaultName, filters)
			local outPath = ffi.alloc(ffi.types.pointer:size())

			local success: FFIPointer = lib.NFD_SaveDialogN(outPath, nil, nil, nil, defaultName)
			local code = BufferUtils:readhexa(success)

			if code == 2 then -- cancel
				return ""
			end

			return BufferUtils.string.ReadOSBased(outPath)
		end,
	})

	renderer_signal:Connect(function(route, dt) end)
end

return FileDialogService
