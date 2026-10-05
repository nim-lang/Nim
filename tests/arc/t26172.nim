discard """
  matrix: "--mm:orc"
  ccodecheck: "'.traceImpl = ((void*) rttiTrace'"
  output: "ok"
"""

# bug #26172
# The `traceImpl` RTTI slot is called through a `void (*)(void*, void*)`
# function pointer, so it must point to a wrapper with exactly that C
# signature, not to the `=trace` hook itself (`-fsanitize=function`).

type V = ref object
  r: V

var h: V
proc j(d: V) = h = d
proc b() = j(V())

b()
GC_fullCollect()
echo "ok"
