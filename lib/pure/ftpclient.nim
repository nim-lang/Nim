#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Dominik Picheta
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import sockets, strutils, parseutils, times, os, asyncio

## This module **partially** implements an FTP client as specified
## by `RFC 959 <http://tools.ietf.org/html/rfc959>`_. 
## 
## This module provides both a synchronous and asynchronous implementation.
## The asynchronous implementation requires you to use the ``AsyncFTPClient``
## function. You are then required to register the ``PAsyncFTPClient`` with a
## asyncio dispatcher using the ``register`` function. Take a look at the
## asyncio module documentation for more information.
##
## Here is some example usage of this module:
## 
## .. code-block:: Nimrod
##    var ftp = FTPClient("example.org", user = "user", pass = "pass")
##    ftp.connect()
##    ftp.retrFile("file.ext", "file.ext")

type
  TFTPClient* = object of TObject
    csock: TSocket # Command connection socket
    dsock: TSocket # Data connection socket
    user, pass: string
    address: string
    port: TPort
    
    jobInProgress: bool
    job: ref TFTPJob

    isAsync: bool

    dsockStatus: TInfo

  FTPJobType = enum
    JRetrText, JRetr, JStore

  TFTPJob = object
    prc: proc (ftp: var TFTPClient, async: bool): bool {.nimcall.}
    case typ*: FTPJobType
    of JRetrText:
      lines: string
    of JRetr, JStore:
      file: TFile
      filename: string
      total: biggestInt # In bytes.
      progress: biggestInt # In bytes.
      oneSecond: biggestInt # Bytes transferred in one second.
      lastProgressReport: float # Time
      toStore: string # Data left to upload (Only used with async)
    else: nil

  PAsyncFTPClient* = ref TAsyncFTPClient ## Async alternative to TFTPClient.
  TAsyncFTPClient* = object of TFTPClient
    handleEvent*: proc (ftp: var TAsyncFTPClient, ev: TFTPEvent, 
                        userArg: PObject) {.nimcall.}
    dele: PDelegate
    userArg: PObject

  FTPEventType* = enum
    EvTransferProgress, EvLines, EvRetr, EvStore

  TFTPEvent* = object ## Event
    filename*: string
    case typ*: FTPEventType
    of EvLines:
      lines*: string ## Lines that have been transferred.
    of EvRetr, EvStore: nil
    of EvTransferProgress:
      bytesTotal*: biggestInt     ## Bytes total.
      bytesFinished*: biggestInt  ## Bytes transferred.
      speed*: biggestInt          ## Speed in bytes/s

  EInvalidReply* = object of ESynch
  EFTP* = object of ESynch

proc FTPClient*(address: string, port = TPort(21),
                user, pass = ""): TFTPClient =
  ## Create a ``TFTPClient`` object.
  result.user = user
  result.pass = pass
  result.address = address
  result.port = port

  result.isAsync = false
  result.dsockStatus = SockIdle

proc expectReply(ftp: var TFTPClient): TaintedString =
  result = TaintedString""
  if not ftp.csock.recvLine(result): setLen(result.string, 0)

proc send*(ftp: var TFTPClient, m: string): TaintedString =
  ## Send a message to the server, and wait for a primary reply.
  ## ``\c\L`` is added for you.
  ftp.csock.send(m & "\c\L")
  return ftp.expectReply()

proc assertReply(received: TaintedString, expected: string) =
  if not received.string.startsWith(expected):
    raise newException(EInvalidReply,
                       "Expected reply '$1' got: $2" % [
                       expected, received.string])

proc assertReply(received: TaintedString, expected: openarray[string]) =
  for i in items(expected):
    if received.string.startsWith(i): return
  raise newException(EInvalidReply,
                     "Expected reply '$1' got: $2" %
                     [expected.join("' or '"), received.string])

proc createJob(ftp: var TFTPClient,
               prc: proc (ftp: var TFTPClient, async: bool): bool {.nimcall.},
               cmd: FTPJobType) =
  if ftp.jobInProgress:
    raise newException(EFTP, "Unable to do two jobs at once.")
  ftp.jobInProgress = true
  new(ftp.job)
  ftp.job.prc = prc
  ftp.job.typ = cmd
  case cmd
  of JRetrText:
    ftp.job.lines = ""
  of JRetr, JStore:
    ftp.job.toStore = ""

