discard """
  file: "tapply.nim"
  output: '''true'''
"""

import sequtils

var x = @[1, 2, 3]
x.apply(proc(x: var int) = x = x+10)
x.apply(proc(x: int): int = x+100)
x.applyIt(it+5000)
echo x == @[5111, 5112, 5113]
