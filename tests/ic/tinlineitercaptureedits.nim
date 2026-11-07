discard """
  description: "IC inline iterator captures survive reuse, environment edits, and multiple importers"
"""

#? metamorphic

#!FILE helper.nim
type Read* = proc(): string {.gcsafe.}

iterator closures*(tag: string; count: var int): Read =
  inc count
  var held = tag
  let read = proc(): string = held
  yield read

#!FILE other.nim
import helper
proc saved*(): Read =
  var count = 0
  for read in closures("other", count):
    result = read
  doAssert count == 1

#!FILE main.nim
import helper, other
proc run() =
  var readers: array[4, Read]
  var count = 0
  readers[0] = saved()
  for i in 0 .. 2:
    for read in closures("main" & $i, count):
      readers[i + 1] = read
  doAssert count == 3
  for read in readers:
    echo read()
run()
#!STEP
#!STEP
#!STEP noop

# A body-only edit grows the environment without changing the signature.
#!FILE helper.nim
type Read* = proc(): string {.gcsafe.}

iterator closures*(tag: string; count: var int): Read =
  inc count
  var held = tag
  var calls = 0
  let read = proc(): string =
    inc calls
    held & ":" & $calls
  yield read
#!STEP body-edit
#!STEP
#!STEP noop
