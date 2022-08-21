import std/enumerate

let a = @[1, 3, 5, 7]

block:
  var res: seq[(int, int)]
  for i, x in enumerate(a):
    res.add (i, x)
  doAssert res == @[(0, 1), (1, 3), (2, 5), (3, 7)]
block:
  var res: seq[(int, int)]
  for (i, x) in enumerate(a.items):
    res.add (i, x)
  doAssert res == @[(0, 1), (1, 3), (2, 5), (3, 7)]
block:
  var res: seq[(int, int)]
  for i, x in enumerate(3, a):
    res.add (i, x)
  doAssert res == @[(3, 1), (4, 3), (5, 5), (6, 7)]
