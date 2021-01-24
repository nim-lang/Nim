import json
type Test = enum
  one, two, three, four, five
let a = [
  one: 300,
  two: 20,
  three: 10,
  four: 0,
  five: -10
]
doAssert (%* a).to(a.typeof) == a