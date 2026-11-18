# Helper for tconcept_alias_scope.nim
type
  Sized* = concept
    proc dynamicBar(x: Self): int

proc dynamicBar*(a: Sized): int = 1
