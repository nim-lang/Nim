import macros, tables

var mapping {.compileTime.}: Table[string, NimNode]

macro register(a: static[string], b: typed): untyped =
  mapping[a] = b

macro getPtr(a: static[string]): untyped =
  result = mapping[a]

proc foo() =
  iterator it() {.closure.} =
    discard
  proc getIterPtr(): pointer {.nimcall.} =
    rawProc(it)
  register("foo", getIterPtr())
  discard getIterPtr() # Comment either this to make it work
foo() # or this

proc bar() =
  iterator it() {.closure.} =
    discard getPtr("foo") # Or this
    discard
  proc getIterPtr(): pointer {.nimcall.} =
    rawProc(it)
  register("bar", getIterPtr())
  discard getIterPtr()
bar()
