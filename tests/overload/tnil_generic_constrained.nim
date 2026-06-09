discard """
  action: compile
"""
type
  LP[S, T] = object
    x: S
    y: T

proc foo[S: SomeInteger; T](x: ref LP[S, T]) =
  doAssert(false)
proc foo(x: pointer) = discard

# nil can't instantiate ref LP[S:SomeInteger, T] — the first overload
# fails speculatively, but foo(pointer) matches. bind foo(pointer).
foo(nil)

type
  FutureBase = ref object of RootObj
  Future[T] = ref object of FutureBase
  InternalRaisesFuture[T, E] = ref object of FutureBase
  SomeFuture = Future | InternalRaisesFuture

proc race(futs: openArray[FutureBase]): auto = discard
proc race(futs: openArray[SomeFuture]): auto =
  doAssert(false)

# should bind to openArray[FutureBase]
race([])

proc one(fut0: SomeFuture; futs: varargs[SomeFuture]) =
  doAssert false
proc one(futs: openArray[SomeFuture]) = discard

proc oneC(x: seq[Future[int]]) =
  # should match openArray[SomeFuture]
  one(x)

# issue #22964
type
  Base = ref object of RootObj
  Inher[T] = ref object of Base

proc a(v: varargs[Base]) = discard

proc a[T](v: varargs[Inher[T]]) = 
  doAssert false

a()
