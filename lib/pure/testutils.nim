## Utilities to help writing tests
##
## Unstable, experimental API.

import std/[sequtils, algorithm]

proc sortedPairs*[T](t: T): auto =
  ## helps when writing tests involving tables in a way that's robust to
  ## changes in hashing functions / table implementation.
  toSeq(t.pairs).sorted

template sortedItems*(t: untyped): untyped =
  ## helps when writing tests involving tables in a way that's robust to
  ## changes in hashing functions / table implementation.
  sorted(toSeq(t))
