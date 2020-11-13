import sharedlist

var
  list: SharedList[int]
  count: int

init(list)

for i in 1 .. 250:
  list.add i

for i in list:
  inc count

doAssert count == 250

deinitSharedList(list)
