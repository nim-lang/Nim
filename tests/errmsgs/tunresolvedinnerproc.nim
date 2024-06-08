proc wrap[T]() =
  proc notConcrete[T](x, y: int): int =
    var dummy: T
    result = x - y

  var x: proc (x, y: T): int
  x = notConcrete #[tt.Error
      ^ 'notConcrete' doesn't have a concrete type, due to unspecified generic parameters.]#

wrap[int]()
