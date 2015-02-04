import chipmunk, sfml, animations, sg_assets
type
  PGameObject* = ref TGameObject
  TGameObject = object
    body*: chipmunk.PBody
    shape*: chipmunk.PShape
    record*: PObjectRecord
    anim*: PAnimation


proc `$`*(obj: PGameObject): string =
  result = "<Object "
  result.add obj.record.name
  result.add ' '
  result.add($obj.body.getpos())
  result.add '>'
proc free(obj: PGameObject) =
  obj.record = nil
  free(obj.anim)
  obj.anim = nil
proc newObject*(record: PObjectRecord): PGameObject =
  if record.isNil: return nil
  new(result, free)
  result.record = record
  result.anim = newAnimation(record.anim, AnimLoop)
  when false:
    result.sprite = record.anim.spriteSheet.sprite.copy()
  result.body = newBody(result.record.physics.mass, 10.0)
  result.shape = chipmunk.newCircleShape(result.body, result.record.physics.radius, VectorZero)
  result.body.setPos(vector(100, 100))
proc newObject*(name: string): PGameObject =
  result = newObject(fetchObj(name))
proc draw*(window: PRenderWindow, obj: PGameObject) {.inline.} =
  window.draw(obj.anim.sprite)
