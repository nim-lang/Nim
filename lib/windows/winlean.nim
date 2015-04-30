#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a small wrapper for some needed Win API procedures,
## so that the Nim compiler does not depend on the huge Windows module.

const
  useWinUnicode* = not defined(useWinAnsi)

type
  THandle* = int
  LONG* = int32
  ULONG* = int
  PULONG* = ptr int
  WINBOOL* = int32
  DWORD* = int32
  PDWORD* = ptr DWORD
  LPINT* = ptr int32
  HDC* = THandle
  HGLRC* = THandle

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
    hStdInput*: THandle
    hStdOutput*: THandle
    hStdError*: THandle

  TPROCESS_INFORMATION* {.final, pure.} = object
    hProcess*: THandle
    hThread*: THandle
    dwProcessId*: int32
    dwThreadId*: int32

  TFILETIME* {.final, pure.} = object ## CANNOT BE int64 BECAUSE OF ALIGNMENT
    dwLowDateTime*: DWORD
    dwHighDateTime*: DWORD
  
  TBY_HANDLE_FILE_INFORMATION* {.final, pure.} = object
    dwFileAttributes*: DWORD
    ftCreationTime*: TFILETIME
    ftLastAccessTime*: TFILETIME
    ftLastWriteTime*: TFILETIME
    dwVolumeSerialNumber*: DWORD
    nFileSizeHigh*: DWORD
    nFileSizeLow*: DWORD
    nNumberOfLinks*: DWORD
    nFileIndexHigh*: DWORD
    nFileIndexLow*: DWORD

when useWinUnicode:
  type TWinChar* = TUtf16Char
else:
  type TWinChar* = char

const
  STARTF_USESHOWWINDOW* = 1'i32
  STARTF_USESTDHANDLES* = 256'i32
  HIGH_PRIORITY_CLASS* = 128'i32
  IDLE_PRIORITY_CLASS* = 64'i32
  NORMAL_PRIORITY_CLASS* = 32'i32
  REALTIME_PRIORITY_CLASS* = 256'i32
  WAIT_OBJECT_0* = 0'i32
  WAIT_TIMEOUT* = 0x00000102'i32
  WAIT_FAILED* = 0xFFFFFFFF'i32
  INFINITE* = -1'i32

  STD_INPUT_HANDLE* = -10'i32
  STD_OUTPUT_HANDLE* = -11'i32
  STD_ERROR_HANDLE* = -12'i32

  DETACHED_PROCESS* = 8'i32
  
  SW_SHOWNORMAL* = 1'i32
  INVALID_HANDLE_VALUE* = THandle(-1)
  
  CREATE_UNICODE_ENVIRONMENT* = 1024'i32

proc closeHandle*(hObject: THandle): WINBOOL {.stdcall, dynlib: "kernel32",
    importc: "CloseHandle".}
    
proc readFile*(hFile: THandle, Buffer: pointer, nNumberOfBytesToRead: int32,
               lpNumberOfBytesRead: ptr int32, lpOverlapped: pointer): WINBOOL{.
    stdcall, dynlib: "kernel32", importc: "ReadFile".}
    
proc writeFile*(hFile: THandle, Buffer: pointer, nNumberOfBytesToWrite: int32,
                lpNumberOfBytesWritten: ptr int32, 
                lpOverlapped: pointer): WINBOOL{.
    stdcall, dynlib: "kernel32", importc: "WriteFile".}

proc createPipe*(hReadPipe, hWritePipe: var THandle,
                 lpPipeAttributes: var TSECURITY_ATTRIBUTES, 
                 nSize: int32): WINBOOL{.
    stdcall, dynlib: "kernel32", importc: "CreatePipe".}

when useWinUnicode:
  proc createProcessW*(lpApplicationName, lpCommandLine: WideCString,
                     lpProcessAttributes: ptr TSECURITY_ATTRIBUTES,
                     lpThreadAttributes: ptr TSECURITY_ATTRIBUTES,
                     bInheritHandles: WINBOOL, dwCreationFlags: int32,
                     lpEnvironment, lpCurrentDirectory: WideCString,
                     lpStartupInfo: var TSTARTUPINFO,
                     lpProcessInformation: var TPROCESS_INFORMATION): WINBOOL{.
    stdcall, dynlib: "kernel32", importc: "CreateProcessW".}

else:
  proc createProcessA*(lpApplicationName, lpCommandLine: cstring,
                       lpProcessAttributes: ptr TSECURITY_ATTRIBUTES,
                       lpThreadAttributes: ptr TSECURITY_ATTRIBUTES,
                       bInheritHandles: WINBOOL, dwCreationFlags: int32,
                       lpEnvironment: pointer, lpCurrentDirectory: cstring,
                       lpStartupInfo: var TSTARTUPINFO,
                       lpProcessInformation: var TPROCESS_INFORMATION): WINBOOL{.
      stdcall, dynlib: "kernel32", importc: "CreateProcessA".}


