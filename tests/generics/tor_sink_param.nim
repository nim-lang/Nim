# issue #25726

proc testOrSink(v: sink (string | seq[int])) =
  discard move(v)

proc testOrSink2(v: sink seq[int]) =
  testOrSink(v)

proc testOrSink3(v: sink string | sink seq[int]) =
  discard move(v)

proc testOrSink4(v: sink string) =
  testOrSink3(v)

var v = newSeq[int]()
testOrSink(v)
var v2 = newSeq[int]()
testOrSink2(v2)

var v3 = "foo"
testOrSink3(v3)
var v4 = "bar"
testOrSink4(v4)
