discard """
  errormsg: "type mismatch"
  line: 23
"""

type
  TObj {.pure, inheritable.} = object
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
