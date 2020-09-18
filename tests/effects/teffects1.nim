discard """
  cmd: "nim check $file"
"""

type
  TObj {.pure, inheritable.} = object
  TObjB = object of TObj
    a, b, c: string

  IO2Error = ref object of IOError

proc forw: int {. .}

proc lier(): int {.raises: [IO2Error].} =
  #[tt.Hint                 ^ 'IO2Error' is declared but not used [XDeclaredButNotUsed] ]#
  writeLine stdout, "arg" #[tt.Error
            ^  can raise an unlisted exception: ref IOError
  ]#

proc forw: int =
  raise newException(IOError, "arg")

{.push raises: [Defect].}

type
  MyProcType* = proc(x: int): string #{.raises: [ValueError, Defect].}

proc foo(x: int): string {.raises: [ValueError].} =
  if x > 9:
    raise newException(ValueError, "Use single digit")
  $x

var p: MyProcType = foo #[tt.Error
                    ^
type mismatch: got <proc (x: int): string{.noSideEffect, gcsafe, locks: 0.}> but expected 'MyProcType = proc (x: int): string{.closure.}'

]#
{.pop.}
