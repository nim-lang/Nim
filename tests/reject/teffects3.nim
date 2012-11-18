discard """
  line: 18
  errormsg: "type mismatch"
"""

type
  TObj = object {.pure, inheritable.}
  TObjB = object of TObj
    a, b, c: string
    fn: proc (): int {.tags: [].}
  
  EIO2 = ref object of EIO
  
proc raiser(): int {.tags: [TObj, FWriteIO].} =
  writeln stdout, "arg"

var o: TObjB
o.fn = raiser

