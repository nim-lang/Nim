import
  os, math, strutils, gl, tables,
  sfml, sfml_audio, sfml_colors, chipmunk, math_helpers,
  input_helpers, animations, game_objects, sfml_stuff, map_filter,
  sg_gui, sg_assets, sound_buffer, enet_client
when defined(profiler):
  import nimprof

type
  PPlayer* = ref TPlayer
  TPlayer* = object
    id: uint16
    vehicle: PVehicle
    spectator: bool
    alias: string
    nameTag: PText
    items: seq[PItem]
  PVehicle* = ref TVehicle
  TVehicle* = object
    body*:      chipmunk.PBody
    shape*:     chipmunk.PShape
    record*:   PVehicleRecord
    sprite*:   PSprite
    spriteRect*: TIntRect
    occupant: PPlayer
    when false:
      position*: TVector2f
      velocity*: TVector2f
      angle*:    float
  PItem* = ref object
    record: PItemRecord
    cooldown: float
  PLiveBullet* = ref TLiveBullet ##represents a live bullet in the arena
  TLiveBullet* = object
    lifetime*: float
    dead: bool
    anim*: PAnimation
    record*: PBulletRecord
    fromPlayer*: PPlayer
    trailDelay*: float
    body: chipmunk.PBody
    shape: chipmunk.PShape
include vehicles
const
  LGrabbable*  = (1 shl 0).TLayers
  LBorders*    = (1 shl 1).TLayers
  LPlayer*     = ((1 shl 2) and LBorders.int).TLayers
  LEnemy*      = ((1 shl 4) and LBorders.int).TLayers
  LEnemyFire*  = (LPlayer).TLayers
  LPlayerFire* = (LEnemy).TLayers
  CTBullet = 1.TCollisionType
  CTVehicle= 2.TCollisionType
  ##temporary constants
  W_LIMIT = 2.3
  V_LIMIT = 35
  MaxLocalBots = 3
var
  localPlayer: PPlayer
  localBots: seq[PPlayer] = @[]
  activeVehicle: PVehicle
  myVehicles: seq[PVehicle] = @[]
  objects: seq[PGameObject] = @[]
  liveBullets: seq[PLiveBullet] = @[]
  explosions: seq[PAnimation] = @[]
  gameRunning = true
  frameRate = newClock()
  showStars = off
  levelArea: TIntRect
  videoMode: TVideoMode
  window: PRenderWindow
  worldView: PView
  guiView: PView
  space = newSpace()
  ingameClient = newKeyClient("ingame")
  specInputClient = newKeyClient("spec")
  specGui = newGuiContainer()
  stars: seq[PSpriteSheet] = @[]
  playBtn: PButton
  shipSelect = newGuiContainer()
  delObjects: seq[int] = @[]
  showShipSelect = false
  myPosition: array[0..1, TVector3f] ##for audio positioning
let
  nameTagOffset = vec2f(0.0, 1.0)
when defined(escapeMenuTest):
  import browsers
  var
    escMenu = newGuiContainer(vec2f(100, 100))
    escMenuOpen = false
    pos = vec2f(0, 0)
  escMenu.newButton("Some Website", pos, proc(b: PButton) =
    openDefaultBrowser(getClientSettings().website))
  pos.y += 20.0
  escMenu.newButton("Back to Lobby", pos, proc(b: PButton) =
    echo "herro")
  proc toggleEscape() =
    escMenuOpen = not escMenuOpen
  ingameClient.registerHandler(KeyEscape, down, toggleEscape)
  specInputClient.registerHandler(KeyEscape, down, toggleEscape)
when defined(foo):
  var mouseSprite: sfml.PCircleShape
when defined(recordMode):
  var
    snapshots: seq[PImage] = @[]
    isRecording = false
  proc startRecording() =
    if snapshots.len > 100: return
    echo "Started recording"
    isRecording = true
  proc stopRecording() =
    if isRecording:
      echo "Stopped recording. ", snapshots.len, " images."
    isRecording = false
  proc zeroPad*(s: string; minLen: int): string =
    if s.len < minLen:
      result = repeat(0, minLen - s.len)
      result.add s
    else:
      result = s
  var
    recordButton = newButton(
      nil, text = "Record", position = vec2f(680, 50),
      onClick = proc(b: PButton) = startRecording())

proc newNameTag*(text: string): PText =
  result = newText()
  result.setFont(guiFont)
  result.setCharacterSize(14)
  result.setColor(Red)
  result.setString(text)

