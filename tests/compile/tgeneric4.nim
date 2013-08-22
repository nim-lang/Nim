type
  TIDGen*[A: Ordinal] = object
    next: A
    free: seq[A]

proc newIDGen*[A]: TIDGen[A] =
    newSeq result.free, 0

var x = newIDGen[int]()

