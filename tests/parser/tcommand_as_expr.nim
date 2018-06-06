discard """
  output: '''140
5-120-120
359
77
-4
-1
-1'''
"""
#import math
import sequtils

proc optarg(x:int, y:int = 0):int = x + 3 * y
proc singlearg(x:int):int = 20*x
echo optarg 1, singlearg 2


proc foo(x: int): int = x-1
proc foo(x, y: int): int = x-y

let x = optarg foo 7.foo
let y = singlearg foo(1, foo 8)
let z = singlearg 1.foo foo 8

echo x, y, z

let a = [2,4,8].map do (d:int) -> int: d + 1
echo a[0], a[1], a[2]

echo(foo 8, foo 8)

# bug #7582
proc f(x: int): int = x

echo f -4

echo int -1 # doesn't compile
echo int `-` 1 # compiles
