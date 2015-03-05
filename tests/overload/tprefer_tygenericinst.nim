discard """
  output: "Version 2 was called."
  disabled: true
"""

# bug #2220

type A[T] = object
type B = A[int]

proc p[X](x: X) =
  echo "Version 1 was called."

proc p(x: B) =
  echo "Version 2 was called."

p(B()) # This call reported as ambiguous.
