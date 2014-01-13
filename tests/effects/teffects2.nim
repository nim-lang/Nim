discard """
  line: 19
  errormsg: "can raise an unlisted exception: ref EIO"
"""

type
  TObj = object {.pure, inheritable.}
  TObjB = object of TObj
    a, b, c: string
  
  EIO2 = ref object of EIO
  
proc forw: int {.raises: [].}

proc lier(): int {.raises: [EIO].} =
  writeln stdout, "arg"

proc forw: int =
  raise newException(EIO, "arg")

