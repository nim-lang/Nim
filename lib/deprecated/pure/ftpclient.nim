#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Dominik Picheta
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

include "system/inclrtl"

import sockets, strutils, parseutils, times, os, asyncio

from asyncnet import nil
from nativesockets import nil
from asyncdispatch import Future
## **Note**: This module is deprecated since version 0.11.3.
## You should use the async version of this module
## `asyncftpclient <asyncftpclient.html>`_.
##
## ----
##
## This module **partially** implements an FTP client as specified
## by `RFC 959 <http://tools.ietf.org/html/rfc959>`_.
##
## This module provides both a synchronous and asynchronous implementation.
## The asynchronous implementation requires you to use the ``asyncFTPClient``
## function. You are then required to register the ``AsyncFTPClient`` with a
## asyncio dispatcher using the ``register`` function. Take a look at the
## asyncio module documentation for more information.
##
## **Note**: The asynchronous implementation is only asynchronous for long
## file transfers, calls to functions which use the command socket will block.
##
## Here is some example usage of this module:
##
## .. code-block:: Nim
##    var ftp = ftpClient("example.org", user = "user", pass = "pass")
##    ftp.connect()
##    ftp.retrFile("file.ext", "file.ext")
##
## **Warning:** The API of this module is unstable, and therefore is subject
## to change.

{.deprecated.}

type
  FtpBase*[SockType] = ref FtpBaseObj[SockType]
  FtpBaseObj*[SockType] = object
    csock*: SockType
    dsock*: SockType
    when SockType is asyncio.AsyncSocket:
      handleEvent*: proc (ftp: AsyncFTPClient, ev: FTPEvent){.closure,gcsafe.}
      disp: Dispatcher
      asyncDSockID: Delegate
    user*, pass*: string
    address*: string
    when SockType is asyncnet.AsyncSocket:
      port*: nativesockets.Port
    else:
      port*: Port

    jobInProgress*: bool
    job*: FTPJob[SockType]

    dsockConnected*: bool

  FTPJobType* = enum
    JRetrText, JRetr, JStore

  FtpJob[T] = ref FtpJobObj[T]
  FTPJobObj[T] = object
    prc: proc (ftp: FTPBase[T], async: bool): bool {.nimcall, gcsafe.}
    case typ*: FTPJobType
    of JRetrText:
      lines: string
    of JRetr, JStore:
      file: File
      filename: string
      total: BiggestInt # In bytes.
      progress: BiggestInt # In bytes.
      oneSecond: BiggestInt # Bytes transferred in one second.
      lastProgressReport: float # Time
      toStore: string # Data left to upload (Only used with async)
    else: nil

  FtpClientObj* = FtpBaseObj[Socket]
  FtpClient* = ref FtpClientObj

  AsyncFtpClient* = ref AsyncFtpClientObj ## Async alternative to TFTPClient.
  AsyncFtpClientObj* = FtpBaseObj[asyncio.AsyncSocket]

  FTPEventType* = enum
    EvTransferProgress, EvLines, EvRetr, EvStore

  FTPEvent* = object ## Event
    filename*: string
    case typ*: FTPEventType
    of EvLines:
      lines*: string ## Lines that have been transferred.
    of EvRetr, EvStore: ## Retr/Store operation finished.
      nil
    of EvTransferProgress:
      bytesTotal*: BiggestInt     ## Bytes total.
      bytesFinished*: BiggestInt  ## Bytes transferred.
      speed*: BiggestInt          ## Speed in bytes/s
      currentJob*: FTPJobType     ## The current job being performed.

  ReplyError* = object of IOError
  FTPError* = object of IOError

{.deprecated: [
  TFTPClient: FTPClientObj, TFTPJob: FTPJob, PAsyncFTPClient: AsyncFTPClient,
  TAsyncFTPClient: AsyncFTPClientObj, TFTPEvent: FTPEvent,
  EInvalidReply: ReplyError, EFTP: FTPError
].}

