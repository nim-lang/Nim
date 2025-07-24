discard """
  action: compile
"""

type
  Ct*[T: SomeUnsignedInt] = distinct T

template `shr`*[T: Ct](x: T, y: SomeInteger): T = T(T.T(x) shr y)

var x: Ct[uint64]
let y {.used.} = x shr 2