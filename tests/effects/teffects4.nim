discard """
  line: 23
  errormsg: "type mismatch"
"""

type
  TObj = object {.pure, inheritable.}
  TObjB = object of TObj
    a, b, c: string
    fn: proc (): int {.tags: [FReadIO].}

  EIO2 = ref object of EIO

proc q() {.tags: [FIO].} =
  discard

proc raiser(): int =
  writeLine stdout, "arg"
  if true:
    q()

var o: TObjB
o.fn = raiser

