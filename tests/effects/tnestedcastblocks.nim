discard """
  output: '''4
3'''
"""
# bug #26092: exiting a nested cast block used to cancel the enclosing
# block's cast for the statements after it.

type Obj = ref object
  x: int
let g: Obj = Obj(x: 1)
var fp: proc(): int {.nimcall.} = proc(): int {.nimcall.} = 2

proc consumer(): int {.gcsafe.} =
  {.cast(gcsafe).}:
    let a = g.x
    var b: int
    {.cast(gcsafe).}:
      b = g.x
    let c = fp()
    a + b + c
echo consumer()

var counter = 0
proc bump() = inc counter

proc pure(): int {.noSideEffect.} =
  {.cast(noSideEffect).}:
    bump()
    {.cast(noSideEffect).}:
      bump()
    bump()
    counter
echo pure()
