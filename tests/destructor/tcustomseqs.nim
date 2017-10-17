discard """
  output: '''1
2
3
4
5
6
after 1 1'''
  cmd: '''nim c --newruntime $file'''
"""

import typetraits

type
  myseq*[T] = object
    len, cap: int
    data: ptr UncheckedArray[T]

# XXX make code memory safe for overflows in '*'
var
  allocCount, deallocCount: int

proc `=destroy`*[T](x: var myseq[T]) =
  if x.data != nil:
    when not supportsCopyMem(T):
      for i in 0..<x.len: `=destroy`(x[i])
    dealloc(x.data)
    inc deallocCount
    x.data = nil
    x.len = 0
    x.cap = 0

proc `=`*[T](a: var myseq[T]; b: myseq[T]) =
  if a.data == b.data: return
  if a.data != nil:
    dealloc(a.data)
    inc deallocCount
    a.data = nil
  a.len = b.len
  a.cap = b.cap
  if b.data != nil:
    a.data = cast[type(a.data)](alloc(a.cap * sizeof(T)))
    inc allocCount
    when supportsCopyMem(T):
      copyMem(a.data, b.data, a.cap * sizeof(T))
    else:
      for i in 0..<a.len:
        a.data[i] = b.data[i]

proc `=sink`*[T](a: var myseq[T]; b: myseq[T]) =
  if a.data != nil and a.data != b.data:
    dealloc(a.data)
    inc deallocCount
  a.len = b.len
  a.cap = b.cap
  a.data = b.data

proc resize[T](s: var seq[T]) =
  if s.cap == 0: s.cap = 8
  else: s.cap = (s.cap * 3) shr 1
  if s.data == nil: inc allocCount
  s.data = cast[type(s.data)](realloc(s.data, s.cap * sizeof(T)))

proc reserveSlot[T](x: var seq[T]): ptr T =
  if x.len >= x.cap: resize(x)
  result = addr(x.data[x.len])
  inc x.len

template add*[T](x: var seq[T]; y: T) =
  reserveSlot(x)[] = y

proc shrink*[T](x: var myseq[T]; newLen: int) =
  assert newLen <= x.len
  assert newLen >= 0
  when not supportsCopyMem(T):
    for i in countdown(x.len - 1, newLen - 1):
      `=destroy`(x.data[i])
  x.len = newLen

proc grow*[T](x: var myseq[T]; newLen: int; value: T) =
  if newLen <= x.len: return
  assert newLen >= 0
  if x.cap == 0: x.cap = newLen
  else: x.cap = max(newLen, (x.cap * 3) shr 1)
  if x.data == nil: inc allocCount
  x.data = cast[type(x.data)](realloc(x.data, x.cap * sizeof(T)))
  for i in x.len..<newLen:
    x.data[i] = value
  x.len = newLen

template default[T](t: typedesc[T]): T =
  var v: T
  v

proc setLen*[T](x: var myseq[T]; newLen: int) {.deprecated.} =
  if newlen < x.len: shrink(x, newLen)
  else: grow(x, newLen, default(T))

template `[]`*[T](x: myseq[T]; i: Natural): T =
  assert i < x.len
  x.data[i]

template `[]=`*[T](x: myseq[T]; i: Natural; y: T) =
  assert i < x.len
  x.data[i] = y

proc createSeq*[T](elems: varargs[T]): myseq[T] =
  result.cap = elems.len
  result.len = elems.len
  result.data = cast[type(result.data)](alloc(result.cap * sizeof(T)))
  inc allocCount
  when supportsCopyMem(T):
    copyMem(result.data, unsafeAddr(elems[0]), result.cap * sizeof(T))
  else:
    for i in 0..<result.len:
      result.data[i] = elems[i]

proc len*[T](x: myseq[T]): int {.inline.} = x.len

proc main =
  let s = createSeq(1, 2, 3, 4, 5, 6)
  for i in 0 ..< s.len:
    echo s[i]

main()
echo "after ", allocCount, " ", deallocCount
