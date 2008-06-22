#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2006 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# set handling

type
  TMyByte = int8
  TNimSet = array [0..4*2048-1, TMyByte]

# implementation:

proc countBits(n: int32): int {.exportc: "countBits".}
# We use a prototype here, not in "cntbits.nim", because that is included
# in math.nim too. So when linking with math.nim it'd give a duplicated
# symbol error which we avoid by renaming here.

include cntbits

proc unionSets(res: var TNimSet, a, b: TNimSet, len: int) {.
    compilerproc, inline.} =
  for i in countup(0, len-1): res[i] = toU8(ze(a[i]) or ze(b[i]))

proc diffSets(res: var TNimSet, a, b: TNimSet, len: int) {.
    compilerproc, inline.} =
  for i in countup(0, len-1): res[i] = toU8(ze(a[i]) and not ze(b[i]))

proc intersectSets(res: var TNimSet, a, b: TNimSet, len: int) {.
    compilerproc, inline.} =
  for i in countup(0, len-1): res[i] = toU8(ze(a[i]) and ze(b[i]))

proc symdiffSets(res: var TNimSet, a, b: TNimSet, len: int) {.
    compilerproc, inline.} =
  for i in countup(0, len-1): res[i] = toU8(ze(a[i]) xor ze(b[i]))

proc containsSets(a, b: TNimSet, len: int): bool {.compilerproc, inline.} =
  # s1 <= s2 ?
  for i in countup(0, len-1):
    if (ze(a[i]) and not ze(b[i])) != 0: return false
  return true

proc containsSubsets(a, b: TNimSet, len: int): bool {.compilerproc, inline.} =
  # s1 < s2 ?
  result = false # assume they are equal
  for i in countup(0, len-1):
    if (ze(a[i]) and not ze(b[i])) != 0: return false
    if ze(a[i]) != ze(b[i]): result = true # they are not equal

proc equalSets(a, b: TNimSet, len: int): bool {.compilerproc, inline.} =
  for i in countup(0, len-1):
    if ze(a[i]) != ze(b[i]): return false
  return true

proc cardSet(s: TNimSet, len: int): int {.compilerproc, inline.} =
  result = 0
  for i in countup(0, len-1):
    inc(result, countBits(ze(s[i])))

const
  WORD_SIZE = sizeof(TMyByte)*8

proc inSet(s: TNimSet, elem: int): bool {.compilerproc, inline.} =
  return (s[elem /% WORD_SIZE] and (1 shl (elem %% WORD_SIZE))) != 0

proc inclSets(s: var TNimSet, e: int) {.compilerproc, inline.} =
  s[e /% WORD_SIZE] = toU8(s[e /% WORD_SIZE] or (1 shl (e %% WORD_SIZE)))

proc inclRange(s: var TNimSet, first, last: int) {.compilerproc.} =
  # not very fast, but it is seldom used
  for i in countup(first, last): inclSets(s, i)

proc smallInclRange(s: var int, first, last: int) {.compilerproc.} =
  # not very fast, but it is seldom used
  for i in countup(first, last):
    s = s or (1 shl (i %% sizeof(int)*8))

proc exclSets(s: var TNimSet, e: int) {.compilerproc, inline.} =
  s[e /% WORD_SIZE] = toU8(s[e /% WORD_SIZE] and
    not (1 shl (e %% WORD_SIZE)))

proc smallContainsSubsets(a, b: int): bool {.compilerProc, inline.} =
  # not used by new code generator
  return ((a and not b) != 0) and (a != b)
