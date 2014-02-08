discard """
  file: "tprocredef.nim"
  line: 8
  errormsg: "redefinition of \'foo\'"
"""

proc foo(a: int, b: string) = nil
proc foo(a: int, b: string) = nil

