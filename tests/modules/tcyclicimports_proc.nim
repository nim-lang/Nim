discard """
  output: "4"
  cmd: "nim c -r $file"
"""

{.experimental: "codeReordering".}

import mcyclicimports_proc

proc a*(x: int): int =
  if x <= 0:
    1
  else:
    b(x) + 1

echo a(3)
