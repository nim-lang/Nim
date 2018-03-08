discard """
  line: 16
  errormsg: "type mismatch: got <void>"
"""

# bug #950

import macros

proc blah(x: proc (a, b: int): int) =
  echo x(5, 5)

macro test(): untyped =
  result = newNimNode(nnkEmpty)

blah(test())
