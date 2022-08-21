## directory server
## handles client authorization and assets

import
  sockets, times, streams, streams_enh, tables, json, os,
  sg_packets, sg_assets, md5, server_utils, map_filter
type
  THandler = proc(client: PCLient; stream: PStream)
var
  server: TSocket
  handlers = initTable[char, THandler](16)
  thisZone = newScZoneRecord("local", "sup")
  zoneList = newScZoneList()
  thisZoneSettings: string
  zoneSlots: seq[tuple[name: string; key: string]] = @[]
  zones: seq[PClient] = @[]
  ## I was high.
  clients = initTable[TupAddress, PClient](16)
  alias2client = initTable[string, PClient](32)
  allClients: seq[PClient] = @[]

proc findClient*(host: string; port: int16): PClient =
  let addy: TupAddress = (host, port)
  if clients.hasKey(addy):
    return clients[addy]
  result = newClient(addy)
  clients[addy] = result
  allClients.add(result)

proc loginZone(client: PClient; login: SdZoneLogin): bool =
  if not client.auth:
    for s in zoneSlots.items:
      if s.name == login.name and s.key == login.key:
        client.auth = true
        client.kind = CServer
        client.record = login.record
        result = true
        break

proc sendZoneList(client: PClient) =
  echo(">> zonelist ", client, ' ', HZoneList)
  client.send(HZonelist, zonelist)
proc forwardPrivate(rcv: PClient; sender: PClient; txt: string) =
  var m = newScChat(CPriv, sender.alias, txt)
  rcv.send(HChat, m)
proc sendChat(client: PClient; kind: ChatType; txt: string) =
  echo(">> chat ", client)
  var m = newScChat(kind, "", txt)
  client.send(HChat, m)



var pubChatQueue = newIncomingBuffer()
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
  if alias2client.hasKey(loginInfo.alias):
    client.sendError("Alias in use.")
    return
  if client.loginPlayer(loginInfo):
    alias2client[client.alias] = client
    client.sendMessage("Welcome "& client.alias)
    var session = newScLogin(client.id, client.alias, client.session)
    client.send HLogin, session
    client.sendZonelist()

handlers[HZoneList] = proc(client: PClient; stream: PStream) =
  var pinfo = readCsZoneList(stream)
  echo("** zonelist req")
  sendZoneList client
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

proc sendServMsg(client: PClient; msg: string) =
  var m = newDsMsg(msg)
  client.send HDsMsg, m
handlers[HZoneLogin] = proc(client: PClient; stream: PStream) =
  var
    login = readSdZoneLogin(stream)
  if not client.loginZone(login):
    client.sendServMsg "Invalid login"
  else:
    client.sendServMsg "Welcome to the servers"
    echo "** Zone logged in: ", login
    zones.add client
    zonelist.zones.add client.record


handlers[HFileChallenge] = proc(client: PClient; stream: PStream) =
  if client.auth:
    if client.kind == CServer:
      var chg = readScFileChallenge(stream)

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
    incoming.data.setLen 512
    let res = server.recvFromAsync(incoming.data, 512, addy, port, 0)
    if not res:
      echo("No recv")
      return
    else:
      var client = findClient(addy, port.int16)
      echo "<< ", res, " ", client, ": ", len(incoming.data), " ", repr(incoming.data)
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
      echo("Write ", c, " result: ", res, " data: ", repr(c.outputBuf.data))
      c.outputBuf.flush()

when true:
  import parseopt, strutils
  var cfgFile = "dirserver_settings.json"
  for kind, key, val in getOpt():
    case kind
    of cmdShortOption, cmdLongOption:
      case key
      of "f", "file":
        if fileExists(val):
          cfgFile = val
        else:
          echo("File does not exist: ", val)
      else:
        echo("Unknown option: ", key," ", val)
    else:
      echo("Unknown option: ", key, " ", val)
  var jsonSettings = parseFile(cfgFile)
  let port = TPort(jsonSettings["port"].num)
  zonelist.network = jsonSettings["network"].str
  for slot in jsonSettings["zones"].items:
    zoneSlots.add((slot["name"].str, slot["key"].str))

  createServer(port)
  echo("Listening on port ", port, "...")
  var pubChatTimer = cpuTime() #newClock()
  const PubChatDelay = 1000/1000
  while true:
    poll(15)
    ## TODO sort this type of thing VV into a queue api
    if cpuTime() - pubChatTimer > PubChatDelay:       #.getElapsedTime.asMilliseconds > 100:
      pubChatTimer -= pubChatDelay
      if pubChatQueue.getPosition > 0:
        var cn = 0
        let sizePubChat = pubChatQueue.data.len
        var sent = 0
        filterIt2(allClients, it.auth == true and it.kind == CPlayer):
          it.outputBuf.writeData(addr pubChatQueue.data[0], sizePubChat)
          sent += 1
        #for c in allClients:
        #  c.outputBuf.writeData(addr pubChatQueue.data[0], sizePubChat)
        pubChatQueue.flush()
        echo "pubChatQueue flushed to ", sent, "clients"