proc suspendThread*(hThread: THandle): int32 {.stdcall, dynlib: "kernel32",
    importc: "SuspendThread".}
proc resumeThread*(hThread: THandle): int32 {.stdcall, dynlib: "kernel32",
    importc: "ResumeThread".}

proc waitForSingleObject*(hHandle: THandle, dwMilliseconds: int32): int32 {.
    stdcall, dynlib: "kernel32", importc: "WaitForSingleObject".}

proc terminateProcess*(hProcess: THandle, uExitCode: int): WINBOOL {.stdcall,
    dynlib: "kernel32", importc: "TerminateProcess".}

proc getExitCodeProcess*(hProcess: THandle, lpExitCode: var int32): WINBOOL {.
    stdcall, dynlib: "kernel32", importc: "GetExitCodeProcess".}

proc getStdHandle*(nStdHandle: int32): THandle {.stdcall, dynlib: "kernel32",
    importc: "GetStdHandle".}
proc setStdHandle*(nStdHandle: int32, hHandle: THandle): WINBOOL {.stdcall,
    dynlib: "kernel32", importc: "SetStdHandle".}
proc flushFileBuffers*(hFile: THandle): WINBOOL {.stdcall, dynlib: "kernel32",
    importc: "FlushFileBuffers".}

proc getLastError*(): int32 {.importc: "GetLastError", 
    stdcall, dynlib: "kernel32".}

when useWinUnicode:
  proc formatMessageW*(dwFlags: int32, lpSource: pointer,
                      dwMessageId, dwLanguageId: int32,
                      lpBuffer: pointer, nSize: int32,
                      Arguments: pointer): int32 {.
                      importc: "FormatMessageW", stdcall, dynlib: "kernel32".}
else:
  proc formatMessageA*(dwFlags: int32, lpSource: pointer,
                    dwMessageId, dwLanguageId: int32,
                    lpBuffer: pointer, nSize: int32,
                    Arguments: pointer): int32 {.
                    importc: "FormatMessageA", stdcall, dynlib: "kernel32".}

proc localFree*(p: pointer) {.
  importc: "LocalFree", stdcall, dynlib: "kernel32".}

when useWinUnicode:
  proc getCurrentDirectoryW*(nBufferLength: int32, 
                             lpBuffer: WideCString): int32 {.
    importc: "GetCurrentDirectoryW", dynlib: "kernel32", stdcall.}
  proc setCurrentDirectoryW*(lpPathName: WideCString): int32 {.
    importc: "SetCurrentDirectoryW", dynlib: "kernel32", stdcall.}
  proc createDirectoryW*(pathName: WideCString, security: pointer=nil): int32 {.
    importc: "CreateDirectoryW", dynlib: "kernel32", stdcall.}
  proc removeDirectoryW*(lpPathName: WideCString): int32 {.
    importc: "RemoveDirectoryW", dynlib: "kernel32", stdcall.}
  proc setEnvironmentVariableW*(lpName, lpValue: WideCString): int32 {.
    stdcall, dynlib: "kernel32", importc: "SetEnvironmentVariableW".}

  proc getModuleFileNameW*(handle: THandle, buf: WideCString, 
                           size: int32): int32 {.importc: "GetModuleFileNameW", 
    dynlib: "kernel32", stdcall.}
else:
  proc getCurrentDirectoryA*(nBufferLength: int32, lpBuffer: cstring): int32 {.
    importc: "GetCurrentDirectoryA", dynlib: "kernel32", stdcall.}
  proc setCurrentDirectoryA*(lpPathName: cstring): int32 {.
    importc: "SetCurrentDirectoryA", dynlib: "kernel32", stdcall.}
  proc createDirectoryA*(pathName: cstring, security: pointer=nil): int32 {.
    importc: "CreateDirectoryA", dynlib: "kernel32", stdcall.}
  proc removeDirectoryA*(lpPathName: cstring): int32 {.
    importc: "RemoveDirectoryA", dynlib: "kernel32", stdcall.}
  proc setEnvironmentVariableA*(lpName, lpValue: cstring): int32 {.
    stdcall, dynlib: "kernel32", importc: "SetEnvironmentVariableA".}

  proc getModuleFileNameA*(handle: THandle, buf: cstring, size: int32): int32 {.
    importc: "GetModuleFileNameA", dynlib: "kernel32", stdcall.}

