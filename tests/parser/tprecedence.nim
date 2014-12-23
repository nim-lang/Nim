discard """
  output: '''holla
true'''
"""

# Test top level semicolon works properly:
import os; echo "holla"

# Test the new predence rules

proc `\+` (x, y: int): int = result = x + y
proc `\*` (x, y: int): int = result = x * y

echo 5 \+ 1 \* 9 == 6*9

