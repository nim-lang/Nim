discard """
  line: 1855
  file: "system.nim"
  errormsg: "can raise an unlisted exception: ref EIO"
"""

type
  TObj = object {.pure, inheritable.}
  TObjB = object of TObj
    a, b, c: string
  
  EIO2 = ref object of EIO
  
proc forw: int {. .}
  
proc lier(): int {.raises: [EIO2].} =
  writeln stdout, "arg"

proc forw: int =
  raise newException(EIO, "arg")

