#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# this unit handles Nimrod sets; it implements bit sets
# the code here should be reused in the Nimrod standard library

type
  TBitSet* = seq[int8]        # we use byte here to avoid issues with
                              # cross-compiling; uint would be more efficient
                              # however

const
  ElemSize* = sizeof(int8) * 8

proc BitSetInit*(b: var TBitSet, length: int)
proc BitSetUnion*(x: var TBitSet, y: TBitSet)
proc BitSetDiff*(x: var TBitSet, y: TBitSet)
proc BitSetSymDiff*(x: var TBitSet, y: TBitSet)
proc BitSetIntersect*(x: var TBitSet, y: TBitSet)
proc BitSetIncl*(x: var TBitSet, elem: BiggestInt)
proc BitSetExcl*(x: var TBitSet, elem: BiggestInt)
proc BitSetIn*(x: TBitSet, e: BiggestInt): bool
proc BitSetEquals*(x, y: TBitSet): bool
proc BitSetContains*(x, y: TBitSet): bool
# implementation

proc BitSetIn(x: TBitSet, e: BiggestInt): bool =
  result = (x[int(e div ElemSize)] and toU8(int(1 shl (e mod ElemSize)))) !=
      toU8(0)

proc BitSetIncl(x: var TBitSet, elem: BiggestInt) =
  assert(elem >= 0)
  x[int(elem div ElemSize)] = x[int(elem div ElemSize)] or
      toU8(int(1 shl (elem mod ElemSize)))

proc BitSetExcl(x: var TBitSet, elem: BiggestInt) =
  x[int(elem div ElemSize)] = x[int(elem div ElemSize)] and
      not toU8(int(1 shl (elem mod ElemSize)))

proc BitSetInit(b: var TBitSet, length: int) =
  newSeq(b, length)

proc BitSetUnion(x: var TBitSet, y: TBitSet) =
  for i in countup(0, high(x)): x[i] = x[i] or y[i]

proc BitSetDiff(x: var TBitSet, y: TBitSet) =
  for i in countup(0, high(x)): x[i] = x[i] and not y[i]

proc BitSetSymDiff(x: var TBitSet, y: TBitSet) =
  for i in countup(0, high(x)): x[i] = x[i] xor y[i]

proc BitSetIntersect(x: var TBitSet, y: TBitSet) =
  for i in countup(0, high(x)): x[i] = x[i] and y[i]

proc BitSetEquals(x, y: TBitSet): bool =
  for i in countup(0, high(x)):
    if x[i] != y[i]:
      return false
  result = true

proc BitSetContains(x, y: TBitSet): bool =
  for i in countup(0, high(x)):
    if (x[i] and not y[i]) != int8(0):
      return false
  result = true
