#{.experimental: "unicodeOperators".}

proc `⊙`(x, y: int): int = x * y
proc `⊙=`(x: var int, y: int) = x *= y

proc `⊞++`(x, y: int): int = x + y

const a = 9

var x = 45
x ⊙= a⊞++4⊙3

var y = 45
y *= 9 + 4 * 3

assert x == y
