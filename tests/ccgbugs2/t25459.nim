discard """
  targets: "c cpp"
  matrix: "-d:checkAbi"
"""

import ./m25459/h

for _ in 0 ..< 500:
  let u = new W
  u[] = a()
