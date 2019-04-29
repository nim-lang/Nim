#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# An ``include`` file for the different table implementations.

include hashcommon

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

proc rawGetDeep[X, A](t: X, key: A, hc: var Hash): int {.inline.} =
  rawGetDeepImpl()

proc rawInsert[X, A, B](t: var X, data: var KeyValuePairSeq[A, B],
                     key: A, val: B, hc: Hash, h: Hash) =
  rawInsertImpl()

template addImpl(enlarge) {.dirty.} =
  if t.dataLen == 0:
    initImpl(t, defaultInitialSize)
  if mustRehash(t.dataLen, t.counter): enlarge(t)
  var hc: Hash
  var j = rawGetDeep(t, key, hc)
  rawInsert(t, t.data, key, val, hc, j)
  inc(t.counter)

template maybeRehashPutImpl(enlarge) {.dirty.} =
  if t.dataLen == 0:
    initImpl(t, defaultInitialSize)
  if mustRehash(t.dataLen, t.counter):
    enlarge(t)
    index = rawGetKnownHC(t, key, hc)
  index = -1 - index                  # important to transform for mgetOrPutImpl
  rawInsert(t, t.data, key, val, hc, index)
  inc(t.counter)

template putImpl(enlarge) {.dirty.} =
  if t.dataLen == 0:
    initImpl(t, defaultInitialSize)
  var hc: Hash
  var index = rawGet(t, key, hc)
  if index >= 0: t.data[index].val = val
  else: maybeRehashPutImpl(enlarge)

template mgetOrPutImpl(enlarge) {.dirty.} =
  if t.dataLen == 0:
    initImpl(t, defaultInitialSize)
  var hc: Hash
  var index = rawGet(t, key, hc)
  if index < 0:
    # not present: insert (flipping index)
    maybeRehashPutImpl(enlarge)
  # either way return modifiable val
  result = t.data[index].val

template hasKeyOrPutImpl(enlarge) {.dirty.} =
  if t.dataLen == 0:
    initImpl(t, defaultInitialSize)
  var hc: Hash
  var index = rawGet(t, key, hc)
  if index < 0:
    result = false
    maybeRehashPutImpl(enlarge)
  else: result = true

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
  for i in 0 ..< t.dataLen:
    when compiles(t.data[i].hcode): # CountTable records don't contain a hcode
      t.data[i].hcode = 0
    t.data[i].key = default(type(t.data[i].key))
    t.data[i].val = default(type(t.data[i].val))
  t.counter = 0

template initImpl(result: typed, size: int) =
  assert isPowerOfTwo(size)
  result.counter = 0
  newSeq(result.data, size)

template insertImpl() = # for CountTable
  if t.dataLen == 0: initImpl(t, defaultInitialSize)
  if mustRehash(len(t.data), t.counter): enlarge(t)
  ctRawInsert(t, t.data, key, val)
  inc(t.counter)

template getOrDefaultImpl(t, key): untyped =
  mixin rawGet
  var hc: Hash
  var index = rawGet(t, key, hc)
  if index >= 0: result = t.data[index].val

template getOrDefaultImpl(t, key, default: untyped): untyped =
  mixin rawGet
  var hc: Hash
  var index = rawGet(t, key, hc)
  result = if index >= 0: t.data[index].val else: default

template dollarImpl(): untyped {.dirty.} =
  if t.len == 0:
    result = "{:}"
  else:
    result = "{"
    for key, val in pairs(t):
      if result.len > 1: result.add(", ")
      result.addQuoted(key)
      result.add(": ")
      result.addQuoted(val)
    result.add("}")

template equalsImpl(s, t: typed): typed =
  if s.counter == t.counter:
    # different insertion orders mean different 'data' seqs, so we have
    # to use the slow route here:
    for key, val in s:
      if not t.hasKey(key): return false
      if t.getOrDefault(key) != val: return false
    return true
