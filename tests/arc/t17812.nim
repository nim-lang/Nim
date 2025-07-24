discard """
  targets: "c js"
  matrix: "--gc:refc; --gc:arc"
"""

import std/times

block: # bug #17812
  block:
    type
      Task = object
        cb: proc ()

    proc hello() = discard


    let t = Task(cb: hello)

    doAssert t.repr.len > 0


  block:
    type MyObj = object
      field: DateTime


    proc `$`(o: MyObj): string = o.repr

    doAssert ($MyObj()).len > 0

# bug #22175

type Xxx = object
  value: string

proc complete(xxx: ref Xxx, v: sink string) =
  xxx.value = move(v)

let yyy = (ref Xxx)()

yyy.complete("test")
