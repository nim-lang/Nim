
const
  pageSize = 4096

type
  Foo*[T; size: static[int] = pageSize] = object
    buffer: array[size, byte] # Error: ordinal type expected

var f1: Foo[int]
var f2: Foo[int, 1024]
doAssert f1.buffer.len == pageSize
doAssert f2.buffer.len == 1024
