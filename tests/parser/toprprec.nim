discard """
  output: '''
done
not -1.0
not 1.0 and not 1.0
Q: did we have success? A: yes we did!!
not -1.0 == not -1.0
'''
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


proc `not`(f: float): string =
  "not " & $f

echo not -1 / 1

proc `and`(s1, s2: string): string =
  $s1 & " and " & s2

echo not 1f and not 1f

proc contains(f1, f2: float): string =
  "Q: did we have success?"

proc `not`(s: string): string =
  s & " A: yes we did!!"

echo not 1f in 1f

echo not -1 / 1, " == not -1.0"

