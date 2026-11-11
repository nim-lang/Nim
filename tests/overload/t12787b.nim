discard """
  errormsg: "overloaded 'p' leads to ambiguous calls"
  line: 7
"""

proc p[T: int](s: string): T = 1
proc p[T: int](s: string): string = "a"
