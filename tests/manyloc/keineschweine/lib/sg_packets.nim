import genpacket_enet, nativesockets, net, md5, enet
defPacketImports()

type
  PacketID* = char

template idpacket(pktName, id, s2c, c2s: untyped) {.dirty.} =
  let `H pktName`* {.inject.} = id
  defPacket(`Sc pktName`, s2c)
  defPacket(`Cs pktName`, c2s)

forwardPacketT(uint8, int8)
forwardPacketT(uint16, int16)
forwardPacketT(Port, int16)

idPacket(Login, 'a',
  tuple[id: int32; alias: string; sessionKey: string],
  tuple[alias: string, passwd: string])

let HZoneJoinReq* = 'j'
defPacket(CsZoneJoinReq, tuple[session: ScLogin])

defPacket(ScZoneRecord, tuple[
  name: string = "", desc: string = "",
  ip: string = "", port: Port = 0.Port])
idPacket(ZoneList, 'z',
  tuple[network: string = "", zones: seq[ScZoneRecord]],
  tuple[time: string])

let HPoing* = 'p'
defPacket(Poing, tuple[id: int32, time: float32])

type ChatType* = enum
  CPub = 0'i8, CPriv, CSystem, CError
forwardPacketT(ChatType, int8)
idPacket(Chat, 'C',
  tuple[kind: ChatType = CPub; fromPlayer: string = ""; text: string = ""],
  tuple[target: string = ""; text: string = ""])

idPacket(Hello, 'h',
  tuple[resp: string],
  tuple[i: int8 = 14])

let HPlayerList* = 'P'
defPacket(ScPlayerRec, tuple[id: int32; alias: string = ""])
defPacket(ScPlayerList, tuple[players: seq[ScPlayerRec]])

let HTeamList* = 'T'
defPacket(ScTeam, tuple[id: int8; name: string = ""])
defPacket(ScTeamList, tuple[teams: seq[ScTeam]])
let HTeamChange* = 't'

idPacket(ZoneQuery, 'Q',
  tuple[playerCount: uint16], ##i should include a time here or something
  tuple[pad: char = '\0'])

type SpawnKind = enum
  SpawnDummy,
  SpawnItem, SpawnVehicle, SpawnObject
forwardPacketT(SpawnKind, int8)
defPacket(ScSpawn, tuple[
  kind: SpawnKind; id: uint16; record: uint16; amount: uint16])




type TAssetType* = enum
  FDummy,
  FZoneCfg, FGraphics, FSound

forwardPacketT(TAssetType, int8)
forwardPacket(MD5Digest, array[0..15, int8])

idPacket(FileChallenge, 'F',
  tuple[file: string; assetType: TAssetType; fullLen: int32],
  tuple[needFile: bool; checksum: MD5Digest])


let HChallengeResult* = '('
defPacket(ScChallengeResult, tuple[status: bool])

let HFileTransfer* = 'f'
defPacket(ScFileTransfer, tuple[fileSize: int32; pos: int32; data: string])
defPacket(CsFilepartAck, tuple[lastpos: int32])

##dir server messages
let HZoneLogin* = 'u'
defPacket(SdZoneLogin, tuple[name: string; key: string; record: ScZoneRecord])
defPacket(DsZoneLogin, tuple[status: bool])
let HDsMsg* = 'c'
defPacket(DsMsg, tuple[msg: string])
let HVerifyClient* = 'v'
defPacket(SdVerifyClient, tuple[session: ScLogin])

when true:

  var buf = newBuffer(100)
  var m = toMd5("hello there")
  echo(repr(m))
  buf.pack m

  echo(repr(buf.data))
  echo(len(buf.data))

  buf.reset()

  var x = buf.readMD5Digest()
  echo(repr(x))
