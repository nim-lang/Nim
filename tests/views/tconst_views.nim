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


type MyObj = object
  data: openarray[char]

const
  val1 = Foo(data: toOpenArray([1, 2, 3], 1, 1))
  val2 = Foo(data: toOpenArray([1, 2, 3], 0, 2))
  val3 = MyObj(data: "Hello".toOpenArray(0, 2))
assert val1.data == [2]
assert val2.data == [1, 2, 3]
assert val3.data == "Hel"