var debugText = newNameTag("Loading...")
debugText.setPosition(vec2f(0.0, 600.0 - 50.0))

when defined(showFPS):
  var fpsText = newNameTag("0")
  #fpsText.setCharacterSize(16)
  fpsText.setPosition(vec2f(300.0, (800 - 50).float))

proc mouseToSpace*(): TVector =
  result = window.convertCoords(vec2i(getMousePos()), worldView).sfml2cp()

proc explode*(b: PLiveBullet)
## TCollisionBeginFunc
proc collisionBulletPlayer(arb: PArbiter; space: PSpace;
                            data: pointer): bool{.cdecl.} =
  var
    bullet = cast[PLiveBullet](arb.a.data)
    target = cast[PVehicle](arb.b.data)
  if target.occupant.isNil or target.occupant == bullet.fromPlayer: return
  bullet.explode()

proc angularDampingSim(body: PBody, gravity: TVector, damping, dt: CpFloat){.cdecl.} =
  body.w -= (body.w * 0.98 * dt)
  body.UpdateVelocity(gravity, damping, dt)

proc initLevel() =
  loadAllAssets()

  if not space.isNil: space.destroy()
  space = newSpace()
  space.addCollisionHandler CTBullet, CTVehicle, collisionBulletPlayer,
    nil, nil, nil, nil

  let levelSettings = getLevelSettings()
  levelArea.width = levelSettings.size.x
  levelArea.height= levelSettings.size.y
  let borderSeq = @[
    vector(0, 0), vector(levelArea.width.float, 0.0),
    vector(levelArea.width.float, levelArea.height.float), vector(0.0, levelArea.height.float)]
  for i in 0..3:
    var seg = space.addShape(
      newSegmentShape(
        space.staticBody,
        borderSeq[i],
        borderSeq[(i + 1) mod 4],
        8.0))
    seg.setElasticity 0.96
    seg.setLayers(LBorders)
  if levelSettings.starfield.len > 0:
    showStars = true
    for sprite in levelSettings.starfield:
      sprite.tex.setRepeated(true)
      sprite.sprite.setTextureRect(levelArea)
      sprite.sprite.setOrigin(vec2f(0, 0))
      stars.add(sprite)
  var pos = vec2f(0.0, 0.0)
  for veh in playableVehicles():
    shipSelect.newButton(
      veh.name,
      position = pos,
      onClick = proc(b: PButton) =
        echo "-__-")
    pos.y += 18.0


proc newItem*(record: PItemRecord): PItem =
  new(result)
  result.record = record
proc newItem*(name: string): PItem {.inline.} =
  return newItem(fetchItm(name))
proc canUse*(itm: PItem): bool =
  if itm.cooldown > 0.0: return
  return true
proc update*(itm: PItem; dt: float) =
  if itm.cooldown > 0:
    itm.cooldown -= dt

proc free(obj: PLiveBullet) =
  obj.shape.free
  obj.body.free
  obj.record = nil


template newExplosion(obj, animation) =
  explosions.add(newAnimation(animation, AnimOnce, obj.body.getPos.cp2sfml, obj.body.getAngle))

template newExplosion(obj, animation, angle) =
  explosions.add(newAnimation(animation, AnimOnce, obj.body.getPos.cp2sfml, angle))

proc explode*(b: PLiveBullet) =
  if b.dead: return
  b.dead = true
  space.removeShape b.shape
  space.removeBody b.body
  if not b.record.explosion.anim.isNil:
    newExplosion(b, b.record.explosion.anim)
  playSound(b.record.explosion.sound, b.body.getPos())

proc bulletUpdate(body: PBody, gravity: TVector, damping, dt: CpFloat){.cdecl.} =
  body.UpdateVelocity(gravity, damping, dt)

template getPhysical() {.dirty.} =
  result.body = space.addBody(newBody(
    record.physics.mass,
    record.physics.moment))
  result.shape = space.addShape(
    chipmunk.newCircleShape(
      result.body,
      record.physics.radius,
      VectorZero))

