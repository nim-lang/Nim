discard """
  errormsg: "illegal capture 'v'"
  line: 7
"""

proc outer(v: int) =
  proc b {.nimcall.} = echo v
  b()
outer(5)
