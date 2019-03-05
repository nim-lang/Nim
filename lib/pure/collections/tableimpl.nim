#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# An ``include`` file for the different table implementations.

# hcode for real keys cannot be zero.  hcode==0 signifies an empty slot.  These
# two procs retain clarity of that encoding without the space cost of an enum.
proc isEmpty(hcode: Hash): bool {.inline.} =
  result = hcode == 0

proc isFilled(hcode: Hash): bool {.inline.} =
  result = hcode != 0

const
  growthFactor = 2

proc mustRehash(length, counter: int): bool {.inline.} =
  assert(length > counter)
  result = (length * 2 < counter * 3) or (length - counter < 4)

proc nextTry(h, maxHash: Hash): Hash {.inline.} =
  result = (h + 1) and maxHash

template rawGetKnownHCImpl() {.dirty.} =
  var h: Hash = hc and maxHash(t)   # start with real hash value
  while isFilled(t.data[h].hcode):
    # Compare hc THEN key with boolean short circuit. This makes the common case
    # zero ==key's for missing (e.g.inserts) and exactly one ==key for present.
    # It does slow down succeeding lookups by one extra Hash cmp&and..usually
    # just a few clock cycles, generally worth it for any non-integer-like A.
    if t.data[h].hcode == hc and t.data[h].key == key:
      return h
    h = nextTry(h, maxHash(t))
  result = -1 - h                   # < 0 => MISSING; insert idx = -1 - result

template genHashImpl(key, hc: typed) =
  hc = hash(key)
  if hc == 0:       # This almost never taken branch should be very predictable.
    hc = 314159265  # Value doesn't matter; Any non-zero favorite is fine.

template genHash(key: typed): Hash =
  var res: Hash
  genHashImpl(key, res)
  res

template rawGetImpl() {.dirty.} =
  genHashImpl(key, hc)
  rawGetKnownHCImpl()

template rawGetDeepImpl() {.dirty.} =   # Search algo for unconditional add
  genHashImpl(key, hc)
  var h: Hash = hc and maxHash(t)
  while isFilled(t.data[h].hcode):
    h = nextTry(h, maxHash(t))
  result = h

template rawInsertImpl() {.dirty.} =
  data[h].key = key
  data[h].val = val
  data[h].hcode = hc

proc rawGetKnownHC[X, A](t: X, key: A, hc: Hash): int {.inline.} =
  rawGetKnownHCImpl()

proc rawGetDeep[X, A](t: X, key: A, hc: var Hash): int {.inline.} =
  rawGetDeepImpl()

proc rawGet[X, A](t: X, key: A, hc: var Hash): int {.inline.} =
  rawGetImpl()

proc rawInsert[X, A, B](t: var X, data: var KeyValuePairSeq[A, B],
                     key: A, val: B, hc: Hash, h: Hash) =
  rawInsertImpl()

template addImpl(enlarge) {.dirty.} =
  if mustRehash(t.dataLen, t.counter): enlarge(t)
  var hc: Hash
  var j = rawGetDeep(t, key, hc)
  rawInsert(t, t.data, key, val, hc, j)
  inc(t.counter)

template maybeRehashPutImpl(enlarge) {.dirty.} =
  if mustRehash(t.dataLen, t.counter):
    enlarge(t)
    index = rawGetKnownHC(t, key, hc)
  index = -1 - index                  # important to transform for mgetOrPutImpl
  rawInsert(t, t.data, key, val, hc, index)
  inc(t.counter)

template putImpl(enlarge) {.dirty.} =
  var hc: Hash
  var index = rawGet(t, key, hc)
  if index >= 0: t.data[index].val = val
  else: maybeRehashPutImpl(enlarge)

template mgetOrPutImpl(enlarge) {.dirty.} =
  var hc: Hash
  var index = rawGet(t, key, hc)
  if index < 0:
    # not present: insert (flipping index)
    maybeRehashPutImpl(enlarge)
  # either way return modifiable val
  result = t.data[index].val

template hasKeyOrPutImpl(enlarge) {.dirty.} =
  var hc: Hash
  var index = rawGet(t, key, hc)
  if index < 0:
    result = false
    maybeRehashPutImpl(enlarge)
  else: result = true

when not defined(nimHasDefault):
  template default[T](t: typedesc[T]): T =
    var v: T
    v

template delImplIdx(t, i) =
  let msk = maxHash(t)
  if i >= 0:
    dec(t.counter)
    block outer:
      while true:         # KnuthV3 Algo6.4R adapted for i=i+1 instead of i=i-1
        var j = i         # The correctness of this depends on (h+1) in nextTry,
        var r = j         # though may be adaptable to other simple sequences.
        t.data[i].hcode = 0              # mark current EMPTY
        t.data[i].key = default(type(t.data[i].key))
        t.data[i].val = default(type(t.data[i].val))
        while true:
          i = (i + 1) and msk            # increment mod table size
          if isEmpty(t.data[i].hcode):   # end of collision cluster; So all done
            break outer
          r = t.data[i].hcode and msk    # "home" location of key@i
          if not ((i >= r and r > j) or (r > j and j > i) or (j > i and i >= r)):
            break
        when defined(js):
          t.data[j] = t.data[i]
        else:
          shallowCopy(t.data[j], t.data[i]) # data[j] will be marked EMPTY next loop

template delImpl() {.dirty.} =
  var hc: Hash
  var i = rawGet(t, key, hc)
  delImplIdx(t, i)

template clearImpl() {.dirty.} =
  for i in 0 ..< t.data.len:
    when compiles(t.data[i].hcode): # CountTable records don't contain a hcode
      t.data[i].hcode = 0
    t.data[i].key = default(type(t.data[i].key))
    t.data[i].val = default(type(t.data[i].val))
  t.counter = 0