const multiLineLimit = 10000

proc ftpClient*(address: string, port = Port(21),
                user, pass = ""): FtpClient =
  ## Create a ``FtpClient`` object.
  new(result)
  result.user = user
  result.pass = pass
  result.address = address
  result.port = port

  result.dsockConnected = false
  result.csock = socket()
  if result.csock == invalidSocket: raiseOSError(osLastError())

template blockingOperation(sock: Socket, body: untyped) =
  body

template blockingOperation(sock: asyncio.AsyncSocket, body: untyped) =
  sock.setBlocking(true)
  body
  sock.setBlocking(false)

proc expectReply[T](ftp: FtpBase[T]): TaintedString =
  result = TaintedString""
  blockingOperation(ftp.csock):
    when T is Socket:
      ftp.csock.readLine(result)
    else:
      discard ftp.csock.readLine(result)
    var count = 0
    while result[3] == '-':
      ## Multi-line reply.
      var line = TaintedString""
      when T is Socket:
        ftp.csock.readLine(line)
      else:
        discard ftp.csock.readLine(line)
      result.add("\n" & line)
      count.inc()
      if count >= multiLineLimit:
        raise newException(ReplyError, "Reached maximum multi-line reply count.")

proc send*[T](ftp: FtpBase[T], m: string): TaintedString =
  ## Send a message to the server, and wait for a primary reply.
  ## ``\c\L`` is added for you.
  ##
  ## **Note:** The server may return multiple lines of coded replies.
  blockingOperation(ftp.csock):
    ftp.csock.send(m & "\c\L")
  return ftp.expectReply()

proc assertReply(received: TaintedString, expected: string) =
  if not received.string.startsWith(expected):
    raise newException(ReplyError,
                       "Expected reply '$1' got: $2" % [
                       expected, received.string])

proc assertReply(received: TaintedString, expected: varargs[string]) =
  for i in items(expected):
    if received.string.startsWith(i): return
  raise newException(ReplyError,
                     "Expected reply '$1' got: $2" %
                     [expected.join("' or '"), received.string])

proc createJob[T](ftp: FtpBase[T],
               prc: proc (ftp: FtpBase[T], async: bool): bool {.
                          nimcall,gcsafe.},
               cmd: FTPJobType) =
  if ftp.jobInProgress:
    raise newException(FTPError, "Unable to do two jobs at once.")
  ftp.jobInProgress = true
  new(ftp.job)
  ftp.job.prc = prc
  ftp.job.typ = cmd
  case cmd
  of JRetrText:
    ftp.job.lines = ""
  of JRetr, JStore:
    ftp.job.toStore = ""

proc deleteJob[T](ftp: FtpBase[T]) =
  assert ftp.jobInProgress
  ftp.jobInProgress = false
  case ftp.job.typ
  of JRetrText:
    ftp.job.lines = ""
  of JRetr, JStore:
    ftp.job.file.close()
  ftp.dsock.close()

proc handleTask(s: AsyncSocket, ftp: AsyncFTPClient) =
  if ftp.jobInProgress:
    if ftp.job.typ in {JRetr, JStore}:
      if epochTime() - ftp.job.lastProgressReport >= 1.0:
        var r: FTPEvent
        ftp.job.lastProgressReport = epochTime()
        r.typ = EvTransferProgress
        r.bytesTotal = ftp.job.total
        r.bytesFinished = ftp.job.progress
        r.speed = ftp.job.oneSecond
        r.filename = ftp.job.filename
        r.currentJob = ftp.job.typ
        ftp.job.oneSecond = 0
        ftp.handleEvent(ftp, r)

proc handleWrite(s: AsyncSocket, ftp: AsyncFTPClient) =
  if ftp.jobInProgress:
    if ftp.job.typ == JStore:
      assert (not ftp.job.prc(ftp, true))

