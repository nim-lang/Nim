discard """
  errormsg: "type mismatch: got <PTest>"
"""

type
  PTest = ref object

proc test(x: PTest, y: int) = discard

var buf: PTest
buf.test()

