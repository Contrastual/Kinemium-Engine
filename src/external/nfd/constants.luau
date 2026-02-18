--!strict
--!optimize 2

local constants = {
	nfdresult_t = {
		NFD_ERROR = 0,
		NFD_OKAY = 1,
		NFD_CANCEL = 2,
	},

	NFD_WINDOW_HANDLE_TYPE_UNSET = 0,
	NFD_WINDOW_HANDLE_TYPE_WINDOWS = 1,
	NFD_WINDOW_HANDLE_TYPE_COCOA = 2,
	NFD_WINDOW_HANDLE_TYPE_X11 = 3,

	-- Defined constants
	NFD_INTERFACE_VERSION = 1,
}

return constants