
import
  sockets, streams, tables, times, math, strutils, json, os, md5,
  sfml, sfml_vector, sfml_colors,
  streams_enh, input_helpers, zlib_helpers, client_helpers, sg_packets, sg_assets, sg_gui
type
  TClientSettings = object
    resolution*: TVideoMode
    offlineFile: string
    dirserver: tuple[host: string, port: TPort]
    website*: string
var
  clientSettings: TClientSettings
  gui = newGuiContainer()
  zonelist = newGuiContainer()
  u_alias, u_passwd: PTextEntry
  activeInput = 0
  aliasText, passwdText: PText
  fpsTimer: PButton
  loginBtn: PButton
  playBtn: PButton
  keyClient = newKeyClient("lobby")
  showZonelist = false
  chatInput*: PTextEntry
  messageArea*: PMessageArea
  mySession*: ScLogin
var
  dirServer: PServer
  zone*: PServer
  activeServer: PServer
  bConnected = false
  outgoing = newStringStream("")
  downloadProgress: PButton
  connectionButtons: seq[PButton] #buttons that depend on connection to function

template dispmessage(m: expr): stmt =
  messageArea.add(m)
proc connectZone(host: string; port: TPort)
proc connectToDirserv()

proc writePkt[T](pid: PacketID; p: var T) =
  if activeServer.isNil: return
  activeServer.writePkt pid, p

proc setConnected(state: bool) =
  if state:
    bConnected = true
    for b in connectionButtons: enable(b)
  else:
    bConnected = false
    for b in connectionButtons: disable(b)

proc setActiveZone(ind: int; zone: ScZoneRecord) =
  #highlight it or something
  dispmessage("Selected " & zone.name)
  connectZone(zone.ip, zone.port)
  playBtn.enable()

proc handleChat(serv: PServer; s: PStream) =
  var msg = readScChat(s)
  messageArea.add(msg)

proc connectToDirserv() =
  if dirServer.isNil:
    dirServer = newServerConnection(clientSettings.dirserver.host, clientSettings.dirserver.port)
    dirServer.handlers[HHello] = proc(serv: PServer; s: PStream) =
      let msg = readScHello(s)
      dispMessage(msg.resp)
      setConnected(true)
    dirServer.handlers[HLogin] = proc(serv: PServer; s: PStream) =
      mySession = readScLogin(s)
      ##do something here
    dirServer.handlers[HZonelist] = proc(serv: PServer; s: PStream) =
      var
        info = readScZonelist(s)
        zones = info.zones
      if zones.len > 0:
        zonelist.clearButtons()
        var pos = vec2f(0.0, 0.0)
        zonelist.newButton(
          text = "Zonelist - "& info.network,
          position = pos,
          onClick = proc(b: PButton) =
            dispmessage("Click on header"))
        pos.y += 20
        for i in 0..zones.len - 1:
          var z = zones[i]
          zonelist.newButton(
            text = z.name, position = pos,
            onClick = proc(b: PButton) =
              setActiveZone(i, z))
          pos.y += 20
        showZonelist = true
    dirServer.handlers[HPoing] = proc(serv: PServer; s: PStream) =
      var ping = readPoing(s)
      dispmessage("Ping: "& $ping.time)
      ping.time = epochTime().float32
      serv.writePkt HPoing, ping
    dirServer.handlers[HChat] = handleChat
    dirServer.handlers[HFileChallenge] = handleFileChallenge
  var hello = newCsHello()
  dirServer.writePkt HHello, hello
  activeServer = dirServer


proc zoneListReq() =
  var pkt = newCsZonelist("sup")
  writePkt HZonelist, pkt

##key handlers
keyClient.registerHandler(MouseMiddle, down, proc() =
  gui.setPosition(getMousePos()))

keyClient.registerHandler(KeyO, down, proc() =
  if keyPressed(KeyRShift): echo(repr(outgoing)))
keyClient.registerHandler(KeyTab, down, proc() =
  activeInput = (activeInput + 1) mod 2) #does this work?
keyClient.registerHandler(MouseLeft, down, proc() =
  let p = getMousePos()
  gui.click(p)
  if showZonelist: zonelist.click(p))
var mptext = newText("", guiFont, 16)
keyClient.registerHandler(MouseRight, down, proc() =
  let p = getMousePos()
  mptext.setPosition(p)
  mptext.setString("($1,$2)"%[$p.x.int,$p.y.int]))


proc connectZone(host: string, port: TPort) =
  echo "Connecting to zone at ", host, ':', port
  if zone.isNil:
    zone = newServerConnection(host, port)
    zone.handlers[HFileChallenge] = handleFileChallenge
    zone.handlers[HChallengeResult] = handleFileChallengeResult
    zone.handlers[HFileTransfer] = handleFileTransfer
    zone.handlers[HChat] = handleChat
  else:
    zone.sock.connect(host, port)
  var hello = newCsHello()
  zone.writePkt HHello, hello



