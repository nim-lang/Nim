{.experimental: "cyclicImports".}

import tcyclic_pragma {.cyclic.}

type
  Payload* = object
    v*: int
    h*: ref Holder