when useWinUnicode:
  proc createSymbolicLinkW*(lpSymlinkFileName, lpTargetFileName: WideCString,
                         flags: DWORD): int32 {.
    importc:"CreateSymbolicLinkW", dynlib: "kernel32", stdcall.}
  proc createHardLinkW*(lpFileName, lpExistingFileName: WideCString,
                         security: pointer=nil): int32 {.
    importc:"CreateHardLinkW", dynlib: "kernel32", stdcall.}
else:
  proc createSymbolicLinkA*(lpSymlinkFileName, lpTargetFileName: cstring,
                           flags: DWORD): int32 {.
    importc:"CreateSymbolicLinkA", dynlib: "kernel32", stdcall.}
  proc createHardLinkA*(lpFileName, lpExistingFileName: cstring,
                           security: pointer=nil): int32 {.
    importc:"CreateHardLinkA", dynlib: "kernel32", stdcall.}

const
  FILE_ATTRIBUTE_ARCHIVE* = 32'i32
  FILE_ATTRIBUTE_COMPRESSED* = 2048'i32
  FILE_ATTRIBUTE_NORMAL* = 128'i32
  FILE_ATTRIBUTE_DIRECTORY* = 16'i32
  FILE_ATTRIBUTE_HIDDEN* = 2'i32
  FILE_ATTRIBUTE_READONLY* = 1'i32
  FILE_ATTRIBUTE_REPARSE_POINT* = 1024'i32
  FILE_ATTRIBUTE_SYSTEM* = 4'i32
  FILE_ATTRIBUTE_TEMPORARY* = 256'i32

  MAX_PATH* = 260
type
  TWIN32_FIND_DATA* {.pure.} = object
    dwFileAttributes*: int32
    ftCreationTime*: TFILETIME
    ftLastAccessTime*: TFILETIME
    ftLastWriteTime*: TFILETIME
    nFileSizeHigh*: int32
    nFileSizeLow*: int32
    dwReserved0: int32
    dwReserved1: int32
    cFileName*: array[0..(MAX_PATH) - 1, TWinChar]
    cAlternateFileName*: array[0..13, TWinChar]

when useWinUnicode:
  proc findFirstFileW*(lpFileName: WideCString,
                      lpFindFileData: var TWIN32_FIND_DATA): THandle {.
      stdcall, dynlib: "kernel32", importc: "FindFirstFileW".}
  proc findNextFileW*(hFindFile: THandle,
                     lpFindFileData: var TWIN32_FIND_DATA): int32 {.
      stdcall, dynlib: "kernel32", importc: "FindNextFileW".}
else:
  proc findFirstFileA*(lpFileName: cstring,
                      lpFindFileData: var TWIN32_FIND_DATA): THANDLE {.
      stdcall, dynlib: "kernel32", importc: "FindFirstFileA".}
  proc findNextFileA*(hFindFile: THANDLE,
                     lpFindFileData: var TWIN32_FIND_DATA): int32 {.
      stdcall, dynlib: "kernel32", importc: "FindNextFileA".}

proc findClose*(hFindFile: THandle) {.stdcall, dynlib: "kernel32",
  importc: "FindClose".}

when useWinUnicode:
  proc getFullPathNameW*(lpFileName: WideCString, nBufferLength: int32,
                        lpBuffer: WideCString, 
                        lpFilePart: var WideCString): int32 {.
                        stdcall, dynlib: "kernel32", 
                        importc: "GetFullPathNameW".}
  proc getFileAttributesW*(lpFileName: WideCString): int32 {.
                          stdcall, dynlib: "kernel32", 
                          importc: "GetFileAttributesW".}
  proc setFileAttributesW*(lpFileName: WideCString, 
                           dwFileAttributes: int32): WINBOOL {.
      stdcall, dynlib: "kernel32", importc: "SetFileAttributesW".}

  proc copyFileW*(lpExistingFileName, lpNewFileName: WideCString,
                 bFailIfExists: cint): cint {.
    importc: "CopyFileW", stdcall, dynlib: "kernel32".}

  proc moveFileW*(lpExistingFileName, lpNewFileName: WideCString,
                 bFailIfExists: cint): cint {.
    importc: "MoveFileW", stdcall, dynlib: "kernel32".}

  proc getEnvironmentStringsW*(): WideCString {.
    stdcall, dynlib: "kernel32", importc: "GetEnvironmentStringsW".}
  proc freeEnvironmentStringsW*(para1: WideCString): int32 {.
    stdcall, dynlib: "kernel32", importc: "FreeEnvironmentStringsW".}

  proc getCommandLineW*(): WideCString {.importc: "GetCommandLineW",
    stdcall, dynlib: "kernel32".}

