discard """
  targets: "c"
  # Only the old-runtime (`--mm:refc`) legs: the seqs-v2 runtime used by
  # `--gc:orc` handles finalizers during growth differently, so the exact
  # element counts asserted here are refc-specific. The realtime-GC leg is
  # skipped because its concurrent finalizers could make the counts
  # nondeterministic.
  matrix: "--mm:refc; -d:release --mm:refc"
"""

# Regression test for https://github.com/nim-lang/Nim/issues/26782
#
# Under `--mm:refc`, growing a seq or string can run a GC cycle whose
# finalizers mutate the *same* object. The growth operation used to keep
# using the payload pointer captured before the allocation, so whatever the
# finalizers appended (and the elements already present) was silently
# overwritten. The growth allocations are now performed with the GC locked
# (`withGCDisabled`), so no finalizer can run in the middle of the payload
# swap; deferred finalizers run at the next collection instead and their
# appends are preserved.
#
# Each scenario uses its own `ref object` type: `new(o, fin)` assigns the
# finalizer on the *type's* typeinfo, so different finalizers require
# different types.

type
  ObjS = ref object
  ObjT = ref object
  ObjStr = ref object

var s: seq[int]
var t: seq[int]
var str: string
var str2: string

proc collectLater() =
  ## Runs whatever finalizers are still queued. What matters is that nothing
  ## they appended is ever *lost*.
  GC_fullCollect()

proc finS(o: ObjS) = s.add 100
proc finT(o: ObjT) = t.add 200
proc finStr(o: ObjStr) =
  str.add 'y'
  str2.add "zz"

proc makeGarbageS() =
  for i in 0 ..< 1000:
    var o: ObjS
    new(o, finS)

proc makeGarbageT() =
  for i in 0 ..< 1000:
    var o: ObjT
    new(o, finT)

proc makeGarbageStr() =
  for i in 0 ..< 1000:
    var o: ObjStr
    new(o, finStr)

proc scenarioSeqAdd() =
  # seq.add growth (incrSeqV3)
  s = newSeqOfCap[int](4)
  for i in 1 .. 4: s.add i

  when defined(gcrefc):
    GC_disable()
    makeGarbageS()
    GC_enable()
  elif defined(gcorc):
    GC_disableOrc()
    makeGarbageS()
    GC_enableOrc()
  else:
    makeGarbageS()

  s.add 5
  collectLater()

  # All 4 original elements, all 1000 finalizer additions and the outer
  # appended element must survive: 4 + 1000 + 1 == 1005.
  doAssert s.len == 1005, "seq.add: expected 1005 elements, got " & $s.len
  doAssert s[0] == 1 and s[1] == 2 and s[2] == 3 and s[3] == 4
  doAssert 5 in s
  var hundreds = 0
  for x in s:
    if x == 100:
      inc hundreds
  doAssert hundreds == 1000, "seq.add: expected 1000 finalizer additions, got " & $hundreds

proc scenarioSetLen() =
  # seq.setLen growth (setLengthSeqV2/Uninit -> extendCapacityRaw)
  t = newSeqOfCap[int](4)
  for i in 1 .. 4: t.add i

  when defined(gcrefc):
    GC_disable()
    makeGarbageT()
    GC_enable()
  elif defined(gcorc):
    GC_disableOrc()
    makeGarbageT()
    GC_enableOrc()
  else:
    makeGarbageT()

  setLen(t, 10)
  collectLater()

  # setLen zero-fills slots 4..9; the 1000 finalizer appends land after.
  doAssert t.len == 1010, "setLen: expected 1010 elements, got " & $t.len
  doAssert t[0] == 1 and t[1] == 2 and t[2] == 3 and t[3] == 4
  var twoHundreds = 0
  for x in t:
    if x == 200:
      inc twoHundreds
  doAssert twoHundreds == 1000, "setLen: expected 1000 finalizer additions, got " & $twoHundreds

proc scenarioStrings() =
  # string add growth (addChar) and append (resizeString via add/&=).
  # Fill each string to its capacity so the next append must reallocate.
  str = newStringOfCap(8)
  for c in "abcdefgh": str.add c
  str2 = newStringOfCap(8)
  for c in "ijklmnop": str2.add c

  when defined(gcrefc):
    GC_disable()
    makeGarbageStr()
    GC_enable()
  elif defined(gcorc):
    GC_disableOrc()
    makeGarbageStr()
    GC_enableOrc()
  else:
    makeGarbageStr()

  str.add 'x'
  str2 &= "yy"
  collectLater()

  # str: "abcdefgh" + 'x' + 1000 x 'y' == 1009;
  # str2: "ijklmnop" + "yy" + 1000 x "zz" == 2010.
  doAssert str.len == 1009, "str.add: expected 1009 chars, got " & $str.len
  doAssert str[0 ..< 8] == "abcdefgh"
  doAssert str[8] == 'x'
  var ys = 0
  for c in str:
    if c == 'y':
      inc ys
  doAssert ys == 1000, "str.add: expected 1000 finalizer additions, got " & $ys

  doAssert str2.len == 2010, "str add: expected 2010 chars, got " & $str2.len
  doAssert str2[0 ..< 8] == "ijklmnop"
  var zs = 0
  for c in str2:
    if c == 'z':
      inc zs
  doAssert zs == 2000, "str add: expected 2000 finalizer chars, got " & $zs

scenarioSeqAdd()
scenarioSetLen()
scenarioStrings()
