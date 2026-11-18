# bug #8868: static params computed in a return type
type
  BigNumber[bits: static[int]] = object
    data: array[bits, uint32]
  RawBigNumber[bits: static[int]] = object
    data: array[bits, byte]

proc decodeRaw[N: static int](src: RawBigNumber[N]): BigNumber[N] =
  discard

proc toRawBigNumber[N: static[int]](v: array[N, byte]): RawBigNumber[N * 8] =
  discard

var a = [0xAA'u8, 0xBB'u8, 0xCC'u8, 0xDD'u8].toRawBigNumber()
var b = decodeRaw(a)
doAssert a.data.len == 32
doAssert b.data.len == 32
