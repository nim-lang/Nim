discard """
  output: '''10
10
1
1
true'''
"""

# bug #1344

var expected: int
var x: range[1..10] = 10

try:
  x += 1
  echo x
except OverflowError, RangeError:
  expected += 1
  echo x

try:
  inc x
  echo x
except OverflowError, RangeError:
  expected += 1
  echo x

x = 1
try:
  x -= 1
  echo x
except OverflowError, RangeError:
  expected += 1
  echo x

try:
  dec x
  echo x
except OverflowError, RangeError:
  expected += 1
  echo x

echo expected == 4
