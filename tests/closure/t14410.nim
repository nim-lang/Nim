discard """
  matrix: "--mm:refc; --mm:orc"
  output: "hello"
"""

# bug #14410
type
  Obj = object
    data: seq[(string, string)]

proc createObj: Obj =
  result.data = @[("hello", "world")]

iterator items(obj: Obj): string =
  for (key, val) in obj.data:
    yield key

const mydata = createObj()

iterator getDataIter() {.closure.} =
  for x in items(mydata):
    echo x

var nameIterVar = getDataIter
nameIterVar()
