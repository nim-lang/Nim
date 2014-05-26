discard """
  errormsg: "type mismatch: got (tissue966.PTest)"
"""

type
  PTest = ref object

proc test(x: PTest, y: int) = nil

var buf: PTest
buf.test()