proc newBullet*(record: PBulletRecord; fromPlayer: PPlayer): PLiveBullet =
  new(result, free)
  result.anim = newAnimation(record.anim, AnimLoop)
  result.fromPlayer = fromPlayer
  result.lifetime = record.lifetime
  result.record = record
  getPhysical()
  if fromPlayer == localPlayer:
    result.shape.setLayers(LPlayerFire)
  else:
    result.shape.setLayers(LEnemyFire)
  result.shape.setCollisionType CTBullet
  result.shape.setUserData(cast[ptr TLiveBullet](result))
  let
    fireAngle = fromPlayer.vehicle.body.getAngle()
    fireAngleV = vectorForAngle(fireAngle)
  result.body.setAngle fireAngle
  result.body.setPos(fromPlayer.vehicle.body.getPos() + (fireAngleV * fromPlayer.vehicle.shape.getCircleRadius()))
  #result.body.velocityFunc = bulletUpdate
  result.body.setVel((fromPlayer.vehicle.body.getVel() * record.inheritVelocity) + (fireAngleV * record.baseVelocity))

proc update*(b: PLiveBullet; dt: float): bool =
  if b.dead: return true
  b.lifetime -= dt
  b.anim.next(dt)
  #b.anim.sprite.setPosition(b.body.getPos.floor())
  b.anim.setPos(b.body.getPos)
  b.anim.setAngle(b.body.getAngle())
  if b.lifetime <= 0.0:
    b.explode()
    return true
  b.trailDelay -= dt
  if b.trailDelay <= 0.0:
    b.trailDelay += b.record.trail.timer
    if b.record.trail.anim.isNil: return
    newExplosion(b, b.record.trail.anim)
proc draw*(window: PRenderWindow; b: PLiveBullet) {.inline.} =
  draw(window, b.anim.sprite)


proc free*(veh: PVehicle) =
  ("Destroying vehicle " & veh.record.name).echo
  destroy(veh.sprite)
  if veh.shape.isNil: "Free'd vehicle's shape was NIL!".echo
  else: space.removeShape(veh.shape)
  if veh.body.isNil: "Free'd vehicle's BODY was NIL!".echo
  else: space.removeBody(veh.body)
  veh.body.free()
  veh.shape.free()
  veh.sprite = nil
  veh.body = nil
  veh.shape  = nil


proc newVehicle*(record: PVehicleRecord): PVehicle =
  echo("Creating " & record.name)
  new(result, free)
  result.record = record
  result.sprite = result.record.anim.spriteSheet.sprite.copy()
  result.spriteRect = result.sprite.getTextureRect()
  getPhysical()
  result.body.setAngVelLimit W_LIMIT
  result.body.setVelLimit result.record.handling.topSpeed
  result.body.velocityFunc = angularDampingSim
  result.shape.setCollisionType CTVehicle
  result.shape.setUserData(cast[ptr TVehicle](result))
proc newVehicle*(name: string): PVehicle =
  result = newVehicle(fetchVeh(name))

proc update*(obj: PVehicle) =
  obj.sprite.setPosition(obj.body.getPos.floor)
  obj.spriteRect.left = (((-obj.body.getAngVel + W_LIMIT) / (W_LIMIT*2.0) * (obj.record.anim.spriteSheet.cols - 1).float).floor.int * obj.record.anim.spriteSheet.framew).cint
  obj.spriteRect.top = ((obj.offsetAngle.wmod(TAU) / TAU) * obj.record.anim.spriteSheet.rows.float).floor.cint * obj.record.anim.spriteSheet.frameh.cint
  obj.sprite.setTextureRect(obj.spriteRect)


proc newPlayer*(alias: string = "poo"): PPlayer =
  new(result)
  result.spectator = true
  result.alias     = alias
  result.nameTag   = newNameTag(result.alias)
  result.items     = @[]
proc updateItems*(player: PPlayer, dt: float) =
  for i in items(player.items):
    update(i, dt)
proc addItem*(player: PPlayer; name: string) =
  player.items.add newItem(name)
proc useItem*(player: PPlayer; slot: int) =
  if slot > player.items.len - 1: return
  let item = player.items[slot]
  if item.canUse:
    item.cooldown += item.record.cooldown
    let b = newBullet(item.record.bullet, player)
    liveBullets.add(b)
    sound_buffer.playSound(item.record.useSound, b.body.getPos)

proc update*(obj: PPlayer) =
  if not obj.spectator:
    obj.vehicle.update()
    obj.nameTag.setPosition(obj.vehicle.body.getPos.floor + (nameTagOffset * (obj.vehicle.record.physics.radius + 5).cfloat))

proc draw(window: PRenderWindow, player: PPlayer) {.inline.} =
  if not player.spectator:
    if player.vehicle != nil:
      window.draw(player.vehicle.sprite)
    window.draw(player.nameTag)

