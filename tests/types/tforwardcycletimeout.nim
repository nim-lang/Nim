discard """
  timeout: "1.0"
"""

type
  Generic[T] = object
    t: T

  A = Generic[B]
  B = Generic[A]
