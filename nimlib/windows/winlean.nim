#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a small wrapper for some needed Win API procedures,
## so that the Nimrod compiler does not depend on the huge Windows module.

type
  THandle* = int
  WINBOOL* = int32

  TSECURITY_ATTRIBUTES* {.final, pure.} = object
    nLength*: int32
    lpSecurityDescriptor*: pointer
    bInheritHandle*: WINBOOL
  
  TSTARTUPINFO* {.final, pure.} = object
    cb*: int32
    lpReserved*: cstring
    lpDesktop*: cstring
    lpTitle*: cstring
    dwX*: int32
    dwY*: int32
    dwXSize*: int32
    dwYSize*: int32
    dwXCountChars*: int32
    dwYCountChars*: int32
    dwFillAttribute*: int32
    dwFlags*: int32
    wShowWindow*: int16
    cbReserved2*: int16
    lpReserved2*: pointer
    hStdInput*: THANDLE
    hStdOutput*: THANDLE
    hStdError*: THANDLE

  TPROCESS_INFORMATION* {.final, pure.} = object
    hProcess*: THANDLE
    hThread*: THANDLE
    dwProcessId*: int32
    dwThreadId*: int32

const
  STARTF_USESHOWWINDOW* = 1'i32
  STARTF_USESTDHANDLES* = 256'i32
  HIGH_PRIORITY_CLASS* = 128'i32
  IDLE_PRIORITY_CLASS* = 64'i32
  NORMAL_PRIORITY_CLASS* = 32'i32
  REALTIME_PRIORITY_CLASS* = 256'i32
  WAIT_TIMEOUT* = 0x00000102'i32
  INFINITE* = -1'i32

  STD_INPUT_HANDLE* = -10'i32
  STD_OUTPUT_HANDLE* = -11'i32
  STD_ERROR_HANDLE* = -12'i32

  DETACHED_PROCESS* = 8'i32

proc CloseHandle*(hObject: THANDLE): WINBOOL {.stdcall, dynlib: "kernel32",
    importc: "CloseHandle".}
    
proc ReadFile*(hFile: THandle, Buffer: pointer, nNumberOfBytesToRead: int32,
               lpNumberOfBytesRead: var int32, lpOverlapped: pointer): WINBOOL{.
    stdcall, dynlib: "kernel32", importc: "ReadFile".}
    
proc WriteFile*(hFile: THandle, Buffer: pointer, nNumberOfBytesToWrite: int32,
                lpNumberOfBytesWritten: var int32, 
                lpOverlapped: pointer): WINBOOL{.
    stdcall, dynlib: "kernel32", importc: "WriteFile".}

proc CreatePipe*(hReadPipe, hWritePipe: var THandle,
                 lpPipeAttributes: var TSECURITY_ATTRIBUTES, 
                 nSize: int32): WINBOOL{.
    stdcall, dynlib: "kernel32", importc: "CreatePipe".}
    
proc CreateProcess*(lpApplicationName, lpCommandLine: cstring,
                    lpProcessAttributes: ptr TSECURITY_ATTRIBUTES,
                    lpThreadAttributes: ptr TSECURITY_ATTRIBUTES,
                    bInheritHandles: WINBOOL, dwCreationFlags: int32,
                    lpEnvironment: pointer, lpCurrentDirectory: cstring,
                    lpStartupInfo: var TSTARTUPINFO,
                    lpProcessInformation: var TPROCESS_INFORMATION): WINBOOL{.
    stdcall, dynlib: "kernel32", importc: "CreateProcessA".}

proc SuspendThread*(hThread: THANDLE): int32 {.stdcall, dynlib: "kernel32",
    importc: "SuspendThread".}
proc ResumeThread*(hThread: THANDLE): int32 {.stdcall, dynlib: "kernel32",
    importc: "ResumeThread".}

proc WaitForSingleObject*(hHandle: THANDLE, dwMilliseconds: int32): int32 {.
    stdcall, dynlib: "kernel32", importc: "WaitForSingleObject".}

proc TerminateProcess*(hProcess: THANDLE, uExitCode: int): WINBOOL {.stdcall,
    dynlib: "kernel32", importc: "TerminateProcess".}

proc GetExitCodeProcess*(hProcess: THANDLE, lpExitCode: var int32): WINBOOL {.
    stdcall, dynlib: "kernel32", importc: "GetExitCodeProcess".}

proc GetStdHandle*(nStdHandle: int32): THANDLE {.stdcall, dynlib: "kernel32",
    importc: "GetStdHandle".}
proc SetStdHandle*(nStdHandle: int32, hHandle: THANDLE): WINBOOL {.stdcall,
    dynlib: "kernel32", importc: "SetStdHandle".}
