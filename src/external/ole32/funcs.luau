local ffi = zune.ffi

-- Type aliases for FFI
type int = number
type float = number
type bool = boolean
type cstring = string
type FFIPointer = typeof(ffi.types.pointer)

-- Import struct types
local structs = require("./structs")
type STGOPTIONS = structs.STGOPTIONS

export type Fns = {
	BindMoniker: (pmk: FFIPointer, grfOpt: FFIPointer, iidResult: FFIPointer, ppvResult: FFIPointer) -> FFIPointer,
	CLSIDFromProgIDEx: (lpszProgID: FFIPointer, lpclsid: FFIPointer) -> FFIPointer,
	CoAllowSetForegroundWindow: (pUnk: FFIPointer, lpvReserved: FFIPointer) -> FFIPointer,
	CoFileTimeNow: (lpFileTime: FFIPointer) -> FFIPointer,
	CoGetInstanceFromFile: (
		pServerInfo: FFIPointer,
		pClsid: FFIPointer,
		punkOuter: FFIPointer,
		dwClsCtx: FFIPointer,
		grfMode: FFIPointer,
		pwszName: FFIPointer,
		dwCount: FFIPointer,
		pResults: FFIPointer
	) -> FFIPointer,
	CoGetInstanceFromIStorage: (
		pServerInfo: FFIPointer,
		pClsid: FFIPointer,
		punkOuter: FFIPointer,
		dwClsCtx: FFIPointer,
		pstg: FFIPointer,
		dwCount: FFIPointer,
		pResults: FFIPointer
	) -> FFIPointer,
	CoGetObject: (pszName: FFIPointer, pBindOptions: FFIPointer, riid: FFIPointer, ppv: () -> ()) -> FFIPointer,
	CoGetSystemSecurityPermissions: (comSDType: FFIPointer, ppSD: FFIPointer) -> FFIPointer,
	CoInitialize: (pvReserved: FFIPointer) -> FFIPointer,
	CoInstall: (
		pbc: FFIPointer,
		dwFlags: FFIPointer,
		pClassSpec: FFIPointer,
		pQuery: FFIPointer,
		pszCodeBase: FFIPointer
	) -> FFIPointer,
	CoRegisterChannelHook: (ExtensionUuid: FFIPointer, pChannelHook: FFIPointer) -> FFIPointer,
	CoRegisterInitializeSpy: (pSpy: FFIPointer, puliCookie: FFIPointer) -> FFIPointer,
	CoRegisterMallocSpy: (pMallocSpy: FFIPointer) -> FFIPointer,
	CoRegisterMessageFilter: (lpMessageFilter: FFIPointer, lplpMessageFilter: FFIPointer) -> FFIPointer,
	CoRevokeInitializeSpy: (uliCookie: FFIPointer) -> FFIPointer,
	CoRevokeMallocSpy: () -> FFIPointer,
	CoTreatAsClass: (clsidOld: FFIPointer, clsidNew: FFIPointer) -> FFIPointer,
	CreateAntiMoniker: (ppmk: FFIPointer) -> FFIPointer,
	CreateBindCtx: (reserved: FFIPointer, ppbc: FFIPointer) -> FFIPointer,
	CreateClassMoniker: (rclsid: FFIPointer, ppmk: FFIPointer) -> FFIPointer,
	CreateDataAdviseHolder: (ppDAHolder: FFIPointer) -> FFIPointer,
	CreateDataCache: (pUnkOuter: FFIPointer, rclsid: FFIPointer, iid: FFIPointer, ppv: FFIPointer) -> FFIPointer,
	CreateFileMoniker: (lpszPathName: FFIPointer, ppmk: FFIPointer) -> FFIPointer,
	CreateGenericComposite: (pmkFirst: FFIPointer, pmkRest: FFIPointer, ppmkComposite: FFIPointer) -> FFIPointer,
	CreateItemMoniker: (lpszDelim: FFIPointer, lpszItem: FFIPointer, ppmk: FFIPointer) -> FFIPointer,
	CreateObjrefMoniker: (punk: FFIPointer, ppmk: FFIPointer) -> FFIPointer,
	CreatePointerMoniker: (punk: FFIPointer, ppmk: FFIPointer) -> FFIPointer,
	CreateStdProgressIndicator: (
		hwndParent: FFIPointer,
		pszTitle: FFIPointer,
		pIbscCaller: FFIPointer,
		ppIbsc: FFIPointer
	) -> FFIPointer,
	DcomChannelSetHResult: (pvReserved: FFIPointer, pulReserved: FFIPointer, appsHR: FFIPointer) -> FFIPointer,
	GetClassFile: (szFilename: FFIPointer, pclsid: FFIPointer) -> FFIPointer,
	GetRunningObjectTable: (reserved: FFIPointer, pprot: FFIPointer) -> FFIPointer,
	MkParseDisplayName: (pbc: FFIPointer, szUserName: FFIPointer, pchEaten: FFIPointer, ppmk: FFIPointer) -> FFIPointer,
	MonikerCommonPrefixWith: (pmkThis: FFIPointer, pmkOther: FFIPointer, ppmkCommon: FFIPointer) -> FFIPointer,
	MonikerRelativePathTo: (
		pmkSrc: FFIPointer,
		pmkDest: FFIPointer,
		ppmkRelPath: FFIPointer,
		dwReserved: FFIPointer
	) -> FFIPointer,
	StgCreateDocfile: (
		pwcsName: FFIPointer,
		grfMode: FFIPointer,
		reserved: FFIPointer,
		ppstgOpen: FFIPointer
	) -> FFIPointer,
	StgCreateDocfileOnILockBytes: (
		plkbyt: FFIPointer,
		grfMode: FFIPointer,
		reserved: FFIPointer,
		ppstgOpen: FFIPointer
	) -> FFIPointer,
	StgCreateStorageEx: (
		pwcsName: FFIPointer,
		grfMode: FFIPointer,
		stgfmt: FFIPointer,
		grfAttrs: FFIPointer,
		pStgOptions: STGOPTIONS,
		pSecurityDescriptor: FFIPointer,
		riid: FFIPointer,
		ppObjectOpen: () -> ()
	) -> FFIPointer,
	StgGetIFillLockBytesOnFile: (pwcsName: FFIPointer, ppflb: FFIPointer) -> FFIPointer,
	StgGetIFillLockBytesOnILockBytes: (pilb: FFIPointer, ppflb: FFIPointer) -> FFIPointer,
	StgIsStorageFile: (pwcsName: FFIPointer) -> FFIPointer,
	StgIsStorageILockBytes: (plkbyt: FFIPointer) -> FFIPointer,
	StgOpenAsyncDocfileOnIFillLockBytes: (
		pflb: FFIPointer,
		grfMode: FFIPointer,
		asyncFlags: FFIPointer,
		ppstgOpen: FFIPointer
	) -> FFIPointer,
	StgOpenStorage: (
		pwcsName: FFIPointer,
		pstgPriority: FFIPointer,
		grfMode: FFIPointer,
		snbExclude: FFIPointer,
		reserved: FFIPointer,
		ppstgOpen: FFIPointer
	) -> FFIPointer,
	StgOpenStorageEx: (
		pwcsName: FFIPointer,
		grfMode: FFIPointer,
		stgfmt: FFIPointer,
		grfAttrs: FFIPointer,
		pStgOptions: STGOPTIONS,
		pSecurityDescriptor: FFIPointer,
		riid: FFIPointer,
		ppObjectOpen: () -> ()
	) -> FFIPointer,
	StgOpenStorageOnILockBytes: (
		plkbyt: FFIPointer,
		pstgPriority: FFIPointer,
		grfMode: FFIPointer,
		snbExclude: FFIPointer,
		reserved: FFIPointer,
		ppstgOpen: FFIPointer
	) -> FFIPointer,
	CoInitializeEx: (pvReserved: FFIPointer, dwCoInit: FFIPointer) -> FFIPointer,

	StgSetTimes: (lpszName: FFIPointer, pctime: FFIPointer, patime: FFIPointer, pmtime: FFIPointer) -> FFIPointer,
}