proc setVehicle(p: PPlayer; v: PVehicle) =
  p.vehicle = v  #sorry mom, this is just how things worked out ;(
  if not v.isNil:
    v.occupant = p

proc createBot() =
  if localBots.len < MaxLocalBots:
    var bot = newPlayer("Dodo Brown")
    bot.setVehicle(newVehicle("Turret0"))
    if bot.isNil:
      echo "BOT IS NIL"
      return
    elif bot.vehicle.isNil:
      echo "BOT VEH IS NIL"
      return
    localBots.add(bot)
    bot.vehicle.body.setPos(vector(100, 100))
    echo "new bot at ", $bot.vehicle.body.getPos()

var inputCursor = newVertexArray(sfml.Lines, 2)
inputCursor[0].position = vec2f(10.0, 10.0)
inputCursor[1].position = vec2f(50.0, 90.0)

proc hasVehicle(p: PPlayer): bool {.inline.} =
  result = not p.spectator and not p.vehicle.isNil

proc setMyVehicle(v: PVehicle) {.inline.} =
  activeVehicle = v
  localPlayer.setVehicle v

proc unspec() =
  var veh = newVehicle("Turret0")
  if not veh.isNil:
    setMyVehicle veh
    localPlayer.spectator = false
    ingameClient.setActive
    veh.body.setPos vector(100, 100)
    veh.shape.setLayers(LPlayer)
    when defined(debugWeps):
      localPlayer.addItem("Mass Driver")
      localPlayer.addItem("Neutron Bomb")
      localPlayer.additem("Dem Lasers")
      localPlayer.addItem("Mold Spore Beam")
      localPlayer.addItem("Genericorp Mine")
      localPlayer.addItem("Gravitic Bomb")
proc spec() =
  setMyVehicle nil
  localPlayer.spectator = true
  specInputClient.setActive

var
  specLimiter = newClock()
  timeBetweenSpeccing = 1.0 #seconds
proc toggleSpec() {.inline.} =
  if specLimiter.getElapsedTime.asSeconds < timeBetweenSpeccing:
    return
  specLimiter.restart()
  if localPlayer.isNil:
    echo("OMG WTF PLAYER IS NILL!!")
  elif localPlayer.spectator: unspec()
  else: spec()

proc addObject*(name: string) =
  var o = newObject(name)
  if not o.isNil:
    echo "Adding object ", o
    discard space.addBody(o.body)
    discard space.addShape(o.shape)
    o.shape.setLayers(LGrabbable)
    objects.add(o)
proc explode(obj: PGameObject) =
  echo obj, " exploded"
  let ind = objects.find(obj)
  if ind != -1:
    delObjects.add ind
proc update(obj: PGameObject; dt: float) =
  if not(obj.anim.next(dt)):
    obj.explode()
  else:
    obj.anim.setPos(obj.body.getPos)
    obj.anim.setAngle(obj.body.getAngle)

proc toggleShipSelect() =
  showShipSelect = not showShipSelect
proc handleLClick() =
  let pos = input_helpers.getMousePos()
  when defined(escapeMenuTest):
    if escMenuOpen:
      escMenu.click(pos)
      return
  if showShipSelect:
    shipSelect.click(pos)
  if localPlayer.spectator:
    specGui.click(pos)

ingameClient.registerHandler(KeyF12, down, proc() = toggleSpec())
ingameClient.registerHandler(KeyF11, down, toggleShipSelect)
ingameClient.registerHandler(MouseLeft, down, handleLClick)
when defined(recordMode):
  if not dirExists("data/snapshots"):
    createDir("data/snapshots")
  ingameClient.registerHandler(keynum9, down, proc() =
    if not isRecording: startRecording()
    else: stopRecording())
  ingameClient.registerHandler(keynum0, down, proc() =
    if snapshots.len > 0 and not isRecording:
      echo "Saving images (LOL)"
      for i in 0..high(snapshots):
        if not(snapshots[i].save("data/snapshots/image"&(zeroPad($i, 3))&".jpg")):
          echo "Could not save"
        snapshots[i].destroy()
      snapshots.setLen 0)
