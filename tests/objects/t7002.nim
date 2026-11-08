discard """
  matrix: "--mm:arc; --mm:orc; --mm:refc"
"""

# bug #7002: assigning an object of a subtype to a location of its base type
# by value slices it; refc and arc/orc both raise ObjectAssignmentDefect.

type
  BaseObj = object of RootObj
    name: string
  DerivedObj = object of BaseObj
    extra: int
  MoreDerivedObj = object of DerivedObj
    more: string

  TrivialBase = object of RootObj
    x: int
  TrivialDerived = object of TrivialBase
    y: int

proc makeDerived(): DerivedObj = DerivedObj(name: "m", extra: 1)

proc copyFromVar(x: var BaseObj): string =
  var b: BaseObj
  b = x
  result = b.name

proc copyFromVarTrivial(x: var TrivialBase): int =
  var b: TrivialBase
  b = x
  result = b.x

block: # the example of #7002
  var dob = DerivedObj(name: "d", extra: 42)
  var base: BaseObj
  doAssertRaises(ObjectAssignmentDefect):
    base = dob

block: # a moved value slices too
  var base: BaseObj
  doAssertRaises(ObjectAssignmentDefect):
    base = makeDerived()

block: # initialization
  var dob = DerivedObj(name: "d", extra: 42)
  doAssertRaises(ObjectAssignmentDefect):
    var base: BaseObj = dob
    discard base

block: # a `var BaseObj` parameter that holds a DerivedObj
  var dob = DerivedObj(name: "v", extra: 42)
  doAssertRaises(ObjectAssignmentDefect):
    discard copyFromVar(dob)

block: # objects without managed fields
  var d = TrivialDerived(x: 1, y: 2)
  var b: TrivialBase
  doAssertRaises(ObjectAssignmentDefect):
    b = d
  doAssertRaises(ObjectAssignmentDefect):
    discard copyFromVarTrivial(d)

block: # a deeper subtype assigned to an intermediate type
  var m = MoreDerivedObj(name: "x", extra: 1, more: "y")
  var d: DerivedObj
  doAssertRaises(ObjectAssignmentDefect):
    d = m

block: # same type assignments still work
  var b1 = BaseObj(name: "b")
  var b2: BaseObj
  b2 = b1
  doAssert b2.name == "b"
  var d1 = DerivedObj(name: "d", extra: 42)
  var d2: DerivedObj
  d2 = d1
  doAssert d2.name == "d" and d2.extra == 42
  doAssert d2 of DerivedObj
  var d3: DerivedObj = makeDerived()
  doAssert d3.name == "m" and d3.extra == 1
  var m1 = MoreDerivedObj(name: "x", extra: 1, more: "y")
  var m2: MoreDerivedObj
  m2 = m1
  doAssert m2.more == "y" and m2.name == "x"
  var t1 = TrivialDerived(x: 1, y: 2)
  var t2: TrivialDerived
  t2 = t1
  doAssert t2.x == 1 and t2.y == 2
  var vb = BaseObj(name: "v")
  doAssert copyFromVar(vb) == "v"
  var s = @[BaseObj(name: "s1")]
  s.add BaseObj(name: "s2")
  let s2 = s
  doAssert s2[1].name == "s2"
