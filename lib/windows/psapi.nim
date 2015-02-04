#
#
#            Nim's Runtime Library
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

#       PSAPI interface unit

# Contains the definitions for the APIs provided by PSAPI.DLL

import                        # Data structure templates
  Windows

const
  psapiDll = "psapi.dll"

proc EnumProcesses*(lpidProcess: ptr DWORD, cb: DWORD,
                    cbNeeded: ptr DWORD): WINBOOL {.stdcall,
    dynlib: psapiDll, importc: "EnumProcesses".}
proc EnumProcessModules*(hProcess: HANDLE, lphModule: ptr HMODULE, cb: DWORD, lpcbNeeded: LPDWORD): WINBOOL {.stdcall,
    dynlib: psapiDll, importc: "EnumProcessModules".}

proc GetModuleBaseNameA*(hProcess: HANDLE, hModule: HMODULE, lpBaseName: LPSTR, nSize: DWORD): DWORD {.stdcall,
    dynlib: psapiDll, importc: "GetModuleBaseNameA".}
proc GetModuleBaseNameW*(hProcess: HANDLE, hModule: HMODULE, lpBaseName: LPWSTR, nSize: DWORD): DWORD {.stdcall,
    dynlib: psapiDll, importc: "GetModuleBaseNameW".}
when defined(winUnicode):
  proc GetModuleBaseName*(hProcess: HANDLE, hModule: HMODULE, lpBaseName: LPWSTR, nSize: DWORD): DWORD {.stdcall,
      dynlib: psapiDll, importc: "GetModuleBaseNameW".}
else:
  proc GetModuleBaseName*(hProcess: HANDLE, hModule: HMODULE, lpBaseName: LPSTR, nSize: DWORD): DWORD {.stdcall,
      dynlib: psapiDll, importc: "GetModuleBaseNameA".}

proc GetModuleFileNameExA*(hProcess: HANDLE, hModule: HMODULE, lpFileNameEx: LPSTR, nSize: DWORD): DWORD {.stdcall,
    dynlib: psapiDll, importc: "GetModuleFileNameExA".}
proc GetModuleFileNameExW*(hProcess: HANDLE, hModule: HMODULE, lpFileNameEx: LPWSTR, nSize: DWORD): DWORD {.stdcall,
    dynlib: psapiDll, importc: "GetModuleFileNameExW".}
when defined(winUnicode):
  proc GetModuleFileNameEx*(hProcess: HANDLE, hModule: HMODULE, lpFileNameEx: LPWSTR, nSize: DWORD): DWORD {.stdcall,
      dynlib: psapiDll, importc: "GetModuleFileNameExW".}
else:
  proc GetModuleFileNameEx*(hProcess: HANDLE, hModule: HMODULE, lpFileNameEx: LPSTR, nSize: DWORD): DWORD {.stdcall,
      dynlib: psapiDll, importc: "GetModuleFileNameExA".}

type
  MODULEINFO* {.final.} = object
    lpBaseOfDll*: LPVOID
    SizeOfImage*: DWORD
    EntryPoint*: LPVOID
  LPMODULEINFO* = ptr MODULEINFO

proc GetModuleInformation*(hProcess: HANDLE, hModule: HMODULE, lpmodinfo: LPMODULEINFO, cb: DWORD): WINBOOL {.stdcall,
    dynlib: psapiDll, importc: "GetModuleInformation".}
proc EmptyWorkingSet*(hProcess: HANDLE): WINBOOL {.stdcall,
    dynlib: psapiDll, importc: "EmptyWorkingSet".}
proc QueryWorkingSet*(hProcess: HANDLE, pv: PVOID, cb: DWORD): WINBOOL {.stdcall,
    dynlib: psapiDll, importc: "QueryWorkingSet".}
proc QueryWorkingSetEx*(hProcess: HANDLE, pv: PVOID, cb: DWORD): WINBOOL {.stdcall,
    dynlib: psapiDll, importc: "QueryWorkingSetEx".}
proc InitializeProcessForWsWatch*(hProcess: HANDLE): WINBOOL {.stdcall,
    dynlib: psapiDll, importc: "InitializeProcessForWsWatch".}

type
  PSAPI_WS_WATCH_INFORMATION* {.final.} = object
    FaultingPc*: LPVOID
    FaultingVa*: LPVOID
  PPSAPI_WS_WATCH_INFORMATION* = ptr PSAPI_WS_WATCH_INFORMATION

proc GetWsChanges*(hProcess: HANDLE, lpWatchInfo: PPSAPI_WS_WATCH_INFORMATION, cb: DWORD): WINBOOL {.stdcall,
    dynlib: psapiDll, importc: "GetWsChanges".}

