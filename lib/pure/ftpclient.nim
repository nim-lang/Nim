import sockets, strutils, parseutils, times

## This module **partially** implements an FTP client as specified
## by `RFC 959 <http://tools.ietf.org/html/rfc959>`_. 
## Functions which require file transfers have an ``async`` parameter, when
## this parameter is set to ``true``, it is your job to call the ``poll`` 
## function periodically to progress the transfer.
##
## Here is some example usage of this module:
## 
## .. code-block:: Nimrod
##    var ftp = FTPClient("example.org", user = "user", pass = "pass")
##    ftp.connect()
##    ftp.retrFile("file.ext", "file.ext", async = true)
##    while True:
##      var event: TFTPEvent
##      if ftp.poll(event):
##        case event.typ
##        of EvRetr:
##          echo("Download finished!")
##          break
##        of EvTransferProgress:
##          echo(event.speed div 1000, " kb/s")
##        else: assert(false)


type
  TFTPClient* = object
    csock: TSocket # Command connection socket
    dsock: TSocket # Data connection socket
    user, pass: string
    address: string
    port: TPort
    
    jobInProgress: bool
    job: ref TFTPJob

  FTPJobType = enum
    JListCmd, JRetrText, JRetr, JStore

  TFTPJob = object
    prc: proc (ftp: var TFTPClient, timeout: int): bool
    case typ*: FTPJobType
    of JListCmd, JRetrText:
      lines: string
    of JRetr, JStore:
      dsockClosed: bool
      file: TFile
      total: biggestInt # In bytes.
      progress: biggestInt # In bytes.
      oneSecond: biggestInt # Bytes transferred in one second.
      lastProgressReport: float # Time
    else: nil

  FTPEventType* = enum
    EvTransferProgress, EvLines, EvRetr, EvStore

  TFTPEvent* = object ## Event
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

proc expectReply(ftp: var TFTPClient): string =
  result = ""
  if not ftp.csock.recvLine(result): setLen(result, 0)

proc send*(ftp: var TFTPClient, m: string): string =
  ## Send a message to the server, and wait for a primary reply.
  ## ``\c\L`` is added for you.
  ftp.csock.send(m & "\c\L")
  return ftp.expectReply()

proc assertReply(received, expected: string) =
  if not received.startsWith(expected):
    raise newException(EInvalidReply,
                       "Expected reply '$1' got: $2" % [expected, received])

proc assertReply(received: string, expected: openarray[string]) =
  for i in items(expected):
    if received.startsWith(i): return
  raise newException(EInvalidReply,
                     "Expected reply '$1' got: $2" %
                     [expected.join("' or '"), received])

proc createJob(ftp: var TFTPClient,
                 prc: proc (ftp: var TFTPClient, timeout: int): bool,
                 cmd: FTPJobType) =
  if ftp.jobInProgress:
    raise newException(EFTP, "Unable to do two jobs at once.")
  ftp.jobInProgress = true
  new(ftp.job)
  ftp.job.prc = prc
  ftp.job.typ = cmd
  case cmd
  of JListCmd, JRetrText:
    ftp.job.lines = ""
  of JRetr, JStore:
    ftp.job.dsockClosed = false

proc deleteJob(ftp: var TFTPClient) =
  assert ftp.jobInProgress
  ftp.jobInProgress = false
  case ftp.job.typ
  of JListCmd, JRetrText:
    ftp.job.lines = ""
  of JRetr, JStore:
    ftp.job.file.close()

proc pasv(ftp: var TFTPClient) =
  ## Negotiate a data connection.
  var pasvMsg = ftp.send("PASV").strip
  assertReply(pasvMsg, "227")
  var betweenParens = captureBetween(pasvMsg, '(', ')')
  var nums = betweenParens.split(',')
  var ip = nums[0.. -3]
  var port = nums[-2.. -1]
  var properPort = port[0].parseInt()*256+port[1].parseInt()
  ftp.dsock = socket()
  ftp.dsock.connect(ip.join("."), TPort(properPort.toU16))

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
  return wd.captureBetween('"') # "

proc cd*(ftp: var TFTPClient, dir: string) =
  ## Changes the current directory on the remote FTP server to ``dir``.
  assertReply ftp.send("CWD " & dir), "250"

proc cdup*(ftp: var TFTPClient) =
  ## Changes the current directory to the parent of the current directory.
  assertReply ftp.send("CDUP"), "200"

proc asyncLines(ftp: var TFTPClient, timeout: int): bool =
  ## Downloads text data in ASCII mode, Asynchronously.
  ## Returns true if the download is complete.
  var readSocks: seq[TSocket] = @[ftp.dsock, ftp.csock]
  if readSocks.select(timeout) != 0:
    if ftp.dsock notin readSocks:
      var r = ""
      if ftp.dsock.recvLine(r):
        ftp.job.lines.add(r & "\n")
    if ftp.csock notin readSocks:
      assertReply ftp.expectReply(), "226"
      return true

proc list*(ftp: var TFTPClient, dir: string = "", async = false): string =
  ## Lists all files in ``dir``. If ``dir`` is ``""``, uses the current
  ## working directory. If ``async`` is true, this function will return
  ## immediately and it will be your job to call ``poll`` to progress this
  ## operation.
  ftp.createJob(asyncLines, JRetrText)
  ftp.pasv()

  assertReply(ftp.send("LIST" & " " & dir), ["125", "150"])

  if not async:
    while not ftp.job.prc(ftp, 500): nil
    result = ftp.job.lines
    ftp.deleteJob()
  else:
    return ""

