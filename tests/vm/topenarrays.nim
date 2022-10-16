proc mutate(a: var openarray[int]) =
  var i = 0
  for x in a.mitems:
    x = i
    inc i

static:
  var a = [10, 20, 30]
  assert a.toOpenArray(1, 2).len == 2

  mutate(a)
  assert a.toOpenArray(0, 2) == [0, 1, 2]
  assert a.toOpenArray(0, 0) == [0]
  assert a.toOpenArray(1, 2) == [1, 2]


