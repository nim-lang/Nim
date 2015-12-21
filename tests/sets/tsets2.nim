discard """
  output: '''true'''
"""

import hashes, sets

const
  data = [
    "34", "12",
    "90", "0",
    "1", "2",
    "3", "4",
    "5", "6",
    "7", "8",
    "9", "---00",
    "10", "11", "19",
    "20", "30", "40",
    "50", "60", "70",
    "80"]

block tableTest1:
  var t = initSet[tuple[x, y: int]]()
  t.incl((0,0))
  t.incl((1,0))
  doAssert(not t.containsOrIncl((0,1)))
  t.incl((1,1))

  for x in 0..1:
    for y in 0..1:
      doAssert((x,y) in t)
  #doAssert($t ==
  #  "{(x: 0, y: 0), (x: 0, y: 1), (x: 1, y: 0), (x: 1, y: 1)}")

block setTest2:
  var t = initSet[string]()
  t.incl("test")
  t.incl("111")
  t.incl("123")
  t.excl("111")

  t.incl("012")
  t.incl("123") # test duplicates

  doAssert "123" in t
  doAssert "111" notin t # deleted

  for key in items(data): t.incl(key)
  for key in items(data): doAssert key in t


block orderedSetTest1:
  var t = data.toOrderedSet
  for key in items(data): doAssert key in t
  var i = 0
  # `items` needs to yield in insertion order:
  for key in items(t):
    doAssert key == data[i]
    inc(i)

echo "true"
