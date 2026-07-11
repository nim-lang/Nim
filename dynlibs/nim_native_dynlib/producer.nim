type
  Vec2* = object
    x*, y*: float32

  Child* = ref object
    label*: string

  Renderer* = ref object
    name*: string
    size*: Vec2
    child*: Child

proc newRenderer*(name: string): Renderer {.exportnim.} =
  Renderer(
    name: name,
    size: Vec2(x: 1, y: 2),
    child: Child(label: "child"))

proc translate*(renderer: Renderer; delta: Vec2) {.exportnim.} =
  renderer.size.x += delta.x
  renderer.size.y += delta.y

proc describe*(renderer: Renderer): string {.exportnim.} =
  renderer.name & ":" & renderer.child.label
