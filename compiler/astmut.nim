type
  Indexable = PNode or PType

proc unsafeAdd(father, son: Indexable) =
  assert son != nil
  when not defined(nimNoNilSeqs):
    if father.sons == nil:
      father.sons = @[]
  father.sons.add son

proc safeAdd*(father, son: Indexable) =
  father.unsafeAdd son

template add*(father, son: PNode or PType) {.deprecated.} =
  father.safeAdd son

