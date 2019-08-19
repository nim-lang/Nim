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

assert(unpack[string](s) is string)
assert(unpack[int](s) is int)

echo unpack[int](s)
echo unpack[string](s)

echo unpack(int,s)
echo unpack(string,s)

template `as`*(x: untyped, t: typedesc): untyped = unpack(t,x)

echo s as int
echo s as string

# bug #4534

proc unit(t: typedesc[int]): int = 0
proc unit(t: typedesc[string]): string = ""
proc unit(t: typedesc[float]): float = 0.0

assert unit(int) == 0
assert unit(string) == ""
assert unit(float) == 0.0