proc deleteJob(ftp: var TFTPClient) =
  assert ftp.jobInProgress
  ftp.jobInProgress = false
  case ftp.job.typ
  of JRetrText:
    ftp.job.lines = ""
  of JRetr, JStore:
    ftp.job.file.close()

proc pasv(ftp: var TFTPClient) =
  ## Negotiate a data connection.
  ftp.dsock = socket()
  if ftp.isAsync: ftp.dsock.setBlocking(false)
  var pasvMsg = ftp.send("PASV").string.strip.TaintedString
  assertReply(pasvMsg, "227")
  var betweenParens = captureBetween(pasvMsg.string, '(', ')')
  var nums = betweenParens.split(',')
  var ip = nums[0.. -3]
  var port = nums[-2.. -1]
  var properPort = port[0].parseInt()*256+port[1].parseInt()
  if ftp.isAsync:
    # connectAsync should work well even if socket is blocking. But we need
    # isAsync anyway... :\
    ftp.dsock.connectAsync(ip.join("."), TPort(properPort.toU16))
    ftp.dsockStatus = SockConnecting
  else:
    ftp.dsock.connect(ip.join("."), TPort(properPort.toU16))
    ftp.dsockStatus = SockConnected

proc normalizePathSep(path: string): string =
  return replace(path, '\\', '/')

proc connect*(ftp: var TFTPClient) =
  ## Connect to the FTP server specified by ``ftp``.
  ftp.csock = socket()
  ftp.csock.connect(ftp.address, ftp.port)

  # TODO: Handle 120? or let user handle it.
  assertReply ftp.expectReply(), "220"

  if ftp.user != "":
    assertReply(ftp.send("USER " & ftp.user), "230", "331")

  if ftp.pass != "":
    assertReply ftp.send("PASS " & ftp.pass), "230"

proc pwd*(ftp: var TFTPClient): string =
  ## Returns the current working directory.
  var wd = ftp.send("PWD")
  assertReply wd, "257"
  return wd.string.captureBetween('"') # "

proc cd*(ftp: var TFTPClient, dir: string) =
  ## Changes the current directory on the remote FTP server to ``dir``.
  assertReply ftp.send("CWD " & dir.normalizePathSep), "250"

proc cdup*(ftp: var TFTPClient) =
  ## Changes the current directory to the parent of the current directory.
  assertReply ftp.send("CDUP"), "200"

proc getLines(ftp: var TFTPClient, async: bool = false): bool =
  ## Downloads text data in ASCII mode
  ## Returns true if the download is complete.
  ## It doesn't if `async` is true, because it doesn't check for 226 then.
  if ftp.dsockStatus == SockConnected:
    var r = TaintedString""
    if ftp.dsock.recvAsync(r):
      if r.string != "":
        ftp.job.lines.add(r.string)
      else:
        ftp.dsockStatus = SockClosed
  
  if not async:
    var readSocks: seq[TSocket] = @[ftp.csock]
    # This is only needed here. Asyncio gets this socket...
    if readSocks.select(1) != 0 and ftp.csock notin readSocks:
      assertReply ftp.expectReply(), "226"
      return true

proc listDirs*(ftp: var TFTPClient, dir: string = "",
               async = false): seq[string] =
  ## Returns a list of filenames in the given directory. If ``dir`` is "",
  ## the current directory is used. If ``async`` is true, this
  ## function will return immediately and it will be your job to
  ## use asyncio's ``poll`` to progress this operation.

  ftp.createJob(getLines, JRetrText)
  ftp.pasv()

  assertReply ftp.send("NLST " & dir.normalizePathSep), ["125", "150"]

  if not async:
    while not ftp.job.prc(ftp, false): nil
    result = splitLines(ftp.job.lines)
    ftp.deleteJob()
  else: return @[]

proc fileExists*(ftp: var TFTPClient, file: string): bool =
  ## Determines whether ``file`` exists.
  ##
  ## Warning: This function may block. Especially on directories with many
  ## files, because a full list of file names must be retrieved.
  var files = ftp.listDirs()
  for f in items(files):
    if f.normalizePathSep == file.normalizePathSep: return true

