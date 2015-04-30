discard """
  output: '''true'''
"""

import tables

proc TestHashIntInt() =
  var tab = initTable[int,int]()
  for i in 1..1_000_000:
    tab[i] = i
  for i in 1..1_000_000:
    var x = tab[i]
    if x != i : echo "not found ", i

proc run1() =         # occupied Memory stays constant, but
  for i in 1 .. 50:   # aborts at run: 44 on win32 with 3.2GB with out of memory
    TestHashIntInt()

# bug #2107

var delTab = initTable[int,int](4)

for i in 1..4:
  delTab[i] = i
  delTab.del(i)
delTab[5] = 5


run1()
echo "true"
