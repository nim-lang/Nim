discard """
  line: 7
  errormsg: "redefinition of \'foo\'"
"""

proc foo(a: int, b: string) = nil
proc foo(a: int, b: string) = nil
