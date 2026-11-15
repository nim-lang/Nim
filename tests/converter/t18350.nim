discard """
action: run
"""

# bug #18350

proc foo(x: int) = discard
proc foo(x: varargs[int]) = discard

foo(42) # this is ok

type D = distinct int

converter toInt(x: D): int = int(x)

foo(D(42)) # but this is ambiguous, somehow