else:
  proc getFullPathNameA*(lpFileName: cstring, nBufferLength: int32,
                        lpBuffer: cstring, lpFilePart: var cstring): int32 {.
                        stdcall, dynlib: "kernel32", 
                        importc: "GetFullPathNameA".}
  proc getFileAttributesA*(lpFileName: cstring): int32 {.
                          stdcall, dynlib: "kernel32", 
                          importc: "GetFileAttributesA".}
  proc setFileAttributesA*(lpFileName: cstring, 
                           dwFileAttributes: int32): WINBOOL {.
      stdcall, dynlib: "kernel32", importc: "SetFileAttributesA".}

  proc copyFileA*(lpExistingFileName, lpNewFileName: cstring,
                 bFailIfExists: cint): cint {.
    importc: "CopyFileA", stdcall, dynlib: "kernel32".}

  proc moveFileA*(lpExistingFileName, lpNewFileName: cstring,
                 bFailIfExists: cint): cint {.
    importc: "MoveFileA", stdcall, dynlib: "kernel32".}

  proc getEnvironmentStringsA*(): cstring {.
    stdcall, dynlib: "kernel32", importc: "GetEnvironmentStringsA".}
  proc freeEnvironmentStringsA*(para1: cstring): int32 {.
    stdcall, dynlib: "kernel32", importc: "FreeEnvironmentStringsA".}

  proc getCommandLineA*(): cstring {.
    importc: "GetCommandLineA", stdcall, dynlib: "kernel32".}

proc rdFileTime*(f: TFILETIME): int64 = 
  result = ze64(f.dwLowDateTime) or (ze64(f.dwHighDateTime) shl 32)

proc rdFileSize*(f: TWIN32_FIND_DATA): int64 = 
  result = ze64(f.nFileSizeLow) or (ze64(f.nFileSizeHigh) shl 32)

proc getSystemTimeAsFileTime*(lpSystemTimeAsFileTime: var TFILETIME) {.
  importc: "GetSystemTimeAsFileTime", dynlib: "kernel32", stdcall.}

proc sleep*(dwMilliseconds: int32){.stdcall, dynlib: "kernel32",
                                    importc: "Sleep".}

when useWinUnicode:
  proc shellExecuteW*(HWND: THandle, lpOperation, lpFile,
                     lpParameters, lpDirectory: WideCString,
                     nShowCmd: int32): THandle{.
      stdcall, dynlib: "shell32.dll", importc: "ShellExecuteW".}

else:
  proc shellExecuteA*(HWND: THandle, lpOperation, lpFile,
                     lpParameters, lpDirectory: cstring,
                     nShowCmd: int32): THandle{.
      stdcall, dynlib: "shell32.dll", importc: "ShellExecuteA".}
  
proc getFileInformationByHandle*(hFile: THandle,
  lpFileInformation: ptr TBY_HANDLE_FILE_INFORMATION): WINBOOL{.
    stdcall, dynlib: "kernel32", importc: "GetFileInformationByHandle".}

const
  WSADESCRIPTION_LEN* = 256
  WSASYS_STATUS_LEN* = 128
  FD_SETSIZE* = 64
  MSG_PEEK* = 2
 
  INADDR_ANY* = 0
  INADDR_LOOPBACK* = 0x7F000001
  INADDR_BROADCAST* = -1
  INADDR_NONE* = -1
  
  ws2dll = "Ws2_32.dll"

  WSAEWOULDBLOCK* = 10035
  WSAEINPROGRESS* = 10036

proc wsaGetLastError*(): cint {.importc: "WSAGetLastError", dynlib: ws2dll.}

type
  SocketHandle* = distinct int

{.deprecated: [TSocketHandle: SocketHandle].}

