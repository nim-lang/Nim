type
  Packed {.packed.} = object
    foo: float

proc bar(a: var float) =
  discard

var p: Packed
bar(p.foo)
