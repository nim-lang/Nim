discard """
  timeout: "1.0"
  errormsg: "illegal recursion in type 'A'"
"""

type
  Generic[T] = object
    t: T

  A = Generic[B]
  B = Generic[A]
