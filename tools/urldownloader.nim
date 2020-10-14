
#
#
#    Windows native FTP/HTTP/HTTPS file downloader
#        (c) Copyright 2017 Eugene Kabanov
#
#    See the file "LICENSE", included in this
#    distribution, for details about the copyright.
#

## This module implements native Windows FTP/HTTP/HTTPS downloading feature,
## using ``urlmon.UrlDownloadToFile()``.
##
##

when not (defined(windows) or defined(nimdoc)):
  {.error: "Platform is not supported.".}

import os

type
  DownloadOptions* = enum
    ## Available download options
    optUseCache,             ## Use Windows cache.
    optUseProgressCallback,  ## Report progress via callback.
    optIgnoreSecurity        ## Ignore HTTPS security problems.

  DownloadStatus* = enum
    ## Available download status sent to ``progress`` callback.
    statusProxyDetecting,    ## Automatic Proxy detection.
    statusCookieSent         ## Cookie will be sent with request.
    statusResolving,         ## Resolving URL with DNS.
    statusConnecting,        ## Establish connection to server.
    statusRedirecting        ## HTTP redirection pending.
    statusRequesting,        ## Sending request to server.
    statusMimetypeAvailable, ## Mimetype received from server.
    statusBeginDownloading,  ## Download process starting.
    statusDownloading,       ## Download process pending.
    statusEndDownloading,    ## Download process finished.
    statusCacheAvailable     ## File found in Windows cache.
    statusUnsupported        ## Unsupported status.
    statusError              ## Error happens.

  DownloadProgressCallback* = proc(status: DownloadStatus, progress: uint,
                                   progressMax: uint,
                                   message: string)
    ## Progress callback.
    ##
    ## status
    ##   Indicate current stage of downloading process.
    ##
    ## progress
    ##   Number of bytes currently downloaded. Available only, if ``status`` is
    ##   ``statusBeginDownloading``, ``statusDownloading`` or
    ##   ``statusEndDownloading``.
    ##
    ## progressMax
    ##   Number of bytes expected to download. Available only, if ``status`` is
    ##   ``statusBeginDownloading``, ``statusDownloading`` or
    ##   ``statusEndDownloading``.
    ##
    ## message
    ##   Status message, which depends on ``status`` code.
    ##
    ## Available messages' values:
    ##
    ## statusResolving
    ##   URL hostname to be resolved.
    ## statusConnecting
    ##   IP address
    ## statusMimetypeAvailable
    ##   Downloading resource MIME type.
    ## statusCacheAvailable
    ##   Path to filename stored in Windows cache.

type
  UUID = array[4, uint32]

  LONG = clong
  ULONG = culong
  HRESULT = clong
  DWORD = uint32
  OLECHAR = uint16
  OLESTR = ptr OLECHAR
  LPWSTR = OLESTR
  UINT = cuint
  REFIID = ptr UUID

const
  E_NOINTERFACE = 0x80004002'i32
  E_NOTIMPL = 0x80004001'i32
  S_OK = 0x00000000'i32

  CP_UTF8 = 65001'u32

  IID_IUnknown = UUID([0'u32, 0'u32, 192'u32, 1174405120'u32])
  IID_IBindStatusCallback = UUID([2045430209'u32, 298760953'u32,
                                  2852160140'u32, 195644160'u32])

  BINDF_GETNEWESTVERSION = 0x00000010'u32
  BINDF_IGNORESECURITYPROBLEM = 0x00000100'u32
  BINDF_RESYNCHRONIZE = 0x00000200'u32
  BINDF_NO_UI = 0x00000800'u32
  BINDF_SILENTOPERATION = 0x00001000'u32
  BINDF_PRAGMA_NO_CACHE = 0x00002000'u32

  ERROR_FILE_NOT_FOUND = 2
  ERROR_ACCESS_DENIED = 5

  BINDSTATUS_FINDINGRESOURCE = 1
  BINDSTATUS_CONNECTING = 2
  BINDSTATUS_REDIRECTING  = 3
  BINDSTATUS_BEGINDOWNLOADDATA  = 4
  BINDSTATUS_DOWNLOADINGDATA  = 5
  BINDSTATUS_ENDDOWNLOADDATA  = 6
  BINDSTATUS_SENDINGREQUEST = 11
  BINDSTATUS_MIMETYPEAVAILABLE  = 13
  BINDSTATUS_CACHEFILENAMEAVAILABLE = 14
  BINDSTATUS_PROXYDETECTING = 32
  BINDSTATUS_COOKIE_SENT = 34

