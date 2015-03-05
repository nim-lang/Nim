discard """
  output: "20365011074"
"""

import tables

proc memoize(f: proc (a: int64): int64): proc (a: int64): int64 =
    var previous = initTable[int64, int64]()
    return proc(i: int64): int64 =
        if not previous.hasKey i:
            previous[i] = f(i)
        return previous[i]

var fib: proc(a: int64): int64

fib = memoize(proc (i: int64): int64 =
    if i == 0 or i == 1:
        return 1
    return fib(i-1) + fib(i-2)
)

echo fib(50)
