# issue #19929

import std/[tables, hashes]

type Foo = object
  a: int

proc hash(f: Foo): Hash =
  var h: Hash = 0
  h = h !& hash(f.a)
  result = !$h

proc transpose[T, S](data: array[T, S]): Table[S, T] =
  for i, x in data:
    result[x] = i

const xs = [Foo(a: 5), Foo(a: -5)]
const x = transpose(xs)

doAssert x[Foo(a: -5)] == 1
doAssert x[Foo(a: 5)] == 0
