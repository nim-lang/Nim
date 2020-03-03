discard """
  errormsg: "type mismatch: got <void>"
  line: 16
"""

# bug #950

import macros

proc blah(x: proc (a, b: int): int) =
  echo x(5, 5)

macro test(): untyped =
  result = newNimNode(nnkEmpty)

blah(test())
