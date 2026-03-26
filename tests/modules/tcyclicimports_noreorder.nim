discard """
  errormsg: "undeclared identifier: 'a'"
  cmd: "nim c $file"
"""

import mcyclicimports_noreorder

proc a*(x: int): int =
  b(x)

discard a(1)
