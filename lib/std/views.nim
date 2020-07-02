##[
Aka in other languages as: slice (in go), span (in C#).
Note that `system.Slice` already exists with a different meaning.

Note: experimental module, unstable API.
]##

import std/pointers

type View*[T] = object
  ## provides a view over a region of memory representing elements of type T
  data*: ptr T
  len*: int # TODO: or lenImpl + template accessor?

type MView*[T] = object
  data*: ptr T
  len*: int

type SomeView*[T] = View[T]|MView[T]

proc view*[T](a: openArray[T]): View[T] {.inline.} =
  ## return an immutable view over `a`
  # PRTEMP: unsafeAddr?
  result = View[T](data: a[0].addr, len: a.len)

proc view*[T](a: var openArray[T]): View[T] {.inline.} =
  ## return an immutable view over `a`
  result = View[T](data: a[0].addr, len: a.len)

# proc toView*[T](a: var openArray[T]): var View[T] =
#   let x = a[0].unsafeAddr
#   # result = View[T](data: a[0].unsafeAddr, len: a.len)
#   result = View[T](data: x, len: a.len)

proc mview*[T](a: var openArray[T]): MView[T] {.inline.} =
  ## return a mutable view over `a`
  result = MView[T](data: a[0].addr, len: a.len)

# iterator items*[T](a: MView[T] | View[T]): lent T =
iterator items*[T](a: SomeView[T]): lent T =
  ## iterator over `a`
  for i in 0..<a.len:
    yield a.data[i]

iterator mitems*[T](a: MView[T]): var T =
  ## mutable iterator over `a`
  for i in 0..<a.len:
    yield a.data[i]

proc `[]`*[T, I](a: View[T], r: Slice[I]): View[T] {.inline.} =
  assert r.a >= 0
  assert r.b < a.len
  result = View[T](data: a.data + r.a, len: r.len)

proc `[]`*[T](a: View[T], index: int): lent T {.inline.} =
  a.data[index]

proc `[]`*[T](a: MView[T], index: int): var T {.inline.} =
  # TODO: `a: var MView[T]`?
  a.data[index]

# proc `[]`*(a: View[T], index: int): lent T =
#   a.data[index]

proc `[]=`*[T](a: var MView[T], index: int, b: T) {.inline.} =
  a.data[index] = b
