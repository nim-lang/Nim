discard """
  output: '''holla
true
defabc 4'''
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
