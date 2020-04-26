# #12671

proc foo =
  var x: seq[int]
  doAssertRaises(IndexError):
    inc x[0]

foo()
