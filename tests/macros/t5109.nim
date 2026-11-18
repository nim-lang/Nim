# bug #5109: symbols for builtin types returned by getType compare equal
import std/macros

proc eq(x, y: typedesc): bool {.compileTime.} =
  let xSym = x.getType
  let ySym = y.getType
  xSym.expectKind(nnkSym)
  ySym.expectKind(nnkSym)
  xSym == ySym

type MyInt = int

static:
  doAssert eq(int, int)
  doAssert eq(string, string)
  doAssert eq(float, float)
  doAssert eq(MyInt, int)
  doAssert not eq(int, int8)
  doAssert not eq(float, float32)
  doAssert $int.getType == "int"
