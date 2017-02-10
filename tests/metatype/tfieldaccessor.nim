type
  Test = object
    x: int
    case p: bool
    of true:
      a: int
    else:
      case q: bool
      of true:
        b: int
      else:
        discard

proc f[T](t: typedesc[T]): int =
  1

assert Test.f == 1
