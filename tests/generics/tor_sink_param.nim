# issue #25726

proc testOrSink(v: string | sink seq[int]) =
  discard move(v)

proc testOrSink2(v: sink seq[int]) =
  testOrSink(v)

var v = newSeq[int]()
testOrSink(v)
var v2 = newSeq[int]()
testOrSink2(v2)
