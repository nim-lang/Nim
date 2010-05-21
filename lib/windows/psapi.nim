#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
#       PSAPI interface unit

# Contains the definitions for the APIs provided by PSAPI.DLL

import                        # Data structure templates
  Windows

proc EnumProcesses*(lpidProcess: ptr DWORD, cb: DWORD, cbNeeded: ptr DWORD): WINBOOL {.stdcall,
    dynlib: "psapi.dll", importc: "EnumProcesses".}
proc EnumProcessModules*(hProcess: HANDLE, lphModule: ptr HMODULE, cb: DWORD, lpcbNeeded: LPDWORD): WINBOOL {.stdcall,
    dynlib: "psapi.dll", importc: "EnumProcessModules".}

proc GetModuleBaseNameA*(hProcess: HANDLE, hModule: HMODULE, lpBaseName: LPSTR, nSize: DWORD): DWORD {.stdcall,
    dynlib: "psapi.dll", importc: "GetModuleBaseNameA".}
proc GetModuleBaseNameW*(hProcess: HANDLE, hModule: HMODULE, lpBaseName: LPWSTR, nSize: DWORD): DWORD {.stdcall,
    dynlib: "psapi.dll", importc: "GetModuleBaseNameW".}
when defined(winUnicode):
  proc GetModuleBaseName*(hProcess: HANDLE, hModule: HMODULE, lpBaseName: LPWSTR, nSize: DWORD): DWORD {.stdcall,
      dynlib: "psapi.dll", importc: "GetModuleBaseNameW".}
else:
  proc GetModuleBaseName*(hProcess: HANDLE, hModule: HMODULE, lpBaseName: LPSTR, nSize: DWORD): DWORD {.stdcall,
      dynlib: "psapi.dll", importc: "GetModuleBaseNameA".}

proc GetModuleFileNameExA*(hProcess: HANDLE, hModule: HMODULE, lpFileNameEx: LPSTR, nSize: DWORD): DWORD {.stdcall,
    dynlib: "psapi.dll", importc: "GetModuleFileNameExA".}
proc GetModuleFileNameExW*(hProcess: HANDLE, hModule: HMODULE, lpFileNameEx: LPWSTR, nSize: DWORD): DWORD {.stdcall,
    dynlib: "psapi.dll", importc: "GetModuleFileNameExW".}
when defined(winUnicode):
  proc GetModuleFileNameEx*(hProcess: HANDLE, hModule: HMODULE, lpFileNameEx: LPWSTR, nSize: DWORD): DWORD {.stdcall,
      dynlib: "psapi.dll", importc: "GetModuleFileNameExW".}
else:
  proc GetModuleFileNameEx*(hProcess: HANDLE, hModule: HMODULE, lpFileNameEx: LPSTR, nSize: DWORD): DWORD {.stdcall,
      dynlib: "psapi.dll", importc: "GetModuleFileNameExA".}

type
  MODULEINFO* {.final.} = object
    lpBaseOfDll*: LPVOID
    SizeOfImage*: DWORD
    EntryPoint*: LPVOID
  LPMODULEINFO* = ptr MODULEINFO

proc GetModuleInformation*(hProcess: HANDLE, hModule: HMODULE, lpmodinfo: LPMODULEINFO, cb: DWORD): WINBOOL {.stdcall,
    dynlib: "psapi.dll", importc: "GetModuleInformation".}
proc EmptyWorkingSet*(hProcess: HANDLE): WINBOOL {.stdcall,
    dynlib: "psapi.dll", importc: "EmptyWorkingSet".}
proc QueryWorkingSet*(hProcess: HANDLE, pv: PVOID, cb: DWORD): WINBOOL {.stdcall,
    dynlib: "psapi.dll", importc: "QueryWorkingSet".}
proc QueryWorkingSetEx*(hProcess: HANDLE, pv: PVOID, cb: DWORD): WINBOOL {.stdcall,
    dynlib: "psapi.dll", importc: "QueryWorkingSetEx".}
proc InitializeProcessForWsWatch*(hProcess: HANDLE): WINBOOL {.stdcall,
    dynlib: "psapi.dll", importc: "InitializeProcessForWsWatch".}

type
  PSAPI_WS_WATCH_INFORMATION* {.final.} = object
    FaultingPc*: LPVOID
    FaultingVa*: LPVOID
  PPSAPI_WS_WATCH_INFORMATION* = ptr PSAPI_WS_WATCH_INFORMATION

proc GetWsChanges*(hProcess: HANDLE, lpWatchInfo: PPSAPI_WS_WATCH_INFORMATION, cb: DWORD): WINBOOL {.stdcall,
    dynlib: "psapi.dll", importc: "GetWsChanges".}

proc GetMappedFileNameA*(hProcess: HANDLE, lpv: LPVOID, lpFilename: LPSTR, nSize: DWORD): DWORD {.stdcall,
    dynlib: "psapi.dll", importc: "GetMappedFileNameA".}
proc GetMappedFileNameW*(hProcess: HANDLE, lpv: LPVOID, lpFilename: LPWSTR, nSize: DWORD): DWORD {.stdcall,
    dynlib: "psapi.dll", importc: "GetMappedFileNameW".}
