import macros

macro test(): untyped =
  result = nnkStmtList.newTree()
  let n = nnkStmtList.newTree(
    newIdentNode("one"),
    newIdentNode("two"),
    newIdentNode("three"),
    newIdentNode("four"),
    newIdentNode("five"),
    newIdentNode("six")
  )

  var i = 1
  for x in n[1 .. ^2]:
    assert x == n[i]
    i.inc
  assert i == 5

  i = 3
  for x in n[3..^1]:
    assert x == n[i]
    i.inc
  assert i == 6

  i = 0
  for x in n[0..3]:
    assert x == n[i]
    i.inc
  assert i == 4

  i = 0
  for x in n[0..5]:
    assert x == n[i]
    i.inc
  assert i == 6

test()