type
  WSAData* {.importc: "WSADATA", header: "winsock2.h".} = object 
    wVersion, wHighVersion: int16
    szDescription: array[0..WSADESCRIPTION_LEN, char]
    szSystemStatus: array[0..WSASYS_STATUS_LEN, char]
    iMaxSockets, iMaxUdpDg: int16
    lpVendorInfo: cstring
    
  SockAddr* {.importc: "SOCKADDR", header: "winsock2.h".} = object 
    sa_family*: int16 # unsigned
    sa_data: array[0..13, char]

  InAddr* {.importc: "IN_ADDR", header: "winsock2.h".} = object
    s_addr*: int32  # IP address
  
  Sockaddr_in* {.importc: "SOCKADDR_IN", 
                  header: "winsock2.h".} = object
    sin_family*: int16
    sin_port*: int16 # unsigned
    sin_addr*: InAddr
    sin_zero*: array[0..7, char]

  In6_addr* {.importc: "IN6_ADDR", header: "winsock2.h".} = object 
    bytes*: array[0..15, char]

  Sockaddr_in6* {.importc: "SOCKADDR_IN6", 
                   header: "winsock2.h".} = object
    sin6_family*: int16
    sin6_port*: int16 # unsigned
    sin6_flowinfo*: int32 # unsigned
    sin6_addr*: In6_addr
    sin6_scope_id*: int32 # unsigned

  Sockaddr_in6_old* = object
    sin6_family*: int16
    sin6_port*: int16 # unsigned
    sin6_flowinfo*: int32 # unsigned
    sin6_addr*: In6_addr

  Servent* = object
    s_name*: cstring
    s_aliases*: cstringArray
    when defined(cpu64):
      s_proto*: cstring
      s_port*: int16
    else:
      s_port*: int16
      s_proto*: cstring

  Hostent* = object
    h_name*: cstring
    h_aliases*: cstringArray
    h_addrtype*: int16
    h_length*: int16
    h_addr_list*: cstringArray
  
  TFdSet* = object
    fd_count*: cint # unsigned
    fd_array*: array[0..FD_SETSIZE-1, SocketHandle]
    
  Timeval* = object
    tv_sec*, tv_usec*: int32
    
  AddrInfo* = object
    ai_flags*: cint         ## Input flags. 
    ai_family*: cint        ## Address family of socket. 
    ai_socktype*: cint      ## Socket type. 
    ai_protocol*: cint      ## Protocol of socket. 
    ai_addrlen*: int        ## Length of socket address. 
    ai_canonname*: cstring  ## Canonical name of service location.
    ai_addr*: ptr SockAddr ## Socket address of socket. 
    ai_next*: ptr AddrInfo ## Pointer to next in list. 

  SockLen* = cuint

{.deprecated: [TSockaddr_in: Sockaddr_in, TAddrinfo: AddrInfo,
    TSockAddr: SockAddr, TSockLen: SockLen, TTimeval: Timeval,
    TWSADATA: WSADATA, Thostent: Hostent, TServent: Servent,
    TInAddr: InAddr, Tin6_addr: In6_addr, Tsockaddr_in6: Sockaddr_in6,
    Tsockaddr_in6_old: Sockaddr_in6_old].}


var
  SOMAXCONN* {.importc, header: "winsock2.h".}: cint
  INVALID_SOCKET* {.importc, header: "winsock2.h".}: SocketHandle
  SOL_SOCKET* {.importc, header: "winsock2.h".}: cint
  SO_DEBUG* {.importc, header: "winsock2.h".}: cint ## turn on debugging info recording
  SO_ACCEPTCONN* {.importc, header: "winsock2.h".}: cint # socket has had listen()
  SO_REUSEADDR* {.importc, header: "winsock2.h".}: cint # allow local address reuse
  SO_KEEPALIVE* {.importc, header: "winsock2.h".}: cint # keep connections alive
  SO_DONTROUTE* {.importc, header: "winsock2.h".}: cint # just use interface addresses
  SO_BROADCAST* {.importc, header: "winsock2.h".}: cint # permit sending of broadcast msgs
  SO_USELOOPBACK* {.importc, header: "winsock2.h".}: cint # bypass hardware when possible
  SO_LINGER* {.importc, header: "winsock2.h".}: cint # linger on close if data present
  SO_OOBINLINE* {.importc, header: "winsock2.h".}: cint # leave received OOB data in line

  SO_DONTLINGER* {.importc, header: "winsock2.h".}: cint
  SO_EXCLUSIVEADDRUSE* {.importc, header: "winsock2.h".}: cint # disallow local address reuse
  SO_ERROR* {.importc, header: "winsock2.h".}: cint

proc `==`*(x, y: SocketHandle): bool {.borrow.}

proc getservbyname*(name, proto: cstring): ptr Servent {.
  stdcall, importc: "getservbyname", dynlib: ws2dll.}

proc getservbyport*(port: cint, proto: cstring): ptr Servent {.
  stdcall, importc: "getservbyport", dynlib: ws2dll.}

proc gethostbyaddr*(ip: ptr InAddr, len: cuint, theType: cint): ptr Hostent {.
  stdcall, importc: "gethostbyaddr", dynlib: ws2dll.}

proc gethostbyname*(name: cstring): ptr Hostent {.
  stdcall, importc: "gethostbyname", dynlib: ws2dll.}

proc socket*(af, typ, protocol: cint): SocketHandle {.
  stdcall, importc: "socket", dynlib: ws2dll.}

proc closesocket*(s: SocketHandle): cint {.
  stdcall, importc: "closesocket", dynlib: ws2dll.}

proc accept*(s: SocketHandle, a: ptr SockAddr, addrlen: ptr SockLen): SocketHandle {.
  stdcall, importc: "accept", dynlib: ws2dll.}
