# xxx rename to something more meaningful

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

template toUnsigned*(T: typedesc[SomeInteger]): untyped =
  when T is int8: uint8
  elif T is int16: uint16
  elif T is int32: uint32
  elif T is int64: uint64
  elif T is int: uint
  else: T

template toSigned*(T: typedesc[SomeInteger]): untyped =
  when T is uint8: int8
  elif T is uint16: int16
  elif T is uint32: int32
  elif T is uint64: int64
  elif T is uint: int
  else: T

template castToUnsigned*(x: SomeInteger): auto = cast[toUnsigned(typeof(x))](x)
template castToSigned*(x: SomeInteger): auto = cast[toUnsigned(typeof(x))](x)
