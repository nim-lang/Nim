# bug #8052

type
  UintImpl*[N: static[int], T: SomeUnsignedInt] = object
    raw_data*: array[N, T]

template genLoHi(TypeImpl: untyped): untyped =
  template loImpl[N: static[int], T: SomeUnsignedInt](dst: TypeImpl[N div 2, T], src: TypeImpl[N, T]) =
    let halfSize = N div 2
    for i in 0 ..< halfSize:
      dst.raw_data[i] = src.raw_data[i]

  proc lo*[N: static[int], T: SomeUnsignedInt](x: TypeImpl[N,T]): TypeImpl[N div 2, T] {.inline.}=
    loImpl(result, x)

genLoHi(UintImpl)

var a: UintImpl[4, uint32]

a.raw_data = [1'u32, 2'u32, 3'u32, 4'u32]
assert a.lo.raw_data.len == 2
assert a.lo.raw_data[0] == 1
assert a.lo.raw_data[1] == 2
