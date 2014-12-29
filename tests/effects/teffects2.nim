discard """
  line: 19
  errormsg: "can raise an unlisted exception: ref IOError"
"""

type
  TObj = object {.pure, inheritable.}
  TObjB = object of TObj
    a, b, c: string
  
  EIO2 = ref object of IOError
  
proc forw: int {.raises: [].}

proc lier(): int {.raises: [IOError].} =
  writeln stdout, "arg"

proc forw: int =
  raise newException(IOError, "arg")

