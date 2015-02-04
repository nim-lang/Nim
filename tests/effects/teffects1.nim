discard """
  file: "system.nim"
  errormsg: "can raise an unlisted exception: ref IOError"
"""

type
  TObj = object {.pure, inheritable.}
  TObjB = object of TObj
    a, b, c: string
  
  IO2Error = ref object of IOError
  
proc forw: int {. .}
  
proc lier(): int {.raises: [IO2Error].} =
  writeln stdout, "arg"

proc forw: int =
  raise newException(IOError, "arg")

