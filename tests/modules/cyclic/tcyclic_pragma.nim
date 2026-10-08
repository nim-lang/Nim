discard """
  joinable: false
  output: "5"
"""

{.experimental: "cyclicImports".}

import mcyclic_pragma {.cyclic.}

type
  Holder* = object
    p*: Payload

echo Holder(p: Payload(v: 5)).p.v
