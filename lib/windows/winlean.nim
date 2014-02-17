#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a small wrapper for some needed Win API procedures,
## so that the Nimrod compiler does not depend on the huge Windows module.
import macros, strutils

const
  useWinUnicode* = not defined(useWinAnsi)

when useWinUnicode:
  type winString = WideCString
  let apiPrefix = "W"
else:
  type winString = CString
  let apiPrefix = "A"

macro winApi*(baseProc: stmt): stmt {.immediate.} =
  ## A pragma meant to be used with procedures that wrap the Windows API
  ## Given a procedure without a 'W' or 'A' suffix, creates two additional
  ## procedures:
  ##  - A conversion/wrapper procedure that uses regular strings instead of
  ##    WinStrings in its parameters, and automatically converts them to
  ##    WinStrings when calling the wrapped procedure
  ##  - A raw procedure with the same behavior as the original, except that
  ##    the name has a 'W' or 'A' suffix, depending on whether unicode or
  ##    ansi api's are used.
  # TODO - Get rid of paramsIdent?
  # TODO - Add WinChar conversion
  # echo(treeRepr(baseProc))
  echo(useWinUnicode, "Is false")
  result = newStmtList()

  var apiName: string
  case baseProc.name.kind
  of nnkPostfix:
    apiName = $baseProc.name[1] & apiPrefix
  else:
    apiName = $baseProc.name & apiPrefix
  apiName = apiName.capitalize()

  # Calculate the new importc pragma
  var cImportPragma = newNimNode(nnkExprColonExpr)
  cImportPragma.add(newIdentNode("importc"), newStrLitNode(apiName))
  baseProc.pragma.add(cImportPragma)
  
  # Generate the raw procedure
  var rawProc = copy(baseProc)
  case baseProc.name.kind
  of nnkPostfix:
    rawProc.name[1] = newIdentNode(apiName)
  else:
    rawProc.name= newIdentNode(apiName)

  # Generate the conversion proc (if needed)
  var conversionNeeded = false
  var convertReturnValue = false
  when useWinUnicode:
    var conversionProc = copy(baseProc)
    conversionProc.pragma= newEmptyNode()
    conversionProc.body= newStmtList()

    # Generate the conversion call, and modify the conversion procs parameters.
    var conversionCall = newCall(apiName)

    for i in 1.. <conversionProc.params.len: # Skip the first value (return type)
      var currentParams = conversionProc.params[i]
      var paramsType = currentParams[currentParams.len-2]
      var paramsIdents = newSeq[PNimrodNode]()
      for k in 0..len(currentParams)-3:
        paramsIdents.add(currentParams[k])

      if paramsType.kind == nnkIdent and $paramsType == "WinString":
        currentParams[currentParams.len-2] = newIdentNode("string")
        for param in paramsIdents:
          conversionCall.add(newCall("newWideCString", copy(param)))
        conversionNeeded = true
      else:
        for param in paramsIdents:
          conversionCall.add(copy(param))

    # Modify the return type, if needed.
    let returnType = baseProc.params[0]
    when useWinUnicode:
      if returnType.kind != nnkEmpty and normalize($returnType) == "winstring":
        conversionProc.params[0] = newIdentNode("string")
        conversionNeeded = true
        convertReturnValue = true


    # Add the call to the conversionProc
    if conversionNeeded:
      var callParent = conversionProc.body
      if returnType.kind != nnkEmpty and normalize($returnType) != "void":
        callParent = newNimNode(nnkReturnStmt)
        conversionProc.body.add(callParent)
      if convertReturnValue:
        echo("Converted return values")
        callParent.add(prefix(conversionCall, "$"))
      else:
        callParent.add(conversionCall)

  # Add the other procs. Order is important!
  result.add(baseProc)
  result.add(rawProc)
  if useWinUnicode and conversionNeeded:
    result.add(conversionProc)

  echo(repr(result))

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
               lpNumberOfBytesRead: var int32, lpOverlapped: pointer): WINBOOL{.
    stdcall, dynlib: "kernel32", importc: "ReadFile".}
    
proc writeFile*(hFile: THandle, Buffer: pointer, nNumberOfBytesToWrite: int32,
                lpNumberOfBytesWritten: var int32, 
                lpOverlapped: pointer): WINBOOL{.
    stdcall, dynlib: "kernel32", importc: "WriteFile".}

