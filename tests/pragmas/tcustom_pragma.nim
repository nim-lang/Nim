import macros

block:
  template myAttr() {.pragma.}

  proc myProc():int {.myAttr.} = 2
  const hasMyAttr = myProc.hasCustomPragma(myAttr)
  static:
    assert(hasMyAttr)

block:
  template myAttr(a: string) {.pragma.}

  type MyObj = object
    myField1, myField2 {.myAttr: "hi".}: int
  var o: MyObj
  static:
    assert o.myField2.hasCustomPragma(myAttr)
    assert(not o.myField1.hasCustomPragma(myAttr))

import custom_pragma
block: # A bit more advanced case
  type
    Subfield {.defaultValue: "catman".} = object
      c {.serializationKey: "cc".}: float

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