proc createDir*(ftp: var TFTPClient, dir: string, recursive: bool = false) =
  ## Creates a directory ``dir``. If ``recursive`` is true, the topmost
  ## subdirectory of ``dir`` will be created first, following the secondmost...
  ## etc. this allows you to give a full path as the ``dir`` without worrying
  ## about subdirectories not existing.
  if not recursive:
    assertReply ftp.send("MKD " & dir.normalizePathSep), "257"
  else:
    var reply = TaintedString""
    var previousDirs = ""
    for p in split(dir, {os.dirSep, os.altSep}):
      if p != "":
        previousDirs.add(p)
        reply = ftp.send("MKD " & previousDirs)
        previousDirs.add('/')
    assertReply reply, "257"

proc chmod*(ftp: var TFTPClient, path: string,
            permissions: set[TFilePermission]) =
  ## Changes permission of ``path`` to ``permissions``.
  var userOctal = 0
  var groupOctal = 0
  var otherOctal = 0
  for i in items(permissions):
    case i
    of fpUserExec: userOctal.inc(1)
    of fpUserWrite: userOctal.inc(2)
    of fpUserRead: userOctal.inc(4)
    of fpGroupExec: groupOctal.inc(1)
    of fpGroupWrite: groupOctal.inc(2)
    of fpGroupRead: groupOctal.inc(4)
    of fpOthersExec: otherOctal.inc(1)
    of fpOthersWrite: otherOctal.inc(2)
    of fpOthersRead: otherOctal.inc(4)

  var perm = $userOctal & $groupOctal & $otherOctal
  assertReply ftp.send("SITE CHMOD " & perm &
                       " " & path.normalizePathSep), "200"

proc list*(ftp: var TFTPClient, dir: string = "", async = false): string =
  ## Lists all files in ``dir``. If ``dir`` is ``""``, uses the current
  ## working directory. If ``async`` is true, this function will return
  ## immediately and it will be your job to call asyncio's 
  ## ``poll`` to progress this operation.
  ftp.createJob(getLines, JRetrText)
  ftp.pasv()

  assertReply(ftp.send("LIST" & " " & dir.normalizePathSep), ["125", "150"])

  if not async:
    while not ftp.job.prc(ftp, false): nil
    result = ftp.job.lines
    ftp.deleteJob()
  else:
    return ""

proc retrText*(ftp: var TFTPClient, file: string, async = false): string =
  ## Retrieves ``file``. File must be ASCII text.
  ## If ``async`` is true, this function will return immediately and
  ## it will be your job to call ``poll`` to progress this operation.
  ftp.createJob(getLines, JRetrText)
  ftp.pasv()
  assertReply ftp.send("RETR " & file.normalizePathSep), ["125", "150"]
  
  if not async:
    while not ftp.job.prc(ftp, false): nil
    result = ftp.job.lines
    ftp.deleteJob()
  else:
    return ""

proc getFile(ftp: var TFTPClient, async = false): bool =
  if ftp.dsockStatus == SockConnected:
    var r = "".TaintedString
    var returned = false
    if async: returned = ftp.dsock.recvAsync(r)
    else: 
      r = ftp.dsock.recv()
      returned = true
    let r2 = r.string
    if r2 != "":
      ftp.job.progress.inc(r2.len)
      ftp.job.oneSecond.inc(r2.len)
      ftp.job.file.write(r2)
    elif returned and r2 == "":
      ftp.dsockStatus = SockClosed
  
  if not async:
    var readSocks: seq[TSocket] = @[ftp.csock]
    if readSocks.select(1) != 0 and ftp.csock notin readSocks:
      assertReply ftp.expectReply(), "226"
      return true

