## Issue 22842 - internal error: getTypeDescAux(tyAnything) with auto in proc type
## Test added because the case now compiles without the internal error.

proc register(cb: proc (e: auto): void) = discard

register(proc (e: int) = echo e)
