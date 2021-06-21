discard """
  output: '''4
8
(a: 1)
2
2
'''
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


#--------------------------------------------------------
# issue #14014

import threadpool

type A = object
    a: int

proc f(t: typedesc): t =
  t(a:1)

let r = spawn f(A)
echo ^r

proc f2(x: static[int]): int =
  x

let r2 = spawn f2(2)
echo ^r2

type statint = static[int]

proc f3(x: statint): int =
  x

let r3 = spawn f3(2)
echo ^r3
