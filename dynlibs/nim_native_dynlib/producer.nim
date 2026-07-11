type
  Vec2* = object
    x*, y*: float32

  Child* = ref object
    label*: string

  Renderer* = ref object
    name*: string
    size*: Vec2
    child*: Child

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
