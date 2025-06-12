# issue #23713

import std/macros

template p {.pragma.}

type
  X {.p.} = object

  Y[T] = object
    t: T

doAssert Y[X].T.hasCustomPragma(p)
