# Bug: https://github.com/nim-lang/Nim/issues/4475
# Fix: https://github.com/nim-lang/Nim/pull/4477

proc test(x: varargs[string], y: int) = discard

test(y = 1)
