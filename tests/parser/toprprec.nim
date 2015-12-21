discard """
  output: "done"
"""
# Test operator precedence:

template `@` (x: expr): expr {.immediate.} = self.x
template `@!` (x: expr): expr {.immediate.} = x
template `===` (x: expr): expr {.immediate.} = x

type
  TO = object
    x: int
  TA = tuple[a, b: int, obj: TO]

proc init(self: var TA): string =
  @a = 3
  === @b = 4
  @obj.x = 4
  @! === result = "abc"
  result = @b.`$`

doAssert 3+5*5-2 == 28- -26-28

proc `^-` (x, y: int): int =
  # now right-associative!
  result = x - y

doAssert 34 ^- 6 ^- 2 == 30
doAssert 34 - 6 - 2 == 26


var s: TA
doAssert init(s) == "4"

echo "done"
