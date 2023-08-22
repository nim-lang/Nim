discard """
  errormsg: "type mismatch: got <seq[empty]>"
  line: 16
"""

# bug #836

type
  TOption*[T] = object
    case FIsSome: bool
    of false: nil
    of true: FData: T

proc some*[T](value: T): TOption[T] = TOption[T](FIsSome: true, FData: value)

echo some(@[]).FIsSome

