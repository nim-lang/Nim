type
  Vec2* = object
    x*, y*: float32

  Child* = ref object
    label*: string

  Renderer* = ref object
    name*: string
    size*: Vec2
    child*: Child

  Hooked* = object
    value*: int

  MoveOnly* = object
    value*: int

var
  hookedCopies = 0
  hookedDestroys = 0
  moveOnlyDestroys = 0

proc `=destroy`(hooked: Hooked) =
  if hooked.value != 0:
    inc hookedDestroys

proc `=copy`(dest: var Hooked; source: Hooked) =
  inc hookedCopies
  dest.value = source.value

proc `=destroy`(moveOnly: MoveOnly) =
  if moveOnly.value != 0:
    inc moveOnlyDestroys

proc `=copy`(dest: var MoveOnly; source: MoveOnly) {.error.}

proc newRenderer*(name: string): Renderer {.exportabi.} =
  Renderer(
    name: name,
    size: Vec2(x: 1, y: 2),
    child: Child(label: "child"))

proc translate*(renderer: Renderer; delta: Vec2) {.exportabi.} =
  renderer.size.x += delta.x
  renderer.size.y += delta.y

proc describe*(renderer: Renderer): string {.exportabi.} =
  renderer.name & ":" & renderer.child.label

proc message*(): string {.exportabi.} =
  "hello from the producer dynlib"

proc newHooked*(value: int): Hooked {.exportabi.} =
  Hooked(value: value)

proc hookedCopyCount*(): int {.exportabi.} =
  hookedCopies

proc hookedDestroyCount*(): int {.exportabi.} =
  hookedDestroys

proc newMoveOnly*(value: int): MoveOnly {.exportabi.} =
  MoveOnly(value: value)
