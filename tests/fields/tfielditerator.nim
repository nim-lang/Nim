discard """
  output: '''
a char: true
a char: false
an int: 5
an int: 6
a string: abc
false
true
true
false
true
a: a
b: b
x: 5
y: 6
z: abc
'''
"""

type
  TMyTuple = tuple[a, b: char, x, y: int, z: string]

proc p(x: char) = echo "a char: ", x <= 'a'
proc p(x: int) = echo "an int: ", x
proc p(x: string) = echo "a string: ", x

var x: TMyTuple = ('a', 'b', 5, 6, "abc")
var y: TMyTuple = ('A', 'b', 5, 9, "abc")

for f in fields(x):
  p f

for a, b in fields(x, y):
  echo a == b

for key, val in fieldPairs(x):
  echo key, ": ", val

assert x != y
assert x == x
assert(not (x < x))
assert x <= x
assert y < x
assert y <= x

