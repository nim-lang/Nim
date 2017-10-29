import macros

type MyAttr = object

block:
  proc myProc() {.attr: MyAttr.} = discard
  const myAttrIdx = myProc.findAttrIt(it is MyAttr)
  assert(myAttrIdx == 0)
  assert(myProc.findAttrIt(it is RootObj) == -1)

  type A = myProc.attrAt(myAttrIdx)
  assert(A is MyAttr)

block:
  type MyObj = object
    myField {.attr: MyAttr.}: int
  var o: MyObj
  const myAttrIdx = o.myField.findAttrIt(it is MyAttr)
  assert(myAttrIdx == 0)
  assert(o.myField.findAttrIt(it is RootObj) == -1)

  type A = o.myField.attrAt(myAttrIdx)
  assert(A is MyAttr)

block: # A bit more advanced case
  type # Attributes
    serializationKey[S: static[string]] = object
    defaultValue[V: static[typed]] = object

  type MySerializable = object
    a {.attr: [serializationKey["asdf"], defaultValue[5]].} : int
    b {.attr: defaultValue["hello"].} : int

  proc get[V: static[int]](a: typedesc[defaultValue[V]]): int = V
  proc get[V: static[string]](a: typedesc[defaultValue[V]]): string = V

  proc get[V: static[string]](a: typedesc[serializationKey[V]]): string = V

  var s: MySerializable

  const aDefVal = get(s.a.attrAt(s.a.findAttrIt(it is defaultValue)))
  doAssert(aDefVal == 5)

  const sDefVal = get(s.b.attrAt(s.b.findAttrIt(it is defaultValue)))
  doAssert(sDefVal == "hello")

  doAssert(get(s.a.attrAt(s.a.findAttrIt(it is serializationKey))) == "asdf")
