discard """
  output: "true"
"""

# Test the new predence rules

proc `\+` (x, y: int): int = result = x + y
proc `\*` (x, y: int): int = result = x * y

echo 5 \+ 1 \* 9 == 14