type
  STGMEDIUM = object
    tymed: DWORD
    pstg: pointer
    pUnkForRelease: pointer

  SECURITY_ATTRIBUTES = object
    nLength*: uint32
    lpSecurityDescriptor*: pointer
    bInheritHandle*: int32

  BINDINFO = object
    cbSize: ULONG
    stgmedData: STGMEDIUM
    szExtraInfo: LPWSTR
    grfBindInfoF: DWORD
    dwBindVerb: DWORD
    szCustomVerb: LPWSTR
    cbstgmedData: DWORD
    dwOptions: DWORD
    dwOptionsFlags: DWORD
    dwCodePage: DWORD
    securityAttributes: SECURITY_ATTRIBUTES
    iid: UUID
    pUnk: pointer
    dwReserved: DWORD

  IBindStatusCallback = object
    vtable: ptr IBindStatusCallbackVTable
    options: set[DownloadOptions]
    objectRefCount: ULONG
    binfoFlags: DWORD
    progressCallback: DownloadProgressCallback

  PIBindStatusCallback = ptr IBindStatusCallback
  LPBINDSTATUSCALLBACK = PIBindStatusCallback

  IBindStatusCallbackVTable = object
    QueryInterface: proc (self: PIBindStatusCallback,
                          riid: ptr UUID,
                          pvObject: ptr pointer): HRESULT {.gcsafe,stdcall.}
    AddRef: proc(self: PIBindStatusCallback): ULONG {.gcsafe, stdcall.}
    Release: proc(self: PIBindStatusCallback): ULONG {.gcsafe, stdcall.}
    OnStartBinding: proc(self: PIBindStatusCallback,
                         dwReserved: DWORD, pib: pointer): HRESULT
                    {.gcsafe, stdcall.}
    GetPriority: proc(self: PIBindStatusCallback, pnPriority: ptr LONG): HRESULT
                 {.gcsafe, stdcall.}
    OnLowResource: proc(self: PIBindStatusCallback, dwReserved: DWORD): HRESULT
                   {.gcsafe, stdcall.}
    OnProgress: proc(self: PIBindStatusCallback, ulProgress: ULONG,
                     ulProgressMax: ULONG, ulStatusCode: ULONG,
                     szStatusText: LPWSTR): HRESULT
                {.gcsafe, stdcall.}
    OnStopBinding: proc(self: PIBindStatusCallback, hresult: HRESULT,
                        szError: LPWSTR): HRESULT
                   {.gcsafe, stdcall.}
    GetBindInfo: proc(self: PIBindStatusCallback, grfBINDF: ptr DWORD,
                      pbindinfo: ptr BINDINFO): HRESULT
                 {.gcsafe, stdcall.}
    OnDataAvailable: proc(self: PIBindStatusCallback, grfBSCF: DWORD,
                          dwSize: DWORD, pformatetc: pointer,
                          pstgmed: pointer): HRESULT
                     {.gcsafe, stdcall.}
    OnObjectAvailable: proc(self: PIBindStatusCallback, riid: REFIID,
                            punk: pointer): HRESULT
                       {.gcsafe, stdcall.}

template FAILED(hr: HRESULT): bool =
  (hr < 0)

proc URLDownloadToFile(pCaller: pointer, szUrl: LPWSTR, szFileName: LPWSTR,
                       dwReserved: DWORD,
                       lpfnCb: LPBINDSTATUSCALLBACK): HRESULT
     {.stdcall, dynlib: "urlmon.dll", importc: "URLDownloadToFileW".}

proc WideCharToMultiByte(CodePage: UINT, dwFlags: DWORD,
                         lpWideCharStr: ptr OLECHAR, cchWideChar: cint,
                         lpMultiByteStr: ptr char, cbMultiByte: cint,
                         lpDefaultChar: ptr char,
                         lpUsedDefaultChar: ptr uint32): cint
     {.stdcall, dynlib: "kernel32.dll", importc: "WideCharToMultiByte".}

proc MultiByteToWideChar(CodePage: UINT, dwFlags: DWORD,
                         lpMultiByteStr: ptr char, cbMultiByte: cint,
                         lpWideCharStr: ptr OLECHAR, cchWideChar: cint): cint
     {.stdcall, dynlib: "kernel32.dll", importc: "MultiByteToWideChar".}
proc DeleteUrlCacheEntry(lpszUrlName: LPWSTR): int32
     {.stdcall, dynlib: "wininet.dll", importc: "DeleteUrlCacheEntryW".}

proc `==`(a, b: UUID): bool =
  result = false
  if a[0] == b[0] and a[1] == b[1] and
     a[2] == b[2] and a[3] == b[3]:
    result = true

