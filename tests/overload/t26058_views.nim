{.experimental: "views".}

# bug #26058: the other direction
proc plainLen(items: seq[int]): int = items.len

var vs: seq[var int]
doAssert not compiles(plainLen(vs))
doAssert vs.len == 0
