discard """
  output: '''4
8'''
  cmd: "nim $target --threads:on $options $file"
"""

import threadpool

var
  x, y = 0

proc p1 =
  for i in 0 .. 10_000:
    discard

  atomicInc x

proc p2 =
  for i in 0 .. 10_000:
    discard

  atomicInc y, 2

for i in 0.. 3:
  spawn(p1())
  spawn(p2())

sync()

echo x
echo y
