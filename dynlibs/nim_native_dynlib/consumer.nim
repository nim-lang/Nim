import generated/producer_abi

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
