discard """
  errormsg: "type mismatch: got <mc.typ>"
  line: 12
"""

import mb, mc

proc test(testing: mb.typ) =
  discard

var s: mc.typ
test(s)
