# bug #16376

block: # main snippet
  type
    Matrix[T] = object
      data: T
  proc randMatrix[T](m, n: int, max: T): Matrix[T] = discard
  proc randMatrix[T](m, n: int, x: Slice[T]): Matrix[T] = discard
  template randMatrix[T](m, n: int): Matrix[T] = randMatrix[T](m, n, T(1.0))
  let B = randMatrix[float32](20, 10)

block: # example 1: regression
  proc fn[T](max: int) = discard
  proc fn[T](x: string) = discard
  template fn[T]() = fn[T](1)
  fn[float32]()

block: # example 3: regression: accepts invalid
  #[
  D20201216T124243
  1.4: bug: was showing ok2
  0.19.6: good (Error: ambiguous call)
  ]#
  template bad() =
    proc fn[T](max: int) = echo "ok1"
    proc fn[T]() =  echo "ok2"
    template fn[T]() = fn[T](1)
    fn[float32]()
  # doAssert not compiles(bad())

when false: # xxx example 2: bad error msg
  block:
    proc fn[T](max: int) = discard
    template fn[T]() = fn[T](1)
    fn[float32]()

when false: # example 4 D20201216T143655
  proc fn[T](max: T, y: string) = discard
  template fn[T](a: T) = fn[int](1, "")
  fn[int8](2) # Error: type mismatch: got <int literal(2)> but expected one of: proc (max: int8, y: string){
  # these are ok:
  # fn(2)
  # also works if we change template name so it's not overloaded
  # also works if `s/proc fn[T]/template fn[T]/`
