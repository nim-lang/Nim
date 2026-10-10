discard """
  output: '''
calls: 4
'''
"""

# `check` must evaluate every operand exactly once (nimly's parser consumed
# its lexer twice otherwise)

import std/unittest

var calls = 0
proc f(x: int): int =
  inc calls
  x

test "operands are evaluated once":
  check f(3) == 3
  check f(1) < f(2)
  check 3 == f(3)

echo "calls: ", calls
