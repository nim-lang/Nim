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
## **Note**: The asynchronous implementation is only asynchronous for long
## file transfers, calls to functions which use the command socket will block.
##
## Here is some example usage of this module:
##
## .. code-block:: Nimrod
##    var ftp = FTPClient("example.org", user = "user", pass = "pass")
##    ftp.connect()
##    ftp.retrFile("file.ext", "file.ext")
##
## **Warning:** The API of this module is unstable, and therefore is subject
## to change.


type
  TFTPClient* = object of TObject
    case isAsync: bool
    of false:
      csock: TSocket # Command connection socket
      dsock: TSocket # Data connection socket
    else:
      dummyA, dummyB: pointer # workaround a Nimrod API issue
      asyncCSock: PAsyncSocket
      asyncDSock: PAsyncSocket
      handleEvent*: proc (ftp: PAsyncFTPClient, ev: TFTPEvent) {.closure.}
      disp: PDispatcher
      asyncDSockID: PDelegate
    user, pass: string
    address: string
    port: TPort

    jobInProgress: bool
    job: ref TFTPJob

    dsockConnected: bool

  PFTPClient* = ref TFTPClient

  FTPJobType* = enum
    JRetrText, JRetr, JStore

  TFTPJob = object
    prc: proc (ftp: PFTPClient, async: bool): bool {.nimcall.}
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

  FTPEventType* = enum
    EvTransferProgress, EvLines, EvRetr, EvStore

  TFTPEvent* = object ## Event
    filename*: string
    case typ*: FTPEventType
    of EvLines:
      lines*: string ## Lines that have been transferred.
    of EvRetr, EvStore: ## Retr/Store operation finished.
      nil
    of EvTransferProgress:
      bytesTotal*: biggestInt     ## Bytes total.
      bytesFinished*: biggestInt  ## Bytes transferred.
      speed*: biggestInt          ## Speed in bytes/s
      currentJob*: FTPJobType     ## The current job being performed.

  EInvalidReply* = object of ESynch
  EFTP* = object of ESynch

proc FTPClient*(address: string, port = TPort(21),
                user, pass = ""): PFTPClient =
  ## Create a ``PFTPClient`` object.
  new(result)
  result.user = user
  result.pass = pass
  result.address = address
  result.port = port

  result.isAsync = false
  result.dsockConnected = false
  result.csock = socket()

proc getDSock(ftp: PFTPClient): TSocket =
  if ftp.isAsync: return ftp.asyncDSock else: return ftp.dsock

proc getCSock(ftp: PFTPClient): TSocket =
  if ftp.isAsync: return ftp.asyncCSock else: return ftp.csock

template blockingOperation(sock: TSocket, body: stmt) {.immediate.} =
  if ftp.isAsync:
    sock.setBlocking(true)
  body
  if ftp.isAsync:
    sock.setBlocking(false)

proc expectReply(ftp: PFTPClient): TaintedString =
  result = TaintedString""
  blockingOperation(ftp.getCSock()):
    ftp.getCSock().readLine(result)

proc send*(ftp: PFTPClient, m: string): TaintedString =
  ## Send a message to the server, and wait for a primary reply.
  ## ``\c\L`` is added for you.
  blockingOperation(ftp.getCSock()):
    ftp.getCSock().send(m & "\c\L")
  return ftp.expectReply()

proc assertReply(received: TaintedString, expected: string) =
  if not received.string.startsWith(expected):
    raise newException(EInvalidReply,
                       "Expected reply '$1' got: $2" % [
                       expected, received.string])

proc assertReply(received: TaintedString, expected: varargs[string]) =
  for i in items(expected):
    if received.string.startsWith(i): return
  raise newException(EInvalidReply,
                     "Expected reply '$1' got: $2" %
                     [expected.join("' or '"), received.string])

