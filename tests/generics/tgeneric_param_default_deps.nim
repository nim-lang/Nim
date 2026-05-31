discard """
  matrix: "; --mm:refc"
"""

import std/deques

# Type-side generic param defaults that reference other type parameters
# (issue #4086).
#
# Currently fails on Nim 2.3.1 devel:
#   `Error: invalid type: 'Foo[system.int, seq[T]]' for var`
#
# Other languages (C++, TypeScript, Rust, Scala) all support this pattern.
# Nim already supports T-independent defaults like `[T; U = int]`; this
# extends support to type-side defaults that reference earlier type params
# (e.g. `type Foo[T; U = seq[T]]`). This is needed for binding C++ templates
# like `std::vector<T, allocator<T>>` and `std::unique_ptr<T, default_delete<T>>`.
#
# Note: proc-side brackets-internal defaults (`proc foo[T, U = T]()`) are
# out of scope; the PR's logic targets type-side default substitution.
# A separate change would be needed for proc-side signature defaults.

block: # #4086 type-side: object generic param default `seq[T]`
  type Foo[T; U = seq[T]] = object
    data: U
  var f: Foo[int]
  f.data.add 42
  doAssert f.data == @[42]

block: # nested reference: U default uses T, V default uses U
  type Foo[T; U = seq[T]; V = seq[U]] = object
    data: V
  var f: Foo[int]
  f.data.add @[1, 2]
  doAssert f.data == @[@[1, 2]]

block: # type-side direct: U = T
  type Foo[T; U = T] = object
    a: T
    b: U
  var f: Foo[int]
  f.a = 1
  f.b = 2
  doAssert f.b is int

block: # type-side compound: U = ref T
  type Foo[T; U = ref T] = object
    p: U
  var f: Foo[int]
  f.p = new(int)
  f.p[] = 9
  doAssert f.p[] == 9

block: # type-side compound: U = array[3, T]
  type Foo[T; U = array[3, T]] = object
    arr: U
  var f: Foo[int]
  f.arr[0] = 10
  f.arr[2] = 30
  doAssert f.arr[0] == 10
  doAssert f.arr[2] == 30

block: # #4086 original: all params defaulted, invocation with no args
  type Foo[T = int] = object
    x: T
  var f: Foo
  f.x = 42
  doAssert f.x == 42

block: # alias of a defaulted instantiation
  type Foo[T; U = T] = object
    a: T
    b: U
  type IntFoo = Foo[int]
  var f: IntFoo
  f.a = 1
  f.b = 2
  doAssert f.b is int

block: # distinct of a defaulted instantiation
  type Foo[T; U = seq[T]] = object
    data: U
  type DistFoo = distinct Foo[int]
  var f: DistFoo
  Foo[int](f).data.add 7
  doAssert Foo[int](f).data == @[7]

block: # union constraint + default referencing T (review request)
  type Foo[T; U: seq[T]|Deque[T] = seq[T]] = object
    data: U
  var f: Foo[int]
  f.data.add 42
  doAssert f.data is seq[int]
  doAssert f.data == @[42]

block: # typeclass constraint + concrete-type default (review request)
  type Foo[T: SomeInteger = int] = object
    x: T
  var f: Foo
  f.x = 7
  doAssert f.x is int
  var g: Foo[int64]
  g.x = 9'i64
  doAssert g.x is int64

block: # concept constraint + default (review request)
  type HasLen = concept x
    x.len is int
  type Foo[T: HasLen = string] = object
    val: T
  var f: Foo
  f.val = "hi"
  doAssert f.val.len == 2
  var g: Foo[seq[int]]
  g.val = @[1, 2, 3]
  doAssert g.val.len == 3
