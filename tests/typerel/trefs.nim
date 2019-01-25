discard """
  errormsg: "type mismatch"
  file: "trefs.nim"
  line: 20
"""
# test for ref types (including refs to procs)

type
  TProc = proc (a, b: int): int {.stdcall.}

proc foo(c, d: int): int {.stdcall.} =
  return 0

proc wrongfoo(c, e: int): int {.inline.} =
  return 0

var p: TProc
p = foo
write(stdout, "success!")
p = wrongfoo  #ERROR_MSG type mismatch
