# bug #26225: `void` fields occupy no storage, so they must not affect the
# layout of the surrounding object or tuple

type
  Application = object
    config: void
    i: int
    f: void

  OnlyTrailingVoid = object
    i: int
    f: void

  VoidBetweenFields = object
    a: int
    v: void
    b: int

  AllVoid = object
    x: void
    y: void

var app: Application

doAssert sizeof(app) == sizeof(int)
doAssert alignof(Application) == sizeof(int)
doAssert offsetof(Application, i) == 0

doAssert sizeof(OnlyTrailingVoid) == sizeof(int)

# a `void` field must not reset the offsets of the fields after it
doAssert sizeof(VoidBetweenFields) == 2 * sizeof(int)
doAssert offsetof(VoidBetweenFields, a) == 0
doAssert offsetof(VoidBetweenFields, b) == sizeof(int)

# an object with only `void` fields behaves like an empty object
doAssert sizeof(AllVoid) == 1

block: # tuples are affected too
  var t1: tuple[x: void, i: int]
  var t2: tuple[i: int, x: void]
  doAssert sizeof(t1) == sizeof(int)
  doAssert sizeof(t2) == sizeof(int)

block: # case object branches with only `void` fields
  type
    CaseObj = object
      case tag: bool
      of false: a: void
      of true: b: int
  doAssert sizeof(CaseObj) == 2 * sizeof(int)
  var c: CaseObj = CaseObj(tag: true, b: 42)
  doAssert c.b == 42

block: # generic instantiation matches the non-generic layout
  type GObj[T] = object
    x: T
    i: int
  doAssert sizeof(GObj[void]) == sizeof(int)
  doAssert sizeof(GObj[int]) == 2 * sizeof(int)

block: # runtime values agree with the compile-time layout
  var o: VoidBetweenFields
  o.a = 1
  o.b = 2
  doAssert o.a == 1 and o.b == 2
