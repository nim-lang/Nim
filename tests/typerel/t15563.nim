discard """
  matrix: "--gc:refc; --gc: arc"
"""

proc hello(x: varargs[string]) =
  var T: seq[string]
  T.add x

hello("123")
