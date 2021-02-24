discard """
  matrix: "--gc:refc; --gc: arc"
"""

proc hello(x: varargs[string]) =
  var s: seq[string]
  s.add x

hello("123")
