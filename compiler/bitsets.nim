#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# this unit handles Nim sets; it implements bit sets
# the code here should be reused in the Nim standard library

type
  ElemType = byte
  TBitSet* = seq[ElemType]    # we use byte here to avoid issues with
                              # cross-compiling; uint would be more efficient
                              # however
const
  ElemSize* = 8
  One = ElemType(1)
  Zero = ElemType(0)

template modElemSize(arg: untyped): untyped = arg and 7
template divElemSize(arg: untyped): untyped = arg shr 3

proc bitSetInit*(b: var TBitSet, length: int)
proc bitSetUnion*(x: var TBitSet, y: TBitSet)
proc bitSetDiff*(x: var TBitSet, y: TBitSet)
proc bitSetSymDiff*(x: var TBitSet, y: TBitSet)
proc bitSetIntersect*(x: var TBitSet, y: TBitSet)
proc bitSetIncl*(x: var TBitSet, elem: BiggestInt)
proc bitSetExcl*(x: var TBitSet, elem: BiggestInt)
proc bitSetIn*(x: TBitSet, e: BiggestInt): bool
proc bitSetEquals*(x, y: TBitSet): bool
proc bitSetContains*(x, y: TBitSet): bool
proc bitSetCard*(x: TBitSet): BiggestInt
# implementation

proc bitSetIn(x: TBitSet, e: BiggestInt): bool =
  result = (x[int(e.divElemSize)] and (One shl e.modElemSize)) != Zero

proc bitSetIncl(x: var TBitSet, elem: BiggestInt) =
  assert(elem >= 0)
  x[int(elem.divElemSize)] = x[int(elem.divElemSize)] or
      (One shl elem.modElemSize)

proc bitSetExcl(x: var TBitSet, elem: BiggestInt) =
  x[int(elem.divElemSize)] = x[int(elem.divElemSize)] and
      not(One shl elem.modElemSize)

proc bitSetInit(b: var TBitSet, length: int) =
  newSeq(b, length)

proc bitSetUnion(x: var TBitSet, y: TBitSet) =
  for i in 0..high(x): x[i] = x[i] or y[i]

proc bitSetDiff(x: var TBitSet, y: TBitSet) =
  for i in 0..high(x): x[i] = x[i] and not y[i]

proc bitSetSymDiff(x: var TBitSet, y: TBitSet) =
  for i in 0..high(x): x[i] = x[i] xor y[i]

proc bitSetIntersect(x: var TBitSet, y: TBitSet) =
  for i in 0..high(x): x[i] = x[i] and y[i]

proc bitSetEquals(x, y: TBitSet): bool =
  for i in 0..high(x):
    if x[i] != y[i]:
      return false
  result = true

proc bitSetContains(x, y: TBitSet): bool =
  for i in 0..high(x):
    if (x[i] and not y[i]) != Zero:
      return false
  result = true

# Number of set bits for all values of int8
const populationCount: array[uint8, uint8] = block:
    var arr: array[uint8, uint8]

    proc countSetBits(x: uint8): uint8 =
      return
        ( x and 0b00000001'u8) +
        ((x and 0b00000010'u8) shr 1) +
        ((x and 0b00000100'u8) shr 2) +
        ((x and 0b00001000'u8) shr 3) +
        ((x and 0b00010000'u8) shr 4) +
        ((x and 0b00100000'u8) shr 5) +
        ((x and 0b01000000'u8) shr 6) +
        ((x and 0b10000000'u8) shr 7)


    for it in low(uint8)..high(uint8):
      arr[it] = countSetBits(cast[uint8](it))

    arr

proc bitSetCard(x: TBitSet): BiggestInt =
  for it in x:
    result.inc int(populationCount[it])
