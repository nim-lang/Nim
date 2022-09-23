discard """
  output: '''1231
4
6
8
--------
4
6
8
'''
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
writeLine(stdout, "")

# ensure closure and inline iterators have the same behaviour regarding
# parameter passing

iterator clo(a: int): int {.closure.} =
  yield 0+a
  yield 1+a
  yield 2+a

iterator inl(a: int): int {.inline.} =
  yield 0+a
  yield 1+a
  yield 2+a

proc main =
  var y = 4
  for i in clo(y):
    echo i
    inc y

  echo "--------"
  y = 4
  for i in inl(y):
    echo i
    inc y

main()
