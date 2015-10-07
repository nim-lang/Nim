discard """
  output: "(kind: None)"
"""

when true:
  # bug #2637

  type
    OptionKind = enum
      None,
      Some

    Option*[T] = object
      case kind: OptionKind
      of None:
        discard
      of Some:
        value*: T

  proc none*[T](): Option[T] =
    Option[T](kind: None)

  proc none*(T: typedesc): Option[T] = none[T]()


  proc test(): Option[int] =
    int.none

  echo test()