when defined(DebugKeys):
  ingameClient.registerHandler MouseRight, down, proc() =
    echo($activevehicle.body.getAngle.vectorForAngle())
  ingameClient.registerHandler KeyBackslash, down, proc() =
    createBot()
  ingameClient.registerHandler(KeyNum1, down, proc() =
    if localPlayer.items.len == 0:
      localPlayer.addItem("Mass Driver")
      echo "Gave you a mass driverz")
  ingameClient.registerHandler(KeyL, down, proc() =
    echo("len(livebullets) = ", len(livebullets)))
  ingameClient.registerHandler(KeyRShift, down, proc() =
    if keyPressed(KeyR):
      echo("Friction: ", ff(activeVehicle.shape.getFriction()))
      echo("Damping: ", ff(space.getDamping()))
    elif keypressed(KeyM):
      echo("Mass: ", activeVehicle.body.getMass.ff())
      echo("Moment: ", activeVehicle.body.getMoment.ff())
    elif keypressed(KeyI):
      echo(repr(activeVehicle.record))
    elif keyPressed(KeyH):
      activeVehicle.body.setPos(vector(100.0, 100.0))
      activeVehicle.body.setVel(VectorZero)
    elif keyPressed(KeyComma):
      activeVehicle.body.setPos mouseToSpace())
  ingameClient.registerHandler(KeyY, down, proc() =
    const looloo = ["Asteroid1", "Asteroid2"]
    addObject(looloo[rand(looloo.len)]))
  ingameClient.registerHandler(KeyO, down, proc() =
    if objects.len == 0:
      echo "Objects is empty"
      return
    for i, o in pairs(objects):
      echo i, " ", o)
  ingameClient.registerHandler(KeyLBracket, down, sound_buffer.report)
  var
    mouseJoint: PConstraint
    mouseBody = space.addBody(newBody(CpInfinity, CpInfinity))
  ingameClient.registerHandler(MouseMiddle, down, proc() =
    var point = mouseToSpace()
    var shape = space.pointQueryFirst(point, LGrabbable, 0)
    if not mouseJoint.isNil:
      space.removeConstraint mouseJoint
      mouseJoint.destroy()
      mouseJoint = nil
    if shape.isNil:
      return
    let body = shape.getBody()
    mouseJoint = space.addConstraint(
      newPivotJoint(mouseBody, body, VectorZero, body.world2local(point)))
    mouseJoint.maxForce = 50000.0
    mouseJoint.errorBias = pow(1.0 - 0.15, 60))

var specCameraSpeed = 5.0
specInputClient.registerHandler(MouseLeft, down, handleLClick)
specInputClient.registerHandler(KeyF11, down, toggleShipSelect)
specInputClient.registerHandler(KeyF12, down, proc() = toggleSpec())
specInputClient.registerHandler(KeyLShift, down, proc() = specCameraSpeed *= 2)
specInputClient.registerHandler(KeyLShift, up, proc() = specCameraSpeed /= 2)

specInputClient.registerHandler(KeyP, down, proc() =
  echo("addObject(solar mold)")
  addObject("Solar Mold"))

proc resetForcesCB(body: PBody; data: pointer) {.cdecl.} =
  body.resetForces()

