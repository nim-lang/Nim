discard """
  file: "tprocredef.nim"
  line: 8
  errormsg: "redefinition of \'foo\'"
"""

proc foo(a: int, b: string) = discard
proc foo(a: int, b: string) = discard

