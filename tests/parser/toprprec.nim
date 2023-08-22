discard """
  output: "done"
"""
# Test operator precedence:

template `@@` (x: untyped): untyped =
  `self`.x

template `@!` (x: untyped): untyped = x
template `===` (x: untyped): untyped = x

type
  TO = object
    x: int
  TA = tuple[a, b: int, obj: TO]

proc init(self: var TA): string =
  @@a = 3
  === @@b = 4
  @@obj.x = 4
  @! === result = "abc"
  result = @@b.`$`

assert 3+5*5-2 == 28- -26-28

proc `^-` (x, y: int): int =
  # now right-associative!
  result = x - y

assert 34 ^- 6 ^- 2 == 30
assert 34 - 6 - 2 == 26


var s: TA
assert init(s) == "4"

echo "done"
