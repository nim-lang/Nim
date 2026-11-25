discard """
  matrix: "--hints:off --warning:UnusedImport:off"
  nimoutFull: true
  nimout: '''
tprecedence.nim(85, 17) Warning: `not` binds tighter than '==': `not a == b` is `(not a) == b`; use parentheses to make the meaning explicit [NotCmp]
tprecedence.nim(86, 17) Warning: `not` binds tighter than '!=': `not a != b` is `(not a) != b`; use parentheses to make the meaning explicit [NotCmp]
tprecedence.nim(87, 17) Warning: `not` binds tighter than '<': `not a < b` is `(not a) < b`; use parentheses to make the meaning explicit [NotCmp]
tprecedence.nim(88, 17) Warning: `not` binds tighter than '<=': `not a <= b` is `(not a) <= b`; use parentheses to make the meaning explicit [NotCmp]
tprecedence.nim(89, 17) Warning: `not` binds tighter than '>': `not a > b` is `(not a) > b`; use parentheses to make the meaning explicit [NotCmp]
tprecedence.nim(90, 17) Warning: `not` binds tighter than '>=': `not a >= b` is `(not a) >= b`; use parentheses to make the meaning explicit [NotCmp]
tprecedence.nim(91, 17) Warning: `not` binds tighter than 'in': `not a in b` is `(not a) in b`; use parentheses to make the meaning explicit [NotCmp]
tprecedence.nim(92, 19) Warning: `not` binds tighter than '==': `not a == b` is `(not a) == b`; use parentheses to make the meaning explicit [NotCmp]
tprecedence.nim(93, 21) Warning: `not` binds tighter than '==': `not a == b` is `(not a) == b`; use parentheses to make the meaning explicit [NotCmp]
tprecedence.nim(94, 21) Warning: `not` binds tighter than '==': `not a == b` is `(not a) == b`; use parentheses to make the meaning explicit [NotCmp]
'''
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


# bug  #10458
template t(x: untyped): untyped = "x"

let
  aaa = t 2 + 4
  ccc = t (1, 1) + 6
  ddd = t [0, 1, 2] + 5

# bug #10896
const
  test =
    proc(): int = 1

# bug #8759
block:
  template `=>`(a, b): untyped = (a, b)
  template `+=`(a, b): untyped = a * b

  doAssert ("abc" => 3 += 5) == ("abc", 15)

# `not` binds tighter than a comparison (`not a == b` is `(not a) == b`,
# unlike Python), so it warns.
block:
  let x = 3
  let n = 1
  let s = [1, 2]
  discard not x == n
  discard not x != n
  discard not x < n
  discard not x <= n
  discard not x > n
  discard not x >= n
  discard not x in s
  discard not (x) == n
  discard not not x == n # one warning, from the inner `not`
  discard 1 + not x == n # `not` takes only `x`, as in `not x == n`

  # no warning: the meaning is explicit or there is no comparison
  discard not (x == n)
  discard (not x) == n
  discard not(x) == n
  discard not x
  discard not x + n
  discard not true and true
  discard x == not n
