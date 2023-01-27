discard """
  errormsg: "type mismatch"
  line: 18
"""

type
  TObj {.pure, inheritable.} = object
  TObjB = object of TObj
    a, b, c: string
    fn: proc (): int {.tags: [].}



proc raiser(): int {.tags: [TObj, WriteIoEffect].} =
  writeLine stdout, "arg"

var o: TObjB
o.fn = raiser
