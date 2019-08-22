discard """
  errormsg: "can raise an unlisted exception: ref IOError"
  file: "io.nim"
"""

type
  TObj {.pure, inheritable.} = object
  TObjB = object of TObj
    a, b, c: string

  IO2Error = ref object of IOError

proc forw: int {. .}

proc lier(): int {.raises: [IO2Error].} =
  writeLine stdout, "arg"

proc forw: int =
  raise newException(IOError, "arg")
