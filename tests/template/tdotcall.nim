import mdotcall

block: # issue #20073
  works()
  boom()

block: # issue #7085
  doAssert baz("hello") == "hellobar"
  doAssert baz"hello" == "hellobar"
  doAssert "hello".baz == "hellobar"

block: # issue #7223
  var r = BytesRange(bytes: @[1.byte, 2, 3], ibegin: 0, iend: 2)
  var a = r.rangeBeginAddr

block: # issue #11733
  var a: ObjA
  var evaluated = false
  a.publicTemplateObjSyntax(42): evaluated = true
  doAssert evaluated
