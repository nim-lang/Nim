discard """
  errormsg: "'onHeartbeat' doesn't have a concrete type, due to unspecified generic parameters."
  line: 15
"""

# bug #12765: casting an uninstantiated generic proc crashed the compiler
type Bar[T] = object
  x: T

proc onHeartbeat[T](bar: ptr Bar[T]) = echo "bazinga"

proc setHeartbeat[T](hook: var proc (env: pointer) {.nimcall.}, bar: var Bar[T]) =
  # fine:
  hook = cast[proc(env: pointer) {.nimcall.}](onHeartbeat[T])
  hook = cast[proc(env: pointer) {.nimcall.}](onHeartbeat)

var hook: proc (env: pointer) {.nimcall.}
var bar: Bar[int]
setHeartbeat(hook, bar)
