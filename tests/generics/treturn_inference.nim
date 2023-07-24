
{.experimental: "inferGenericTypes".}


block:
  type
    MyOption[T, Z] = object
      x: T
      y: Z

  proc none[T, Z](): MyOption[T, Z] =
    when T is int:
      result.x = 22
    when Z is float:
      result.y = 12.0

  proc myGenericProc[T, Z](): MyOption[T, Z] =
    none() # implied by return type

  let a = myGenericProc[int, float]()
  doAssert a.x == 22
  doAssert a.y == 12.0

  let b: MyOption[int, float] = none() # implied by type of b
  doAssert b.x == 22
  doAssert b.y == 12.0

# Simple template based result with inferred type for errors
block:
  type
    ResultKind {.pure.} = enum
      Ok
      Err

    Result[T] = object
      case kind: ResultKind
      of Ok:
        data: T
      of Err:
        errmsg: cstring

  template err[T](msg: static cstring): Result[T] =
    Result[T](kind : ResultKind.Err, errmsg : msg)

  proc testproc(): Result[int] =
    err("Inferred error!") # implied by proc return
  let r = testproc()
  doAssert r.kind == ResultKind.Err
  doAssert r.errmsg == "Inferred error!"

# Builtin seq
block:
  let x: seq[int] = newSeq(1)
  doAssert x is seq[int]
  doAssert x.len() == 1

  type
    MyType[T, Z] = object
      x: T
      y: Z

  let y: seq[MyType[int, float]] = newSeq(2)
  doAssert y is seq[MyType[int, float]]
  doAssert y.len() == 2

  let z = MyType[seq[float], string](
    x : newSeq(3),
    y : "test"
  )
  doAssert z.x is seq[float]
  doAssert z.x.len() == 3
  doAssert z.y is string
  doAssert z.y == "test"

# array
block:
  proc giveArray[N, T](): array[N, T] =
    for i in 0 .. N.high:
      result[i] = i
  var x: array[2, int] = giveArray()
  doAssert x == [0, 1]

# Tuples are quite tough and don't work
#[
# tuples
block:
  proc giveTuple[T, Z]: (T, Z, T) = discard
  let x: (int, float, int) = giveTuple()
  doAssert x is (int, float)
  doAssert x[0] == 0 and x[1] == 0.0

  proc giveNamedTuple[T, Z]: tuple[a: T, b: Z] = discard
  let y: tuple[a: int, b: float] = giveTuple()
  doAssert y is (int, float)
  doAssert y is tuple[a: int, b: float]
  doAssert y.a == 0 and y.b == 0.0

  proc giveNestedTuple[T, Z]: ((T, Z), Z) = discard
  let z: ((int, float), float) = giveNestedTuple()
]#


# basic constructors
block:
  type MyType[T] = object
    x: T

  proc giveValue[T](): T =
    when T is int:
      12
    else:
      default(T)

  let x = MyType[int](x : giveValue())
  doAssert x.x is int
  doAssert x.x == 12

  let y = MyType[MyType[float]](x : MyType[float](x : giveValue()))
  doAssert y.x is MyType[float]
  doAssert y.x.x is float
  doAssert y.x.x == 0.0

  # 'MyType[float]' is bound to 'T' directly
  #  instead of mapping 'T' to 'float'
  let z = MyType[MyType[float]](x : giveValue())
  doAssert z.x is MyType[float]
  doAssert z.x.x == 0.0
