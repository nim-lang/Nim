import tables

type
  FFoo* = object
  FBar* = object

proc new*(_: typedesc[FFoo]): int = 2
proc new*[T](_: typedesc[T]): int = 3
proc new*(_: typedesc): int = 4
proc new*(_: typedesc[seq[Table[int, seq[Table[int, string]]]]]): int = 5
proc new*(_: typedesc[seq[Table[int, seq[Table[int, typedesc]]]]]): int = 6
