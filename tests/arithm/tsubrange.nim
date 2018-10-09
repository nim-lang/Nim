discard """
  output: '''1'''
"""

# bug #5854
type
  n16* = range[0'i16..high(int16)]

var level: n16 = 1
let maxLevel: n16 = 1

level = min(level + 2, maxLevel)
echo level
