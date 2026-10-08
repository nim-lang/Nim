discard """
  errormsg: "selector type 'R[V]' depends on a type that is not yet defined"
  line: 11
"""

# used to segfault after the fix for #26368

type
  R[T] = range[0..1]
  O = object
    case k: R[V]
    of 0: a: int
    of 1: b: int
  V = object
