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

proc `⟑`(x, y: int): int = x * y
proc `⟇`(x, y: int): int = x * y
proc `⩓`(x, y: int): int = x * y
proc `⩔`(x, y: int): int = x * y
proc `■`(x, y: int): int = x * y
proc `□`(x, y: int): int = x * y
proc `☆`(x, y: int): int = x * y
proc `★`(x, y: int): int = x * y

assert 2 + 3 ⟑ 4 ⟇ 5 ⩓ 6 ⩔ 7 ■ 8 □ 9 ☆ 10 ★ 11 == 2 + 3 * 4 * 5 * 6 * 7 * 8 * 9 * 10 * 11

proc `⟑=`(x: var int, y: int) = x *= y

proc `⩓++`(x, y: int): int = x * y

var z = 45
z ⟑= a⩓++4⟑3

var w = 45
w *= 9 * 4 * 3

assert z == w
