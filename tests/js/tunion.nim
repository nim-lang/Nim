discard """
  errormsg: "`{.union.}` is not implemented for js backend."
"""

type Foo {.union.} = object
  as_bytes: array[8, int8]
  data: int64


var a = Foo(data: 12345)

echo a.as_bytes
echo a.data

a.as_bytes[0] = 1

echo a.data
echo a.as_bytes
