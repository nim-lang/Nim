discard """
  output: "A"
"""

# bug #5337: `A[var T]` must not match `A[int]`
type
  A[T] = object
  B[T] = A[var T]

proc foo[T](a: A[T]) = echo "A"
proc foo[T](a: B[T]) {.error.} = discard

var a: A[int]
foo(a)
