import sugar

proc foo[T]: seq[int] =
    return lc[x | (x <- 1..10, x mod 2 == 0), int]

doAssert foo[float32]() == @[2, 4, 6, 8, 10]
