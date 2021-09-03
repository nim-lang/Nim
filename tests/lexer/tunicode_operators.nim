#{.experimental: "unicodeOperators".}

proc `⊙`(x, y: int): int = x * y
proc `⊙=`(x: var int, y: int) = x *= y

var x = 45
x ⊙= 9 ⊙ 4

var y = 45
y *= 9 * 4

assert x == y