proc GetMappedFileNameA*(hProcess: HANDLE, lpv: LPVOID, lpFilename: LPSTR, nSize: DWORD): DWORD {.stdcall,
    dynlib: psapiDll, importc: "GetMappedFileNameA".}
proc GetMappedFileNameW*(hProcess: HANDLE, lpv: LPVOID, lpFilename: LPWSTR, nSize: DWORD): DWORD {.stdcall,
    dynlib: psapiDll, importc: "GetMappedFileNameW".}
when defined(winUnicode):
  proc GetMappedFileName*(hProcess: HANDLE, lpv: LPVOID, lpFilename: LPWSTR, nSize: DWORD): DWORD {.stdcall,
      dynlib: psapiDll, importc: "GetMappedFileNameW".}
else:
  proc GetMappedFileName*(hProcess: HANDLE, lpv: LPVOID, lpFilename: LPSTR, nSize: DWORD): DWORD {.stdcall,
      dynlib: psapiDll, importc: "GetMappedFileNameA".}

proc EnumDeviceDrivers*(lpImageBase: LPVOID, cb: DWORD, lpcbNeeded: LPDWORD): WINBOOL {.stdcall,
    dynlib: psapiDll, importc: "EnumDeviceDrivers".}

proc GetDeviceDriverBaseNameA*(ImageBase: LPVOID, lpBaseName: LPSTR, nSize: DWORD): DWORD {.stdcall,
    dynlib: psapiDll, importc: "GetDeviceDriverBaseNameA".}
proc GetDeviceDriverBaseNameW*(ImageBase: LPVOID, lpBaseName: LPWSTR, nSize: DWORD): DWORD {.stdcall,
    dynlib: psapiDll, importc: "GetDeviceDriverBaseNameW".}
when defined(winUnicode):
  proc GetDeviceDriverBaseName*(ImageBase: LPVOID, lpBaseName: LPWSTR, nSize: DWORD): DWORD {.stdcall,
      dynlib: psapiDll, importc: "GetDeviceDriverBaseNameW".}
else:
  proc GetDeviceDriverBaseName*(ImageBase: LPVOID, lpBaseName: LPSTR, nSize: DWORD): DWORD {.stdcall,
      dynlib: psapiDll, importc: "GetDeviceDriverBaseNameA".}

proc GetDeviceDriverFileNameA*(ImageBase: LPVOID, lpFileName: LPSTR, nSize: DWORD): DWORD {.stdcall,
    dynlib: psapiDll, importc: "GetDeviceDriverFileNameA".}
proc GetDeviceDriverFileNameW*(ImageBase: LPVOID, lpFileName: LPWSTR, nSize: DWORD): DWORD {.stdcall,
    dynlib: psapiDll, importc: "GetDeviceDriverFileNameW".}
when defined(winUnicode):
  proc GetDeviceDriverFileName*(ImageBase: LPVOID, lpFileName: LPWSTR, nSize: DWORD): DWORD {.stdcall,
      dynlib: psapiDll, importc: "GetDeviceDriverFileNameW".}
else:
  proc GetDeviceDriverFileName*(ImageBase: LPVOID, lpFileName: LPSTR, nSize: DWORD): DWORD {.stdcall,
      dynlib: psapiDll, importc: "GetDeviceDriverFileNameA".}

type
  PROCESS_MEMORY_COUNTERS* {.final.} = object
    cb*: DWORD
    PageFaultCount*: DWORD
    PeakWorkingSetSize: SIZE_T
    WorkingSetSize: SIZE_T
    QuotaPeakPagedPoolUsage: SIZE_T
    QuotaPagedPoolUsage: SIZE_T
    QuotaPeakNonPagedPoolUsage: SIZE_T
    QuotaNonPagedPoolUsage: SIZE_T
    PagefileUsage: SIZE_T
    PeakPagefileUsage: SIZE_T
  PPROCESS_MEMORY_COUNTERS* = ptr PROCESS_MEMORY_COUNTERS

type
  PROCESS_MEMORY_COUNTERS_EX* {.final.} = object
    cb*: DWORD
    PageFaultCount*: DWORD
    PeakWorkingSetSize: SIZE_T
    WorkingSetSize: SIZE_T
    QuotaPeakPagedPoolUsage: SIZE_T
    QuotaPagedPoolUsage: SIZE_T
    QuotaPeakNonPagedPoolUsage: SIZE_T
    QuotaNonPagedPoolUsage: SIZE_T
    PagefileUsage: SIZE_T
    PeakPagefileUsage: SIZE_T
    PrivateUsage: SIZE_T
  PPROCESS_MEMORY_COUNTERS_EX* = ptr PROCESS_MEMORY_COUNTERS_EX

