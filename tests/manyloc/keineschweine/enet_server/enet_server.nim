import enet, strutils, idgen, tables, math_helpers,
  estreams, sg_packets, server_utils, sg_assets, client_helpers
when appType == "gui":
  import sfml, sfml_colors, sg_gui,
    input_helpers, sfml_stuff
else:
  import times
type
  TCallback = proc(client: PClient; buffer: PBuffer)
var
  server: PHost
  dirServer: PServer
  standAloneMode = true
  event: enet.TEvent
  clientID = newIDGen[int32]()
  clients = initTable[int32, PClient](64)
  handlers = initTable[char, TCallback](32)

when appType == "gui":
  var
    gui = newGuiContainer()
    chatBox = gui.newMessageArea(vec2f(15, 550))
    window = newRenderWindow(videoMode(800, 600, 32), "Sup yo", sfDefaultSTyle)
    mousepos = newText("", guiFont, 16)
    fpsText = mousePos.copy()
    inputClient = newKeyClient(setActive = true)
  chatBox.sizeVisible = 30
  mousePos.setColor(Green)
  fpsText.setposition(vec2f(0, 20))
  inputClient.registerHandler MouseLeft, down, proc() =
    gui.click(input_helpers.getMousePos())
  inputClient.registerHandler MouseMiddle, down, proc() =
    let pos = input_helpers.getMousePos()
    mousePos.setString("($1,$2)".format(ff(pos.x), ff(pos.y)))
    mousePos.setPosition(pos)
  proc dispMessage(args: varargs[string, `$`]) =
    var s = ""
    for it in items(args):
      s.add it
    chatbox.add(s)
  proc dispError(args: varargs[string, `$`]) =
    var s = ""
    for it in items(args): s.add(it)
    chatBox.add(newScChat(kind = CError, text = s))
else:
  proc dispMessage(args: varargs[string, `$`]) =
    var m = ""
    for it in items(args): m.add(it)
    echo "<msg> ", m
  proc dispError(args: varargs[string, `$`]) =
    var m = ""
    for it in items(args): m.add(it)
    echo "**", m


var pubChatQueue = newBuffer(1024)
proc queuePub(sender: PClient, msg: CsChat) =
  var chat = newScChat(kind = CPub, fromPlayer = sender.alias, text = msg.text)
  pubChatQueue.write(HChat)
  pubChatQueue.pack(chat)
proc flushPubChat() =
  if pubChatQueue.isDirty:
    let packet = pubChatQueue.toPacket(FlagReliable)
    for id, client in pairs(clients):
      discard client.peer.send(0.cuchar, packet)
    pubChatQueue.flush()

handlers[HChat] = proc(client: PClient; buffer: PBuffer) =
  var chat = readCsChat(buffer)

  if not client.auth:
    client.sendError("You are not logged in.")
    return
  #if chat.target != "": ##private
  #  if alias2client.hasKey(chat.target):
  #    alias2client[chat.target].forwardPrivate(client, chat.text)
  #else:

  dispmessage("<", client.alias, "> ", chat.text)
  queuePub(client, chat)

handlers[HLogin] = proc(client: PClient; buffer: PBuffer) =
  var info = readCsLogin(buffer)
  if client.auth:
    client.sendError "You are already logged in."
    return
  client.alias = info.alias
  client.auth = true
  var resp = newScLogin(client.id, client.alias, "sessionkeylulz")
  client.send HLogin, resp
  client.sendMessage "welcome"
  dispMessage("Client logged in: ", client)


handlers[HFileTransfer] = server_utils.handleFilePartAck
handlers[HFileChallenge] = server_utils.handleFileChallengeResp

handlers[HZoneJoinReq] = proc(client: PClient; buffer: PBuffer) =
  var info = readCsZoneJoinReq(buffer)
  dispmessage "Got zone join request"
  client.startVerifyingFiles()



