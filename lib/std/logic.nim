## This module provides further logic operators like 'forall' and 'exists'
## They are only supported in `.ensures` etc pragmas.

func `->`*(a, b: bool): bool {.magic: "Implies".}
func `<->`*(a, b: bool): bool {.magic: "Iff".}

func forall*(args: varargs[untyped]): bool {.magic: "Forall".}
func exists*(args: varargs[untyped]): bool {.magic: "Exists".}

func old*[T](x: T): T {.magic: "Old".}
