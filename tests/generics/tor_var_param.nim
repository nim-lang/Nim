proc testOrVar(v: var (string | seq[int])) =
  v.setLen(7)

proc testOrVar2(v: var seq[int]) =
  testOrVar(v)

proc testOrVar3(v: var string | var seq[int]) =
  v.setLen(11)

proc testOrVar4(v: var string) =
  testOrVar3(v)

var v = newSeq[int]()
testOrVar(v)
doAssert v.len == 7
var v2 = newSeq[int]()
testOrVar2(v2)
doAssert v.len == 7

var v3 = "foo"
testOrVar3(v3)
doAssert v3.len == 11
var v4 = "bar"
testOrVar4(v4)
doAssert v4.len == 11