proc bindSocket*(s: SocketHandle, name: ptr SockAddr, namelen: SockLen): cint {.
  stdcall, importc: "bind", dynlib: ws2dll.}
proc connect*(s: SocketHandle, name: ptr SockAddr, namelen: SockLen): cint {.
  stdcall, importc: "connect", dynlib: ws2dll.}
proc getsockname*(s: SocketHandle, name: ptr SockAddr, 
                  namelen: ptr SockLen): cint {.
  stdcall, importc: "getsockname", dynlib: ws2dll.}
proc getsockopt*(s: SocketHandle, level, optname: cint, optval: pointer,
                 optlen: ptr SockLen): cint {.
  stdcall, importc: "getsockopt", dynlib: ws2dll.}
proc setsockopt*(s: SocketHandle, level, optname: cint, optval: pointer,
                 optlen: SockLen): cint {.
  stdcall, importc: "setsockopt", dynlib: ws2dll.}

proc listen*(s: SocketHandle, backlog: cint): cint {.
  stdcall, importc: "listen", dynlib: ws2dll.}
proc recv*(s: SocketHandle, buf: pointer, len, flags: cint): cint {.
  stdcall, importc: "recv", dynlib: ws2dll.}
proc recvfrom*(s: SocketHandle, buf: cstring, len, flags: cint, 
               fromm: ptr SockAddr, fromlen: ptr SockLen): cint {.
  stdcall, importc: "recvfrom", dynlib: ws2dll.}
proc select*(nfds: cint, readfds, writefds, exceptfds: ptr TFdSet,
             timeout: ptr Timeval): cint {.
  stdcall, importc: "select", dynlib: ws2dll.}
proc send*(s: SocketHandle, buf: pointer, len, flags: cint): cint {.
  stdcall, importc: "send", dynlib: ws2dll.}
proc sendto*(s: SocketHandle, buf: pointer, len, flags: cint,
             to: ptr SockAddr, tolen: SockLen): cint {.
  stdcall, importc: "sendto", dynlib: ws2dll.}

proc shutdown*(s: SocketHandle, how: cint): cint {.
  stdcall, importc: "shutdown", dynlib: ws2dll.}
  
proc getnameinfo*(a1: ptr SockAddr, a2: SockLen,
                  a3: cstring, a4: SockLen, a5: cstring,
                  a6: SockLen, a7: cint): cint {.
  stdcall, importc: "getnameinfo", dynlib: ws2dll.}
  
proc inet_addr*(cp: cstring): int32 {.
  stdcall, importc: "inet_addr", dynlib: ws2dll.} 

proc WSAFDIsSet(s: SocketHandle, set: var TFdSet): bool {.
  stdcall, importc: "__WSAFDIsSet", dynlib: ws2dll, noSideEffect.}

proc FD_ISSET*(socket: SocketHandle, set: var TFdSet): cint = 
  result = if WSAFDIsSet(socket, set): 1'i32 else: 0'i32

proc FD_SET*(socket: SocketHandle, s: var TFdSet) = 
  if s.fd_count < FD_SETSIZE:
    s.fd_array[int(s.fd_count)] = socket
    inc(s.fd_count)

proc FD_ZERO*(s: var TFdSet) =
  s.fd_count = 0

proc wsaStartup*(wVersionRequired: int16, WSData: ptr WSAData): cint {.
  stdcall, importc: "WSAStartup", dynlib: ws2dll.}

proc getaddrinfo*(nodename, servname: cstring, hints: ptr AddrInfo,
                  res: var ptr AddrInfo): cint {.
  stdcall, importc: "getaddrinfo", dynlib: ws2dll.}

proc freeaddrinfo*(ai: ptr AddrInfo) {.
  stdcall, importc: "freeaddrinfo", dynlib: ws2dll.}

proc inet_ntoa*(i: InAddr): cstring {.
  stdcall, importc, dynlib: ws2dll.}

const
  MAXIMUM_WAIT_OBJECTS* = 0x00000040

type
  TWOHandleArray* = array[0..MAXIMUM_WAIT_OBJECTS - 1, THandle]
  PWOHandleArray* = ptr TWOHandleArray

proc waitForMultipleObjects*(nCount: DWORD, lpHandles: PWOHandleArray,
                             bWaitAll: WINBOOL, dwMilliseconds: DWORD): DWORD{.
    stdcall, dynlib: "kernel32", importc: "WaitForMultipleObjects".}
    
    
# for memfiles.nim:

