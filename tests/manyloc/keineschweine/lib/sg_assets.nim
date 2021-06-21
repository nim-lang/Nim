import
  re, json, strutils, tables, math, os, math_helpers,
  sg_packets, md5, zlib_helpers

when defined(NoSFML):
  import server_utils
  type TVector2i = object
    x*, y*: int32
  proc vec2i(x, y: int32): TVector2i =
    result.x = x
    result.y = y
else:
  import sfml, sfml_audio, sfml_stuff
when not defined(NoChipmunk):
  import chipmunk

type
  TChecksumFile* = object
    unpackedSize*: int
    sum*: MD5Digest
    compressed*: string
  PZoneSettings* = ref TZoneSettings
  TZoneSettings* = object
    vehicles: seq[PVehicleRecord]
    items: seq[PItemRecord]
    objects: seq[PObjectRecord]
    bullets: seq[PBulletRecord]
    levelSettings: PLevelSettings
  PLevelSettings* = ref TLevelSettings
  TLevelSettings* = object
    size*: TVector2i
    starfield*: seq[PSpriteSheet]
  PVehicleRecord* = ref TVehicleRecord
  TVehicleRecord* = object
    id*: int16
    name*: string
    playable*: bool
    anim*: PAnimationRecord
    physics*: TPhysicsRecord
    handling*: THandlingRecord
  TItemKind* = enum
    Projectile, Utility, Ammo
  PObjectRecord* = ref TObjectRecord
  TObjectRecord* = object
    id*: int16
    name*: string
    anim*: PAnimationRecord
    physics*: TPhysicsRecord
  PItemRecord* = ref TItemRecord
  TItemRecord* = object
    id*: int16
    name*: string
    anim*: PAnimationRecord
    physics*: TPhysicsRecord ##apply when the item is dropped in the arena
    cooldown*: float
    energyCost*: float
    useSound*: PSoundRecord
    case kind*: TItemKind
    of Projectile:
      bullet*: PBulletRecord
    else:
      discard
  PBulletRecord* = ref TBulletRecord
  TBulletRecord* = object
    id*: int16
    name*: string
    anim*: PAnimationRecord
    physics*: TPhysicsRecord
    lifetime*, inheritVelocity*, baseVelocity*: float
    explosion*: TExplosionRecord
    trail*: TTrailRecord
  TTrailRecord* = object
    anim*: PAnimationRecord
    timer*: float ##how often it should be created
  TPhysicsRecord* = object
    mass*: float
    radius*: float
    moment*: float
  THandlingRecord = object
    thrust*, top_speed*: float
    reverse*, strafe*, rotation*: float
  TSoulRecord = object
    energy*: int
    health*: int
  TExplosionRecord* = object
    anim*: PAnimationRecord
    sound*: PSoundRecord
  PAnimationRecord* = ref TAnimationRecord
  TAnimationRecord* = object
    spriteSheet*: PSpriteSheet
    angle*: float
    delay*: float  ##animation delay
  PSoundRecord* = ref TSoundRecord
  TSoundRecord* = object
    file*: string
    when defined(NoSFML):
      contents*: TChecksumFile
    else:
      soundBuf*: PSoundBuffer
  PSpriteSheet* = ref TSpriteSheet
  TSpriteSheet* = object
    file*: string
    framew*,frameh*: int
    rows*, cols*: int
    when defined(NoSFML):
      contents*: TChecksumFile
    when not defined(NoSFML):
      sprite*: PSprite
      tex*: PTexture
  TGameState* = enum
    Lobby, Transitioning, Field
const
  MomentMult* = 0.62 ## global moment of inertia multiplier
var
  cfg: PZoneSettings
  SpriteSheets* = initTable[string, PSpriteSheet](64)
  SoundCache  * = initTable[string, PSoundRecord](64)
  nameToVehID*: Table[string, int]
  nameToItemID*: Table[string, int]
  nameToObjID*: Table[string, int]
  nameToBulletID*: Table[string, int]
  activeState = Lobby

proc newSprite*(filename: string; errors: var seq[string]): PSpriteSheet
proc load*(ss: PSpriteSheet): bool {.discardable.}
proc newSound*(filename: string; errors: var seq[string]): PSoundRecord
proc load*(s: PSoundRecord): bool {.discardable.}

proc validateSettings*(settings: JsonNode; errors: var seq[string]): bool
proc loadSettings*(rawJson: string, errors: var seq[string]): bool
proc loadSettingsFromFile*(filename: string, errors: var seq[string]): bool

