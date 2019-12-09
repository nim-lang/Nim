{.experimental: "notnil".}

import macros

block:
  template myAttr() {.pragma.}

  proc myProc():int {.myAttr.} = 2
  const hasMyAttr = myProc.hasCustomPragma(myAttr)
  static:
    assert(hasMyAttr)

block:
  template myAttr(a: string) {.pragma.}

  type
    MyObj = object
      myField1, myField2 {.myAttr: "hi".}: int

  var o: MyObj
  static:
    assert o.myField2.hasCustomPragma(myAttr)
    assert(not o.myField1.hasCustomPragma(myAttr))

import custom_pragma
block: # A bit more advanced case
  type
    Subfield {.defaultValue: "catman".} = object
      `c`* {.serializationKey: "cc".}: float

    MySerializable = object
      a {.serializationKey"asdf", defaultValue: 5.} : int
      b {.custom_pragma.defaultValue"hello".} : int
      field: Subfield
      d {.alternativeKey("df", 5).}: float
      e {.alternativeKey(V = 5).}: seq[bool]

  proc myproc(x: int, s: string) {.alternativeKey(V = 5), serializationKey"myprocSS".} =
    echo x, s


  var s: MySerializable

  const aDefVal = s.a.getCustomPragmaVal(defaultValue)
  static: assert(aDefVal == 5)

  const aSerKey = s.a.getCustomPragmaVal(serializationKey)
  static: assert(aSerKey == "asdf")

  const cSerKey = getCustomPragmaVal(s.field.c, serializationKey)
  static: assert(cSerKey == "cc")

  const procSerKey = getCustomPragmaVal(myproc, serializationKey)
  static: assert(procSerKey == "myprocSS")

  static: assert(hasCustomPragma(myproc, alternativeKey))

  const hasFieldCustomPragma = s.field.hasCustomPragma(defaultValue)
  static: assert(hasFieldCustomPragma == false)

  # pragma on an object
  static:
    assert Subfield.hasCustomPragma(defaultValue)
    assert(Subfield.getCustomPragmaVal(defaultValue) == "catman")

    assert hasCustomPragma(type(s.field), defaultValue)

  proc foo(s: var MySerializable) =
    static: assert(s.a.getCustomPragmaVal(defaultValue) == 5)

  foo(s)

block: # ref types
  type
    Node = object of RootObj
      left {.serializationKey:"l".}, right {.serializationKey:"r".}: NodeRef
    NodeRef = ref Node
    NodePtr = ptr Node

    SpecialNodeRef = ref object of NodeRef
      data {.defaultValue"none".}: string

    MyFile {.defaultValue: "closed".} = ref object
      path {.defaultValue: "invalid".}: string

    TypeWithoutPragma = object

  var s = NodeRef()

  const
    leftSerKey = getCustomPragmaVal(s.left, serializationKey)
    rightSerKey = getCustomPragmaVal(s.right, serializationKey)
  static:
    assert leftSerKey == "l"
    assert rightSerKey == "r"

  var specS = SpecialNodeRef()

  const
    dataDefVal = hasCustomPragma(specS.data, defaultValue)
    specLeftSerKey = hasCustomPragma(specS.left, serializationKey)
  static:
    assert dataDefVal == true
    assert specLeftSerKey == true

  var ptrS = NodePtr(nil)
  const
    ptrRightSerKey = getCustomPragmaVal(ptrS.right, serializationKey)
  static:
    assert ptrRightSerKey == "r"

  var f = MyFile()
  const
    fileDefVal = f.getCustomPragmaVal(defaultValue)
    filePathDefVal = f.path.getCustomPragmaVal(defaultValue)
  static:
    assert fileDefVal == "closed"
    assert filePathDefVal == "invalid"

  static:
    assert TypeWithoutPragma.hasCustomPragma(defaultValue) == false

