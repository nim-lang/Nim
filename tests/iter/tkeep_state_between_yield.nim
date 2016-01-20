discard """
  output: '''@[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 18, 20, 21, 24, 27, 30, 36, 40, 42]
1002'''
"""

import strutils

proc slice[T](iter: iterator(): T {.closure.}, sl: auto): seq[T] =
  var res: seq[int64] = @[]
  var i = 0
  for n in iter():
    if i > sl.b:
      break
    if i >= sl.a:
      res.add(n)
    inc i
  res

iterator harshad(): int64 {.closure.} =
  for n in 1 .. < int64.high:
    var sum = 0
    for ch in string($n):
      sum += parseInt("" & ch)
    if n mod sum == 0:
      yield n

echo harshad.slice 0 .. <20

for n in harshad():
  if n > 1000:
    echo n
    break


# bug #3499 last snippet fixed
# bug 705  last snippet fixed
