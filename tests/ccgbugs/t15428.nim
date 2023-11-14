discard """
    cmd: "nim $target --mm:refc $file"
    output: '''5
5
[1, 2, 3, 4, 5]
(data: [1, 2, 3, 4, 5])
'''
"""

proc take[T](f: openArray[T]) =
  echo f.len
let f = @[0,1,2,3,4]
take(f.toOpenArray(0,4))

{.experimental: "views".}
type
  Foo = object
    data: openArray[int]
let f2 = Foo(data: [1,2,3,4,5])
echo f2.data.len
echo f2.data
echo f2