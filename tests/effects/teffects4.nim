discard """
  line: 23
  errormsg: "type mismatch"
"""

type
  TObj = object {.pure, inheritable.}
  TObjB = object of TObj
    a, b, c: string
    fn: proc (): int {.tags: [ReadIOEffect].}



proc q() {.tags: [IoEffect].} =
  discard

proc raiser(): int =
  writeLine stdout, "arg"
  if true:
    q()

var o: TObjB
o.fn = raiser

