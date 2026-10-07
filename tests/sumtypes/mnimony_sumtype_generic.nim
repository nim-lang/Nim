type
  Option*[T] = object
    case
    of Some:
      val*: T
    of None:
      discard

  Either*[A, B] = object
    case
    of Left:
      a*: A
    of Right:
      b*: B

  Pair*[T] = object
    first*: T
    second*: T

proc getOrDefault*[T](opt: Option[T]; default: T): T =
  case opt
  of Some(val):
    result = val
  of None():
    result = default
