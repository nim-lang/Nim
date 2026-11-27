discard """
  description: "IC private iterator graphs preserve recursion, wrappers, top-level expansion and shared storage"
"""

#? metamorphic

#!FILE helper.nim
type Read* = proc(): string
var shared* = 0
iterator readers*[T](tag: T): Read =
  var calls {.global.}: int
  inc calls
  var held = $tag & ":" & $calls
  proc read(n: int): int =
    if n == 0: 0 else: 1 + read(n - 1)
  let f = proc(): string = held & $read(2)
  inc shared
  yield f
  held.add "!"
  yield f

iterator wrapped*(tag: string): Read =
  for f in readers(tag): yield f

#!FILE other.nim
import helper
proc saved*(): Read =
  for f in wrapped("other"):
    result = f

#!FILE main.nim
import helper, other
var top: Read
for f in readers(123): top = f
let otherRead = saved()
proc run() =
  var first, second: Read
  for f in wrapped("first"): first = f
  for f in wrapped("second"): second = f
  echo first(), " ", second(), " ", top(), " ", otherRead()
  echo shared
run()
#!STEP
#!STEP
#!STEP noop
