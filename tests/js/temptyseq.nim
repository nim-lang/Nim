# #12671

proc foo =
  var x: seq[int]
  doAssertRaises(IndexDefect):
    inc x[0]

foo()