const
  GENERIC_READ* = 0x80000000'i32
  GENERIC_WRITE* = 0x40000000'i32
  GENERIC_ALL* = 0x10000000'i32
  FILE_SHARE_READ* = 1'i32
  FILE_SHARE_DELETE* = 4'i32
  FILE_SHARE_WRITE* = 2'i32
 
  CREATE_ALWAYS* = 2'i32
  CREATE_NEW* = 1'i32
  OPEN_EXISTING* = 3'i32
  FILE_BEGIN* = 0'i32
  INVALID_SET_FILE_POINTER* = -1'i32
  NO_ERROR* = 0'i32
  PAGE_READONLY* = 2'i32
  PAGE_READWRITE* = 4'i32
  FILE_MAP_READ* = 4'i32
  FILE_MAP_WRITE* = 2'i32
  INVALID_FILE_SIZE* = -1'i32

  FILE_FLAG_BACKUP_SEMANTICS* = 33554432'i32
  FILE_FLAG_OPEN_REPARSE_POINT* = 0x00200000'i32

# Error Constants
const
  ERROR_ACCESS_DENIED* = 5
  ERROR_HANDLE_EOF* = 38

when useWinUnicode:
  proc createFileW*(lpFileName: WideCString, dwDesiredAccess, dwShareMode: DWORD,
                    lpSecurityAttributes: pointer,
                    dwCreationDisposition, dwFlagsAndAttributes: DWORD,
                    hTemplateFile: THandle): THandle {.
      stdcall, dynlib: "kernel32", importc: "CreateFileW".}
  proc deleteFileW*(pathName: WideCString): int32 {.
    importc: "DeleteFileW", dynlib: "kernel32", stdcall.}
else:
  proc createFileA*(lpFileName: cstring, dwDesiredAccess, dwShareMode: DWORD,
                    lpSecurityAttributes: pointer,
                    dwCreationDisposition, dwFlagsAndAttributes: DWORD,
                    hTemplateFile: THANDLE): THANDLE {.
      stdcall, dynlib: "kernel32", importc: "CreateFileA".}
  proc deleteFileA*(pathName: cstring): int32 {.
    importc: "DeleteFileA", dynlib: "kernel32", stdcall.}

proc setEndOfFile*(hFile: THandle): WINBOOL {.stdcall, dynlib: "kernel32",
    importc: "SetEndOfFile".}

proc setFilePointer*(hFile: THandle, lDistanceToMove: LONG,
                     lpDistanceToMoveHigh: ptr LONG, 
                     dwMoveMethod: DWORD): DWORD {.
    stdcall, dynlib: "kernel32", importc: "SetFilePointer".}

proc getFileSize*(hFile: THandle, lpFileSizeHigh: ptr DWORD): DWORD{.stdcall,
    dynlib: "kernel32", importc: "GetFileSize".}

proc mapViewOfFileEx*(hFileMappingObject: THandle, dwDesiredAccess: DWORD,
                      dwFileOffsetHigh, dwFileOffsetLow: DWORD,
                      dwNumberOfBytesToMap: DWORD, 
                      lpBaseAddress: pointer): pointer{.
    stdcall, dynlib: "kernel32", importc: "MapViewOfFileEx".}

proc createFileMappingW*(hFile: THandle,
                       lpFileMappingAttributes: pointer,
                       flProtect, dwMaximumSizeHigh: DWORD,
                       dwMaximumSizeLow: DWORD, 
                       lpName: pointer): THandle {.
  stdcall, dynlib: "kernel32", importc: "CreateFileMappingW".}

when not useWinUnicode:
  proc createFileMappingA*(hFile: THANDLE,
                           lpFileMappingAttributes: pointer,
                           flProtect, dwMaximumSizeHigh: DWORD,
                           dwMaximumSizeLow: DWORD, lpName: cstring): THANDLE {.
      stdcall, dynlib: "kernel32", importc: "CreateFileMappingA".}

proc unmapViewOfFile*(lpBaseAddress: pointer): WINBOOL {.stdcall,
    dynlib: "kernel32", importc: "UnmapViewOfFile".}

type
  TOVERLAPPED* {.pure, inheritable.} = object
    internal*: PULONG
    internalHigh*: PULONG
    offset*: DWORD
    offsetHigh*: DWORD
    hEvent*: THandle

  POVERLAPPED* = ptr TOVERLAPPED

  POVERLAPPED_COMPLETION_ROUTINE* = proc (para1: DWORD, para2: DWORD,
      para3: POVERLAPPED){.stdcall.}

  TGUID* {.final, pure.} = object
    D1*: int32
    D2*: int16
    D3*: int16
    D4*: array [0..7, int8]