proc handleConnect(s: AsyncSocket, ftp: AsyncFTPClient) =
  ftp.dsockConnected = true
  assert(ftp.jobInProgress)
  if ftp.job.typ == JStore:
    s.setHandleWrite(proc (s: AsyncSocket) = handleWrite(s, ftp))
  else:
    s.delHandleWrite()

proc handleRead(s: AsyncSocket, ftp: AsyncFTPClient) =
  assert ftp.jobInProgress
  assert ftp.job.typ != JStore
  # This can never return true, because it shouldn't check for code
  # 226 from csock.
  assert(not ftp.job.prc(ftp, true))

proc pasv[T](ftp: FtpBase[T]) =
  ## Negotiate a data connection.
  when T is Socket:
    ftp.dsock = socket()
    if ftp.dsock == invalidSocket: raiseOSError(osLastError())
  elif T is AsyncSocket:
    ftp.dsock = asyncSocket()
    ftp.dsock.handleRead =
      proc (s: AsyncSocket) =
        handleRead(s, ftp)
    ftp.dsock.handleConnect =
      proc (s: AsyncSocket) =
        handleConnect(s, ftp)
    ftp.dsock.handleTask =
      proc (s: AsyncSocket) =
        handleTask(s, ftp)
    ftp.disp.register(ftp.dsock)
  else:
    {.fatal: "Incorrect socket instantiation".}

  var pasvMsg = ftp.send("PASV").string.strip.TaintedString
  assertReply(pasvMsg, "227")
  var betweenParens = captureBetween(pasvMsg.string, '(', ')')
  var nums = betweenParens.split(',')
  var ip = nums[0.. ^3]
  var port = nums[^2.. ^1]
  var properPort = port[0].parseInt()*256+port[1].parseInt()
  ftp.dsock.connect(ip.join("."), Port(properPort.toU16))
  when T is AsyncSocket:
    ftp.dsockConnected = false
  else:
    ftp.dsockConnected = true

proc normalizePathSep(path: string): string =
  return replace(path, '\\', '/')

proc connect*[T](ftp: FtpBase[T]) =
  ## Connect to the FTP server specified by ``ftp``.
  when T is AsyncSocket:
    blockingOperation(ftp.csock):
      ftp.csock.connect(ftp.address, ftp.port)
  elif T is Socket:
    ftp.csock.connect(ftp.address, ftp.port)
  else:
    {.fatal: "Incorrect socket instantiation".}

  var reply = ftp.expectReply()
  if reply.startsWith("120"):
    # 120 Service ready in nnn minutes.
    # We wait until we receive 220.
    reply = ftp.expectReply()

  # Handle 220 messages from the server
  assertReply ftp.expectReply(), "220"

  if ftp.user != "":
    assertReply(ftp.send("USER " & ftp.user), "230", "331")

  if ftp.pass != "":
    assertReply ftp.send("PASS " & ftp.pass), "230"

proc pwd*[T](ftp: FtpBase[T]): string =
  ## Returns the current working directory.
  var wd = ftp.send("PWD")
  assertReply wd, "257"
  return wd.string.captureBetween('"') # "

proc cd*[T](ftp: FtpBase[T], dir: string) =
  ## Changes the current directory on the remote FTP server to ``dir``.
  assertReply ftp.send("CWD " & dir.normalizePathSep), "250"

proc cdup*[T](ftp: FtpBase[T]) =
  ## Changes the current directory to the parent of the current directory.
  assertReply ftp.send("CDUP"), "200"

