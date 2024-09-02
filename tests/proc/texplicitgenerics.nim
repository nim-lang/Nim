block: # issue #16376
  type
    Matrix[T] = object
      data: T
  proc randMatrix[T](m, n: int, max: T): Matrix[T] = discard
  proc randMatrix[T](m, n: int, x: Slice[T]): Matrix[T] = discard
  template randMatrix[T](m, n: int): Matrix[T] = randMatrix[T](m, n, T(1.0))
  let B = randMatrix[float32](20, 10)

block: # different generic param counts 
  type
    Matrix[T] = object
      data: T
  proc randMatrix[T](m: T, n: T): Matrix[T] = Matrix[T](data: T(1.0))
  proc randMatrix[T; U: not T](m: T, n: U): (Matrix[T], U) = (Matrix[T](data: T(1.0)), default(U))
  let b = randMatrix[float32](20, 10)
  doAssert b == Matrix[float32](data: 1.0)

block: # above for templates 
  type
    Matrix[T] = object
      data: T
  template randMatrix[T](m: T, n: T): Matrix[T] = Matrix[T](data: T(1.0))
  template randMatrix[T; U: not T](m: T, n: U): (Matrix[T], U) = (Matrix[T](data: T(1.0)), default(U))
  let b = randMatrix[float32](20, 10)
  doAssert b == Matrix[float32](data: 1.0)

block: # sigmatch can't handle this without pre-instantiating the type:
  # minimized from numericalnim
  type Foo[T] = proc (x: T)
  proc foo[T](x: T) = discard
  proc bar[T](f: Foo[T]) = discard
  bar[int](foo)

block: # ditto but may be wrong minimization
  # minimized from measuremancer
  type Foo[T] = object
  proc foo[T](): Foo[T] = Foo[T]()
  when false:
    # this is the actual issue but there are other instantiation problems
    proc bar[T](x = foo[T]()) = discard
  else:
    proc bar[T](x: Foo[T] = foo[T]()) = discard
  bar[int](Foo[int]())
  bar[int]()
  when false:
    # alternative version, also causes instantiation issue
    proc baz[T](x: typeof(foo[T]())) = discard
    baz[int](Foo[int]())

block: # auto
  proc foo[T, U](x: T, y: U): (T, U) = (x, y)
  doAssert foo(1, 2) is (int, int)
  doAssert foo[auto, auto](1, 2) is (int, int)
  doAssert foo[int, auto](1, 2) is (int, int)
  doAssert foo[auto, int](1, 2) is (int, int)
  doAssert foo[auto, auto](1, "a") is (int, string)
  doAssert foo[int, auto](1, "a") is (int, string)
  doAssert foo[auto, string](1, "a") is (int, string)
