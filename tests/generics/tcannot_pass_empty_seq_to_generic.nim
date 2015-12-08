discard """
  file: "tcannot_pass_empty_seq_to_generic.nim"
  errormsg: "type mismatch: got (seq[empty])"
  line: 17
"""

# bug #836

type
  TOption*[T] = object
    case FIsSome: bool
    of false: nil
    of true: FData: T

proc some*[T](value: T): TOption[T] = TOption[T](FIsSome: true, FData: value)

echo some(@[]).FIsSome

