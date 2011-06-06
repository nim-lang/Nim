discard """
  output: '''true'''
"""

import hashes, tables

var t = initTable[tuple[x, y: int], string]()
t[(0,0)] = "00"
t[(1,0)] = "10"
t[(0,1)] = "01"
t[(1,1)] = "11"

for x in 0..1:
  for y in 0..1:
    assert t[(x,y)] == $x & $y

echo "true"