proc fetchVeh*(name: string): PVehicleRecord
proc fetchItm*(itm: string): PItemRecord
proc fetchObj*(name: string): PObjectRecord
proc fetchBullet(name: string): PBulletRecord

proc importLevel(data: JsonNode; errors: var seq[string]): PLevelSettings
proc importVeh(data: JsonNode; errors: var seq[string]): PVehicleRecord
proc importObject(data: JsonNode; errors: var seq[string]): PObjectRecord
proc importItem(data: JsonNode; errors: var seq[string]): PItemRecord
proc importPhys(data: JsonNode): TPhysicsRecord
proc importAnim(data: JsonNode; errors: var seq[string]): PAnimationRecord
proc importHandling(data: JsonNode): THandlingRecord
proc importBullet(data: JsonNode; errors: var seq[string]): PBulletRecord
proc importSoul(data: JsonNode): TSoulRecord
proc importExplosion(data: JsonNode; errors: var seq[string]): TExplosionRecord
proc importSound*(data: JsonNode; errors: var seq[string]; fieldName: string = ""): PSoundRecord

## this is the only pipe between lobby and main.nim
proc getActiveState*(): TGameState =
  result = activeState
proc transition*() =
  assert activeState == Lobby, "Transition() called from a state other than lobby!"
  activeState = Transitioning
proc doneWithSaidTransition*() =
  assert activeState == Transitioning, "Finished() called from a state other than transitioning!"
  activeState = Field


proc checksumFile*(filename: string): TChecksumFile =
  let fullText = readFile(filename)
  result.unpackedSize = fullText.len
  result.sum = toMD5(fullText)
  result.compressed = compress(fullText)
proc checksumStr*(str: string): TChecksumFile =
  result.unpackedSize = str.len
  result.sum = toMD5(str)
  result.compressed = compress(str)


##at this point none of these should ever be freed
proc free*(obj: PZoneSettings) =
  echo "Free'd zone settings"
proc free*(obj: PSpriteSheet) =
  echo "Free'd ", obj.file
proc free*(obj: PSoundRecord) =
  echo "Free'd ", obj.file

proc loadAllAssets*() =
  var
    loaded = 0
    failed = 0
  for name, ss in SpriteSheets.pairs():
    if load(ss):
      inc loaded
    else:
      inc failed
  echo loaded," sprites loaded. ", failed, " sprites failed."
  loaded = 0
  failed = 0
  for name, s in SoundCache.pairs():
    if load(s):
      inc loaded
    else:
      inc failed
  echo loaded, " sounds loaded. ", failed, " sounds failed."
proc getLevelSettings*(): PLevelSettings =
  result = cfg.levelSettings

iterator playableVehicles*(): PVehicleRecord =
  for v in cfg.vehicles.items():
    if v.playable:
      yield v

template allAssets*(body: untyped) {.dirty.}=
  block:
    var assetType = FGraphics
    for file, asset in pairs(SpriteSheets):
      body
    assetType = FSound
    for file, asset in pairs(SoundCache):
      body

template cacheImpl(procName, cacheName, resultType, body: untyped) {.dirty.} =
  proc procName*(filename: string; errors: var seq[string]): resulttype =
    if hasKey(cacheName, filename):
      return cacheName[filename]
    new(result, free)
    body
    cacheName[filename] = result

template checkFile(path: untyped) {.dirty.} =
  if not fileExists(path):
    errors.add("File missing: " & path)

cacheImpl newSprite, SpriteSheets, PSpriteSheet:
  result.file = filename
  if filename =~ re"\S+_(\d+)x(\d+)\.\S\S\S":
    result.framew = strutils.parseInt(matches[0])
    result.frameh = strutils.parseInt(matches[1])
    checkFile("data/gfx"/result.file)
  else:
    errors.add "Bad file: " & filename & " must be in format name_WxH.png"
    return

cacheImpl newSound, SoundCache, PSoundRecord:
  result.file = filename
  checkFile("data/sfx"/result.file)

proc expandPath*(assetType: TAssetType; fileName: string): string =
  result = "data/"
  case assetType
  of FGraphics: result.add "gfx/"
  of FSound:    result.add "sfx/"
  else: discard
  result.add fileName
proc expandPath*(fc: ScFileChallenge): string {.inline.} =
  result = expandPath(fc.assetType, fc.file)

