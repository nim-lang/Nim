#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import allocators, typetraits

## Default seq implementation used by Nim's core.
type
  seq*[T] = object
    len, cap: int
    data: ptr UncheckedArray[T]

const nimSeqVersion {.core.} = 2

template frees(s) = dealloc(s.data, s.cap * sizeof(T))

# XXX make code memory safe for overflows in '*'

when defined(nimHasTrace):
  proc `=trace`[T](s: seq[T]; a: Allocator) =
    for i in 0 ..< s.len: `=trace`(s.data[i], a)

proc `=destroy`[T](x: var seq[T]) =
  if x.data != nil:
    when not supportsCopyMem(T):
      for i in 0..<x.len: `=destroy`(x[i])
    frees(x)
    x.data = nil
    x.len = 0
    x.cap = 0

proc `=`[T](a: var seq[T]; b: seq[T]) =
  if a.data == b.data: return
  if a.data != nil:
    frees(a)
    a.data = nil
  a.len = b.len
  a.cap = b.cap
  if b.data != nil:
    a.data = cast[type(a.data)](alloc(a.cap * sizeof(T)))
    when supportsCopyMem(T):
      copyMem(a.data, b.data, a.cap * sizeof(T))
    else:
      for i in 0..<a.len:
        a.data[i] = b.data[i]

proc `=sink`[T](a: var seq[T]; b: seq[T]) =
  if a.data != nil and a.data != b.data:
    frees(a)
  a.len = b.len
  a.cap = b.cap
  a.data = b.data

proc resize[T](s: var seq[T]) =
  let old = s.cap
  if old == 0: s.cap = 8
  else: s.cap = (s.cap * 3) shr 1
  s.data = cast[type(s.data)](realloc(s.data, old * sizeof(T), s.cap * sizeof(T)))

proc reserveSlot[T](x: var seq[T]): ptr T =
  if x.len >= x.cap: resize(x)
  result = addr(x.data[x.len])
  inc x.len

template add*[T](x: var seq[T]; y: T) =
  reserveSlot(x)[] = y

proc shrink*[T](x: var seq[T]; newLen: int) =
  assert newLen <= x.len
  assert newLen >= 0
  when not supportsCopyMem(T):
    for i in countdown(x.len - 1, newLen - 1):
      `=destroy`(x.data[i])
  x.len = newLen

proc grow*[T](x: var seq[T]; newLen: int; value: T) =
  if newLen <= x.len: return
  assert newLen >= 0
  if x.cap == 0: x.cap = newLen
  else: x.cap = max(newLen, (x.cap * 3) shr 1)
  x.data = cast[type(x.data)](realloc(x.data, x.cap * sizeof(T)))
  for i in x.len..<newLen:
    x.data[i] = value
  x.len = newLen

template default[T](t: typedesc[T]): T =
  var v: T
  v

proc setLen*[T](x: var seq[T]; newLen: int) {.deprecated.} =
  if newlen < x.len: shrink(x, newLen)
  else: grow(x, newLen, default(T))

template `[]`*[T](x: seq[T]; i: Natural): T =
  assert i < x.len
  x.data[i]

template `[]=`*[T](x: seq[T]; i: Natural; y: T) =
  assert i < x.len
  x.data[i] = y

proc `@`*[T](elems: openArray[T]): seq[T] =
  result.cap = elems.len
  result.len = elems.len
  result.data = cast[type(result.data)](alloc(result.cap * sizeof(T)))
  when supportsCopyMem(T):
    copyMem(result.data, unsafeAddr(elems[0]), result.cap * sizeof(T))
  else:
    for i in 0..<result.len:
      result.data[i] = elems[i]

proc len*[T](x: seq[T]): int {.inline.} = x.len

proc `$`*[T](x: seq[T]): string =
  result = "@["
  var firstElement = true
  for i in 0..<x.len:
    let
      value = x.data[i]
    if firstElement:
      firstElement = false
    else:
      result.add(", ")

    when compiles(value.isNil):
      # this branch should not be necessary
      if value.isNil:
        result.add "nil"
      else:
        result.addQuoted(value)
    else:
      result.addQuoted(value)

  result.add("]")
