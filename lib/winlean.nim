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