proc retrFile*(ftp: var TFTPClient, file, dest: string, async = false) =
  ## Downloads ``file`` and saves it to ``dest``. Usage of this function
  ## asynchronously is recommended to view the progress of the download.
  ## The ``EvRetr`` event is given by ``poll`` when the download is finished,
  ## and the ``filename`` field will be equal to ``file``.
  ftp.createJob(getFile, JRetr)
  ftp.job.file = open(dest, mode = fmWrite)
  ftp.pasv()
  var reply = ftp.send("RETR " & file.normalizePathSep)
  assertReply reply, ["125", "150"]
  if {'(', ')'} notin reply.string:
    raise newException(EInvalidReply, "Reply has no file size.")
  var fileSize: biggestInt
  if reply.string.captureBetween('(', ')').parseBiggestInt(fileSize) == 0:
    raise newException(EInvalidReply, "Reply has no file size.")
    
  ftp.job.total = fileSize
  ftp.job.lastProgressReport = epochTime()
  ftp.job.filename = file.normalizePathSep

  if not async:
    while not ftp.job.prc(ftp, false): nil
    ftp.deleteJob()

proc doUpload(ftp: var TFTPClient, async = false): bool =
  if ftp.dsockStatus == SockConnected:
    if ftp.job.toStore.len() > 0:
      assert(async)
      if ftp.dsock.sendAsync(ftp.job.toStore):
        ftp.job.toStore = ""
        ftp.job.progress.inc(ftp.job.toStore.len)
        ftp.job.oneSecond.inc(ftp.job.toStore.len)
      
    else:
      var s = newStringOfCap(4000)
      var len = ftp.job.file.readBuffer(addr(s[0]), 4000)
      setLen(s, len)
      if len == 0:
        # File finished uploading.
        ftp.dsock.close()
        ftp.dsockStatus = SockClosed
  
        if not async:
          assertReply ftp.expectReply(), "226"
          return true
        return false
    
      if not async:
        ftp.dsock.send(s)
      else:
        if not ftp.dsock.sendAsync(s):
          ftp.job.toStore = s
      
      ftp.job.progress.inc(len)
      ftp.job.oneSecond.inc(len)

proc store*(ftp: var TFTPClient, file, dest: string, async = false) =
  ## Uploads ``file`` to ``dest`` on the remote FTP server. Usage of this
  ## function asynchronously is recommended to view the progress of
  ## the download.
  ## The ``EvStore`` event is given by ``poll`` when the upload is finished,
  ## and the ``filename`` field will be equal to ``file``.
  ftp.createJob(doUpload, JStore)
  ftp.job.file = open(file)
  ftp.job.total = ftp.job.file.getFileSize()
  ftp.job.lastProgressReport = epochTime()
  ftp.job.filename = file
  ftp.pasv()
  
  assertReply ftp.send("STOR " & dest.normalizePathSep), ["125", "150"]

  if not async:
    while not ftp.job.prc(ftp, false): nil
    ftp.deleteJob()

proc close*(ftp: var TFTPClient) =
  ## Terminates the connection to the server.
  assertReply ftp.send("QUIT"), "221"
  if ftp.jobInProgress: ftp.deleteJob()
  ftp.csock.close()
  ftp.dsock.close()

proc handleTask(h: PObject) =
  var ftp = PAsyncFTPClient(h)
  if ftp.jobInProgress:
    if ftp.job.typ in {JRetr, JStore}:
      if epochTime() - ftp.job.lastProgressReport >= 1.0:
        var r: TFTPEvent
        ftp.job.lastProgressReport = epochTime()
        r.typ = EvTransferProgress
        r.bytesTotal = ftp.job.total
        r.bytesFinished = ftp.job.progress
        r.speed = ftp.job.oneSecond
        r.filename = ftp.job.filename
        ftp.job.oneSecond = 0
        ftp.handleEvent(ftp[], r, ftp.userArg)

proc getSocket(h: PObject): tuple[info: TInfo, sock: TSocket] =
  result = (SockIdle, InvalidSocket)
  var ftp = PAsyncFTPClient(h)
  if ftp.jobInProgress:
    case ftp.job.typ
    of JRetrText, JRetr, JStore:
      if ftp.dsockStatus == SockConnecting or ftp.dsockStatus == SockConnected:
        result = (ftp.dsockStatus, ftp.dsock)
      else: result = (SockIdle, ftp.dsock)

proc handleConnect(h: PObject) =
  var ftp = PAsyncFTPClient(h)
  ftp.dsockStatus = SockConnected
  assert(ftp.jobInProgress)
  if ftp.job.typ == JStore:
    ftp.dele.mode = MWriteable
  else: 
    ftp.dele.mode = MReadable