proc FlushFileBuffers*(hFile: THANDLE): WINBOOL {.stdcall, dynlib: "kernel32",
    importc: "FlushFileBuffers".}

proc GetLastError*(): int32 {.importc, stdcall, dynlib: "kernel32".}
proc FormatMessageA*(dwFlags: int32, lpSource: pointer,
                    dwMessageId, dwLanguageId: int32,
                    lpBuffer: pointer, nSize: int32,
                    Arguments: pointer): int32 {.
                    importc, stdcall, dynlib: "kernel32".}
proc LocalFree*(p: pointer) {.importc, stdcall, dynlib: "kernel32".}

proc GetCurrentDirectoryA*(nBufferLength: int32, lpBuffer: cstring): int32 {.
  importc, dynlib: "kernel32", stdcall.}
proc SetCurrentDirectoryA*(lpPathName: cstring): int32 {.
  importc, dynlib: "kernel32", stdcall.}
proc CreateDirectoryA*(pathName: cstring, security: Pointer): int32 {.
  importc: "CreateDirectoryA", dynlib: "kernel32", stdcall.}
proc RemoveDirectoryA*(lpPathName: cstring): int32 {.
  importc, dynlib: "kernel32", stdcall.}
proc SetEnvironmentVariableA*(lpName, lpValue: cstring): int32 {.
  stdcall, dynlib: "kernel32", importc.}

proc GetModuleFileNameA*(handle: THandle, buf: CString, size: int32): int32 {.
  importc, dynlib: "kernel32", stdcall.}

const
  FILE_ATTRIBUTE_ARCHIVE* = 32'i32
  FILE_ATTRIBUTE_COMPRESSED* = 2048'i32
  FILE_ATTRIBUTE_NORMAL* = 128'i32
  FILE_ATTRIBUTE_DIRECTORY* = 16'i32
  FILE_ATTRIBUTE_HIDDEN* = 2'i32
  FILE_ATTRIBUTE_READONLY* = 1'i32
  FILE_ATTRIBUTE_SYSTEM* = 4'i32

  MAX_PATH* = 260
type
  FILETIME* {.final, pure.} = object ## CANNOT BE int64 BECAUSE OF ALIGNMENT
    dwLowDateTime*: int32
    dwHighDateTime*: int32
  TWIN32_FIND_DATA* {.pure.} = object
    dwFileAttributes*: int32
    ftCreationTime*: FILETIME
    ftLastAccessTime*: FILETIME
    ftLastWriteTime*: FILETIME
    nFileSizeHigh*: int32
    nFileSizeLow*: int32
    dwReserved0: int32
    dwReserved1: int32
    cFileName*: array[0..(MAX_PATH) - 1, char]
    cAlternateFileName*: array[0..13, char]
proc FindFirstFileA*(lpFileName: cstring,
                    lpFindFileData: var TWIN32_FIND_DATA): THANDLE {.
    stdcall, dynlib: "kernel32", importc: "FindFirstFileA".}
proc FindNextFileA*(hFindFile: THANDLE,
                   lpFindFileData: var TWIN32_FIND_DATA): int32 {.
    stdcall, dynlib: "kernel32", importc: "FindNextFileA".}
proc FindClose*(hFindFile: THANDLE) {.stdcall, dynlib: "kernel32",
  importc: "FindClose".}

proc GetFullPathNameA*(lpFileName: cstring, nBufferLength: int32,
                      lpBuffer: cstring, lpFilePart: var cstring): int32 {.
                      stdcall, dynlib: "kernel32", importc.}
proc GetFileAttributesA*(lpFileName: cstring): int32 {.
                        stdcall, dynlib: "kernel32", importc.}
proc SetFileAttributesA*(lpFileName: cstring, dwFileAttributes: int32): WINBOOL {.
    stdcall, dynlib: "kernel32", importc: "SetFileAttributesA".}

proc CopyFileA*(lpExistingFileName, lpNewFileName: CString,
               bFailIfExists: cint): cint {.
  importc, stdcall, dynlib: "kernel32".}

proc GetEnvironmentStringsA*(): cstring {.
  stdcall, dynlib: "kernel32", importc.}
proc FreeEnvironmentStringsA*(para1: cstring): int32 {.
  stdcall, dynlib: "kernel32", importc.}

proc GetCommandLineA*(): CString {.importc, stdcall, dynlib: "kernel32".}

proc rdFileTime*(f: FILETIME): int64 = 
  result = ze64(f.dwLowDateTime) or (ze64(f.dwHighDateTime) shl 32)

proc Sleep*(dwMilliseconds: int32){.stdcall, dynlib: "kernel32",
                                    importc: "Sleep".}


