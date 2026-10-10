discard """
  matrix: "--mm:refc; --mm:orc"
"""

import ./m25294/[c, t]

block:
  let a = new D
  a[] = p()
  discard a[]
block:
  let a = new D
  a[] = p()
  discard a[]
block:
  let a = new D
  a[] = p()
  discard a[]