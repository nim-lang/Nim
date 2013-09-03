# test the new 'compiles' feature:

template supports(opr, x: expr): bool {.immediate.} =
  compiles(opr(x)) or compiles(opr(x, x))

template ok(x: expr): stmt =
  static: assert(x)

template no(x: expr): stmt =
  static: assert(not x)

type
  TObj = object

var
  myObj {.compileTime.}: TObj

ok supports(`==`, myObj)
ok supports(`==`, 45)

no supports(`++`, 34)
ok supports(`not`, true)
ok supports(`+`, 34)

no compiles(4+5.0 * "hallo")

