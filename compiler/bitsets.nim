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
  TBitSet* = seq[int8]        # we use byte here to avoid issues with
                              # cross-compiling; uint would be more efficient
                              # however

const
  ElemSize* = sizeof(int8) * 8

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
  result = (x[int(e div ElemSize)] and toU8(int(1 shl (e mod ElemSize)))) !=
      toU8(0)

proc bitSetIncl(x: var TBitSet, elem: BiggestInt) =
  assert(elem >= 0)
  x[int(elem div ElemSize)] = x[int(elem div ElemSize)] or
      toU8(int(1 shl (elem mod ElemSize)))

proc bitSetExcl(x: var TBitSet, elem: BiggestInt) =
  x[int(elem div ElemSize)] = x[int(elem div ElemSize)] and
      not toU8(int(1 shl (elem mod ElemSize)))

proc bitSetInit(b: var TBitSet, length: int) =
  newSeq(b, length)

proc bitSetUnion(x: var TBitSet, y: TBitSet) =
  for i in countup(0, high(x)): x[i] = x[i] or y[i]

proc bitSetDiff(x: var TBitSet, y: TBitSet) =
  for i in countup(0, high(x)): x[i] = x[i] and not y[i]

proc bitSetSymDiff(x: var TBitSet, y: TBitSet) =
  for i in countup(0, high(x)): x[i] = x[i] xor y[i]

proc bitSetIntersect(x: var TBitSet, y: TBitSet) =
  for i in countup(0, high(x)): x[i] = x[i] and y[i]

proc bitSetEquals(x, y: TBitSet): bool =
  for i in countup(0, high(x)):
    if x[i] != y[i]:
      return false
  result = true

proc bitSetContains(x, y: TBitSet): bool =
  for i in countup(0, high(x)):
    if (x[i] and not y[i]) != int8(0):
      return false
  result = true

# Number of set bits for all values of int8
const populationCount: array[low(int8)..high(int8), int8] = [
  1.int8, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5, 
  2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 
  2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 
  3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 
  2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 
  3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 
  3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 
  4, 5, 5, 6, 5, 6, 6, 7, 5, 6, 6, 7, 6, 7, 7, 8, 
  0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4, 
  1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5, 
  1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5, 
  2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 
  1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5, 
  2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 
  2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 
  3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7
]

proc bitSetCard(x: TBitSet): BiggestInt =
  for it in x:
    result.inc populationCount[it]
