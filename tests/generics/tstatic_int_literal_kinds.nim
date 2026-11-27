discard """
  output: '''
ok
'''
"""

# The same integer value reaches a static type argument as different literal
# node kinds: a conversion of an unsigned type is folded to `nkUIntLit`, a
# suffix literal or a value read by the VM is `nkUInt16Lit` (and so on), and
# the argument written as a field of a `const` is evaluated rather than written.
# Two static arguments are equal when their values are, so every spelling of
# `3` has to select the parameter written with any other.

type
  S[H; T: static[H]] = object

  Vals = object
    u8* = 3'u8
    u16* = 3'u16
    u32* = 3'u32
    u64* = 3'u64
    u* = 3'u
    i8* = 3'i8
    i16* = 3'i16
    i32* = 3'i32
    i64* = 3'i64
    i* = 3

const Attrs = Vals()

# the formal reads its static value from a const object's field; the actual
# argument is written as a suffix literal, a conversion, or the same field
proc take8(x: S[uint8, Attrs.u8]): int = 1
proc take16(x: S[uint16, Attrs.u16]): int = 1
proc take32(x: S[uint32, Attrs.u32]): int = 1
proc take64(x: S[uint64, Attrs.u64]): int = 1
proc takeU(x: S[uint, Attrs.u]): int = 1
proc takeI8(x: S[int8, Attrs.i8]): int = 1
proc takeI16(x: S[int16, Attrs.i16]): int = 1
proc takeI32(x: S[int32, Attrs.i32]): int = 1
proc takeI64(x: S[int64, Attrs.i64]): int = 1
proc takeI(x: S[int, Attrs.i]): int = 1

doAssert take8(S[uint8, 3'u8]()) == 1
doAssert take8(S[uint8, 3.uint8]()) == 1
doAssert take8(S[uint8, uint8(3)]()) == 1
doAssert take8(S[uint8, Attrs.u8]()) == 1

doAssert take16(S[uint16, 3'u16]()) == 1
doAssert take16(S[uint16, 3.uint16]()) == 1
doAssert take16(S[uint16, uint16(3)]()) == 1
doAssert take16(S[uint16, Attrs.u16]()) == 1

doAssert take32(S[uint32, 3'u32]()) == 1
doAssert take32(S[uint32, 3.uint32]()) == 1
doAssert take32(S[uint32, uint32(3)]()) == 1
doAssert take32(S[uint32, Attrs.u32]()) == 1

doAssert take64(S[uint64, 3'u64]()) == 1
doAssert take64(S[uint64, 3.uint64]()) == 1
doAssert take64(S[uint64, uint64(3)]()) == 1
doAssert take64(S[uint64, Attrs.u64]()) == 1

doAssert takeU(S[uint, 3'u]()) == 1
doAssert takeU(S[uint, 3.uint]()) == 1
doAssert takeU(S[uint, uint(3)]()) == 1
doAssert takeU(S[uint, Attrs.u]()) == 1

doAssert takeI8(S[int8, 3'i8]()) == 1
doAssert takeI8(S[int8, int8(3)]()) == 1
doAssert takeI8(S[int8, Attrs.i8]()) == 1

doAssert takeI16(S[int16, 3'i16]()) == 1
doAssert takeI16(S[int16, int16(3)]()) == 1
doAssert takeI16(S[int16, Attrs.i16]()) == 1

doAssert takeI32(S[int32, 3'i32]()) == 1
doAssert takeI32(S[int32, int32(3)]()) == 1
doAssert takeI32(S[int32, Attrs.i32]()) == 1

doAssert takeI64(S[int64, 3'i64]()) == 1
doAssert takeI64(S[int64, int64(3)]()) == 1
doAssert takeI64(S[int64, Attrs.i64]()) == 1

doAssert takeI(S[int, 3]()) == 1
doAssert takeI(S[int, int(3)]()) == 1
doAssert takeI(S[int, Attrs.i]()) == 1

# a different value is still a different type argument
doAssert not compiles(take8(S[uint8, 4'u8]()))
doAssert not compiles(take16(S[uint16, uint16(4)]()))
doAssert not compiles(take64(S[uint64, 4.uint64]()))
doAssert not compiles(takeI32(S[int32, int32(4)]()))

# one value, one type: the instance cache must not hold a type per spelling
doAssert S[uint16, 3'u16] is S[uint16, uint16(3)]
doAssert S[uint16, uint16(3)] is S[uint16, Attrs.u16]
doAssert S[uint8, 3'u8] is S[uint8, 3.uint8]
doAssert S[uint64, 3'u64] is S[uint64, uint64(3)]
doAssert S[int8, 3'i8] is S[int8, int8(3)]

# the `distinct` wrapper that a protocol library uses as its attribute id
type
  AttrId = distinct uint16
  Ids = object
    revision* = AttrId(1)

const IdValues = Ids()

proc readRevision(x: S[AttrId, IdValues.revision]): int = 1

doAssert readRevision(S[AttrId, AttrId(1)]()) == 1
doAssert not compiles(readRevision(S[AttrId, AttrId(2)]()))

echo "ok"