proc `$`(bstr: LPWSTR): string =
  var buffer: char
  var count = WideCharToMultiByte(CP_UTF8, 0, bstr, -1, addr(buffer), 0,
                                nil, nil)
  if count == 0:
    raiseOsError(osLastError())
  else:
    result = newString(count + 8)
    let res = WideCharToMultiByte(CP_UTF8, 0, bstr, -1, addr(result[0]), count,
                                  nil, nil)
    if res == 0:
      raiseOsError(osLastError())
    result.setLen(res - 1)

proc toBstring(str: string): LPWSTR =
  var buffer: OLECHAR
  var count = MultiByteToWideChar(CP_UTF8, 0, unsafeAddr(str[0]), -1,
                                  addr(buffer), 0)
  if count == 0:
    raiseOsError(osLastError())
  else:
    result = cast[LPWSTR](alloc0((count + 1) * sizeof(OLECHAR)))
    let res = MultiByteToWideChar(CP_UTF8, 0, unsafeAddr(str[0]), -1,
                                  result, count)
    if res == 0:
      raiseOsError(osLastError())

proc freeBstring(bstr: LPWSTR) =
  dealloc(bstr)

proc getStatus(scode: ULONG): DownloadStatus =
  case scode
  of 0: result = statusError
  of BINDSTATUS_PROXYDETECTING: result = statusProxyDetecting
  of BINDSTATUS_REDIRECTING: result = statusRedirecting
  of BINDSTATUS_COOKIE_SENT: result = statusCookieSent
  of BINDSTATUS_FINDINGRESOURCE: result = statusResolving
  of BINDSTATUS_CONNECTING: result = statusConnecting
  of BINDSTATUS_SENDINGREQUEST: result = statusRequesting
  of BINDSTATUS_MIMETYPEAVAILABLE: result = statusMimetypeAvailable
  of BINDSTATUS_BEGINDOWNLOADDATA: result = statusBeginDownloading
  of BINDSTATUS_DOWNLOADINGDATA: result = statusDownloading
  of BINDSTATUS_ENDDOWNLOADDATA: result = statusEndDownloading
  of BINDSTATUS_CACHEFILENAMEAVAILABLE: result = statusCacheAvailable
  else: result = statusUnsupported

proc addRef(self: PIBindStatusCallback): ULONG {.gcsafe, stdcall.} =
  inc(self.objectRefCount)
  result = self.objectRefCount

proc release(self: PIBindStatusCallback): ULONG {.gcsafe, stdcall.} =
  dec(self.objectRefCount)
  result = self.objectRefCount

proc queryInterface(self: PIBindStatusCallback, riid: ptr UUID,
                    pvObject: ptr pointer): HRESULT {.gcsafe,stdcall.} =
  pvObject[] = nil

  if riid[] == IID_IUnknown:
    pvObject[] = cast[pointer](self)
  elif riid[] == IID_IBindStatusCallback:
    pvObject[] = cast[pointer](self)

  if not isNil(pvObject[]):
    discard addRef(self)
    result = S_OK
  else:
    result = E_NOINTERFACE

proc onStartBinding(self: PIBindStatusCallback, dwReserved: DWORD,
                    pib: pointer): HRESULT {.gcsafe, stdcall.} =
  result = S_OK

proc getPriority(self: PIBindStatusCallback,
                 pnPriority: ptr LONG): HRESULT {.gcsafe, stdcall.} =
  result = E_NOTIMPL

proc onLowResource(self: PIBindStatusCallback,
                   dwReserved: DWORD): HRESULT {.gcsafe, stdcall.} =
  result = S_OK

proc onStopBinding(self: PIBindStatusCallback,
                   hresult: HRESULT, szError: LPWSTR): HRESULT
     {.gcsafe, stdcall.} =
  result = S_OK

proc getBindInfo(self: PIBindStatusCallback,
                 grfBINDF: ptr DWORD, pbindinfo: ptr BINDINFO): HRESULT
     {.gcsafe, stdcall.} =
  var cbSize = pbindinfo.cbSize
  zeroMem(cast[pointer](pbindinfo), cbSize)
  pbindinfo.cbSize = cbSize
  grfBINDF[] = self.binfoFlags
  result = S_OK

proc onDataAvailable(self: PIBindStatusCallback,
                     grfBSCF: DWORD, dwSize: DWORD, pformatetc: pointer,
                     pstgmed: pointer): HRESULT {.gcsafe, stdcall.} =
  result = S_OK

