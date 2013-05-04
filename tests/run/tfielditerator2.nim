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
myDisc: enC
c: Z
enC
Z
'''
"""

type
  TMyObj = object
    a, b: char
    x, y: int
    z: string
    
  TEnum = enum enA, enB, enC
  TMyCaseObj = object
    case myDisc: TEnum
    of enA: a: int
    of enB: b: string
    of enC: c: char

proc p(x: char) = echo "a char: ", x <= 'a'
proc p(x: int) = echo "an int: ", x
proc p(x: string) = echo "a string: ", x

proc myobj(a, b: char, x, y: int, z: string): TMyObj =
  result.a = a; result.b = b; result.x = x; result.y = y; result.z = z

var x = myobj('a', 'b', 5, 6, "abc")
var y = myobj('A', 'b', 5, 9, "abc")

for f in fields(x): 
  p f

for a, b in fields(x, y):
  echo a == b

for key, val in fieldPairs(x):
  echo key, ": ", val

var co: TMyCaseObj
co.myDisc = enC
co.c = 'Z'
for key, val in fieldPairs(co):
  echo key, ": ", val

for val in fields(co):
  echo val
