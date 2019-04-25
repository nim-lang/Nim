discard """
  errormsg: "invalid recursion in type 'TPearl'"
"""

type
  TPearl[T] = tuple
    next: TPearl[T]

var x: TPearl[int]
