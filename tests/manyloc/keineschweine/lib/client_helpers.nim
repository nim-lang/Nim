import
  tables, sg_packets, enet, estreams, sg_gui, sfml,
  zlib_helpers, md5, sg_assets, os
type
  PServer* = ptr TServer
  TServer* = object
    connected*: bool
    addy: enet.TAddress
    host*: PHost
    peer*: PPeer
    handlers*: Table[char, TScPktHandler]
  TScPktHandler* = proc(serv: PServer; buffer: PBuffer)
  TFileTransfer = object
    fileName: string
    assetType: TAssetType
    fullLen: int
    pos: int32
    data: string
    readyToSave: bool
var
  currentFileTransfer: TFileTransfer
  downloadProgress* = newButton(nil, "", vec2f(0,0), nil)
currentFileTransfer.data = ""

proc addHandler*(serv: PServer; packetType: char; handler: TScPktHandler) =
  serv.handlers[packetType] = handler

proc newServer*(): PServer =
  result = cast[PServer](alloc0(sizeof(TServer)))
  result.connected = false
  result.host = createHost(nil, 1, 2, 0, 0)
  result.handlers = initTable[char, TScPktHandler](32)

proc connect*(serv: PServer; host: string; port: int16; error: var string): bool =
  if setHost(serv.addy, host) != 0:
    error = "Could not resolve host "
    error.add host
    return false
  serv.addy.port = port.cushort
  serv.peer = serv.host.connect(serv.addy, 2, 0)
  if serv.peer.isNil:
    error = "Could not connect to host "
    error.add host
    return false
  return true

proc send*[T](serv: PServer; packetType: char; pkt: var T) =
  if serv.connected:
    var b = newBuffer(100)
    b.write packetType
    b.pack pkt
    serv.peer.send(0.cuchar, b, FlagUnsequenced)

proc sendPubChat*(server: PServer; msg: string) =
  var chat = newCsChat("", msg)
  server.send HChat, chat

proc handlePackets*(server: PServer; buf: PBuffer) =
  while not buf.atEnd():
    let typ = readChar(buf)
    if server.handlers.hasKey(typ):
      server.handlers[typ](server, buf)
    else:
      break

proc updateFileProgress*() =
  let progress = currentFileTransfer.pos / currentFileTransfer.fullLen
  downloadProgress.bg.setSize(vec2f(progress * 100, 20))
  downloadProgress.setString($currentFileTransfer.pos & '/' & $currentFileTransfer.fullLen)

## HFileTransfer
proc handleFilePartRecv*(serv: PServer; buffer: PBuffer) =
  var
    f = readScFileTransfer(buffer)
  updateFileProgress()
  if not(f.pos == currentFileTransfer.pos):
    echo "returning early from filepartrecv"
    return ##issues, probably
  if currentFileTransfer.data.len == 0:
    echo "setting current file size"
    currentFileTransfer.data.setLen f.fileSize
  let len = f.data.len
  copymem(
    addr currentFileTransfer.data[f.pos],
    addr f.data[0],
    len)
  currentFileTransfer.pos = f.pos + len.int32
  if currentFileTransfer.pos == f.fileSize: #file should be done, rizzight
    currentFileTransfer.data = uncompress(
      currentFileTransfer.data, currentFileTransfer.fullLen)
    currentFileTransfer.readyToSave = true
    var resp: CsFileChallenge
    resp.checksum = toMD5(currentFileTransfer.data)
    serv.send HFileChallenge, resp
    echo "responded with challenge (ready to save)"
  else:
    var resp = newCsFilepartAck(currentFileTransfer.pos)
    serv.send HFileTransfer, resp
    echo "responded for next part"

proc saveCurrentFile() =
  if not currentFileTransfer.readyToSave: return
  let
    path = expandPath(currentFileTransfer.assetType, currentFileTransfer.fileName)
    parent = parentDir(path)
  if not dirExists(parent):
    createDir(parent)
    echo("Created dir")
  writeFile path, currentFIleTransfer.data
  echo "Write file"

## HChallengeResult
proc handleFileChallengeResult*(serv: PServer; buffer: PBuffer) =
  var res = readScChallengeResult(buffer).status
  echo "got challnege result: ", res
  if res and currentFileTransfer.readyToSave:
    echo "saving"
    saveCurrentFile()
  else:
    currentFileTransfer.readyToSave = false
    currentFileTransfer.pos = 0
    echo "REsetting current file"

## HFileCHallenge
proc handleFileChallenge*(serv: PServer; buffer: PBuffer) =
  var
    challenge = readScFileChallenge(buffer)
    path = expandPath(challenge)
    resp: CsFileChallenge
  if not fileExists(path):
    resp.needFile = true
    echo "Got file challenge, need file."
  else:
    resp.checksum = toMD5(readFile(path))
    echo "got file challenge, sending sum"
  currentFileTransfer.fileName = challenge.file
  currentFileTransfer.assetType = challenge.assetType
  currentFileTransfer.fullLen = challenge.fullLen.int
  currentFileTransfer.pos = 0
  currentFileTransfer.data.setLen 0
  currentFileTransfer.readyToSave = false
  serv.send HFileChallenge, resp
