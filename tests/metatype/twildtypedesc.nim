discard """
  output: '''123
123
123
123
123
123'''
"""

import strutils

proc unpack(t: typedesc[string], v: string): string = $v
proc unpack(t: typedesc[int], v: string): int = parseInt(v)

proc unpack[T](v: string): T =
  unpack T, v

var s = "123"

doAssert(unpack[string](s) is string)
doAssert(unpack[int](s) is int)

echo unpack[int](s)
echo unpack[string](s)

echo unpack(int,s)
echo unpack(string,s)

template `as`*(x: untyped, t: typedesc): untyped = unpack(t,x)

echo s as int
echo s as string

# bug #4534

proc unit(t: typedesc[int]): t = 0
proc unit(t: typedesc[string]): t = ""
proc unit(t: typedesc[float]): t = 0.0

doAssert unit(int) == 0
doAssert unit(string) == ""
doAssert unit(float) == 0.0