proc createPipe*(hReadPipe, hWritePipe: var THandle,
                 lpPipeAttributes: var TSECURITY_ATTRIBUTES, 
                 nSize: int32): WINBOOL{.
    stdcall, dynlib: "kernel32", importc: "CreatePipe".}

when useWinUnicode:
  proc createProcessW*(lpApplicationName, lpCommandLine: WinString,
                     lpProcessAttributes: ptr TSECURITY_ATTRIBUTES,
                     lpThreadAttributes: ptr TSECURITY_ATTRIBUTES,
                     bInheritHandles: WINBOOL, dwCreationFlags: int32,
                     lpEnvironment, lpCurrentDirectory: WinString,
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

proc formatMessage*(dwFlags: int32, lpSource: pointer,
                    dwMessageId, dwLanguageId: int32,
                    lpBuffer: pointer, nSize: int32,
                    Arguments: pointer): int32 {.
                    winApi, stdcall, dynlib: "kernel32".}

proc localFree*(p: pointer) {.
  importc: "LocalFree", stdcall, dynlib: "kernel32".}

proc getCurrentDirectory*(nBufferLength: int32, 
                           lpBuffer: WinString): int32 {.
  winApi, dynlib: "kernel32", stdcall.}
proc setCurrentDirectory*(lpPathName: WinString): int32 {.
  winApi, dynlib: "kernel32", stdcall.}
proc createDirectory*(pathName: WinString, security: pointer=nil): int32 {.
  winApi, dynlib: "kernel32", stdcall.}
proc removeDirectory*(lpPathName: WinString): int32 {.
  winApi, dynlib: "kernel32", stdcall.}
proc setEnvironmentVariable*(lpName, lpValue: WinString): int32 {.
  winApi, stdcall, dynlib: "kernel32".}

proc getModuleFileName*(handle: THandle, buf: WinString, 
                         size: int32): int32 {.winApi, 
  dynlib: "kernel32", stdcall.}

proc createSymbolicLink*(lpSymlinkFileName, lpTargetFileName: WinString,
                       flags: DWORD): int32 {.
  winApi, dynlib: "kernel32", stdcall.}
proc createHardLink*(lpFileName, lpExistingFileName: WinString,
                       security: pointer=nil): int32 {.
  winApi, dynlib: "kernel32", stdcall.}

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

proc findFirstFile*(lpFileName: WinString,
                    lpFindFileData: var TWIN32_FIND_DATA): THandle {.
    stdcall, dynlib: "kernel32", winApi.}
proc findNextFile*(hFindFile: THandle,
                   lpFindFileData: var TWIN32_FIND_DATA): int32 {.
    stdcall, dynlib: "kernel32", winApi.}

proc findClose*(hFindFile: THandle) {.stdcall, dynlib: "kernel32",
  importc: "FindClose".}


proc getFullPathName*(lpFileName: WinString, nBufferLength: int32,
                      lpBuffer: WinString, 
                      lpFilePart: var WinString): int32 {.
                      stdcall, dynlib: "kernel32", 
                      winApi.}
proc getFileAttributes*(lpFileName: WinString): int32 {.
                        stdcall, dynlib: "kernel32", 
                        winApi.}
proc setFileAttributes*(lpFileName: WinString, 
                         dwFileAttributes: int32): WINBOOL {.
    stdcall, dynlib: "kernel32", winApi.}

proc copyFile*(lpExistingFileName, lpNewFileName: WinString,
               bFailIfExists: cint): cint {.
  winApi, stdcall, dynlib: "kernel32".}

proc getEnvironmentStrings*(): WinString {.
  stdcall, dynlib: "kernel32", winApi.}
proc freeEnvironmentStrings*(para1: WinString): int32 {.
  stdcall, dynlib: "kernel32", winApi.}

proc getCommandLine*(): WinString {.winApi,
  stdcall, dynlib: "kernel32".}


proc rdFileTime*(f: TFILETIME): int64 = 
  result = ze64(f.dwLowDateTime) or (ze64(f.dwHighDateTime) shl 32)

proc rdFileSize*(f: TWIN32_FIND_DATA): int64 = 
  result = ze64(f.nFileSizeLow) or (ze64(f.nFileSizeHigh) shl 32)

proc getSystemTimeAsFileTime*(lpSystemTimeAsFileTime: var TFILETIME) {.
  importc: "GetSystemTimeAsFileTime", dynlib: "kernel32", stdcall.}

proc sleep*(dwMilliseconds: int32){.stdcall, dynlib: "kernel32",
                                    importc: "Sleep".}

proc shellExecute*(HWND: THandle, lpOperation, lpFile,
                   lpParameters, lpDirectory: WinString,
                   nShowCmd: int32): THandle{.
    stdcall, dynlib: "shell32.dll", winApi.}
  
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
  TSocketHandle* = distinct int

type
  TWSAData* {.pure, final, importc: "WSADATA", header: "Winsock2.h".} = object 
    wVersion, wHighVersion: int16
    szDescription: array[0..WSADESCRIPTION_LEN, char]
    szSystemStatus: array[0..WSASYS_STATUS_LEN, char]
    iMaxSockets, iMaxUdpDg: int16
    lpVendorInfo: cstring
    
  TSockAddr* {.pure, final, importc: "SOCKADDR", header: "Winsock2.h".} = object 
    sa_family*: int16 # unsigned
    sa_data: array[0..13, char]

  TInAddr* {.pure, final, importc: "IN_ADDR", header: "Winsock2.h".} = object
    s_addr*: int32  # IP address
  
  Tsockaddr_in* {.pure, final, importc: "SOCKADDR_IN", 
                  header: "Winsock2.h".} = object
    sin_family*: int16
    sin_port*: int16 # unsigned
    sin_addr*: TInAddr
    sin_zero*: array[0..7, char]

  Tin6_addr* {.pure, final, importc: "IN6_ADDR", header: "Winsock2.h".} = object 
    bytes*: array[0..15, char]

  Tsockaddr_in6* {.pure, final, importc: "SOCKADDR_IN6", 
                   header: "Winsock2.h".} = object
    sin6_family*: int16
    sin6_port*: int16 # unsigned
    sin6_flowinfo*: int32 # unsigned
    sin6_addr*: Tin6_addr
    sin6_scope_id*: int32 # unsigned

  Tsockaddr_in6_old* {.pure, final.} = object
    sin6_family*: int16
    sin6_port*: int16 # unsigned
    sin6_flowinfo*: int32 # unsigned
    sin6_addr*: Tin6_addr

  TServent* {.pure, final.} = object
    s_name*: cstring
    s_aliases*: cstringArray
    when defined(cpu64):
      s_proto*: cstring
      s_port*: int16
    else:
      s_port*: int16
      s_proto*: cstring

  Thostent* {.pure, final.} = object
    h_name*: cstring
    h_aliases*: cstringArray
    h_addrtype*: int16
    h_length*: int16
    h_addr_list*: cstringArray
  
  TFdSet* {.pure, final.} = object
    fd_count*: cint # unsigned
    fd_array*: array[0..FD_SETSIZE-1, TSocketHandle]
    
  TTimeval* {.pure, final.} = object
    tv_sec*, tv_usec*: int32
    
  TAddrInfo* {.pure, final.} = object
    ai_flags*: cint         ## Input flags. 
    ai_family*: cint        ## Address family of socket. 
    ai_socktype*: cint      ## Socket type. 
    ai_protocol*: cint      ## Protocol of socket. 
    ai_addrlen*: int        ## Length of socket address. 
    ai_canonname*: cstring  ## Canonical name of service location.
    ai_addr*: ptr TSockAddr ## Socket address of socket. 
    ai_next*: ptr TAddrInfo ## Pointer to next in list. 

  TSockLen* = cuint

var
  SOMAXCONN* {.importc, header: "Winsock2.h".}: cint
  INVALID_SOCKET* {.importc, header: "Winsock2.h".}: TSocketHandle
  SOL_SOCKET* {.importc, header: "Winsock2.h".}: cint
  SO_DEBUG* {.importc, header: "Winsock2.h".}: cint ## turn on debugging info recording
  SO_ACCEPTCONN* {.importc, header: "Winsock2.h".}: cint # socket has had listen()
  SO_REUSEADDR* {.importc, header: "Winsock2.h".}: cint # allow local address reuse
  SO_KEEPALIVE* {.importc, header: "Winsock2.h".}: cint # keep connections alive
  SO_DONTROUTE* {.importc, header: "Winsock2.h".}: cint # just use interface addresses
  SO_BROADCAST* {.importc, header: "Winsock2.h".}: cint # permit sending of broadcast msgs
  SO_USELOOPBACK* {.importc, header: "Winsock2.h".}: cint # bypass hardware when possible
  SO_LINGER* {.importc, header: "Winsock2.h".}: cint # linger on close if data present
  SO_OOBINLINE* {.importc, header: "Winsock2.h".}: cint # leave received OOB data in line

  SO_DONTLINGER* {.importc, header: "Winsock2.h".}: cint
  SO_EXCLUSIVEADDRUSE* {.importc, header: "Winsock2.h".}: cint # disallow local address reuse

proc `==`*(x, y: TSocketHandle): bool {.borrow.}

proc getservbyname*(name, proto: cstring): ptr TServent {.
  stdcall, importc: "getservbyname", dynlib: ws2dll.}

proc getservbyport*(port: cint, proto: cstring): ptr TServent {.
  stdcall, importc: "getservbyport", dynlib: ws2dll.}

proc gethostbyaddr*(ip: ptr TInAddr, len: cuint, theType: cint): ptr Thostent {.
  stdcall, importc: "gethostbyaddr", dynlib: ws2dll.}

proc gethostbyname*(name: cstring): ptr Thostent {.
  stdcall, importc: "gethostbyname", dynlib: ws2dll.}

proc socket*(af, typ, protocol: cint): TSocketHandle {.
  stdcall, importc: "socket", dynlib: ws2dll.}

proc closesocket*(s: TSocketHandle): cint {.
  stdcall, importc: "closesocket", dynlib: ws2dll.}

proc accept*(s: TSocketHandle, a: ptr TSockAddr, addrlen: ptr TSockLen): TSocketHandle {.
  stdcall, importc: "accept", dynlib: ws2dll.}
proc bindSocket*(s: TSocketHandle, name: ptr TSockAddr, namelen: TSockLen): cint {.
  stdcall, importc: "bind", dynlib: ws2dll.}
proc connect*(s: TSocketHandle, name: ptr TSockAddr, namelen: TSockLen): cint {.
  stdcall, importc: "connect", dynlib: ws2dll.}
proc getsockname*(s: TSocketHandle, name: ptr TSockAddr, 
                  namelen: ptr TSockLen): cint {.
  stdcall, importc: "getsockname", dynlib: ws2dll.}
proc getsockopt*(s: TSocketHandle, level, optname: cint, optval: pointer,
                 optlen: ptr TSockLen): cint {.
  stdcall, importc: "getsockopt", dynlib: ws2dll.}
proc setsockopt*(s: TSocketHandle, level, optname: cint, optval: pointer,
                 optlen: TSockLen): cint {.
  stdcall, importc: "setsockopt", dynlib: ws2dll.}

proc listen*(s: TSocketHandle, backlog: cint): cint {.
  stdcall, importc: "listen", dynlib: ws2dll.}
proc recv*(s: TSocketHandle, buf: pointer, len, flags: cint): cint {.
  stdcall, importc: "recv", dynlib: ws2dll.}
proc recvfrom*(s: TSocketHandle, buf: cstring, len, flags: cint, 
               fromm: ptr TSockAddr, fromlen: ptr TSockLen): cint {.
  stdcall, importc: "recvfrom", dynlib: ws2dll.}
proc select*(nfds: cint, readfds, writefds, exceptfds: ptr TFdSet,
             timeout: ptr TTimeval): cint {.
  stdcall, importc: "select", dynlib: ws2dll.}
proc send*(s: TSocketHandle, buf: pointer, len, flags: cint): cint {.
  stdcall, importc: "send", dynlib: ws2dll.}
proc sendto*(s: TSocketHandle, buf: pointer, len, flags: cint,
             to: ptr TSockAddr, tolen: TSockLen): cint {.
  stdcall, importc: "sendto", dynlib: ws2dll.}

proc shutdown*(s: TSocketHandle, how: cint): cint {.
  stdcall, importc: "shutdown", dynlib: ws2dll.}
  
proc getnameinfo*(a1: ptr TSockAddr, a2: TSockLen,
                  a3: cstring, a4: TSockLen, a5: cstring,
                  a6: TSockLen, a7: cint): cint {.
  stdcall, importc: "getnameinfo", dynlib: ws2dll.}
  
proc inet_addr*(cp: cstring): int32 {.
  stdcall, importc: "inet_addr", dynlib: ws2dll.} 

proc WSAFDIsSet(s: TSocketHandle, FDSet: var TFdSet): bool {.
  stdcall, importc: "__WSAFDIsSet", dynlib: ws2dll.}

proc FD_ISSET*(Socket: TSocketHandle, FDSet: var TFdSet): cint = 
  result = if WSAFDIsSet(Socket, FDSet): 1'i32 else: 0'i32

proc FD_SET*(Socket: TSocketHandle, FDSet: var TFdSet) = 
  if FDSet.fd_count < FD_SETSIZE:
    FDSet.fd_array[int(FDSet.fd_count)] = Socket
    inc(FDSet.fd_count)

proc FD_ZERO*(FDSet: var TFdSet) =
  FDSet.fd_count = 0

proc wsaStartup*(wVersionRequired: int16, WSData: ptr TWSAData): cint {.
  stdcall, importc: "WSAStartup", dynlib: ws2dll.}

proc getaddrinfo*(nodename, servname: cstring, hints: ptr TAddrInfo,
                  res: var ptr TAddrInfo): cint {.
  stdcall, importc: "getaddrinfo", dynlib: ws2dll.}

proc freeaddrinfo*(ai: ptr TAddrInfo) {.
  stdcall, importc: "freeaddrinfo", dynlib: ws2dll.}

proc inet_ntoa*(i: TInAddr): cstring {.
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
  GENERIC_ALL* = 0x10000000'i32
  FILE_SHARE_READ* = 1'i32
  FILE_SHARE_DELETE* = 4'i32
  FILE_SHARE_WRITE* = 2'i32
 
  CREATE_ALWAYS* = 2'i32
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

# Error Constants
const
  ERROR_ACCESS_DENIED* = 5

proc createFile*(lpFileName: WinString, dwDesiredAccess, dwShareMode: DWORD,
                  lpSecurityAttributes: pointer,
                  dwCreationDisposition, dwFlagsAndAttributes: DWORD,
                  hTemplateFile: THandle): THandle {.
    stdcall, dynlib: "kernel32", winApi.}
proc deleteFile*(pathName: WinString): int32 {.
  winApi, dynlib: "kernel32", stdcall.}

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
  TOVERLAPPED* {.final, pure.} = object
    Internal*: DWORD
    InternalHigh*: DWORD
    Offset*: DWORD
    OffsetHigh*: DWORD
    hEvent*: THANDLE

  POVERLAPPED* = ptr TOVERLAPPED

  POVERLAPPED_COMPLETION_ROUTINE* = proc (para1: DWORD, para2: DWORD,
      para3: POVERLAPPED){.stdcall.}

  TGUID* {.final, pure.} = object
    D1*: int32
    D2*: int16
    D3*: int16
    D4*: array [0..7, int8]

const
  ERROR_IO_PENDING* = 997

proc CreateIoCompletionPort*(FileHandle: THANDLE, ExistingCompletionPort: THANDLE,
                             CompletionKey: DWORD,
                             NumberOfConcurrentThreads: DWORD): THANDLE{.stdcall,
    dynlib: "kernel32", importc: "CreateIoCompletionPort".}

proc GetQueuedCompletionStatus*(CompletionPort: THandle,
    lpNumberOfBytesTransferred: PDWORD, lpCompletionKey: PULONG,
                                lpOverlapped: ptr POverlapped,
                                dwMilliseconds: DWORD): WINBOOL{.stdcall,
    dynlib: "kernel32", importc: "GetQueuedCompletionStatus".}

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

proc WSAIoctl*(s: TSocketHandle, dwIoControlCode: DWORD, lpvInBuffer: pointer,
  cbInBuffer: DWORD, lpvOutBuffer: pointer, cbOutBuffer: DWORD,
  lpcbBytesReturned: PDword, lpOverlapped: POVERLAPPED,
  lpCompletionRoutine: POVERLAPPED_COMPLETION_ROUTINE): cint 
  {.stdcall, importc: "WSAIoctl", dynlib: "Ws2_32.dll".}

type
  TWSABuf* {.importc: "WSABUF", header: "winsock2.h".} = object
    len*: ULONG
    buf*: cstring

proc WSARecv*(s: TSocketHandle, buf: ptr TWSABuf, bufCount: DWORD,
  bytesReceived, flags: PDWORD, lpOverlapped: POverlapped,
  completionProc: POVERLAPPED_COMPLETION_ROUTINE): cint {.
  stdcall, importc: "WSARecv", dynlib: "Ws2_32.dll".}

proc WSASend*(s: TSocketHandle, buf: ptr TWSABuf, bufCount: DWORD,
  bytesSent: PDWord, flags: DWORD, lpOverlapped: POverlapped,
  completionProc: POVERLAPPED_COMPLETION_ROUTINE): cint {.
  stdcall, importc: "WSASend", dynlib: "Ws2_32.dll".}
