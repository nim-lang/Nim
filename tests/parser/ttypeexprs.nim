proc foo[T: ptr int | ptr string](x: T) = discard
var x = "abc"
foo(addr x)

let n = 3'u32
type Double = (
  when n.sizeof == 4: uint64
  elif n.sizeof == 2: uint32
  else: uint16
)
