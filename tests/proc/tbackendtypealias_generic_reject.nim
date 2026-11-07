discard """
  errormsg: "type mismatch"
  line: 15
"""

# The instantiated formal still rejects a backend type alias mismatch
# (csize_t vs uint) next to a generic invocation.

type Box[T] = object
  item: T

proc h(v: (csize_t, seq[Box[int]])) = discard
proc take[T](x: T, cb: proc(v: (uint, seq[Box[T]])) {.nimcall.}) =
  cb((1'u, @[Box[T](item: x)]))
take(1, h)