proc GetProcessMemoryInfo*(hProcess: HANDLE, ppsmemCounters: PPROCESS_MEMORY_COUNTERS, cb: DWORD): WINBOOL {.stdcall,
    dynlib: psapiDll, importc: "GetProcessMemoryInfo".}

type
  PERFORMANCE_INFORMATION* {.final.} = object
    cb*: DWORD
    CommitTotal: SIZE_T
    CommitLimit: SIZE_T
    CommitPeak: SIZE_T
    PhysicalTotal: SIZE_T
    PhysicalAvailable: SIZE_T
    SystemCache: SIZE_T
    KernelTotal: SIZE_T
    KernelPaged: SIZE_T
    KernelNonpaged: SIZE_T
    PageSize: SIZE_T
    HandleCount*: DWORD
    ProcessCount*: DWORD
    ThreadCount*: DWORD
  PPERFORMANCE_INFORMATION* = ptr PERFORMANCE_INFORMATION
  # Skip definition of PERFORMACE_INFORMATION...

proc GetPerformanceInfo*(pPerformanceInformation: PPERFORMANCE_INFORMATION, cb: DWORD): WINBOOL {.stdcall,
    dynlib: psapiDll, importc: "GetPerformanceInfo".}

type
  ENUM_PAGE_FILE_INFORMATION* {.final.} = object
    cb*: DWORD
    Reserved*: DWORD
    TotalSize: SIZE_T
    TotalInUse: SIZE_T
    PeakUsage: SIZE_T
  PENUM_PAGE_FILE_INFORMATION* = ptr ENUM_PAGE_FILE_INFORMATION

# Callback procedure
type
  PENUM_PAGE_FILE_CALLBACKW* = proc (pContext: LPVOID, pPageFileInfo: PENUM_PAGE_FILE_INFORMATION, lpFilename: LPCWSTR): WINBOOL{.stdcall.}
  PENUM_PAGE_FILE_CALLBACKA* = proc (pContext: LPVOID, pPageFileInfo: PENUM_PAGE_FILE_INFORMATION, lpFilename: LPCSTR): WINBOOL{.stdcall.}

#TODO
proc EnumPageFilesA*(pCallBackRoutine: PENUM_PAGE_FILE_CALLBACKA, pContext: LPVOID): WINBOOL {.stdcall,
    dynlib: psapiDll, importc: "EnumPageFilesA".}
proc EnumPageFilesW*(pCallBackRoutine: PENUM_PAGE_FILE_CALLBACKW, pContext: LPVOID): WINBOOL {.stdcall,
    dynlib: psapiDll, importc: "EnumPageFilesW".}
when defined(winUnicode):
  proc EnumPageFiles*(pCallBackRoutine: PENUM_PAGE_FILE_CALLBACKW, pContext: LPVOID): WINBOOL {.stdcall,
      dynlib: psapiDll, importc: "EnumPageFilesW".}
  type PENUM_PAGE_FILE_CALLBACK* = proc (pContext: LPVOID, pPageFileInfo: PENUM_PAGE_FILE_INFORMATION, lpFilename: LPCWSTR): WINBOOL{.stdcall.}
else:
  proc EnumPageFiles*(pCallBackRoutine: PENUM_PAGE_FILE_CALLBACKA, pContext: LPVOID): WINBOOL {.stdcall,
      dynlib: psapiDll, importc: "EnumPageFilesA".}
  type PENUM_PAGE_FILE_CALLBACK* = proc (pContext: LPVOID, pPageFileInfo: PENUM_PAGE_FILE_INFORMATION, lpFilename: LPCSTR): WINBOOL{.stdcall.}

proc GetProcessImageFileNameA*(hProcess: HANDLE, lpImageFileName: LPSTR, nSize: DWORD): DWORD {.stdcall,
    dynlib: psapiDll, importc: "GetProcessImageFileNameA".}
proc GetProcessImageFileNameW*(hProcess: HANDLE, lpImageFileName: LPWSTR, nSize: DWORD): DWORD {.stdcall,
    dynlib: psapiDll, importc: "GetProcessImageFileNameW".}
when defined(winUnicode):
  proc GetProcessImageFileName*(hProcess: HANDLE, lpImageFileName: LPWSTR, nSize: DWORD): DWORD {.stdcall,
      dynlib: psapiDll, importc: "GetProcessImageFileNameW".}
else:
  proc GetProcessImageFileName*(hProcess: HANDLE, lpImageFileName: LPSTR, nSize: DWORD): DWORD {.stdcall,
      dynlib: psapiDll, importc: "GetProcessImageFileNameA".}