var frameCount= 0
proc mainUpdate(dt: float) =
  if localPlayer.spectator:
    if keyPressed(KeyLeft):
      worldView.move(vec2f(-1.0, 0.0) * specCameraSpeed)
    elif keyPressed(KeyRight):
      worldView.move(vec2f( 1.0, 0.0) * specCameraSpeed)
    if keyPressed(KeyUp):
      worldView.move(vec2f(0.0, -1.0) * specCameraSpeed)
    elif keyPressed(KeyDown):
      worldView.move(vec2f(0.0,  1.0) * specCameraSpeed)
  elif not activeVehicle.isNil:
    if keyPressed(KeyUp):
      activeVehicle.accel(dt)
    elif keyPressed(KeyDown):
      activeVehicle.reverse(dt)
    if keyPressed(KeyRight):
      activeVehicle.turn_right(dt)
    elif keyPressed(KeyLeft):
      activeVehicle.turn_left(dt)
    if keyPressed(Keyz):
      activeVehicle.strafe_left(dt)
    elif keyPressed(Keyx):
      activeVehicle.strafe_right(dt)
    if keyPressed(KeyLControl):
      localPlayer.useItem 0
    if keyPressed(KeyTab):
      localPlayer.useItem 1
    if keyPressed(KeyQ):
      localPlayer.useItem 2
    if keyPressed(KeyW):
      localPlayer.useItem 3
    if keyPressed(KeyA):
      localPlayer.useItem 4
    if keyPressed(sfml.KeyS):
      localPlayer.useItem 5
    if keyPressed(KeyD):
      localPlayer.useItem 6
    worldView.setCenter(activeVehicle.body.getPos.floor)#cp2sfml)

  if localPlayer != nil:
    localPlayer.update()
    localPlayer.updateItems(dt)
  for b in localBots:
    b.update()

  for o in items(objects):
    o.update(dt)
  for i in countdown(high(delObjects), 0):
    objects.del i
  delObjects.setLen 0

  var i = 0
  while i < len(liveBullets):
    if liveBullets[i].update(dt):
      liveBullets.del i
    else:
      inc i
  i = 0
  while i < len(explosions):
    if explosions[i].next(dt): inc i
    else: explosions.del i

  when defined(DebugKeys):
    mouseBody.setPos(mouseToSpace())

  space.step(dt)
  space.eachBody(resetForcesCB, nil)

  when defined(foo):
    var coords = window.convertCoords(vec2i(getMousePos()), worldView)
    mouseSprite.setPosition(coords)

  if localPlayer != nil and localPlayer.vehicle != nil:
    let
      pos = localPlayer.vehicle.body.getPos()
      ang = localPlayer.vehicle.body.getAngle.vectorForAngle()
    myPosition[0].x = pos.x
    myPosition[0].z = pos.y
    myPosition[1].x = ang.x
    myPosition[1].z = ang.y
    listenerSetPosition(myPosition[0])
    listenerSetDirection(myPosition[1])

  inc frameCount
  when defined(showFPS):
    if frameCount mod 60 == 0:
      fpsText.setString($(1.0/dt).round)
  if frameCount mod 250 == 0:
    updateSoundBuffer()
    frameCount = 0

proc mainRender() =
  window.clear(Black)
  window.setView(worldView)

  if showStars:
    for star in stars:
      window.draw(star.sprite)
  window.draw(localPlayer)

  for b in localBots:
    window.draw(b)
  for o in objects:
    window.draw(o)

  for b in explosions: window.draw(b)
  for b in liveBullets: window.draw(b)

  when defined(Foo):
    window.draw(mouseSprite)

  window.setView(guiView)

  when defined(EscapeMenuTest):
    if escMenuOpen:
      window.draw escMenu
  when defined(showFPS):
    window.draw(fpsText)
  when defined(recordMode):
    window.draw(recordButton)

  if localPlayer.spectator:
    window.draw(specGui)
  if showShipSelect: window.draw shipSelect
  window.display()

  when defined(recordMode):
    if isRecording:
      if snapshots.len < 100:
        if frameCount mod 5 == 0:
          snapshots.add(window.capture())
      else: stopRecording()

proc readyMainState() =
  specInputClient.setActive()

when true:
  import parseopt

  localPlayer = newPlayer()
  lobbyInit()

  videoMode = getClientSettings().resolution
  window = newRenderWindow(videoMode, "sup", sfDefaultStyle)
  window.setFrameRateLimit 60

  worldView = window.getView.copy()
  guiView = worldView.copy()
  shipSelect.setPosition vec2f(665.0, 50.0)

  when defined(foo):
    mouseSprite = sfml.newCircleShape(14)
    mouseSprite.setFillColor Transparent
    mouseSprite.setOutlineColor RoyalBlue
    mouseSprite.setOutlineThickness 1.4
    mouseSprite.setOrigin vec2f(14, 14)

  lobbyReady()
  playBtn = specGui.newButton(
    "Unspec - F12", position = vec2f(680.0, 8.0), onClick = proc(b: PButton) =
      toggleSpec())

  block:
    var bPlayOffline = false
    for kind, key, val in getOpt():
      case kind
      of cmdArgument:
        if key == "offline": bPlayOffline = true
      else:
        echo "Invalid argument ", key, " ", val
    if bPlayOffline:
      playoffline(nil)

  gameRunning = true
  while gameRunning:
    for event in window.filterEvents:
      if event.kind == EvtClosed:
        gameRunning = false
        break
      elif event.kind == EvtMouseWheelMoved and getActiveState() == Field:
        if event.mouseWheel.delta == 1:
          worldView.zoom(0.9)
        else:
          worldView.zoom(1.1)
    let dt = frameRate.restart.asMilliSeconds().float / 1000.0
    case getActiveState()
    of Field:
      mainUpdate(dt)
      mainRender()
    of Lobby:
      lobbyUpdate(dt)
      lobbyDraw(window)
    else:
      initLevel()
      echo("Done? lol")
      doneWithSaidTransition()
      readyMainState()
