import enet, sg_packets, estreams, md5, zlib_helpers, client_helpers, strutils,
  idgen, sg_assets, tables, os
type
  PClient* = ref object
    id*: int32
    auth*: bool
    alias*: string
    peer*: PPeer

  FileChallengePair* = tuple[challenge: ScFileChallenge; file: TChecksumFile]
  PFileChallengeSequence* = ref TFileChallengeSequence
  TFileChallengeSequence = object
    index: int  #which file is active
    transfer: ScFileTransfer
    file: ptr FileChallengePair
var
  clientID = newIdGen[int32]()
  myAssets*: seq[FileChallengePair] = @[]
  fileChallenges = initTable[int32, PFileChallengeSequence](32)
const FileChunkSize = 256

proc free(client: PClient) =
  if client.id != 0:
    fileChallenges.del client.id
    clientID.del client.id
proc newClient*(): PClient =
  new(result, free)
  result.id = clientID.next()
  result.alias = "billy"

proc `$`*(client: PClient): string =
  result = "$1:$2".format(client.id, client.alias)

proc send*[T](client: PClient; pktType: char; pkt: var T) =
  var buf = newBuffer(128)
  buf.write pktType
  buf.pack pkt
  discard client.peer.send(0.cuchar, buf, flagReliable)

proc sendMessage*(client: PClient; txt: string) =
  var m = newScChat(CSystem, text = txt)
  client.send HChat, m
proc sendError*(client: PClient; error: string) =
  var m = newScChat(CError, text = error)
  client.send HChat, m




proc next*(challenge: PFileChallengeSequence, client: PClient)
proc sendChunk*(challenge: PFileChallengeSequence, client: PClient)

proc startVerifyingFiles*(client: PClient) =
  var fcs: PFileChallengeSequence
  new(fcs)
  fcs.index = -1
  fileChallenges[client.id] = fcs
  next(fcs, client)

proc next*(challenge: PFileChallengeSequence, client: PClient) =
  inc(challenge.index)
  if challenge.index >= myAssets.len:
    client.sendMessage "You are cleared to enter"
    fileChallenges.del client.id
    return
  else:
    echo myAssets.len, "assets"
  challenge.file = addr myAssets[challenge.index]
  client.send HFileChallenge, challenge.file.challenge # :rolleyes:
  echo "sent challenge"

proc sendChunk*(challenge: PFileChallengeSequence, client: PClient) =
  let size = min(FileChunkSize, challenge.transfer.fileSize - challenge.transfer.pos)
  challenge.transfer.data.setLen size
  copyMem(
    addr challenge.transfer.data[0],
    addr challenge.file.file.compressed[challenge.transfer.pos],
    size)
  client.send HFileTransfer, challenge.transfer
  echo "chunk sent"

proc startSend*(challenge: PFileChallengeSequence, client: PClient) =
  challenge.transfer.fileSize = challenge.file.file.compressed.len().int32
  challenge.transfer.pos = 0
  challenge.transfer.data = ""
  challenge.transfer.data.setLen FileChunkSize
  challenge.sendChunk(client)
  echo "starting xfer"

## HFileTransfer
proc handleFilePartAck*(client: PClient; buffer: PBuffer) =
  echo "got filepartack"
  var
    ftrans = readCsFilepartAck(buffer)
    fcSeq = fileChallenges[client.id]
  fcSeq.transfer.pos = ftrans.lastPos
  fcSeq.sendChunk client

## HFileCHallenge
proc handleFileChallengeResp*(client: PClient; buffer: PBuffer) =
  echo "got file challenge resp"
  var
    fcResp = readCsFileChallenge(buffer)
    fcSeq = fileChallenges[client.id]
  let index = $(fcSeq.index + 1) / $(myAssets.len)
  if fcResp.needFile:
    client.sendMessage "Sending file... "&index
    fcSeq.startSend(client)
  else:
    var resp = newScChallengeResult(false)
    if fcResp.checksum == fcSeq.file.file.sum: ##client is good
      client.sendMessage "Checksum is good. "&index
      resp.status = true
      client.send HChallengeResult, resp
      fcSeq.next(client)
    else:
      client.sendMessage "Checksum is bad, sending file... "&index
      client.send HChallengeResult, resp
      fcSeq.startSend(client)

