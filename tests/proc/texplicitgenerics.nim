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
  proc randMatrix[T, U](m: T, n: U): (Matrix[T], U) = (Matrix[T](data: T(1.0)), default(U))
  let b = randMatrix[float32](20, 10)
  doAssert b == Matrix[float32](data: 1.0)

block: # above for templates 
  type
    Matrix[T] = object
      data: T
  proc randMatrix[T](m: T, n: T): Matrix[T] = Matrix[T](data: T(1.0))
  proc randMatrix[T, U](m: T, n: U): (Matrix[T], U) = (Matrix[T](data: T(1.0)), default(U))
  let b = randMatrix[float32](20, 10)
  doAssert b == Matrix[float32](data: 1.0)