proc getLines[T](ftp: FtpBase[T], async: bool = false): bool =
  ## Downloads text data in ASCII mode
  ## Returns true if the download is complete.
  ## It doesn't if `async` is true, because it doesn't check for 226 then.
  if ftp.dsockConnected:
    var r = TaintedString""
    when T is AsyncSocket:
      if ftp.asyncDSock.readLine(r):
        if r.string == "":
          ftp.dsockConnected = false
        else:
          ftp.job.lines.add(r.string & "\n")
    elif T is Socket:
      assert(not async)
      ftp.dsock.readLine(r)
      if r.string == "":
        ftp.dsockConnected = false
      else:
        ftp.job.lines.add(r.string & "\n")
    else:
      {.fatal: "Incorrect socket instantiation".}

  if not async:
    var readSocks: seq[Socket] = @[ftp.csock]
    # This is only needed here. Asyncio gets this socket...
    blockingOperation(ftp.csock):
      if readSocks.select(1) != 0 and ftp.csock in readSocks:
        assertReply ftp.expectReply(), "226"
        return true

proc listDirs*[T](ftp: FtpBase[T], dir: string = "",
               async = false): seq[string] =
  ## Returns a list of filenames in the given directory. If ``dir`` is "",
  ## the current directory is used. If ``async`` is true, this
  ## function will return immediately and it will be your job to
  ## use asyncio's ``poll`` to progress this operation.

  ftp.createJob(getLines[T], JRetrText)
  ftp.pasv()

  assertReply ftp.send("NLST " & dir.normalizePathSep), ["125", "150"]

  if not async:
    while not ftp.job.prc(ftp, false): discard
    result = splitLines(ftp.job.lines)
    ftp.deleteJob()
  else: return @[]

proc fileExists*(ftp: FtpClient, file: string): bool {.deprecated.} =
  ## **Deprecated since version 0.9.0:** Please use ``existsFile``.
  ##
  ## Determines whether ``file`` exists.
  ##
  ## Warning: This function may block. Especially on directories with many
  ## files, because a full list of file names must be retrieved.
  var files = ftp.listDirs()
  for f in items(files):
    if f.normalizePathSep == file.normalizePathSep: return true

proc existsFile*(ftp: FtpClient, file: string): bool =
  ## Determines whether ``file`` exists.
  ##
  ## Warning: This function may block. Especially on directories with many
  ## files, because a full list of file names must be retrieved.
  var files = ftp.listDirs()
  for f in items(files):
    if f.normalizePathSep == file.normalizePathSep: return true

proc createDir*[T](ftp: FtpBase[T], dir: string, recursive: bool = false) =
  ## Creates a directory ``dir``. If ``recursive`` is true, the topmost
  ## subdirectory of ``dir`` will be created first, following the secondmost...
  ## etc. this allows you to give a full path as the ``dir`` without worrying
  ## about subdirectories not existing.
  if not recursive:
    assertReply ftp.send("MKD " & dir.normalizePathSep), "257"
  else:
    var reply = TaintedString""
    var previousDirs = ""
    for p in split(dir, {os.DirSep, os.AltSep}):
      if p != "":
        previousDirs.add(p)
        reply = ftp.send("MKD " & previousDirs)
        previousDirs.add('/')
    assertReply reply, "257"

proc chmod*[T](ftp: FtpBase[T], path: string,
            permissions: set[FilePermission]) =
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

proc list*[T](ftp: FtpBase[T], dir: string = "", async = false): string =
  ## Lists all files in ``dir``. If ``dir`` is ``""``, uses the current
  ## working directory. If ``async`` is true, this function will return
  ## immediately and it will be your job to call asyncio's
  ## ``poll`` to progress this operation.
  ftp.createJob(getLines[T], JRetrText)
  ftp.pasv()

  assertReply(ftp.send("LIST" & " " & dir.normalizePathSep), ["125", "150"])

  if not async:
    while not ftp.job.prc(ftp, false): discard
    result = ftp.job.lines
    ftp.deleteJob()
  else:
    return ""

proc retrText*[T](ftp: FtpBase[T], file: string, async = false): string =
  ## Retrieves ``file``. File must be ASCII text.
  ## If ``async`` is true, this function will return immediately and
  ## it will be your job to call asyncio's ``poll`` to progress this operation.
  ftp.createJob(getLines[T], JRetrText)
  ftp.pasv()
  assertReply ftp.send("RETR " & file.normalizePathSep), ["125", "150"]

  if not async:
    while not ftp.job.prc(ftp, false): discard
    result = ftp.job.lines
    ftp.deleteJob()
  else:
    return ""