when defined(NoSFML):
  proc load*(ss: PSpriteSheet): bool =
    if not ss.contents.unpackedSize == 0: return
    ss.contents = checksumFile(expandPath(FGraphics, ss.file))
    result = true
  proc load*(s: PSoundRecord): bool =
    if not s.contents.unpackedSize == 0: return
    s.contents = checksumFile(expandPath(FSound, s.file))
    result = true
else:
  proc load*(ss: PSpriteSheet): bool =
    if not ss.sprite.isNil:
      return
    var image = sfml.newImage("data/gfx/"/ss.file)
    if image == nil:
      echo "Image could not be loaded"
      return
    let size = image.getSize()
    ss.rows = int(size.y / ss.frameh) #y is h
    ss.cols = int(size.x / ss.framew) #x is w
    ss.tex = newTexture(image)
    image.destroy()
    ss.sprite = newSprite()
    ss.sprite.setTexture(ss.tex, true)
    ss.sprite.setTextureRect(intrect(0, 0, ss.framew.cint, ss.frameh.cint))
    ss.sprite.setOrigin(vec2f(ss.framew / 2, ss.frameh / 2))
    result = true
  proc load*(s: PSoundRecord): bool =
    s.soundBuf = newSoundBuffer("data/sfx"/s.file)
    if not s.soundBuf.isNil:
      result = true

template addError(e: untyped) =
  errors.add(e)
  result = false
proc validateSettings*(settings: JsonNode, errors: var seq[string]): bool =
  result = true
  if settings.kind != JObject:
    addError("Settings root must be an object")
    return
  if not settings.hasKey("vehicles"):
    addError("Vehicles section missing")
  if not settings.hasKey("objects"):
    errors.add("Objects section is missing")
    result = false
  if not settings.hasKey("level"):
    errors.add("Level settings section is missing")
    result = false
  else:
    let lvl = settings["level"]
    if lvl.kind != JObject or not lvl.hasKey("size"):
      errors.add("Invalid level settings")
      result = false
    elif not lvl.hasKey("size") or lvl["size"].kind != JArray or lvl["size"].len != 2:
      errors.add("Invalid/missing level size")
      result = false
  if not settings.hasKey("items"):
    errors.add("Items section missing")
    result = false
  else:
    let items = settings["items"]
    if items.kind != JArray or items.len == 0:
      errors.add "Invalid or empty item list"
    else:
      var id = 0
      for i in items.items:
        if i.kind != JArray: errors.add("Item #$1 is not an array" % $id)
        elif i.len != 3: errors.add("($1) Item record should have 3 fields"%($id))
        elif i[0].kind != JString or i[1].kind != JString or i[2].kind != JObject:
          errors.add("($1) Item should be in form [name, type, {item: data}]" % $id)
          result = false
        inc id

proc loadSettingsFromFile*(filename: string, errors: var seq[string]): bool =
  if not fileExists(filename):
    errors.add("File does not exist: "&filename)
  else:
    result = loadSettings(readFile(filename), errors)

proc loadSettings*(rawJson: string, errors: var seq[string]): bool =
  var settings: JsonNode
  try:
    settings = parseJson(rawJson)
  except JsonParsingError:
    errors.add("JSON parsing error: " & getCurrentExceptionMsg())
    return
  except:
    errors.add("Unknown exception: " & getCurrentExceptionMsg())
    return
  if not validateSettings(settings, errors):
    return
  if cfg != nil: #TODO try this
    echo("Overwriting zone settings")
    free(cfg)
    cfg = nil
  new(cfg, free)
  cfg.levelSettings = importLevel(settings, errors)
  cfg.vehicles = @[]
  cfg.items = @[]
  cfg.objects = @[]
  cfg.bullets = @[]
  nameToVehID = initTable[string, int](32)
  nameToItemID = initTable[string, int](32)
  nameToObjID = initTable[string, int](32)
  nameToBulletID = initTable[string, int](32)
  var
    vID = 0'i16
    bID = 0'i16
  for vehicle in settings["vehicles"].items:
    var veh = importVeh(vehicle, errors)
    veh.id = vID
    cfg.vehicles.add veh
    nameToVehID[veh.name] = veh.id
    inc vID
  vID = 0
  if settings.hasKey("bullets"):
    for blt in settings["bullets"].items:
      var bullet = importBullet(blt, errors)
      bullet.id = bID
      cfg.bullets.add bullet
      nameToBulletID[bullet.name] = bullet.id
      inc bID
  for item in settings["items"].items:
    var itm = importItem(item, errors)
    itm.id = vID
    cfg.items.add itm
    nameToItemID[itm.name] = itm.id
    inc vID
    if itm.kind == Projectile:
      if itm.bullet.isNil:
        errors.add("Projectile #$1 has no bullet!" % $vID)
      elif itm.bullet.id == -1:
        ## this item has an anonymous bullet, fix the ID and name
        itm.bullet.id = bID
        itm.bullet.name = itm.name
        cfg.bullets.add itm.bullet
        nameToBulletID[itm.bullet.name] = itm.bullet.id
        inc bID
  vID = 0
  for obj in settings["objects"].items:
    var o = importObject(obj, errors)
    o.id = vID
    cfg.objects.add o
    nameToObjID[o.name] = o.id
    inc vID
  result = (errors.len == 0)