when defined(winUnicode):
  proc GetMappedFileName*(hProcess: HANDLE, lpv: LPVOID, lpFilename: LPWSTR, nSize: DWORD): DWORD {.stdcall,
      dynlib: "psapi.dll", importc: "GetMappedFileNameW".}
else:
  proc GetMappedFileName*(hProcess: HANDLE, lpv: LPVOID, lpFilename: LPSTR, nSize: DWORD): DWORD {.stdcall,
      dynlib: "psapi.dll", importc: "GetMappedFileNameA".}

proc EnumDeviceDrivers*(lpImageBase: LPVOID, cb: DWORD, lpcbNeeded: LPDWORD): WINBOOL {.stdcall,
    dynlib: "psapi.dll", importc: "EnumDeviceDrivers".}

proc GetDeviceDriverBaseNameA*(ImageBase: LPVOID, lpBaseName: LPSTR, nSize: DWORD): DWORD {.stdcall,
    dynlib: "psapi.dll", importc: "GetDeviceDriverBaseNameA".}
proc GetDeviceDriverBaseNameW*(ImageBase: LPVOID, lpBaseName: LPWSTR, nSize: DWORD): DWORD {.stdcall,
    dynlib: "psapi.dll", importc: "GetDeviceDriverBaseNameW".}
when defined(winUnicode):
  proc GetDeviceDriverBaseName*(ImageBase: LPVOID, lpBaseName: LPWSTR, nSize: DWORD): DWORD {.stdcall,
      dynlib: "psapi.dll", importc: "GetDeviceDriverBaseNameW".}
else:
  proc GetDeviceDriverBaseName*(ImageBase: LPVOID, lpBaseName: LPSTR, nSize: DWORD): DWORD {.stdcall,
      dynlib: "psapi.dll", importc: "GetDeviceDriverBaseNameA".}

proc GetDeviceDriverFileNameA*(ImageBase: LPVOID, lpFileName: LPSTR, nSize: DWORD): DWORD {.stdcall,
    dynlib: "psapi.dll", importc: "GetDeviceDriverFileNameA".}
proc GetDeviceDriverFileNameW*(ImageBase: LPVOID, lpFileName: LPWSTR, nSize: DWORD): DWORD {.stdcall,
    dynlib: "psapi.dll", importc: "GetDeviceDriverFileNameW".}
when defined(winUnicode):
  proc GetDeviceDriverFileName*(ImageBase: LPVOID, lpFileName: LPWSTR, nSize: DWORD): DWORD {.stdcall,
      dynlib: "psapi.dll", importc: "GetDeviceDriverFileNameW".}
else:
  proc GetDeviceDriverFileName*(ImageBase: LPVOID, lpFileName: LPSTR, nSize: DWORD): DWORD {.stdcall,
      dynlib: "psapi.dll", importc: "GetDeviceDriverFileNameA".}

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
    dynlib: "psapi.dll", importc: "GetProcessMemoryInfo".}

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
    dynlib: "psapi.dll", importc: "GetPerformanceInfo".}

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
    dynlib: "psapi.dll", importc: "EnumPageFilesA".}
proc EnumPageFilesW*(pCallBackRoutine: PENUM_PAGE_FILE_CALLBACKW, pContext: LPVOID): WINBOOL {.stdcall,
    dynlib: "psapi.dll", importc: "EnumPageFilesW".}
when defined(winUnicode):
  proc EnumPageFiles*(pCallBackRoutine: PENUM_PAGE_FILE_CALLBACKW, pContext: LPVOID): WINBOOL {.stdcall,
      dynlib: "psapi.dll", importc: "EnumPageFilesW".}
  type PENUM_PAGE_FILE_CALLBACK* = proc (pContext: LPVOID, pPageFileInfo: PENUM_PAGE_FILE_INFORMATION, lpFilename: LPCWSTR): WINBOOL{.stdcall.}
else:
  proc EnumPageFiles*(pCallBackRoutine: PENUM_PAGE_FILE_CALLBACKA, pContext: LPVOID): WINBOOL {.stdcall,
      dynlib: "psapi.dll", importc: "EnumPageFilesA".}
  type PENUM_PAGE_FILE_CALLBACK* = proc (pContext: LPVOID, pPageFileInfo: PENUM_PAGE_FILE_INFORMATION, lpFilename: LPCSTR): WINBOOL{.stdcall.}

proc GetProcessImageFileNameA*(hProcess: HANDLE, lpImageFileName: LPSTR, nSize: DWORD): DWORD {.stdcall,
    dynlib: "psapi.dll", importc: "GetProcessImageFileNameA".}
proc GetProcessImageFileNameW*(hProcess: HANDLE, lpImageFileName: LPWSTR, nSize: DWORD): DWORD {.stdcall,
    dynlib: "psapi.dll", importc: "GetProcessImageFileNameW".}
when defined(winUnicode):
  proc GetProcessImageFileName*(hProcess: HANDLE, lpImageFileName: LPWSTR, nSize: DWORD): DWORD {.stdcall,
      dynlib: "psapi.dll", importc: "GetProcessImageFileNameW".}
else:
  proc GetProcessImageFileName*(hProcess: HANDLE, lpImageFileName: LPSTR, nSize: DWORD): DWORD {.stdcall,
      dynlib: "psapi.dll", importc: "GetProcessImageFileNameA".}
