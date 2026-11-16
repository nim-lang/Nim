discard """
  matrix: "--mm:refc; --mm:orc --deepcopy:on"
  output: "3 1 true"
"""

# bug #14573: `=deepCopy` for a generic ref object type
type
  SomeObj[T] = ref object
    x: T
var called = 0
proc `=deepCopy`[T](o: SomeObj[T]): SomeObj[T] =
  inc called
  if o != nil: result = SomeObj[T](x: o.x)
let a = SomeObj[int](x: 3)
var b: SomeObj[int]
deepCopy(b, a)
echo b.x, " ", called, " ", cast[pointer](a) != cast[pointer](b)
