discard """
  output: '''253'''
"""

# bug #2427

import unsigned

var x = 0'u8
dec x # OverflowError
x -= 1 # OverflowError
x = x - 1 # No error

echo x
