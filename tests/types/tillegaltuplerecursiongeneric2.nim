discard """
  errormsg: "illegal recursion in type 'TPearl'"
"""

type
  TPearl[T] = tuple
    next: TPearl[T]

var x: TPearl[int]