when true:
  import parseopt, os, json


  if enetInit() != 0:
    quit "Could not initialize ENet"

  var address: enet.TAddress

  block:
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
      port = uint16(jsonSettings["port"].num)
      zoneFile = jsonSettings["settings"].str
      dirServerInfo = jsonSettings["dirserver"]

    address.host = EnetHostAny
    address.port = port

    var path = getAppDir()/../"data"/zoneFile
    if not fileExists(path):
      echo("Zone settings file does not exist: ../data/", zoneFile)
      echo(path)
      quit(1)

    discard """block:
      var
        TestFile: FileChallengePair
        contents = repeat("abcdefghijklmnopqrstuvwxyz", 2)
      testFile.challenge = newScFileChallenge("foobar.test", FZoneCfg, contents.len.int32)
      testFile.file = checksumStr(contents)
      myAssets.add testFile"""

    setCurrentDir getAppDir().parentDir()
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

    dirServer = newServer()

    dirServer.addHandler HDsMsg, proc(serv: PServer; buffer: PBuffer) =
      var m = readDsMsg(buffer)
      dispMessage("<DirServer> ", m.msg)
    dirServer.addHandler HZoneLogin, proc(serv: PServer; buffer: PBuffer) =
      let loggedIn = readDsZoneLogin(buffer).status
      if loggedIn:
        #dirServerConnected = true

    if dirServerInfo.kind == JArray:
      var error: string
      if not dirServer.connect(dirServerInfo[0].str, dirServerInfo[1].num.int16, error):
        dispError("<DirServer> "&error)


  server = enet.createHost(address, 32, 2,  0,  0)
  if server == nil:
    quit "Could not create the server!"

  dispMessage("Listening on port ", address.port)

  var
    serverRunning = true
  when appType == "gui":
    var frameRate = newClock()
    var pubChatDelay = newClock()
  else:
    var frameRate = epochTime()
    var pubChatDelay = frameRate

  while serverRunning:
    when appType == "gui":
      let dt = frameRate.restart.asMilliseconds().float / 1000.0

      for event in window.filterEvents():
        case event.kind
        of sfml.EvtClosed:
          window.close()
          serverRunning = false
        else:
          discard
    else:
      let dt = epochTime() - frameRate ##is this right? probably not
      frameRate = epochTime()

    while server.hostService(event, 10) > 0:
      case event.kind
      of EvtConnect:
        var client = newClient()
        clients[client.id] = client

        event.peer.data = addr client.id
        client.peer = event.peer

        dispMessage("New client connected ", client)

        var
          msg = "hello"
          resp = createPacket(cstring(msg), msg.len + 1, FlagReliable)

        if event.peer.send(0.cuchar, resp) < 0:
          echo "FAILED"
        else:
          echo "Replied"
      of EvtReceive:
        let client = clients[cast[ptr int32](event.peer.data)[]]

        var buf = newBuffer(event.packet)
        let k = buf.readChar()
        if handlers.hasKey(k):
          handlers[k](client, buf)
        else:
          dispError("Unknown packet from ", client)

        destroy(event.packet)
      of EvtDisconnect:
        var
          id = cast[ptr int32](event.peer.data)[]
          client = clients[id]
        if client.isNil:
          disperror("CLIENT IS NIL!")
          dispmessage(event.peer.data.isNil)
        else:
          dispMessage(clients[id], " disconnected")
          GCUnref(clients[id])
          clients.del id

        event.peer.data = nil
      else:
        discard

    when appType == "gui":
      fpsText.setString(ff(1.0/dt))
      if pubChatDelay.getElapsedTime.asSeconds > 0.25:
        pubChatDelay.restart()
        flushPubChat()
    else:
      pubChatDelay -= dt
      if frameRate - pubChatDelay > 0.25:
        flushPubChat()

    when appType == "gui":
      window.clear(Black)
      window.draw(GUI)
      window.draw chatbox
      window.draw mousePos
      window.draw fpstext
      window.display()

  server.destroy()
  enetDeinit()
