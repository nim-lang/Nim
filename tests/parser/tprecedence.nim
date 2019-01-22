discard """
  output: '''holla
true
defabc 4
0'''
"""

# Test top level semicolon works properly:
import os; echo "holla"

# Test the new predence rules

proc `\+` (x, y: int): int = result = x + y
proc `\*` (x, y: int): int = result = x * y

echo 5 \+ 1 \* 9 == 6*9

proc foo[S, T](x: S, y: T): T = x & y

proc bar[T](x: T): T = x

echo "def".foo[:string, string]("abc"), " ", 4.bar[:int]

# bug #9574
proc isFalse(a: int): bool = false

assert not isFalse(3)

# bug #9633

type
  MyField = object
    b: seq[string]

  MyObject = object
    f: MyField

proc getX(x: MyObject): lent MyField {.inline.} =
  x.f

let a = MyObject()
echo a.getX.b.len
