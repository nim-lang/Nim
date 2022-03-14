# #12671
import std/assertions
proc foo =
  var x: seq[int]
  doAssertRaises(IndexDefect):
    inc x[0]

foo()