proc onObjectAvailable(self: PIBindStatusCallback,
                       riid: REFIID, punk: pointer): HRESULT
     {.gcsafe, stdcall.} =
  result = S_OK

proc onProgress(self: PIBindStatusCallback,
                ulProgress: ULONG, ulProgressMax: ULONG, ulStatusCode: ULONG,
                szStatusText: LPWSTR): HRESULT {.gcsafe, stdcall.} =
  var message: string
  if optUseProgressCallback in self.options:
    if not isNil(szStatusText):
      message = $szStatusText
    else:
      message = ""
    self.progressCallback(getStatus(ulStatusCode), uint(ulProgress),
                          uint(ulProgressMax), message)
  result = S_OK

proc newBindStatusCallback(): IBindStatusCallback =
  result = IBindStatusCallback()
  result.vtable = cast[ptr IBindStatusCallbackVTable](
    alloc0(sizeof(IBindStatusCallbackVTable))
  )
  result.vtable.QueryInterface = queryInterface
  result.vtable.AddRef = addRef
  result.vtable.Release = release
  result.vtable.OnStartBinding = onStartBinding
  result.vtable.GetPriority = getPriority
  result.vtable.OnLowResource = onLowResource
  result.vtable.OnStopBinding = onStopBinding
  result.vtable.GetBindInfo = getBindInfo
  result.vtable.OnDataAvailable = onDataAvailable
  result.vtable.OnObjectAvailable = onObjectAvailable
  result.vtable.OnProgress = onProgress
  result.objectRefCount = 1

proc freeBindStatusCallback(v: var IBindStatusCallback) =
  dealloc(v.vtable)

proc downloadToFile*(szUrl: string, szFileName: string,
                     options: set[DownloadOptions] = {},
                     progresscb: DownloadProgressCallback = nil) =
  ## Downloads from URL specified in ``szUrl`` to local filesystem path
  ## specified in ``szFileName``.
  ##
  ## szUrl
  ##   URL to download, international names are supported.
  ## szFileName
  ##   Destination path for downloading resource.
  ## options
  ##   Downloading options. Currently only 2 options supported.
  ## progresscb
  ##   Callback procedure, which will be called throughout the download
  ##   process, indicating status and progress.
  ##
  ## Available downloading options:
  ##
  ## optUseCache
  ##   Try to use Windows cache when downloading.
  ## optIgnoreSecurity
  ##   Ignore HTTPS security problems, e.g. self-signed HTTPS certificate.
  ##
  var bszUrl = szUrl.toBstring()
  var bszFile = szFileName.toBstring()
  var bstatus = newBindStatusCallback()

  bstatus.options = {}

  if optUseCache notin options:
    bstatus.options.incl(optUseCache)
    let res = DeleteUrlCacheEntry(bszUrl)
    if res == 0:
      let err = osLastError()
      if err.int notin {ERROR_ACCESS_DENIED, ERROR_FILE_NOT_FOUND}:
        freeBindStatusCallback(bstatus)
        freeBstring(bszUrl)
        freeBstring(bszFile)
        raiseOsError(err)

  bstatus.binfoFlags = BINDF_GETNEWESTVERSION or BINDF_RESYNCHRONIZE or
                       BINDF_PRAGMA_NO_CACHE or BINDF_NO_UI or
                       BINDF_SILENTOPERATION

  if optIgnoreSecurity in options:
    bstatus.binfoFlags = bstatus.binfoFlags or BINDF_IGNORESECURITYPROBLEM

  if not isNil(progresscb):
    bstatus.options.incl(optUseProgressCallback)
    bstatus.progressCallback = progresscb

  let res = URLDownloadToFile(nil, bszUrl, bszFile, 0, addr bstatus)
  if FAILED(res):
    freeBindStatusCallback(bstatus)
    freeBstring(bszUrl)
    freeBstring(bszFile)
    raiseOsError(OSErrorCode(res))

  freeBindStatusCallback(bstatus)
  freeBstring(bszUrl)
  freeBstring(bszFile)

when isMainModule:
  proc progress(status: DownloadStatus, progress: uint, progressMax: uint,
                message: string) {.gcsafe.} =
    const downset: set[DownloadStatus] = {statusBeginDownloading,
                                        statusDownloading, statusEndDownloading}
    if status in downset:
      var message = "Downloaded " & $progress & " of " & $progressMax & "\c"
      stdout.write(message)
    else:
      echo "Status [" & $status & "] message = [" & $message & "]"

  downloadToFile("https://nim-lang.org/download/mingw64.7z",
                 "test.zip", {optUseCache}, progress)
