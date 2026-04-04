## Regression test for issue 22842 - auto in proc type
## The example should compile and run without internal compiler error.

proc register(cb: proc (e: auto): void) = discard

register(proc (e: int) = echo e)
