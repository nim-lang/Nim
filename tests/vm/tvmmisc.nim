

# bug #4462
import macros

proc foo(t: typedesc) {.compileTime.} =
  echo getType(t).treeRepr

static:
  foo(int)

# #4412
proc default[T](t: typedesc[T]): T {.inline.} = discard

static:
  var x = default(type(0))
