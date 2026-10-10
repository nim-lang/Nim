type
  Foo[T] = distinct seq[T]
  Bar[T] = object

proc newFoo[T](): Foo[T] = Foo[T](newSeq[T]())

var x = newFoo[Bar[int]]()

# issue #22936

import std/macros

type
  InternalFutureBase = object of RootObj

  FutureBase = ref object of InternalFutureBase

  Future[T] = ref object of FutureBase
    internalValue: T

  B[T, E] = ref object of Future[T]

proc take[F: Future](fut: F) = discard

proc takeMany[F: Future](futs: seq[F]) = discard

macro checkFutures[F: Future](futs: seq[F]): untyped =
  newEmptyNode()

var future: B[void, void]
var futures: seq[B[void, void]]

take(future)
takeMany(futures)
checkFutures(futures)
