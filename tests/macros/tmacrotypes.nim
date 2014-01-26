import macros, typetraits

macro checkType(ex, expected: expr): stmt {.immediate.} =
  var t = ex.typ
  assert t.name == expected.strVal

proc voidProc = echo "hello"
proc intProc(a, b): int = 10

checkType(voidProc(), "void")
checkType(intProc(10, 20.0), "int")
checkType(noproc(10, 20.0), "Error Type")
