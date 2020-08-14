import
  sockets, times, streams, streams_enh, tables, json, os,
  sg_packets, sg_assets, md5, server_utils, client_helpers
var
  dirServer: PServer
  thisZone = newScZoneRecord("local", "sup")
  thisZoneSettings: PZoneSettings
  dirServerConnected = false
  ## I was high.
  clients = initTable[TupAddress, PClient](16)
  alias2client = initTable[string, PClient](32)
  allClients: seq[PClient] = @[]
  zonePlayers: seq[PClient] = @[]
const
  PubChatDelay = 100/1000 #100 ms

import hashes
proc hash*(x: uint16): THash {.inline.} =
  result = int32(x)

proc findClient*(host: string; port: int16): PClient =
  let addy: TupAddress = (host, port)
  if clients.hasKey(addy):
    return clients[addy]
  result = newClient(addy)
  clients[addy] = result
  allClients.add(result)


proc sendZoneList(client: PClient) =
  echo(">> zonelist ", client)
  #client.send(HZonelist, zonelist)

proc forwardPrivate(rcv: PClient; sender: PClient; txt: string) =
  var m = newScChat(CPriv, sender.alias, txt)
  rcv.send(HChat, m)
proc sendChat(client: PClient; kind: ChatType; txt: string) =
  echo(">> chat ", client)
  var m = newScChat(kind, "", txt)
  client.send(HChat, m)

var pubChatQueue = newStringStream("")
pubChatQueue.flushImpl = proc(stream: PStream) =
  stream.setPosition(0)
  PStringStream(stream).data.setLen(0)
proc queuePub(sender: string, msg: CsChat) =
  var chat = newScChat(kind = CPub, fromPlayer = sender, text = msg.text)
  pubChatQueue.write(HChat)
  chat.pack(pubChatQueue)

handlers[HHello] = (proc(client: PClient; stream: PStream) =
  var h = readCsHello(stream)
  if h.i == 14:
    var greet = newScHello("Well hello there")
    client.send(HHello, greet))
handlers[HLogin] = proc(client: PClient; stream: PStream) =
  var loginInfo = readCsLogin(stream)
  echo("** login: alias = ", loginInfo.alias)
  if not dirServerConnected and client.loginPlayer(loginInfo):
    client.sendMessage("Welcome "& client.alias)
    alias2client[client.alias] = client
    client.sendZonelist()
handlers[HZoneList] = proc(client: PClient; stream: PStream) =
  var pinfo = readCsZoneList(stream)
  echo("** zonelist req")
handlers[HChat] = proc(client: PClient; stream: PStream) =
  var chat = readCsChat(stream)
  if not client.auth:
    client.sendError("You are not logged in.")
    return
  if chat.target != "": ##private
    if alias2client.hasKey(chat.target):
      alias2client[chat.target].forwardPrivate(client, chat.text)
  else:
    queuePub(client.alias, chat)
handlers[HZoneQuery] = proc(client: PClient; stream: PStream) =
  echo("Got zone query")
  var q = readCsZoneQuery(stream)
  var resp = newScZoneQuery(zonePlayers.len.uint16)
  client.send(HZoneQuery, resp)



handlers[HZoneJoinReq] = proc(client: PClient; stream: PStream) =
  var req = readCsZoneJoinReq(stream)
  echo "Join zone request from (",req.session.id,") ", req.session.alias
  if client.auth and client.kind == CPlayer:
    echo "Client is authenticated, verifying filez"
    client.startVerifyingFiles()
  elif dirServerConnected:
    echo "Dirserver is connected, verifying client"
    dirServer.send HVerifyClient, req.session
  else:
    echo "Dirserver is disconnected =("
    client.startVerifyingFiles()



proc handlePkt(s: PClient; stream: PStream) =
  while not stream.atEnd:
    var typ = readChar(stream)
    if not handlers.hasKey(typ):
      break
    else:
      handlers[typ](s, stream)

proc createServer(port: TPort) =
  if not server.isNil:
    server.close()
  server = socket(typ = SOCK_DGRAM, protocol = IPPROTO_UDP, buffered = false)
  server.bindAddr(port)

