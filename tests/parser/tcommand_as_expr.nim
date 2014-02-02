discard """
  output: '''140
5-120'''
"""

proc optarg(x:int):int = x
proc singlearg(x:int):int = 20*x
echo optarg 1, singlearg 2


proc foo(x: int): int = x-1
proc foo(x, y: int): int = x-y

let x = optarg foo 7.foo
let y = singlearg foo(1, foo 8)

echo x, y
