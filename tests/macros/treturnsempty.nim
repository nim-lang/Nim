discard """
  errormsg: "type mismatch"
  line: 11
"""
# bug #2372
macro foo(dummy: int): untyped =
  discard

proc takeStr(s: string) = echo s

takeStr foo(12)