var clientIndex = 0
var incoming = newIncomingBuffer()
proc poll*(timeout: int = 250) =
  if server.isNil: return
  var
    reads = @[server]
    writes = @[server]
  if select(reads, timeout) > 0:
    var
      addy = ""
      port: TPort
    let res = server.recvFromAsync(incoming.data, 512, addy, port, 0)
    if not res:
      echo("No recv")
      return
    else:
      var client = findClient(addy, port.int16)
      #echo("<< ", res, " ", client.alias, ": ", len(line.data), " ", repr(line.data))
      handlePkt(client, incoming)
    incoming.flush()
  if selectWrite(writes, timeout) > 0:
    let nclients = allClients.len
    if nclients == 0:
      return
    clientIndex = (clientIndex + 1) mod nclients
    var c = allClients[clientIndex]
    if c.outputBuf.getPosition > 0:
      let res = server.sendTo(c.addy.host, c.addy.port.TPort, c.outputBuf.data)
      echo("Write ", c, " result: ", res, " data: ", c.outputBuf.data)
      c.outputBuf.flush()

when true:
  import parseopt, strutils
  var zoneCfgFile = "./server_settings.json"
  for kind, key, val in getOpt():
    case kind
    of cmdShortOption, cmdLongOption:
      case key
      of "f", "file":
        if fileExists(val):
          zoneCfgFile = val
        else:
          echo("File does not exist: ", val)
      else:
        echo("Unknown option: ", key," ", val)
    else:
      echo("Unknown option: ", key, " ", val)
  var jsonSettings = parseFile(zoneCfgFile)
  let
    host = jsonSettings["host"].str
    port = TPort(jsonSettings["port"].num)
    zoneFile = jsonSettings["settings"].str
    dirServerInfo = jsonSettings["dirserver"]

  var path = getAppDir()/../"data"/zoneFile
  if not fileExists(path):
    echo("Zone settings file does not exist: ../data/", zoneFile)
    echo(path)
    quit(1)

  ## Test file
  block:
    var
      TestFile: FileChallengePair
      contents = repeat("abcdefghijklmnopqrstuvwxyz", 2)
    testFile.challenge = newScFileChallenge("foobar.test", FZoneCfg, contents.len.int32)
    testFile.file = checksumStr(contents)
    myAssets.add testFile

  setCurrentDir getAppDir().parentDir()
  block:
    let zonesettings = readFile(path)
    var
      errors: seq[string] = @[]
    if not loadSettings(zoneSettings, errors):
      echo("You have errors in your zone settings:")
      for e in errors: echo("**", e)
      quit(1)
    errors.setLen 0

    var pair: FileChallengePair
    pair.challenge.file = zoneFile
    pair.challenge.assetType = FZoneCfg
    pair.challenge.fullLen = zoneSettings.len.int32
    pair.file = checksumStr(zoneSettings)
    myAssets.add pair

    allAssets:
      if not load(asset):
        echo "Invalid or missing file ", file
      else:
        var pair: FileChallengePair
        pair.challenge.file = file
        pair.challenge.assetType = assetType
        pair.challenge.fullLen = getFileSize(
          expandPath(assetType, file)).int32
        pair.file = asset.contents
        myAssets.add pair

    echo "Zone has ", myAssets.len, " associated assets"


    dirServer = newServerConnection(dirServerInfo[0].str, dirServerInfo[1].num.TPort)
    dirServer.handlers[HDsMsg] = proc(serv: PServer; stream: PStream) =
      var m = readDsMsg(stream)
      echo("DirServer> ", m.msg)
    dirServer.handlers[HZoneLogin] = proc(serv: PServer; stream: PStream) =
      let loggedIn = readDsZoneLogin(stream).status
      if loggedIn:
        dirServerConnected = true
    dirServer.writePkt HZoneLogin, login

  thisZone.name = jsonSettings["name"].str
  thisZone.desc = jsonSettings["desc"].str
  thisZone.ip = "localhost"
  thisZone.port = port
  var login = newSdZoneLogin(
    dirServerInfo[2].str, dirServerInfo[3].str,
    thisZone)
  #echo "MY LOGIN: ", $login



  createServer(port)
  echo("Listening on port ", port, "...")
  var pubChatTimer = cpuTime()#newClock()
  while true:
    discard dirServer.pollServer(15)
    poll(15)
    ## TODO sort this type of thing VV into a queue api
    #let now = cpuTime()
    if cpuTime() - pubChatTimer > PubChatDelay:       #.getElapsedTime.asMilliseconds > 100:
      pubChatTimer -= pubChatDelay #.restart()
      if pubChatQueue.getPosition > 0:
        var cn = 0
        let sizePubChat = pubChatQueue.data.len
        for c in allClients:
          c.outputBuf.writeData(addr pubChatQueue.data[0], sizePubChat)
        pubChatQueue.flush()



