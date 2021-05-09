import macros

# bug #5034

macro copyImpl(srsProc: typed, toSym: untyped) =
  result = copyNimTree(getImplTransformed(srsProc))
  result[0] = ident $toSym.toStrLit()

proc foo1(x: float, one: bool = true): float =
  if one:
    return 1'f
  result = x

proc bar1(what: string): string =
  ## be a little more adversarial with `skResult`
  proc buzz: string =
    result = "lightyear"
  if what == "buzz":
    result = "buzz " & buzz()
  else:
    result = what
  return result

copyImpl(foo1, foo2)
doAssert foo1(1'f) == 1.0
doAssert foo2(10.0, false) == 10.0
doAssert foo2(10.0) == 1.0

copyImpl(bar1, bar2)
doAssert bar1("buzz") == "buzz lightyear"
doAssert bar1("macros") == "macros"
