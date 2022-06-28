discard """
  matrix: "--gc:arc"
"""

import sequtils

type
  CpuStorage*[T] = ref CpuStorageObj[T]
  CpuStorageObj[T] = object
    size*: int
    raw_buffer*: ptr UncheckedArray[T]
  Tensor[T] = object
    buf*: CpuStorage[T]

proc `=destroy`[T](s: var CpuStorageObj[T]) =
  s.raw_buffer.deallocShared()
  s.size = 0
  s.raw_buffer = nil

proc `=`[T](a: var CpuStorageObj[T]; b: CpuStorageObj[T]) {.error.}

proc allocCpuStorage[T](s: var CpuStorage[T], size: int) =
  new(s)
  s.raw_buffer = cast[ptr UncheckedArray[T]](allocShared0(sizeof(T) * size))
  s.size = size

proc newTensor[T](size: int): Tensor[T] =
  allocCpuStorage(result.buf, size)

proc `[]`[T](t: Tensor[T], idx: int): T = t.buf.raw_buffer[idx]
proc `[]=`[T](t: Tensor[T], idx: int, val: T) = t.buf.raw_buffer[idx] = val
func size[T](t: Tensor[T]): int = t.buf.size

proc toTensor[T](s: seq[T]): Tensor[T] =
  result = newTensor[T](s.len)
  for i, x in s:
    result[i] = x

type
  Column* = ref object # works if normal object
    fCol: Tensor[float]

proc asType*(t: Tensor[float]): Tensor[float] {.noInit.} = # works if `noInit` removed
  result = t

proc toColumn*(t: Tensor[float]): Column =
  result = Column(fCol: t.asType())
  # works with regular contruction of ref object:
  #result = new Column
  #result.fCol = t.asType()

proc theBug =
  # replacing toSeq.mapIt by a for loop makes it go away
  # broken starting from `32252` on my machine, toSeq(0 .. 32251).mapIt(it.float).toTensor() works
  let occ = toSeq(0 .. 32252).mapIt(it.float).toTensor()
  let c = toColumn occ

theBug()