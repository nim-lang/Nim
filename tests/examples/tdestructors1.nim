type
  myseq*[T] = object
    len, cap: int
    data: ptr UncheckedArray[T]

proc `=destroy`*[T](x: var myseq[T]) =
  if x.data != nil:
    for i in 0..<x.len: `=destroy`(x.data[i])
    dealloc(x.data)

proc `=copy`*[T](a: var myseq[T]; b: myseq[T]) =
  # do nothing for self-assignments:
  if a.data == b.data: return
  `=destroy`(a)
  wasMoved(a)
  a.len = b.len
  a.cap = b.cap
  if b.data != nil:
    a.data = cast[typeof(a.data)](alloc(a.cap * sizeof(T)))
    for i in 0..<a.len:
      a.data[i] = b.data[i]

proc `=sink`*[T](a: var myseq[T]; b: myseq[T]) =
  # move assignment, optional.
  # Compiler is using `=destroy` and `copyMem` when not provided
  `=destroy`(a)
  wasMoved(a)
  a.len = b.len
  a.cap = b.cap
  a.data = b.data

proc add*[T](x: var myseq[T]; y: sink T) =
  if x.len >= x.cap:
    x.cap = max(x.len + 1, x.cap * 2)
    x.data = cast[typeof(x.data)](realloc(x.data, x.cap * sizeof(T)))
  # if x.len >= x.cap: resize(x)
  x.data[x.len] = y
  inc x.len

proc `[]`*[T](x: myseq[T]; i: Natural): lent T =
  assert i < x.len
  x.data[i]

proc `[]=`*[T](x: var myseq[T]; i: Natural; y: sink T) =
  assert i < x.len
  x.data[i] = y

proc createSeq*[T](elems: varargs[T]): myseq[T] =
  result.cap = elems.len
  result.len = elems.len
  result.data = cast[typeof(result.data)](alloc(result.cap * sizeof(T)))
  for i in 0..<result.len: result.data[i] = elems[i]

proc len*[T](x: myseq[T]): int {.inline.} = x.len

var witness: seq[int]

type Foo = object
  x: int

proc `=destroy`(a: var Foo) =
  witness.add a.x

var s = createSeq(Foo(x: 0), Foo(x: 1))
s.add Foo(x: 2)
assert s.len == 3
s[1] = Foo(x: 11)
assert s[1] == Foo(x: 11)
assert witness.len >= 2