proc createJob(ftp: PFTPClient,
               prc: proc (ftp: PFTPClient, async: bool): bool {.nimcall.},
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

proc deleteJob(ftp: PFTPClient) =
  assert ftp.jobInProgress
  ftp.jobInProgress = false
  case ftp.job.typ
  of JRetrText:
    ftp.job.lines = ""
  of JRetr, JStore:
    ftp.job.file.close()
  if ftp.isAsync:
    ftp.asyncDSock.close()
  else:
    ftp.dsock.close()

proc handleTask(s: PAsyncSocket, ftp: PFTPClient) =
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
        r.currentJob = ftp.job.typ
        ftp.job.oneSecond = 0
        ftp.handleEvent(PAsyncFTPClient(ftp), r)

proc handleWrite(s: PAsyncSocket, ftp: PFTPClient) =
  if ftp.jobInProgress:
    if ftp.job.typ == JStore:
      assert (not ftp.job.prc(ftp, true))

proc handleConnect(s: PAsyncSocket, ftp: PFTPClient) =
  ftp.dsockConnected = true
  assert(ftp.jobInProgress)
  if ftp.job.typ == JStore:
    s.setHandleWrite(proc (s: PAsyncSocket) = handleWrite(s, ftp))
  else:
    s.delHandleWrite()

proc handleRead(s: PAsyncSocket, ftp: PFTPClient) =
  assert ftp.jobInProgress
  assert ftp.job.typ != JStore
  # This can never return true, because it shouldn't check for code
  # 226 from csock.
  assert(not ftp.job.prc(ftp, true))

proc pasv(ftp: PFTPClient) =
  ## Negotiate a data connection.
  if not ftp.isAsync:
    ftp.dsock = socket()
  else:
    ftp.asyncDSock = AsyncSocket()
    ftp.asyncDSock.handleRead =
      proc (s: PAsyncSocket) =
        handleRead(s, ftp)
    ftp.asyncDSock.handleConnect =
      proc (s: PAsyncSocket) =
        handleConnect(s, ftp)
    ftp.asyncDSock.handleTask =
      proc (s: PAsyncSocket) =
        handleTask(s, ftp)
    ftp.disp.register(ftp.asyncDSock)

  var pasvMsg = ftp.send("PASV").string.strip.TaintedString
  assertReply(pasvMsg, "227")
  var betweenParens = captureBetween(pasvMsg.string, '(', ')')
  var nums = betweenParens.split(',')
  var ip = nums[0.. -3]
  var port = nums[-2.. -1]
  var properPort = port[0].parseInt()*256+port[1].parseInt()
  if ftp.isAsync:
    ftp.asyncDSock.connect(ip.join("."), TPort(properPort.toU16))
    ftp.dsockConnected = False
  else:
    ftp.dsock.connect(ip.join("."), TPort(properPort.toU16))
    ftp.dsockConnected = True

proc normalizePathSep(path: string): string =
  return replace(path, '\\', '/')

proc connect*(ftp: PFTPClient) =
  ## Connect to the FTP server specified by ``ftp``.
  if ftp.isAsync:
    blockingOperation(ftp.asyncCSock):
      ftp.asyncCSock.connect(ftp.address, ftp.port)
  else:
    ftp.csock.connect(ftp.address, ftp.port)

  # TODO: Handle 120? or let user handle it.
  assertReply ftp.expectReply(), "220"

  if ftp.user != "":
    assertReply(ftp.send("USER " & ftp.user), "230", "331")

  if ftp.pass != "":
    assertReply ftp.send("PASS " & ftp.pass), "230"

proc pwd*(ftp: PFTPClient): string =
  ## Returns the current working directory.
  var wd = ftp.send("PWD")
  assertReply wd, "257"
  return wd.string.captureBetween('"') # "

proc cd*(ftp: PFTPClient, dir: string) =
  ## Changes the current directory on the remote FTP server to ``dir``.
  assertReply ftp.send("CWD " & dir.normalizePathSep), "250"

proc cdup*(ftp: PFTPClient) =
  ## Changes the current directory to the parent of the current directory.
  assertReply ftp.send("CDUP"), "200"

proc getLines(ftp: PFTPClient, async: bool = false): bool =
  ## Downloads text data in ASCII mode
  ## Returns true if the download is complete.
  ## It doesn't if `async` is true, because it doesn't check for 226 then.
  if ftp.dsockConnected:
    var r = TaintedString""
    if ftp.isAsync:
      if ftp.asyncDSock.readLine(r):
        if r.string == "":
          ftp.dsockConnected = false
        else:
          ftp.job.lines.add(r.string & "\n")
    else:
      assert(not async)
      ftp.dsock.readLine(r)
      if r.string == "":
        ftp.dsockConnected = false
      else:
        ftp.job.lines.add(r.string & "\n")

  if not async:
    var readSocks: seq[TSocket] = @[ftp.getCSock()]
    # This is only needed here. Asyncio gets this socket...
    blockingOperation(ftp.getCSock()):
      if readSocks.select(1) != 0 and ftp.getCSock() notin readSocks:
        assertReply ftp.expectReply(), "226"
        return true

proc listDirs*(ftp: PFTPClient, dir: string = "",
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

proc fileExists*(ftp: PFTPClient, file: string): bool {.deprecated.} =
  ## **Deprecated since version 0.9.0:** Please use ``existsFile``.
  ##
  ## Determines whether ``file`` exists.
  ##
  ## Warning: This function may block. Especially on directories with many
  ## files, because a full list of file names must be retrieved.
  var files = ftp.listDirs()
  for f in items(files):
    if f.normalizePathSep == file.normalizePathSep: return true

proc existsFile*(ftp: PFTPClient, file: string): bool =
  ## Determines whether ``file`` exists.
  ##
  ## Warning: This function may block. Especially on directories with many
  ## files, because a full list of file names must be retrieved.
  var files = ftp.listDirs()
  for f in items(files):
    if f.normalizePathSep == file.normalizePathSep: return true

proc createDir*(ftp: PFTPClient, dir: string, recursive: bool = false) =
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

proc chmod*(ftp: PFTPClient, path: string,
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

proc list*(ftp: PFTPClient, dir: string = "", async = false): string =
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

proc retrText*(ftp: PFTPClient, file: string, async = false): string =
  ## Retrieves ``file``. File must be ASCII text.
  ## If ``async`` is true, this function will return immediately and
  ## it will be your job to call asyncio's ``poll`` to progress this operation.
  ftp.createJob(getLines, JRetrText)
  ftp.pasv()
  assertReply ftp.send("RETR " & file.normalizePathSep), ["125", "150"]

  if not async:
    while not ftp.job.prc(ftp, false): nil
    result = ftp.job.lines
    ftp.deleteJob()
  else:
    return ""

proc getFile(ftp: PFTPClient, async = false): bool =
  if ftp.dsockConnected:
    var r = "".TaintedString
    var bytesRead = 0
    var returned = false
    if async:
      if not ftp.isAsync: raise newException(EFTP, "FTPClient must be async.")
      bytesRead = ftp.AsyncDSock.recvAsync(r, BufferSize)
      returned = bytesRead != -1
    else:
      bytesRead = getDSock(ftp).recv(r, BufferSize)
      returned = true
    let r2 = r.string
    if r2 != "":
      ftp.job.progress.inc(r2.len)
      ftp.job.oneSecond.inc(r2.len)
      ftp.job.file.write(r2)
    elif returned and r2 == "":
      ftp.dsockConnected = False

  if not async:
    var readSocks: seq[TSocket] = @[ftp.getCSock()]
    blockingOperation(ftp.getCSock()):
      if readSocks.select(1) != 0 and ftp.getCSock() notin readSocks:
        assertReply ftp.expectReply(), "226"
        return true

proc retrFile*(ftp: PFTPClient, file, dest: string, async = false) =
  ## Downloads ``file`` and saves it to ``dest``. Usage of this function
  ## asynchronously is recommended to view the progress of the download.
  ## The ``EvRetr`` event is passed to the specified ``handleEvent`` function
  ## when the download is finished, and the ``filename`` field will be equal
  ## to ``file``.
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

proc doUpload(ftp: PFTPClient, async = false): bool =
  if ftp.dsockConnected:
    if ftp.job.toStore.len() > 0:
      assert(async)
      let bytesSent = ftp.asyncDSock.sendAsync(ftp.job.toStore)
      if bytesSent == ftp.job.toStore.len:
        ftp.job.toStore = ""
      elif bytesSent != ftp.job.toStore.len and bytesSent != 0:
        ftp.job.toStore = ftp.job.toStore[bytesSent .. -1]
      ftp.job.progress.inc(bytesSent)
      ftp.job.oneSecond.inc(bytesSent)
    else:
      var s = newStringOfCap(4000)
      var len = ftp.job.file.readBuffer(addr(s[0]), 4000)
      setLen(s, len)
      if len == 0:
        # File finished uploading.
        if ftp.isAsync: ftp.asyncDSock.close() else: ftp.dsock.close()
        ftp.dsockConnected = false

        if not async:
          assertReply ftp.expectReply(), "226"
          return true
        return false

      if not async:
        getDSock(ftp).send(s)
      else:
        let bytesSent = ftp.asyncDSock.sendAsync(s)
        if bytesSent == 0:
          ftp.job.toStore.add(s)
        elif bytesSent != s.len:
          ftp.job.toStore.add(s[bytesSent .. -1])
        len = bytesSent

      ftp.job.progress.inc(len)
      ftp.job.oneSecond.inc(len)

proc store*(ftp: PFTPClient, file, dest: string, async = false) =
  ## Uploads ``file`` to ``dest`` on the remote FTP server. Usage of this
  ## function asynchronously is recommended to view the progress of
  ## the download.
  ## The ``EvStore`` event is passed to the specified ``handleEvent`` function
  ## when the upload is finished, and the ``filename`` field will be
  ## equal to ``file``.
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

proc close*(ftp: PFTPClient) =
  ## Terminates the connection to the server.
  assertReply ftp.send("QUIT"), "221"
  if ftp.jobInProgress: ftp.deleteJob()
  if ftp.isAsync:
    ftp.asyncCSock.close()
    ftp.asyncDSock.close()
  else:
    ftp.csock.close()
    ftp.dsock.close()

proc csockHandleRead(s: PAsyncSocket, ftp: PAsyncFTPClient) =
  if ftp.jobInProgress:
    assertReply ftp.expectReply(), "226" # Make sure the transfer completed.
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
    ftp.deleteJob()

    ftp.handleEvent(ftp, r)

proc AsyncFTPClient*(address: string, port = TPort(21),
                     user, pass = "",
    handleEvent: proc (ftp: PAsyncFTPClient, ev: TFTPEvent) {.closure.} =
      (proc (ftp: PAsyncFTPClient, ev: TFTPEvent) = nil)): PAsyncFTPClient =
  ## Create a ``PAsyncFTPClient`` object.
  ##
  ## Use this if you want to use asyncio's dispatcher.
  var dres: PAsyncFTPClient
  new(dres)
  dres.user = user
  dres.pass = pass
  dres.address = address
  dres.port = port
  dres.isAsync = true
  dres.dsockConnected = false
  dres.handleEvent = handleEvent
  dres.asyncCSock = AsyncSocket()
  dres.asyncCSock.handleRead =
    proc (s: PAsyncSocket) =
      csockHandleRead(s, dres)
  result = dres

proc register*(d: PDispatcher, ftp: PAsyncFTPClient): PDelegate {.discardable.} =
  ## Registers ``ftp`` with dispatcher ``d``.
  assert ftp.isAsync
  ftp.disp = d
  return ftp.disp.register(ftp.asyncCSock)

when isMainModule:
  var d = newDispatcher()
  let hev =
    proc (ftp: PAsyncFTPClient, event: TFTPEvent) =
      case event.typ
      of EvStore:
        echo("Upload finished!")
        ftp.retrFile("payload.JPG", "payload2.JPG", async = true)
      of EvTransferProgress:
        var time: int64 = -1
        if event.speed != 0:
          time = (event.bytesTotal - event.bytesFinished) div event.speed
        echo(event.currentJob)
        echo(event.speed div 1000, " kb/s. - ",
             event.bytesFinished, "/", event.bytesTotal,
             " - ", time, " seconds")
        echo(d.len)
      of EvRetr:
        echo("Download finished!")
        ftp.close()
        echo d.len
      else: assert(false)
  var ftp = AsyncFTPClient("picheta.me", user = "test", pass = "asf", handleEvent = hev)

  d.register(ftp)
  d.len.echo()
  ftp.connect()
  echo "connected"
  ftp.store("payload.JPG", "payload.JPG", async = true)
  d.len.echo()
  echo "uploading..."
  while true:
    if not d.poll(): break


when isMainModule and false:
  var ftp = FTPClient("picheta.me", user = "asdasd", pass = "asfwq")
  ftp.connect()
  echo ftp.pwd()
  echo ftp.list()
  echo("uploading")
  ftp.store("payload.JPG", "payload.JPG", async = false)

  echo("Upload complete")
  ftp.retrFile("payload.JPG", "payload2.JPG", async = false)

  echo("Download complete")
  sleep(5000)
  ftp.close()
  sleep(200)
