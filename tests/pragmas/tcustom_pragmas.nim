import macros

block:
  template myAttr() {.pragma.}
  template myAttr2() {.pragma.}

  proc myProc() {.myAttr.} = discard
  const myAttrIdx = myProc.hasCustomPragma(myAttr)
  assert(myAttrIdx)
  assert(not myProc.hasCustomPragma(myAttr2))

block:
  template myAttr(a: string) {.pragma.}

  type MyObj = object
    myField {.myAttr: "hi".}: int
  var o: MyObj
  assert o.myField.hasCustomPragma(myAttr)

block: # A bit more advanced case
  template serializationKey(s: string) {.pragma.}
  template defaultValue(V: typed) {.pragma.}

  type MySerializable = object
    a {.serializationKey: "asdf", defaultValue: 5.} : int
    b {.defaultValue: "hello".} : int

  var s: MySerializable

  const aDefVal = s.a.getCustomPragmaVal(defaultValue)
  doAssert(aDefVal == 5)

  const aSerKey = s.a.getCustomPragmaVal(serializationKey)
  doAssert(aSerKey == "asdf")