proc getFile[T](ftp: FtpBase[T], async = false): bool =
  if ftp.dsockConnected:
    var r = "".TaintedString
    var bytesRead = 0
    var returned = false
    if async:
      when T is Socket:
        raise newException(FTPError, "FTPClient must be async.")
      else:
        bytesRead = ftp.dsock.recvAsync(r, BufferSize)
        returned = bytesRead != -1
    else:
      bytesRead = ftp.dsock.recv(r, BufferSize)
      returned = true
    let r2 = r.string
    if r2 != "":
      ftp.job.progress.inc(r2.len)
      ftp.job.oneSecond.inc(r2.len)
      ftp.job.file.write(r2)
    elif returned and r2 == "":
      ftp.dsockConnected = false

  when T is Socket:
    if not async:
      var readSocks: seq[Socket] = @[ftp.csock]
      blockingOperation(ftp.csock):
        if readSocks.select(1) != 0 and ftp.csock in readSocks:
          assertReply ftp.expectReply(), "226"
          return true

proc retrFile*[T](ftp: FtpBase[T], file, dest: string, async = false) =
  ## Downloads ``file`` and saves it to ``dest``. Usage of this function
  ## asynchronously is recommended to view the progress of the download.
  ## The ``EvRetr`` event is passed to the specified ``handleEvent`` function
  ## when the download is finished, and the ``filename`` field will be equal
  ## to ``file``.
  ftp.createJob(getFile[T], JRetr)
  ftp.job.file = open(dest, mode = fmWrite)
  ftp.pasv()
  var reply = ftp.send("RETR " & file.normalizePathSep)
  assertReply reply, ["125", "150"]
  if {'(', ')'} notin reply.string:
    raise newException(ReplyError, "Reply has no file size.")
  var fileSize: BiggestInt
  if reply.string.captureBetween('(', ')').parseBiggestInt(fileSize) == 0:
    raise newException(ReplyError, "Reply has no file size.")

  ftp.job.total = fileSize
  ftp.job.lastProgressReport = epochTime()
  ftp.job.filename = file.normalizePathSep

  if not async:
    while not ftp.job.prc(ftp, false): discard
    ftp.deleteJob()

proc doUpload[T](ftp: FtpBase[T], async = false): bool =
  if ftp.dsockConnected:
    if ftp.job.toStore.len() > 0:
      assert(async)
      let bytesSent = ftp.dsock.sendAsync(ftp.job.toStore)
      if bytesSent == ftp.job.toStore.len:
        ftp.job.toStore = ""
      elif bytesSent != ftp.job.toStore.len and bytesSent != 0:
        ftp.job.toStore = ftp.job.toStore[bytesSent .. ^1]
      ftp.job.progress.inc(bytesSent)
      ftp.job.oneSecond.inc(bytesSent)
    else:
      var s = newStringOfCap(4000)
      var len = ftp.job.file.readBuffer(addr(s[0]), 4000)
      setLen(s, len)
      if len == 0:
        # File finished uploading.
        ftp.dsock.close()
        ftp.dsockConnected = false

        if not async:
          assertReply ftp.expectReply(), "226"
          return true
        return false

      if not async:
        ftp.dsock.send(s)
      else:
        let bytesSent = ftp.dsock.sendAsync(s)
        if bytesSent == 0:
          ftp.job.toStore.add(s)
        elif bytesSent != s.len:
          ftp.job.toStore.add(s[bytesSent .. ^1])
        len = bytesSent

      ftp.job.progress.inc(len)
      ftp.job.oneSecond.inc(len)

