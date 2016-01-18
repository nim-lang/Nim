discard """
  output: '''0
1
2
3
4
5
6
7
8
9
10
5 5
7 7
9 9
0
0
0
0
1
2'''
"""

when true:
  proc main() =
    let
      lo=0
      hi=10

    iterator itA(): int =
      for x in lo..hi:
        yield x

    for x in itA():
      echo x

    var y: int

    iterator itB(): int =
      while y <= hi:
        yield y
        inc y

    y = 5
    for x in itB():
      echo x, " ", y
      inc y

  main()


iterator infinite(): int {.closure.} =
  var i = 0
  while true:
    yield i
    inc i

iterator take[T](it: iterator (): T, numToTake: int): T {.closure.} =
  var i = 0
  for x in it():
    if i >= numToTake:
      break
    yield x
    inc i

# gives wrong reasult (3 times 0)
for x in infinite.take(3):
  echo x

# does what we want
let inf = infinite
for x in inf.take(3):
  echo x
