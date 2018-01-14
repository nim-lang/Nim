import macros
 
block:
  template myAttr() {.pragma.}

  proc myProc():int {.myAttr.} = 2
  const myAttrIdx = myProc.hasCustomPragma(myAttr)
  static: 
    assert(myAttrIdx)

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
    Subfield = object
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
