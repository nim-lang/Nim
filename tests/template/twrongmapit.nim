discard """
  output: "####"
"""
# unfortunately our tester doesn't support multiple lines of compiler
# error messages yet...

# bug #1562
type Foo* {.pure, final.} = object
  elt: float

template defineOpAssign(T, op: untyped) =
  proc `op`*(v: var T, w: T) {.inline.} =
    for i in 0..1:
      `op`(v.elt, w.elt)

const ATTEMPT = 0

when ATTEMPT == 0:
  # FAILS: defining `/=` with template calling template
  # ERROR about sem.nim line 144
  template defineOpAssigns(T: untyped) =
    mixin `/=`
    defineOpAssign(T, `/=`)

  defineOpAssigns(Foo)

# bug #1543
import sequtils

(var i = @[""];i).applyIt(it)
# now works:
echo "##", i[0], "##"
