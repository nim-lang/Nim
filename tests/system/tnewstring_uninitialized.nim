discard """
  matrix: "--mm:refc;"
"""

# bug #22555
var x = newStringUninit(10)
doAssert x.len == 10
for i in 0..<x.len:
  x[i] = chr(ord('a') + i)

doAssert x == "abcdefghij"
