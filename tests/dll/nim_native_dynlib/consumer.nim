import generated/producer_abi

echo "Producer says: ", message()

block customHooks:
  let original = newHooked(7)
  var copied: Hooked
  copied = original
  doAssert copied.value == 7
  doAssert hookedCopyCount() == 1

doAssert hookedDestroyCount() == 2

let moveOnly = newMoveOnly(9)
doAssert moveOnly.value == 9

let renderer = newRenderer("main")
doAssert renderer.name == "main"
doAssert renderer.size.x == 1
doAssert renderer.size.y == 2
doAssert renderer.child.label == "child"
doAssert describe(renderer) == "main:child"

renderer.name = "consumer"
renderer.child.label = "updated"
translate(renderer, Vec2(x: 3, y: 4))

doAssert renderer.name == "consumer"
doAssert renderer.size.x == 4
doAssert renderer.size.y == 6
doAssert describe(renderer) == "consumer:updated"
