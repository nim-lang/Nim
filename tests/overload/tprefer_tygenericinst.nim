discard """
  output: '''Version 2 was called.
This has the highest precedence.
This has the second-highest precedence.
This has the lowest precedence.'''
"""

# bug #2220
when true:
  type A[T] = object
  type B = A[int]

  proc q[X](x: X) =
    echo "Version 1 was called."

  proc q(x: B) =
    echo "Version 2 was called."

  q(B()) # This call reported as ambiguous.

# bug #2219
template testPred(a: expr) =
  block:
    type A = object of RootObj
    type B = object of A
    type SomeA = A|A # A hack to make "A" a typeclass.

    when a >= 3:
      proc p[X](x: X) =
        echo "This has the highest precedence."
    when a >= 2:
      proc p[X: A](x: X) =
        echo "This has the second-highest precedence."
    when a >= 1:
      proc p[X: SomeA](x: X) =
        echo "This has the lowest precedence."

    p(B())

testPred(3)
testPred(2)
testPred(1)