block:
  type
    VariantKind = enum
      variInt,
      variFloat
      variString
      variNestedCase
    Variant = object
      case kind: VariantKind
      of variInt: integer {.serializationKey: "int".}: BiggestInt
      of variFloat: floatp: BiggestFloat
      of variString: str {.serializationKey: "string".}: string
      of variNestedCase:
        case nestedKind: VariantKind
        of variInt..variNestedCase: nestedItem {.defaultValue: "Nimmers of the world, unite!".}: int

  let vari = Variant(kind: variInt)

  const
    hasIntSerKey = vari.integer.hasCustomPragma(serializationKey)
    strSerKey = vari.str.getCustomPragmaVal(serializationKey)
    nestedItemDefVal = vari.nestedItem.getCustomPragmaVal(defaultValue)

  static:
    assert hasIntSerKey
    assert strSerKey == "string"
    assert nestedItemDefVal == "Nimmers of the world, unite!"

block:
  template simpleAttr {.pragma.}

  type Annotated {.simpleAttr.} = object

  proc generic_proc[T]() =
    assert Annotated.hasCustomPragma(simpleAttr)


#--------------------------------------------------------------------------
# Pragma on proc type

let a: proc(x: int) {.defaultValue(5).} = nil
static:
  doAssert hasCustomPragma(a.type, defaultValue)

# bug #8371
template thingy {.pragma.}

type
  Cardinal = enum
    north, east, south, west
  Something = object
    a: float32
    case cardinal: Cardinal
    of north:
      b {.thingy.}: int
    of east:
      c: int
    of south: discard
    else: discard

var foo: Something
foo.cardinal = north
doAssert foo.b.hasCustomPragma(thingy) == true

proc myproc(s: string): int =
  {.thingy.}:
    s.len

doAssert myproc("123") == 3

let xx = compiles:
  proc myproc_bad(s: string): int =
    {.not_exist.}:
      s.len
doAssert: xx == false

macro checkSym(s: typed{nkSym}): untyped =
  let body = s.getImpl.body
  doAssert body[1].kind == nnkPragmaBlock
  doAssert body[1][0].kind == nnkPragma
  doAssert body[1][0][0] == bindSym"thingy"

checkSym(myproc)

# var and let pragmas
block:
  template myAttr() {.pragma.}
  template myAttr2(x: int) {.pragma.}
  template myAttr3(x: string) {.pragma.}

  type
    MyObj2 = ref object
    MyObjNotNil = MyObj2 not nil

  let a {.myAttr,myAttr2(2),myAttr3:"test".}: int = 0
  let b {.myAttr,myAttr2(2),myAttr3:"test".} = 0
  var x {.myAttr,myAttr2(2),myAttr3:"test".}: int = 0
  var y {.myAttr,myAttr2(2),myAttr3:"test".}: int
  var z {.myAttr,myAttr2(2),myAttr3:"test".} = 0
  var z2 {.myAttr.}: MyObjNotNil

  template check(s: untyped) =
    doAssert s.hasCustomPragma(myAttr)
    doAssert s.hasCustomPragma(myAttr2)
    doAssert s.getCustomPragmaVal(myAttr2) == 2
    doAssert s.hasCustomPragma(myAttr3)
    doAssert s.getCustomPragmaVal(myAttr3) == "test"

  check(a)
  check(b)
  check(x)
  check(y)
  check(z)

# pragma with multiple fields
block:
  template myAttr(first: string, second: int, third: float) {.pragma.}
  let a {.myAttr("one", 2, 3.0).} = 0
  let ps = a.getCustomPragmaVal(myAttr)
  doAssert ps.first == ps[0] and ps.first == "one"
  doAssert ps.second == ps[1] and ps.second == 2
  doAssert ps.third == ps[2] and ps.third == 3.0

# pragma with implicit&explicit generic types
block:
  template fooBar[T](x: T; c: static[int] = 42; m: char) {.pragma.}
  var e {.fooBar("foo", 123, 'u').}: int
  doAssert(hasCustomPragma(e, fooBar))
  doAssert(getCustomPragmaVal(e, fooBar).c == 123)
