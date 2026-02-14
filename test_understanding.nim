# This should work - v is only used after the last yield
proc goodIter(v: sink string): iterator(): int =
  iterator(): int =
    yield 1
    echo v  # State 1: after this, state = -1 (done)

# This should fail - v is used before a yield, accessed again on next call
proc badIter(v: sink string): iterator(): int =
  iterator(): int =
    echo v  # State 0: uses v
    yield 1
    echo v  # State 1: uses v again - this is the problem
