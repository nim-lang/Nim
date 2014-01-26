discard """
  output: "XXXXX01234"
"""

iterator modPairs(a: var array[0..4,string]): tuple[key: int, val: var string] =
  for i in 0..a.high:
    yield (i, a[i])

iterator modItems*[T](a: var array[0..4,T]): var T =
  for i in 0..a.high:
    yield a[i]

var
  arr = ["a", "b", "c", "d", "e"]

for a in modItems(arr):
  a = "X"

for a in items(arr):
  stdout.write(a)

for i, a in modPairs(arr):
  a = $i

for a in items(arr):
  stdout.write(a)

echo ""