proc store*[T](ftp: FtpBase[T], file, dest: string, async = false) =
  ## Uploads ``file`` to ``dest`` on the remote FTP server. Usage of this
  ## function asynchronously is recommended to view the progress of
  ## the download.
  ## The ``EvStore`` event is passed to the specified ``handleEvent`` function
  ## when the upload is finished, and the ``filename`` field will be
  ## equal to ``file``.
  ftp.createJob(doUpload[T], JStore)
  ftp.job.file = open(file)
  ftp.job.total = ftp.job.file.getFileSize()
  ftp.job.lastProgressReport = epochTime()
  ftp.job.filename = file
  ftp.pasv()

  assertReply ftp.send("STOR " & dest.normalizePathSep), ["125", "150"]

  if not async:
    while not ftp.job.prc(ftp, false): discard
    ftp.deleteJob()

proc close*[T](ftp: FtpBase[T]) =
  ## Terminates the connection to the server.
  assertReply ftp.send("QUIT"), "221"
  if ftp.jobInProgress: ftp.deleteJob()
  ftp.csock.close()
  ftp.dsock.close()

proc csockHandleRead(s: AsyncSocket, ftp: AsyncFTPClient) =
  if ftp.jobInProgress:
    assertReply ftp.expectReply(), "226" # Make sure the transfer completed.
    var r: FTPEvent
    case ftp.job.typ
    of JRetrText:
      r.typ = EvLines
      r.lines = ftp.job.lines
    of JRetr:
      r.typ = EvRetr
      r.filename = ftp.job.filename
      if ftp.job.progress != ftp.job.total:
        raise newException(FTPError, "Didn't download full file.")
    of JStore:
      r.typ = EvStore
      r.filename = ftp.job.filename
      if ftp.job.progress != ftp.job.total:
        raise newException(FTPError, "Didn't upload full file.")
    ftp.deleteJob()

    ftp.handleEvent(ftp, r)

proc asyncFTPClient*(address: string, port = Port(21),
                     user, pass = "",
    handleEvent: proc (ftp: AsyncFTPClient, ev: FTPEvent) {.closure,gcsafe.} =
      (proc (ftp: AsyncFTPClient, ev: FTPEvent) = discard)): AsyncFTPClient =
  ## Create a ``AsyncFTPClient`` object.
  ##
  ## Use this if you want to use asyncio's dispatcher.
  var dres: AsyncFtpClient
  new(dres)
  dres.user = user
  dres.pass = pass
  dres.address = address
  dres.port = port
  dres.dsockConnected = false
  dres.handleEvent = handleEvent
  dres.csock = asyncSocket()
  dres.csock.handleRead =
    proc (s: AsyncSocket) =
      csockHandleRead(s, dres)
  result = dres

proc register*(d: Dispatcher, ftp: AsyncFTPClient): Delegate {.discardable.} =
  ## Registers ``ftp`` with dispatcher ``d``.
  ftp.disp = d
  return ftp.disp.register(ftp.csock)

when not defined(testing) and isMainModule:
  proc main =
    var d = newDispatcher()
    let hev =
      proc (ftp: AsyncFTPClient, event: FTPEvent) =
        case event.typ
        of EvStore:
          echo("Upload finished!")
          ftp.retrFile("payload.jpg", "payload2.jpg", async = true)
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
    var ftp = asyncFTPClient("example.com", user = "foo", pass = "bar", handleEvent = hev)

    d.register(ftp)
    d.len.echo()
    ftp.connect()
    echo "connected"
    ftp.store("payload.jpg", "payload.jpg", async = true)
    d.len.echo()
    echo "uploading..."
    while true:
      if not d.poll(): break
  main()

when not defined(testing) and isMainModule:
  var ftp = ftpClient("example.com", user = "foo", pass = "bar")
  ftp.connect()
  echo ftp.pwd()
  echo ftp.list()
  echo("uploading")
  ftp.store("payload.jpg", "payload.jpg", async = false)

  echo("Upload complete")
  ftp.retrFile("payload.jpg", "payload2.jpg", async = false)

  echo("Download complete")
  sleep(5000)
  ftp.close()
  sleep(200)
