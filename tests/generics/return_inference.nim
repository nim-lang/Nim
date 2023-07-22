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