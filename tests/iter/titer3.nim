discard """
  file: "titer3.nim"
  output: "1231"
"""

iterator count1_3: int =
  yield 1
  yield 2
  yield 3

for x in count1_3():
  write(stdout, $x)

# yield inside an iterator, but not in a loop:
iterator iter1(a: openArray[int]): int =
  yield a[0]

var x = [[1, 2, 3], [4, 5, 6]]
for y in iter1(x[0]): write(stdout, $y)

#OUT 1231

