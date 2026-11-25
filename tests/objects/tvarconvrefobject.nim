discard """
  action: "compile"
"""

# #26775: viewing a `ref`/`ptr` object as its parent type through a conversion
# must not keep the l-value: the callee could store a parent into a variable
# that holds a child, and the child's fields would be read past that object.

type
  P = ref object of RootObj
    a: int
  C = ref object of P
    s: string
  PP = ptr object of RootObj
    a: int
  CP = ptr object of PP
    s: string
  DP = distinct P
  PV = object of RootObj
    a: int
  CV = object of PV
    s: string

proc setRef(x: var P) = x = P(a: 3)
proc setPtr(x: var PP) = x = nil
proc setVal(x: var PV) = x.a = 3

var
  c = C(a: 1, s: "hello")
  p = P(a: 1)
  dp = DP(P(a: 1))
  cp: CP
  pp: PP
  cv = CV(a: 1, s: "hello")
  pv = PV(a: 1)

doAssert not compiles(setRef(P(c)))
doAssert not compiles(setPtr(PP(cp)))

# the exact type, and an object (not reference) seen as its parent, stay mutable
doAssert compiles(setRef(p))
doAssert compiles(setRef(P(p)))
# a distinct reference seen as its base type is the same value set (std/json)
doAssert compiles(setRef(P(dp)))
doAssert compiles(setPtr(pp))
doAssert compiles(setVal(pv))
doAssert compiles(setVal(PV(cv)))
