discard """
  cmd: "nim c --experimental:views $file"
  output: '''(data: [1, 2, 3], other: 4)
[1, 20, 3]'''
"""

type
  Foo = object
    data: openArray[int]
    other: int

const
  c = Foo(data: [1, 2, 3], other: 4)

  c2 = Foo(data: [1, 20, 3], other: 4)

proc `$`(x: openArray[int]): string =
  result = "["
  for i in x:
    if result.len > 1: result.add ", "
    result.add $i
  result.add "]"

echo c
echo c2.data

