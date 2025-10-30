discard """
  targets: "c cpp js"
  matrix: "--mm:refc; --mm:orc"
"""

#bug #6049
import uselocks
import std/assertions

var m = createMyType[int]()
doAssert m.use() == 3


import std/locks

type
  S = object
    r: proc()

  B = object
    d: Lock
    w: S

proc v(x: ptr B) {.exportc.} = reset(x[])

type
  Test = object
    path: string # Removing this makes both cases work.
    lock: Lock

# A: This is not fine.
var a = Test()

proc main(): void =
  # B: This is fine.
  var b = Test()

main()
