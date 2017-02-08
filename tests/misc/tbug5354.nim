type
  Test = object
    case p: bool
    of true:
      a: int
    else:
      discard

proc f[T](t: typedesc[T]): int =
  1

assert Test.f == 1