local funcs = {
	CoInitialize = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	CoRegisterMallocSpy = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	CoRevokeMallocSpy = { returns = ffi.types.pointer, args = {} },
	CoRegisterInitializeSpy = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.pointer } },
	CoRevokeInitializeSpy = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	CoGetSystemSecurityPermissions = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.pointer } },
	CoGetInstanceFromFile = {
		returns = ffi.types.pointer,
		args = {
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
		},
	},
	CoInitializeEx = {
		returns = ffi.types.i32, -- HRESULT
		args = { ffi.types.pointer, ffi.types.i32 }, -- LPVOID, DWORD
	},

	CoGetInstanceFromIStorage = {
		returns = ffi.types.pointer,
		args = {
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
		},
	},
	CoAllowSetForegroundWindow = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.pointer } },
	DcomChannelSetHResult = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
	CLSIDFromProgIDEx = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.pointer } },
	CoFileTimeNow = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	CoRegisterMessageFilter = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.pointer } },
	CoRegisterChannelHook = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.pointer } },
	CoTreatAsClass = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.pointer } },
	CreateDataAdviseHolder = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	CreateDataCache = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},

	StgCreateDocfile = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
	StgCreateDocfileOnILockBytes = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
	StgOpenStorage = {
		returns = ffi.types.pointer,
		args = {
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
		},
	},
	StgOpenStorageOnILockBytes = {
		returns = ffi.types.pointer,
		args = {
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
		},
	},
	StgIsStorageFile = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	StgIsStorageILockBytes = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	StgSetTimes = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
	StgOpenAsyncDocfileOnIFillLockBytes = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
	StgGetIFillLockBytesOnILockBytes = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.pointer } },
	StgGetIFillLockBytesOnFile = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.pointer } },
	StgCreateStorageEx = {
		returns = ffi.types.pointer,
		args = {
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
		},
	},
	StgOpenStorageEx = {
		returns = ffi.types.pointer,
		args = {
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
			ffi.types.pointer,
		},
	},
	BindMoniker = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
	CoGetObject = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer } },
	MkParseDisplayName = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
	MonikerRelativePathTo = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
	MonikerCommonPrefixWith = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
	CreateBindCtx = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.pointer } },
	CreateGenericComposite = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
	GetClassFile = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.pointer } },
	CreateClassMoniker = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.pointer } },
	CreateFileMoniker = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.pointer } },
	CreateItemMoniker = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
	CreateAntiMoniker = { returns = ffi.types.pointer, args = { ffi.types.pointer } },
	CreatePointerMoniker = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.pointer } },
	CreateObjrefMoniker = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.pointer } },
	CoInstall = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
	GetRunningObjectTable = { returns = ffi.types.pointer, args = { ffi.types.pointer, ffi.types.pointer } },
	CreateStdProgressIndicator = {
		returns = ffi.types.pointer,
		args = { ffi.types.pointer, ffi.types.pointer, ffi.types.pointer, ffi.types.pointer },
	},
}

return funcs