proc `$`*(obj: PSpriteSheet): string =
  return "<Sprite $1 ($2x$3) $4 rows $5 cols>" % [obj.file, $obj.framew, $obj.frameh, $obj.rows, $obj.cols]

proc fetchVeh*(name: string): PVehicleRecord =
  return cfg.vehicles[nameToVehID[name]]
proc fetchItm*(itm: string): PItemRecord =
  return cfg.items[nameToItemID[itm]]
proc fetchObj*(name: string): PObjectRecord =
  return cfg.objects[nameToObjID[name]]
proc fetchBullet(name: string): PBulletRecord =
  return cfg.bullets[nameToBulletID[name]]

proc getField(node: JsonNode, field: string, target: var float) =
  if not node.hasKey(field):
    return
  if node[field].kind == JFloat:
    target = node[field].fnum
  elif node[field].kind == JInt:
    target = node[field].num.float
proc getField(node: JsonNode, field: string, target: var int) =
  if not node.hasKey(field):
    return
  if node[field].kind == JInt:
    target = node[field].num.int
  elif node[field].kind == JFloat:
    target = node[field].fnum.int
proc getField(node: JsonNode; field: string; target: var bool) =
  if not node.hasKey(field):
    return
  case node[field].kind
  of JBool:
    target = node[field].bval
  of JInt:
    target = (node[field].num != 0)
  of JFloat:
    target = (node[field].fnum != 0.0)
  else: discard

template checkKey(node: untyped; key: string) =
  if not hasKey(node, key):
    return

proc importTrail(data: JsonNode; errors: var seq[string]): TTrailRecord =
  checkKey(data, "trail")
  result.anim = importAnim(data["trail"], errors)
  result.timer = 1000.0
  getField(data["trail"], "timer", result.timer)
  result.timer /= 1000.0
proc importLevel(data: JsonNode; errors: var seq[string]): PLevelSettings =
  new(result)
  result.size = vec2i(5000, 5000)
  result.starfield = @[]

  checkKey(data, "level")
  var level = data["level"]
  if level.hasKey("size") and level["size"].kind == JArray and level["size"].len == 2:
    result.size.x = level["size"][0].num.cint
    result.size.y = level["size"][1].num.cint
  if level.hasKey("starfield"):
    for star in level["starfield"].items:
      result.starfield.add(newSprite(star.str, errors))
proc importPhys(data: JsonNode): TPhysicsRecord =
  result.radius = 20.0
  result.mass = 10.0

  if data.hasKey("physics") and data["physics"].kind == JObject:
    let phys = data["physics"]
    phys.getField("radius", result.radius)
    phys.getField("mass", result.mass)
  when not defined(NoChipmunk):
    result.moment = momentForCircle(result.mass, 0.0, result.radius, VectorZero) * MomentMult
proc importHandling(data: JsonNode): THandlingRecord =
  result.thrust = 45.0
  result.topSpeed = 100.0 #unused
  result.reverse = 30.0
  result.strafe = 30.0
  result.rotation = 2200.0

  checkKey(data, "handling")
  if data["handling"].kind != JObject:
    return

  let hand = data["handling"]
  hand.getField("thrust", result.thrust)
  hand.getField("top_speed", result.topSpeed)
  hand.getField("reverse", result.reverse)
  hand.getField("strafe", result.strafe)
  hand.getField("rotation", result.rotation)
