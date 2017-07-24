import macros

block:
  template myAttr(a: string) = discard

  type MyObj = object
    myField {.myAttr: "hi".}: int
  var o: MyObj
  assert o.myField.hasCustomPragma(myAttr)

block: # A bit more advanced case
  template serializationKey(s: string) = discard
  template defaultValue(V: typed) = discard

  type MySerializable = object
    a {.serializationKey: "asdf", defaultValue: 5.} : int
    b {.defaultValue: "hello".} : int

  var s: MySerializable

  const aDefVal = s.a.getCustomPragmaVal(defaultValue)
  doAssert(aDefVal == 5)

  const aSerKey = s.a.getCustomPragmaVal(serializationKey)
  doAssert(aSerKey == "asdf")
