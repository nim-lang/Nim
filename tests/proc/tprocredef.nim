discard """
  errormsg: "redefinition of \'foo\'"
  file: "tprocredef.nim"
  line: 8
"""

proc foo(a: int, b: string) = discard
proc foo(a: int, b: string) = discard