proc handleRead(h: PObject) =
  var ftp = PAsyncFTPClient(h)
  assert(ftp.jobInProgress)
  assert(ftp.job.typ != JStore)
  # This can never return true, because it shouldn't check for code 
  # 226 from csock.
  assert(not ftp.job.prc(ftp[], true))

proc handleWrite(h: PObject) =
  var ftp = PAsyncFTPClient(h)
  if ftp.jobInProgress:
    if ftp.job.typ == JStore:
      assert (not ftp.job.prc(ftp[], true))

proc csockGetSocket(h: PObject): tuple[info: TInfo, sock: TSocket] =
  # This only returns the csock if a job is in progress. Otherwise handle read
  # would capture data which is not for it to capture.
  result = (SockIdle, InvalidSocket)
  var ftp = PAsyncFTPClient(h)
  if ftp.jobInProgress:
    result = (SockConnected, ftp.csock)

proc csockHandleRead(h: PObject) =
  var ftp = PAsyncFTPClient(h)
  assert(ftp.jobInProgress)
  assertReply ftp[].expectReply(), "226" # Make sure the transfer completed.
  var r: TFTPEvent
  case ftp.job.typ
  of JRetrText:
    r.typ = EvLines
    r.lines = ftp.job.lines
  of JRetr:
    r.typ = EvRetr
    r.filename = ftp.job.filename
    if ftp.job.progress != ftp.job.total:
      raise newException(EFTP, "Didn't download full file.")
  of JStore:
    r.typ = EvStore
    r.filename = ftp.job.filename
    if ftp.job.progress != ftp.job.total:
      raise newException(EFTP, "Didn't upload full file.")
  ftp[].deleteJob()
  ftp.handleEvent(ftp[], r, ftp.userArg)

proc AsyncFTPClient*(address: string, port = TPort(21),
                     user, pass = "", userArg: PObject = nil): PAsyncFTPClient =
  ## Create a ``PAsyncFTPClient`` object.
  ##
  ## Use this if you want to use asyncio's dispatcher.
  new(result)
  result.user = user
  result.pass = pass
  result.address = address
  result.port = port
  result.isAsync = true
  result.dsockStatus = SockIdle
  result.userArg = userArg
  result.handleEvent = (proc (ftp: var TAsyncFTPClient, ev: TFTPEvent,
                               userArg: PObject) = nil)

proc register*(d: PDispatcher, ftp: PAsyncFTPClient) =
  ## Registers ``ftp`` with dispatcher ``d``.
  ftp.dele = newDelegate()
  ftp.dele.deleVal = ftp
  ftp.dele.getSocket = getSocket
  ftp.dele.task = handleTask
  ftp.dele.handleConnect = handleConnect
  ftp.dele.handleRead = handleRead
  ftp.dele.handleWrite = handleWrite
  d.register(ftp.dele)

  # Add csock into the dispatcher (to check for 226).
  var cDele = newDelegate()
  cDele.deleVal = ftp
  cDele.getSocket = csockGetSocket
  cDele.handleRead = csockHandleRead
  d.register(cDele)

when isMainModule:
  var ftp = FTPClient("picheta.me", user = "blah", pass = "sd")
  ftp.connect()
  echo ftp.pwd()
  echo ftp.list()
  echo("uploading")
  ftp.store("payload.avi", "payload.avi", async = false)
  discard """
  while True:
    var event: TFTPEvent
    if ftp.poll(event):
      case event.typ
      of EvStore:
        echo("Upload finished!")
        break
      of EvTransferProgress:
        var time: int64 = -1
        if event.speed != 0:
          time = (event.bytesTotal - event.bytesFinished) div event.speed
        echo(event.speed div 1000, " kb/s. - ",
             event.bytesFinished, "/", event.bytesTotal,
             " - ", time, " seconds")

      else: assert(false)
  """
  echo("Upload complete")
  ftp.retrFile("payload.avi", "payload2.avi", async = false)
  discard """
  while True:
    var event: TFTPEvent
    if ftp.poll(event):
      case event.typ
      of EvRetr:
        echo("Download finished!")
        break
      of EvTransferProgress:
        echo(event.speed div 1000, " kb/s")
      else: assert(false)
  """
  echo("Download complete")
  sleep(5000)
  ftp.close()
  sleep(200)
