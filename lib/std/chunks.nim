#[
`Slice` would be a better name but unfortunately, `system.Slice` exists.
]#

import std/pointers

type Chunk*[T] = object
  data*: ptr T
  len*: int # TODO: or lenImpl + template accessor?

type MChunk*[T] = object
  data*: ptr T
  len*: int

proc toChunk*[T](a: openArray[T]): Chunk[T] =
  result = Chunk[T](data: a[0].addr, len: a.len)

# proc toChunk*[T](a: var openArray[T]): var Chunk[T] =
#   let x = a[0].unsafeAddr
#   # result = Chunk[T](data: a[0].unsafeAddr, len: a.len)
#   result = Chunk[T](data: x, len: a.len)

proc toMChunk*[T](a: var openArray[T]): MChunk[T] =
  result = MChunk[T](data: a[0].addr, len: a.len)

iterator mitems*[T](a: MChunk[T]): var T =
  for i in 0..<a.len:
    yield a.data[i]

iterator items*[T](a: MChunk[T] | Chunk[T]): lent T =
  for i in 0..<a.len:
    yield a.data[i]
