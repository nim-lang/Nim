import mns2fieldlib

proc usePoint*(p: Point): int = p.x
proc useOther*(o: Other): int = o.x
proc useNested*(p: Point): int =
  proc inner(): int = p.x
  inner()
proc useGeneric*[T](p: Point; y: T): int = p.x
discard useGeneric(newPoint(), 1)
