discard """
  action: compile
"""

# bug #22922
import std/atomics

type
  R[L: static int] = range[0..L]
  Q[L: static int] = object
    v: Atomic[R[L]]

proc f[L: static int](q: var Q[L]): void =
  discard

var q: Q[4]
q.f
