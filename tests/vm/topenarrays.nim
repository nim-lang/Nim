proc mutate(a: var openarray[int]) =
  var i = 0
  for x in a.mitems:
    x = i
    inc i

proc mutate(a: var openarray[char]) =
  var i = 1
  for ch in a.mitems:
    ch = 'a'


static:
  var a = [10, 20, 30]
  assert a.toOpenArray(1, 2).len == 2

  mutate(a)
  assert a.toOpenArray(0, 2) == [0, 1, 2]
  assert a.toOpenArray(0, 0) == [0]
  assert a.toOpenArray(1, 2) == [1, 2]
  assert "Hello".toOpenArray(1, 4) == "ello"
  var str = "Hello"
  str.toOpenArray(2, 4).mutate()
  assert str.toOpenArray(0, 4).len == 5
  assert str.toOpenArray(0, 0).len == 1
  assert str.toOpenArray(0, 0).high == 0
  assert str == "Heaaa"
  assert str.toOpenArray(0, 4) == "Heaaa"

  var arr: array[3..4, int] = [1, 2]
  assert arr.toOpenArray(3, 4) == [1, 2]
  assert arr.toOpenArray(3, 4).len == 2
  assert arr.toOpenArray(3, 3).high == 0

  assert arr.toOpenArray(3, 4).toOpenArray(0, 0) == [1]



