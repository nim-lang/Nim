# bug #10945: a bare `Ordinal` parameter type
type E = enum a, b, c

proc bar(x: Ordinal): int = int x
proc twice(x, y: Ordinal): int = int(x) + int(y)

doAssert bar(3) == 3
doAssert bar(c) == 2
doAssert bar('a') == 97
doAssert bar(3'u8) == 3
doAssert twice(1, 2) == 3
doAssert not compiles(bar(1.0))
doAssert not compiles(bar("x"))
doAssert not compiles(twice(1, 'a'))
