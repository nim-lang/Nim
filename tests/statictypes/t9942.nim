# bug #9942: static generic params with default values as array sizes
const
  pageSize = 4096

type
  Foo[T; size: static[int] = pageSize] = object
    buffer: array[size, byte]
  Bar[T; size = pageSize] = object
    buffer: array[size, byte]
  Q[size: static int = 8] = object
    buffer: array[size, byte]

var f1: Foo[int]
var f2: Foo[int, 1024]
doAssert f1.buffer.len == 4096
doAssert f2.buffer.len == 1024

var b2: Bar[int, 1024]
var b1: Bar[int]
doAssert b1.buffer.len == 4096
doAssert b2.buffer.len == 1024

var q2: Q[16]
doAssert q2.buffer.len == 16
