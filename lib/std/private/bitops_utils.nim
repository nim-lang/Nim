template forwardImpl*(impl, arg) {.dirty.} =
  when sizeof(x) <= 4:
    when x is SomeSignedInt:
      impl(cast[uint32](x.int32))
    else:
      impl(x.uint32)
  else:
    when x is SomeSignedInt:
      impl(cast[uint64](x.int64))
    else:
      impl(x.uint64)

template toUnsigned*(x: int8): uint8 = cast[uint8](x)
template toUnsigned*(x: int16): uint16 = cast[uint16](x)
template toUnsigned*(x: int32): uint32 = cast[uint32](x)
template toUnsigned*(x: int64): uint64 = cast[uint64](x)
template toUnsigned*(x: int): uint = cast[uint](x)
