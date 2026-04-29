# issue #25726

proc testOrSink(v: string | sink seq[int]) =
  discard move(v)

proc testOrSink2(v: sink seq[int]) =
  testOrSink(v)

proc testOrSink3(v: var seq[int]) =
  testOrSink(v)

proc testOrVar(x: string or var seq[int]) =
  x.setLen(1)
  doAssert x.len == 1

proc testOrVar2(x: var seq[int]) =
  testOrVar(x)

proc testOrVar3(x: sink seq[int]) =
  testOrVar(x)

var v = newSeq[int]()
testOrSink(v)
var v2 = newSeq[int]()
testOrSink2(v2)
var v3 = newSeq[int]()
testOrSink3(v3)

var v4 = newSeq[int]()
testOrVar(v4)
testOrVar2(v4)
testOrVar3(v4)
