## This module provides further logic operators like 'forall' and 'exists'
## They are only supported in `.ensures` etc pragmas.

proc `->`*(a, b: bool): bool {.magic: "Implies".}
proc `<->`*(a, b: bool): bool {.magic: "Iff".}

proc forall*(args: varargs[untyped]): bool {.magic: "Forall".}
proc exists*(args: varargs[untyped]): bool {.magic: "Exists".}

proc old*[T](x: T): T {.magic: "Old".}
