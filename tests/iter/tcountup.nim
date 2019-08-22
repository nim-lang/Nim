discard """
  output: '''
0123456789
0.0
'''
"""

# Test new countup

for i in 0 ..< 10'i64:
  stdout.write(i)

echo()

# 11099

var
  x: uint32
  y: float

for i in 0 ..< x:
  if i == 1: echo i
  y += 1

echo y
