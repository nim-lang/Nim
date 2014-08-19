discard """
  output: '''true
true
true'''
"""

# bug 1420
import unsigned

var x = 40'u32
var y = 30'u32
echo x > y # works

echo((40'i32) > (30'i32))
echo((40'u32) > (30'u32)) # Error: ordinal type expected
