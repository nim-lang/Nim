discard """
  output: '''
we
direct
generic
generic
'''
joinable: false
"""

import algorithm, sugar, sequtils, typetraits, asyncdispatch

block tconfusing_arrow:
  type Deck = object
    value: int

  proc sort(h: var seq[Deck]) =
    # works:
    h.sort(proc (x, y: Deck): auto =
      cmp(x.value, y.value))
    # fails:
    h.sort((x, y: Deck) => cmp(ord(x.value), ord(y.value)))

  var player: seq[Deck] = @[]
  player.sort()



block tdictdestruct:
  type
    TDict[TK, TV] = object
      k: TK
      v: TV
    PDict[TK, TV] = ref TDict[TK, TV]

  proc fakeNew[T](x: var ref T, destroy: proc (a: ref T) {.nimcall.}) =
    discard

  proc destroyDict[TK, TV](a: PDict[TK, TV]) =
      return
  proc newDict[TK, TV](a: TK, b: TV): PDict[TK, TV] =
      fakeNew(result, destroyDict[TK, TV])

  # Problem: destroyDict is not instantiated when newDict is instantiated!
  discard newDict("a", "b")



block tgenericdefaults:
  type
    TFoo[T, U, R = int] = object
      x: T
      y: U
      z: R

    TBar[T] = TFoo[T, array[4, T], T]

  var x1: TFoo[int, float]

  static:
    assert type(x1.x) is int
    assert type(x1.y) is float
    assert type(x1.z) is int

  var x2: TFoo[string, R = float, U = seq[int]]

  static:
    assert type(x2.x) is string
    assert type(x2.y) is seq[int]
    assert type(x2.z) is float

  var x3: TBar[float]

  static:
    assert type(x3.x) is float
    assert type(x3.y) is array[4, float]
    assert type(x3.z) is float



block tprop:
  type
    TProperty[T] = object of RootObj
      getProc: proc(property: TProperty[T]): T {.nimcall.}
      setProc: proc(property: TProperty[T], value: T) {.nimcall.}
      value: T

  proc newProperty[T](value: RootObj): TProperty[T] =
    result.getProc = proc (property: TProperty[T]) =
      return property.value



block trefs:
  type
    PA[T] = ref TA[T]
    TA[T] = object
      field: T
  var a: PA[string]
  new(a)
  a.field = "some string"

  proc someOther[T](len: string): seq[T] = discard
  proc someOther[T](len: int): seq[T] = echo "we"

  proc foo[T](x: T) =
    var s = someOther[T](34)
    #newSeq[T](34)

  foo 23

  when false:
    # Compiles unless you use var a: PA[string]
    type
      PA = ref TA
      TA[T] = object

    # Cannot instantiate:
    type
      TA[T] = object
        a: PA[T]
      PA[T] = ref TA[T]

    type
      PA[T] = ref TA[T]
      TA[T] = object



block tsharedcases:
  proc typeNameLen(x: typedesc): int {.compileTime.} =
    result = x.name.len
  macro selectType(a, b: typedesc): typedesc =
    result = a

  type
    Foo[T] = object
      data1: array[T.high, int]
      data2: array[typeNameLen(T), float]
      data3: array[0..T.typeNameLen, selectType(float, int)]
    MyEnum = enum A, B, C, D

  var f1: Foo[MyEnum]
  var f2: Foo[int8]

  doAssert high(f1.data1) == 2 # (D = 3) - 1 == 2
  doAssert high(f1.data2) == 5 # (MyEnum.len = 6) - 1 == 5

  doAssert high(f2.data1) == 126 # 127 - 1 == 126
  doAssert high(f2.data2) == 3 # int8.len - 1 == 3

  static:
    assert high(f1.data1) == ord(C)
    assert high(f1.data2) == 5 # length of MyEnum minus one, because we used T.high

    assert high(f2.data1) == 126
    assert high(f2.data2) == 3

    assert high(f1.data3) == 6 # length of MyEnum
    assert high(f2.data3) == 4 # length of int8

    assert f2.data3[0] is float



block tmap_auto:
  let x = map(@[1, 2, 3], x => x+10)
  assert x == @[11, 12, 13]

  let y = map(@[(1,"a"), (2,"b"), (3,"c")], x => $x[0] & x[1])
  assert y == @["1a", "2b", "3c"]

  proc eatsTwoArgProc[T,S,U](a: T, b: S, f: proc(t: T, s: S): U): U =
    f(a,b)

  let z = eatsTwoArgProc(1, "a", (t,s) => $t & s)
  assert z == "1a"



block tproctypecache_falsepositive:
  type
    Callback = proc() {.closure, gcsafe.}
    GameState = ref object
      playerChangeHandlers: seq[Callback]

  proc newGameState(): GameState =
    result = GameState(
      playerChangeHandlers: newSeq[Callback]() # this fails
    )



block tptrinheritance:
  type NSPasteboardItem = ptr object
  type NSPasteboard = ptr object
  type NSArrayAbstract = ptr object {.inheritable.}
  type NSMutableArrayAbstract = ptr object of NSArrayAbstract
  type NSArray[T] = ptr object of NSArrayAbstract
  type NSMutableArray[T] = ptr object of NSArray[T]

  proc newMutableArrayAbstract(): NSMutableArrayAbstract = discard

  template newMutableArray(T: typedesc): NSMutableArray[T] =
    cast[NSMutableArray[T]](newMutableArrayAbstract())

  proc writeObjects(p: NSPasteboard, o: NSArray[NSPasteboardItem]) = discard

  let a = newMutableArray NSPasteboardItem
  var x: NSMutableArray[NSPasteboardItem]
  var y: NSArray[NSPasteboardItem] = x

  writeObjects(nil, a)



block tsigtypeop:
  type Vec3[T] = array[3, T]

  proc foo(x: Vec3, y: Vec3.T, z: x.T): x.type.T =
    return 10

  var y: Vec3[int] = [1, 2, 3]
  var z: int = foo(y, 3, 4)



block tvarargs_vs_generics:
  proc withDirectType(args: string) =
    echo "direct"
  proc withDirectType[T](arg: T) =
    echo "generic"
  proc withOpenArray(args: openarray[string]) =
    echo "openarray"
  proc withOpenArray[T](arg: T) =
    echo "generic"
  proc withVarargs(args: varargs[string]) =
    echo "varargs"
  proc withVarargs[T](arg: T) =
    echo "generic"

  withDirectType "string"
  withOpenArray "string"
  withVarargs "string"

block:
  type
    Que[T] {.gcsafe.} = object
      x: T

  proc `=`[T](q: var Que[T]; x: Que[T]) =
    discard

  var x: Que[int]
  doAssert(x.x == 0)