proc retrText*(ftp: var TFTPClient, file: string, async = false): string =
  ## Retrieves ``file``. File must be ASCII text.
  ## If ``async`` is true, this function will return immediately and
  ## it will be your job to call ``poll`` to progress this operation.
  ftp.createJob(asyncLines, JRetrText)
  ftp.pasv()
  assertReply ftp.send("RETR " & file), ["125", "150"]
  
  if not async:
    while not ftp.job.prc(ftp, 500): nil
    result = ftp.job.lines
    ftp.deleteJob()
  else:
    return ""

proc asyncFile(ftp: var TFTPClient, timeout: int): bool =
  var readSocks: seq[TSocket] = @[ftp.dsock, ftp.csock]
  if readSocks.select(timeout) != 0:
    if ftp.dsock notin readSocks:
      var r = ftp.dsock.recv()
      if r != "":
        ftp.job.progress.inc(r.len())
        ftp.job.oneSecond.inc(r.len())
        ftp.job.file.write(r)
      
    if ftp.csock notin readSocks:
      assertReply ftp.expectReply(), "226"
      return true

proc retrFile*(ftp: var TFTPClient, file, dest: string, async = false) =
  ## Downloads ``file`` and saves it to ``dest``. Usage of this function
  ## asynchronously is recommended to view the progress of the download.
  ftp.createJob(asyncFile, JRetr)
  ftp.job.file = open(dest, mode = fmWrite)
  ftp.pasv()
  var reply = ftp.send("RETR " & file)
  assertReply reply, ["125", "150"]
  if {'(', ')'} notin reply:
    raise newException(EInvalidReply, "Reply has no file size.")
  var fileSize: biggestInt
  assert reply.captureBetween('(', ')').parseBiggestInt(fileSize) != 0
  ftp.job.total = fileSize
  ftp.job.lastProgressReport = epochTime()

  if not async:
    while not ftp.job.prc(ftp, 500): nil
    ftp.deleteJob()

proc asyncUpload(ftp: var TFTPClient, timeout: int): bool =
  var writeSocks: seq[TSocket] = @[ftp.dsock]
  var readSocks: seq[TSocket] = @[ftp.csock]

  if select(readSocks, writeSocks, timeout) != 0:
    if ftp.dsock notin writeSocks and not ftp.job.dsockClosed:
      var buffer: array[0..1023, byte]
      var len = ftp.job.file.readBytes(buffer, 0, 1024)
      if len == 0:
        # File finished uploading.
        ftp.dsock.close()
        ftp.job.dsockClosed = true
        return

      if ftp.dsock.send(addr(buffer), len) != len: assert(false)
      ftp.job.progress.inc(len)
      ftp.job.oneSecond.inc(len)
  
    if ftp.csock notin readSocks:
      # TODO: Why does this block? Why does select 
      # think that the socket is readable?
      assertReply ftp.expectReply(), "226"
      return true

proc store*(ftp: var TFTPClient, file, dest: string, async = false) =
  ## Uploads ``file`` to ``dest`` on the remote FTP server. Usage of this
  ## function asynchronously is recommended to view the progress of
  ## the download.
  ftp.createJob(asyncUpload, JStore)
  ftp.job.file = open(file)
  ftp.job.total = ftp.job.file.getFileSize()
  ftp.job.lastProgressReport = epochTime()
  ftp.pasv()
  
  assertReply ftp.send("STOR " & dest), ["125", "150"]

  if not async:
    while not ftp.job.prc(ftp, 500): nil
    ftp.deleteJob()

proc poll*(ftp: var TFTPClient, r: var TFTPEvent, timeout = 500): bool =
  ## Progresses an async job(if available). Returns true if ``r`` has been set.
  if ftp.jobInProgress:
    if ftp.job.prc(ftp, timeout):
      result = true
      case ftp.job.typ
      of JListCmd, JRetrText:
        r.typ = EvLines
        r.lines = ftp.job.lines
      of JRetr:
        r.typ = EvRetr
        if ftp.job.progress != ftp.job.total:
          raise newException(EFTP, "Didn't download full file.")
      of JStore:
        r.typ = EvStore
        if ftp.job.progress != ftp.job.total:
          raise newException(EFTP, "Didn't upload full file.")
      ftp.deleteJob()
      return
    
    if ftp.job.typ in {JRetr, JStore}:
      if epochTime() - ftp.job.lastProgressReport >= 1.0:
        result = true
        ftp.job.lastProgressReport = epochTime()
        r.typ = EvTransferProgress
        r.bytesTotal = ftp.job.total
        r.bytesFinished = ftp.job.progress
        r.speed = ftp.job.oneSecond
        ftp.job.oneSecond = 0

proc close*(ftp: var TFTPClient) =
  ## Terminates the connection to the server.
  assertReply ftp.send("QUIT"), "221"
  if ftp.jobInProgress: ftp.deleteJob()
  ftp.csock.close()
  ftp.dsock.close()

when isMainModule:
  import os
  var ftp = FTPClient("ex.org", user = "user", pass = "p")
  ftp.connect()
  echo ftp.pwd()
  echo ftp.list()

  ftp.store("payload.avi", "payload.avi", async = true)
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

  ftp.retrFile("payload.avi", "payload2.avi", async = true)
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

  sleep(5000)
  ftp.close()
  sleep(200)
