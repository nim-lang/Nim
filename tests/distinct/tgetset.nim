discard """
  file: "tgetset.nim"
  output: '''true'''
"""
type dring = distinct string

let a = "Hello".dring
let b = ", World".dring

proc `[]`(d: dring; x: int): char {.borrow.}
proc `[]=`(d: dring; x: int; b: char): void {.borrow.}
proc `==`(x, y: dring): bool {.borrow.}
proc `$`(d: dring): string {.borrow.}
assert(not (a == b))
assert(a[1] == 'e')
assert(b[0] == ',')
var c = b
c[0] = 'A'
c[2] = 'w'
assert($c == "A world")
assert(c == "A world".dring)

let d = new(dring)
d[] = a
(d[])[4] = '!'
assert($d[] == "Hell!")

echo "true"