const
  ERROR_IO_PENDING* = 997 # a.k.a WSA_IO_PENDING
  FILE_FLAG_OVERLAPPED* = 1073741824
  WSAECONNABORTED* = 10053
  WSAECONNRESET* = 10054
  WSAEDISCON* = 10101
  WSAENETRESET* = 10052
  WSAETIMEDOUT* = 10060
  ERROR_NETNAME_DELETED* = 64

proc createIoCompletionPort*(FileHandle: THandle, ExistingCompletionPort: THandle,
                             CompletionKey: DWORD,
                             NumberOfConcurrentThreads: DWORD): THandle{.stdcall,
    dynlib: "kernel32", importc: "CreateIoCompletionPort".}

proc getQueuedCompletionStatus*(CompletionPort: THandle,
    lpNumberOfBytesTransferred: PDWORD, lpCompletionKey: PULONG,
                                lpOverlapped: ptr POVERLAPPED,
                                dwMilliseconds: DWORD): WINBOOL{.stdcall,
    dynlib: "kernel32", importc: "GetQueuedCompletionStatus".}

proc getOverlappedResult*(hFile: THandle, lpOverlapped: TOVERLAPPED,
              lpNumberOfBytesTransferred: var DWORD, bWait: WINBOOL): WINBOOL{.
    stdcall, dynlib: "kernel32", importc: "GetOverlappedResult".}

const 
 IOC_OUT* = 0x40000000
 IOC_IN*  = 0x80000000
 IOC_WS2* = 0x08000000
 IOC_INOUT* = IOC_IN or IOC_OUT

template WSAIORW*(x,y): expr = (IOC_INOUT or x or y)

const
  SIO_GET_EXTENSION_FUNCTION_POINTER* = WSAIORW(IOC_WS2,6).DWORD
  SO_UPDATE_ACCEPT_CONTEXT* = 0x700B

var
  WSAID_CONNECTEX*: TGUID = TGUID(D1: 0x25a207b9, D2: 0xddf3'i16, D3: 0x4660, D4: [
    0x8e'i8, 0xe9'i8, 0x76'i8, 0xe5'i8, 0x8c'i8, 0x74'i8, 0x06'i8, 0x3e'i8])
  WSAID_ACCEPTEX*: TGUID = TGUID(D1: 0xb5367df1'i32, D2: 0xcbac'i16, D3: 0x11cf, D4: [
    0x95'i8, 0xca'i8, 0x00'i8, 0x80'i8, 0x5f'i8, 0x48'i8, 0xa1'i8, 0x92'i8])
  WSAID_GETACCEPTEXSOCKADDRS*: TGUID = TGUID(D1: 0xb5367df2'i32, D2: 0xcbac'i16, D3: 0x11cf, D4: [
    0x95'i8, 0xca'i8, 0x00'i8, 0x80'i8, 0x5f'i8, 0x48'i8, 0xa1'i8, 0x92'i8])

proc WSAIoctl*(s: SocketHandle, dwIoControlCode: DWORD, lpvInBuffer: pointer,
  cbInBuffer: DWORD, lpvOutBuffer: pointer, cbOutBuffer: DWORD,
  lpcbBytesReturned: PDWORD, lpOverlapped: POVERLAPPED,
  lpCompletionRoutine: POVERLAPPED_COMPLETION_ROUTINE): cint 
  {.stdcall, importc: "WSAIoctl", dynlib: "Ws2_32.dll".}

type
  TWSABuf* {.importc: "WSABUF", header: "winsock2.h".} = object
    len*: ULONG
    buf*: cstring

proc WSARecv*(s: SocketHandle, buf: ptr TWSABuf, bufCount: DWORD,
  bytesReceived, flags: PDWORD, lpOverlapped: POVERLAPPED,
  completionProc: POVERLAPPED_COMPLETION_ROUTINE): cint {.
  stdcall, importc: "WSARecv", dynlib: "Ws2_32.dll".}

proc WSASend*(s: SocketHandle, buf: ptr TWSABuf, bufCount: DWORD,
  bytesSent: PDWORD, flags: DWORD, lpOverlapped: POVERLAPPED,
  completionProc: POVERLAPPED_COMPLETION_ROUTINE): cint {.
  stdcall, importc: "WSASend", dynlib: "Ws2_32.dll".}

proc get_osfhandle*(fd:FileHandle): THandle {.
  importc: "_get_osfhandle", header:"<io.h>".}

proc getSystemTimes*(lpIdleTime, lpKernelTime, 
                     lpUserTime: var TFILETIME): WINBOOL {.stdcall,
  dynlib: "kernel32", importc: "GetSystemTimes".}

proc getProcessTimes*(hProcess: THandle; lpCreationTime, lpExitTime,
  lpKernelTime, lpUserTime: var TFILETIME): WINBOOL {.stdcall,
  dynlib: "kernel32", importc: "GetProcessTimes".}
