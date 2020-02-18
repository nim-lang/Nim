## utilities to help writing tests

import std/[sequtils, algorithm]

proc sortedPairs*[T](t: T): auto =
  ## helps when writing tests involving tables in a way that's robust to
  ## changes in hashing functions / table implementation.
  toSeq(t.pairs).sorted
