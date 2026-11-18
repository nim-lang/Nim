# bug #11321: closure iterators used in inner routines
iterator foo(n: int): int {.closure.} =
  for i in 1..n: yield i

iterator rec(n: int): int {.closure.} =
  if n > 0:
    for x in rec(n-1): yield x
  yield n

iterator bar: int {.closure.} =
  var x = iterator: int =
    for v in foo(2): yield v
    for v in rec(2): yield v
  for v in x(): yield v

proc p(): seq[int] =
  let q = proc (): seq[int] =
    for v in foo(3): result.add v
  result = q()

var s: seq[int]
for v in bar(): s.add v
doAssert s == @[1, 2, 0, 1, 2]
doAssert p() == @[1, 2, 3]
