import
  math,
  sfml, chipmunk,
  sg_assets, sfml_stuff, math_helpers
type
  PAnimation* = ref TAnimation
  TAnimation* = object
    sprite*: PSprite
    record*: PAnimationRecord
    delay*: float
    index*: int
    direction*: int
    spriteRect*: TIntRect
    style*: TAnimationStyle
  TAnimationStyle* = enum
    AnimLoop = 0'i8, AnimBounce, AnimOnce

proc setPos*(obj: PAnimation; pos: TVector) {.inline.}
proc setPos*(obj: PAnimation; pos: TVector2f) {.inline.}
proc setAngle*(obj: PAnimation; radians: float) {.inline.}

proc free*(obj: PAnimation) =
  obj.sprite.destroy()
  obj.record = nil

proc newAnimation*(src: PAnimationRecord; style: TAnimationStyle): PAnimation =
  new(result, free)
  result.sprite = src.spriteSheet.sprite.copy()
  result.record = src
  result.delay = src.delay
  result.index = 0
  result.direction = 1
  result.spriteRect = result.sprite.getTextureRect()
  result.style = style
proc newAnimation*(src: PAnimationRecord; style: TAnimationStyle;
                    pos: TVector2f; angle: float): PAnimation =
  result = newAnimation(src, style)
  result.setPos pos
  setAngle(result, angle)

proc next*(obj: PAnimation; dt: float): bool {.discardable.} =
  ## step the animation. Returns false if the object is out of frames
  result = true
  obj.delay -= dt
  if obj.delay <= 0.0:
    obj.delay += obj.record.delay
    obj.index += obj.direction
    #if obj.index > (obj.record.spriteSheet.cols - 1) or obj.index < 0:
    if not(obj.index in 0..(obj.record.spriteSheet.cols - 1)):
      case obj.style
      of AnimOnce:
        return false
      of AnimBounce:
        obj.direction *= -1
        obj.index += obj.direction * 2
      of AnimLoop:
        obj.index = 0
    obj.spriteRect.left = obj.index.cint * obj.record.spriteSheet.frameW.cint
    obj.sprite.setTextureRect obj.spriteRect

proc setPos*(obj: PAnimation; pos: TVector) =
  setPosition(obj.sprite, pos.floor())
proc setPos*(obj: PAnimation; pos: TVector2f) =
  setPosition(obj.sprite, pos)
proc setAngle*(obj: PAnimation; radians: float)  =
  let rads = (radians + obj.record.angle).wmod(TAU)
  if obj.record.spriteSheet.rows > 1:
    ## (rotation percent * rows).floor * frameheight
    obj.spriteRect.top = (rads / TAU * obj.record.spriteSheet.rows.float).floor.cint * obj.record.spriteSheet.frameh.cint
    obj.sprite.setTextureRect obj.spriteRect
  else:
    setRotation(obj.sprite, degrees(rads)) #stupid sfml, who uses degrees these days? -__-

proc draw*(window: PRenderWindow; obj: PAnimation) {.inline.} =
  window.draw(obj.sprite)
