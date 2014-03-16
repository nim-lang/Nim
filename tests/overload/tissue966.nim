discard """
  msg: "type mismatch: got (PTest)"
"""

type
  PTest = ref object

proc test(x: PTest, y: int) = nil

var buf: PTest
buf.test()