proc importAnim(data: JsonNode, errors: var seq[string]): PAnimationRecord =
  new(result)
  result.angle = 0.0
  result.delay = 1000.0
  result.spriteSheet = nil

  if data.hasKey("anim"):
    let anim = data["anim"]
    if anim.kind == JObject:
      if anim.hasKey("file"):
        result.spriteSheet = newSprite(anim["file"].str, errors)

      anim.getField "angle", result.angle
      anim.getField "delay", result.delay
    elif data["anim"].kind == JString:
      result.spriteSheet = newSprite(anim.str, errors)

  result.angle = radians(result.angle) ## comes in as degrees
  result.delay /= 1000 ## delay comes in as milliseconds
proc importSoul(data: JsonNode): TSoulRecord =
  result.energy = 10000
  result.health = 1
  checkKey(data, "soul")
  let soul = data["soul"]
  soul.getField("energy", result.energy)
  soul.getField("health", result.health)
proc importExplosion(data: JsonNode; errors: var seq[string]): TExplosionRecord =
  checkKey(data, "explode")
  let expl = data["explode"]
  result.anim = importAnim(expl, errors)
  result.sound = importSound(expl, errors, "sound")
proc importSound*(data: JsonNode; errors: var seq[string]; fieldName: string = ""): PSoundRecord =
  if data.kind == JObject:
    checkKey(data, fieldName)
    result = newSound(data[fieldName].str, errors)
  elif data.kind == JString:
    result = newSound(data.str, errors)

proc importVeh(data: JsonNode; errors: var seq[string]): PVehicleRecord =
  new(result)
  result.playable = false
  if data.kind != JArray or data.len != 2 or
    (data.kind == JArray and
      (data[0].kind != JString or data[1].kind != JObject)):
    result.name = "(broken)"
    errors.add "Vehicle record is malformed"
    return
  var vehData = data[1]
  result.name = data[0].str
  result.anim = importAnim(vehdata, errors)
  result.physics = importPhys(vehdata)
  result.handling = importHandling(vehdata)
  vehdata.getField("playable", result.playable)
  if result.anim.spriteSheet.isNil and result.playable:
    result.playable = false
proc importObject(data: JsonNode; errors: var seq[string]): PObjectRecord =
  new(result)
  if data.kind != JArray or data.len != 2:
    result.name = "(broken)"
    return
  result.name = data[0].str
  result.anim = importAnim(data[1], errors)
  result.physics = importPhys(data[1])
proc importItem(data: JsonNode; errors: var seq[string]): PItemRecord =
  new(result)
  if data.kind != JArray or data.len != 3:
    result.name = "(broken)"
    errors.add "Item record is malformed"
    return
  result.name = data[0].str
  result.anim = importAnim(data[2], errors)
  result.physics = importPhys(data[2])

  result.cooldown = 100.0
  data[2].getField("cooldown", result.cooldown)
  result.cooldown /= 1000.0  ##cooldown is stored in ms

  result.useSound = importSound(data[2], errors, "useSound")

  case data[1].str.toLowerAscii
  of "projectile":
    result.kind = Projectile
    if data[2]["bullet"].kind == JString:
      result.bullet = fetchBullet(data[2]["bullet"].str)
    elif data[2]["bullet"].kind == JInt:
      result.bullet = cfg.bullets[data[2]["bullet"].num.int]
    elif data[2]["bullet"].kind == JObject:
      result.bullet = importBullet(data[2]["bullet"], errors)
    else:
      errors.add "UNKNOWN BULLET TYPE for item " & result.name
  of "ammo":
    result.kind = Ammo
  of "utility":
    discard
  else:
    errors.add "Invalid item type \""&data[1].str&"\" for item "&result.name

proc importBullet(data: JsonNode; errors: var seq[string]): PBulletRecord =
  new(result)
  result.id = -1

  var bdata: JsonNode
  if data.kind == JArray:
    result.name = data[0].str
    bdata = data[1]
  elif data.kind == JObject:
    bdata = data
  else:
    errors.add "Malformed bullet record"
    return

  result.anim = importAnim(bdata, errors)
  result.physics = importPhys(bdata)

  result.lifetime = 2000.0
  result.inheritVelocity = 1000.0
  result.baseVelocity = 30.0
  getField(bdata, "lifetime", result.lifetime)
  getField(bdata, "inheritVelocity", result.inheritVelocity)
  getField(bdata, "baseVelocity", result.baseVelocity)
  result.lifetime /= 1000.0 ## lifetime is stored as milliseconds
  result.inheritVelocity /= 1000.0 ## inherit velocity 1000 = 1.0 (100%)
  result.explosion = importExplosion(bdata, errors)
  result.trail = importTrail(bdata, errors)
