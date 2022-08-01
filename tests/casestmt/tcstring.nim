discard """
  targets: "c cpp js"
"""

type Result = enum none, a, b, c, d, e, f

proc foo1(x: cstring): Result =
  const y = cstring"hash"
  const arr = [cstring"it", cstring"finally"]
  result = none
  case x
  of "Andreas", "Rumpf": result = a
  of cstring"aa", "bb": result = b
  of "cc", y, "when": result = c
  of "will", arr, "be", "generated": result = d
  of nil: result = f

var results = [
  foo1("Rumpf"), foo1("Andreas"),
  foo1("aa"), foo1(cstring"bb"),
  foo1("cc"), foo1("hash"),
  foo1("finally"), foo1("generated"),
  foo1("no"), foo1("another no"),
  foo1(nil)]
doAssert results == [a, a, b, b, c, c, d, d, none, none, f], $results

proc foo2(x: cstring): Result =
  const y = cstring"hash"
  const arr = [cstring"it", cstring"finally"]
  doAssert not (compiles do:
    result = case x
    of "Andreas", "Rumpf": a
    of cstring"aa", "bb": b
    of "cc", y, "when": c
    of "will", arr, "be", "generated": d)
  case x
  of "Andreas", "Rumpf": a
  of cstring"aa", "bb": b
  of "cc", y, "when": c
  of "will", arr, "be", "generated": d
  of nil: f
  else: e

results = [
  foo2("Rumpf"), foo2("Andreas"),
  foo2("aa"), foo2(cstring"bb"),
  foo2("cc"), foo2("hash"),
  foo2("finally"), foo2("generated"),
  foo2("no"), foo2("another no"),
  foo2(nil)]

doAssert results == [a, a, b, b, c, c, d, d, e, e, f], $results
