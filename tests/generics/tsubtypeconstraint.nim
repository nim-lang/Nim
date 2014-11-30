
# bug #1684
type
  BaseType {.inheritable pure.} = object
    idx: int

  DerivedType* {.final pure.} = object of BaseType

proc index*[Toohoo: BaseType](h: Toohoo): int {.inline.} = h.idx
proc newDerived(idx: int): DerivedType {.inline.} = DerivedType(idx: idx)

let d = newDerived(2)
assert(d.index == 2)
