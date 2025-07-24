proc foo[T: ptr int | ptr string](x: T) = discard
var x = "abc"
foo(addr x)

let n = 3'u32
type Double = (
  when n.sizeof == 4: uint64
  elif n.sizeof == 2: uint32
  else: uint16
)

type
  A = (ref | ptr | pointer)
  B = pointer | ptr | ref
  C = ref | ptr | pointer

template `+`(a, b): untyped = (b, a)
template `*`(a, b): untyped = (a, b)

doAssert (ref int + ref float * ref string + ref bool) is
  (ref bool, ((ref float, ref string), ref int))
type X = ref int + ref float * ref string + ref bool
doAssert X is (ref bool, ((ref float, ref string), ref int))

type SomePointer = proc | ref | ptr | pointer
