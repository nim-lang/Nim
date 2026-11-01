discard """
  description: "IC inline iterator captures survive reuse, environment edits, and multiple importers"
"""

#? metamorphic

#!FILE helper.nim
type Read* = proc(): string {.gcsafe.}

iterator closures*(tag: string): Read =
  var held = tag
  let read = proc(): string = held
  yield read

#!FILE other.nim
import helper
proc saved*(): Read =
  for read in closures("other"):
    result = read

#!FILE main.nim
import helper, other
proc run() =
  var readers: array[4, Read]
  readers[0] = saved()
  for i in 0 .. 2:
    for read in closures("main" & $i):
      readers[i + 1] = read
  for read in readers:
    echo read()
run()
#!STEP
#!STEP
#!STEP noop

# A body-only edit grows the environment without changing the signature.
#!FILE helper.nim
type Read* = proc(): string {.gcsafe.}

iterator closures*(tag: string): Read =
  var held = tag
  var calls = 0
  let read = proc(): string =
    inc calls
    held & ":" & $calls
  yield read
#!STEP body-edit
#!STEP
#!STEP noop