proc lobbyReady*() =
  keyClient.setActive()
  gui.setActive(u_alias)

proc tryConnect*(b: PButton) =
  connectToDirserv()
proc tryLogin*(b: PButton) =
  var login = newCsLogin(
    alias = u_alias.getText(),
    passwd = u_passwd.getText())
  writePkt HLogin, login
proc tryTransition*(b: PButton) =
  ##check if we're logged in
  #<implementation censored by the church>
  #var joinReq = newCsJ
  zone.writePkt HZoneJoinReq, mySession
  #var errors: seq[string] = @[]
  #if loadSettings("", errors):
  #  transition()
  #else:
  #  for e in errors: dispmessage(e)
proc playOffline*(b: PButton) =
  var errors: seq[string] = @[]
  if loadSettingsFromFile(clientSettings.offlineFile, errors):
    transition()
  else:
    dispmessage("Errors reading the file ("& clientSettings.offlineFile &"):")
    for e in errors: dispmessage(e)

proc getClientSettings*(): TClientSettings =
  result = clientSettings

proc lobbyInit*() =
  var s = json.parseFile("./client_settings.json")
  clientSettings.offlineFile = "data/"
  clientSettings.offlineFile.add s["default-file"].str
  let dirserv = s["directory-server"]
  clientSettings.dirserver.host = dirserv["host"].str
  clientSettings.dirserver.port = dirserv["port"].num.TPort
  clientSettings.resolution.width = s["resolution"][0].num.cint
  clientSettings.resolution.height= s["resolution"][1].num.cint
  clientSettings.resolution.bitsPerPixel = s["resolution"][2].num.cint
  clientSettings.website = s["website"].str
  zonelist.setPosition(vec2f(200.0, 100.0))
  connectionButtons = @[]

  downloadProgress = gui.newButton(
    text = "", position = vec2f(10, 130), onClick = nil)
  downloadProgress.bg.setFillColor(color(34, 139, 34))
  downloadProgress.bg.setSize(vec2f(0, 0))

  var pos = vec2f(10, 10)
  u_alias = gui.newTextEntry(
    if s.existsKey("alias"): s["alias"].str else: "alias",
    pos)
  pos.y += 20
  u_passwd = gui.newTextEntry("buzz", pos)
  pos.y += 20
  connectionButtons.add(gui.newButton(
    text = "Login",
    position = pos,
    onClick = tryLogin,
    startEnabled = false))
  pos.y += 20
  fpsText.setPosition(pos)

  playBtn = gui.newButton(
    text = "Play",
    position = vec2f(680.0, 8.0),
    onClick = tryTransition,
    startEnabled = false)
  gui.newButton(
    text = "Play Offline",
    position = vec2f(680.0, 28.0),
    onClick = playOffline)
  fpsTimer = gui.newButton(
    text = "FPS: ",
    position = vec2f(10.0, 70.0),
    onClick = proc(b: PButton) = nil)
  gui.newButton(
    text = "Connect",
    position = vec2f(10.0, 90.0),
    onClick = tryConnect)
  connectionButtons.add(gui.newButton(
    text = "Test Chat",
    position = vec2f(10.0, 110.0),
    onClick = (proc(b: PButton) =
      var pkt = newCsChat(text = "ohai")
      writePkt HChat, pkt),
    startEnabled = false))
  chatInput = gui.newTextEntry("...", vec2f(10.0, 575.0), proc() =
    sendChat dirServer, chatInput.getText()
    chatInput.clearText())
  messageArea = gui.newMessageArea(vec2f(10.0, 575.0 - 20.0))
  messageArea.sizeVisible = 25
  gui.newButton(text = "Scrollback + 1", position = vec2f(185, 10), onClick = proc(b: PButton) =
    messageArea.scrollBack += 1
    update(messageArea))
  gui.newButton(text = "Scrollback - 1", position = vec2f(185+160, 10), onClick = proc(b: PButton) =
    messageArea.scrollBack -= 1
    update(messageArea))
  gui.newButton(text = "Flood msg area", position = vec2f(185, 30), onClick = proc(b: PButton) =
    for i in 0..< 30:
      dispMessage($i))

var i = 0
proc lobbyUpdate*(dt: float) =
  #let res = disp.poll()
  gui.update(dt)
  i = (i + 1) mod 60
  if i == 0:
    fpsTimer.setString("FPS: "& $round(1.0/dt))
  if not pollServer(dirServer, 5) and bConnected:
    setConnected(false)
    echo("Lost connection")
  discard pollServer(zone, 5)

proc lobbyDraw*(window: PRenderWindow) =
  window.clear(Black)
  window.draw messageArea
  window.draw mptext
  window.draw gui
  if showZonelist: window.draw zonelist
  window.display()
