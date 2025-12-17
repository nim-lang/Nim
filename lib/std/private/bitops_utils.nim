const useBuiltins = not defined(noIntrinsicsBitOpts)
const noUndefined = defined(noUndefinedBitOpts)
const useGCC_builtins = (defined(gcc) or defined(llvm_gcc) or
                         defined(clang)) and useBuiltins
const useICC_builtins = defined(icc) and useBuiltins
const useVCC_builtins = defined(vcc) and useBuiltins
const arch64 = sizeof(int) == 8

template forwardImpl(impl, arg) {.dirty.} =
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

# this could also be implemented via:
# import std/typetraits
# template castToUnsigned*(x: SomeInteger): auto = cast[toUnsigned(typeof(x))](x)

template castToUnsigned(x: int8): uint8 = cast[uint8](x)
template castToUnsigned(x: int16): uint16 = cast[uint16](x)
template castToUnsigned(x: int32): uint32 = cast[uint32](x)
template castToUnsigned(x: int64): uint64 = cast[uint64](x)
template castToUnsigned(x: int): uint = cast[uint](x)
template castToUnsigned[T: SomeUnsignedInt](x: T): T = x
