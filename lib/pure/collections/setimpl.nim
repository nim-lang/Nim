#
#
#            Nim's Runtime Library
#        (c) Copyright 2019 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# An ``include`` file for the different hash set implementations.


const
  growthFactor = 2

when not defined(nimHasDefault):
  template default[T](t: typedesc[T]): T =
    ## Used by clear methods to get a default value.
    var v: T
    v

template initImpl(s: typed, size: int) =
  assert isPowerOfTwo(size)
  when s is OrderedSet:
    s.first = -1
    s.last = -1
  s.counter = 0
  newSeq(s.data, size)

# hcode for real keys cannot be zero.  hcode==0 signifies an empty slot.  These
# two procs retain clarity of that encoding without the space cost of an enum.
proc isEmpty(hcode: Hash): bool {.inline.} =
  result = hcode == 0

proc isFilled(hcode: Hash): bool {.inline.} =
  result = hcode != 0

proc nextTry(h, maxHash: Hash): Hash {.inline.} =
  result = (h + 1) and maxHash

template rawGetKnownHCImpl() {.dirty.} =
  if s.data.len == 0:
    return -1
  var h: Hash = hc and high(s.data)  # start with real hash value
  while isFilled(s.data[h].hcode):
    # Compare hc THEN key with boolean short circuit. This makes the common case
    # zero ==key's for missing (e.g.inserts) and exactly one ==key for present.
    # It does slow down succeeding lookups by one extra Hash cmp&and..usually
    # just a few clock cycles, generally worth it for any non-integer-like A.
    if s.data[h].hcode == hc and s.data[h].key == key:  # compare hc THEN key
      return h
    h = nextTry(h, high(s.data))
  result = -1 - h                   # < 0 => MISSING; insert idx = -1 - result

template genHash(key: typed): Hash =
  var hc = hash(key)
  if hc == 0:       # This almost never taken branch should be very predictable.
    hc = 314159265  # Value doesn't matter; Any non-zero favorite is fine.
  hc

template rawGetImpl() {.dirty.} =
  hc = genHash(key)
  rawGetKnownHCImpl()

template rawInsertImpl() {.dirty.} =
  if data.len == 0:
    initImpl(s, defaultInitialSize)
  data[h].key = key
  data[h].hcode = hc

proc rawGetKnownHC[A](s: HashSet[A], key: A, hc: Hash): int {.inline.} =
  rawGetKnownHCImpl()

proc rawGet[A](s: HashSet[A], key: A, hc: var Hash): int {.inline.} =
  rawGetImpl()

proc rawInsert[A](s: var HashSet[A], data: var KeyValuePairSeq[A], key: A,
                  hc: Hash, h: Hash) =
  rawInsertImpl()

proc enlarge[A](s: var HashSet[A]) =
  var n: KeyValuePairSeq[A]
  newSeq(n, len(s.data) * growthFactor)
  swap(s.data, n)                   # n is now old seq
  for i in countup(0, high(n)):
    if isFilled(n[i].hcode):
      var j = -1 - rawGetKnownHC(s, n[i].key, n[i].hcode)
      rawInsert(s, s.data, n[i].key, n[i].hcode, j)

template inclImpl() {.dirty.} =
  if s.data.len == 0:
    initImpl(s, defaultInitialSize)
  var hc: Hash
  var index = rawGet(s, key, hc)
  if index < 0:
    if mustRehash(len(s.data), s.counter):
      enlarge(s)
      index = rawGetKnownHC(s, key, hc)
    rawInsert(s, s.data, key, hc, -1 - index)
    inc(s.counter)

template containsOrInclImpl() {.dirty.} =
  var hc: Hash
  var index = rawGet(s, key, hc)
  if index >= 0:
    result = true
  else:
    if mustRehash(len(s.data), s.counter):
      enlarge(s)
      index = rawGetKnownHC(s, key, hc)
    rawInsert(s, s.data, key, hc, -1 - index)
    inc(s.counter)

template doWhile(a, b) =
  while true:
    b
    if not a: break

proc exclImpl[A](s: var HashSet[A], key: A) : bool {. inline .} =
  var hc: Hash
  var i = rawGet(s, key, hc)
  var msk = high(s.data)
  result = true

  if i >= 0:
    result = false
    dec(s.counter)
    while true:         # KnuthV3 Algo6.4R adapted for i=i+1 instead of i=i-1
      var j = i         # The correctness of this depends on (h+1) in nextTry,
      var r = j         # though may be adaptable to other simple sequences.
      s.data[i].hcode = 0              # mark current EMPTY
      s.data[i].key = default(type(s.data[i].key))
      doWhile((i >= r and r > j) or (r > j and j > i) or (j > i and i >= r)):
        i = (i + 1) and msk            # increment mod table size
        if isEmpty(s.data[i].hcode):   # end of collision cluster; So all done
          return
        r = s.data[i].hcode and msk    # "home" location of key@i
      shallowCopy(s.data[j], s.data[i]) # data[i] will be marked EMPTY next loop

proc mustRehash(length, counter: int): bool {.inline.} =
  assert(length > counter)
  result = (length * 2 < counter * 3) or (length - counter < 4)

template dollarImpl() {.dirty.} =
  result = "{"
  for key in items(s):
    if result.len > 1: result.add(", ")
    result.addQuoted(key)
  result.add("}")



# --------------------------- OrderedSet ------------------------------

proc rawGetKnownHC[A](s: OrderedSet[A], key: A, hc: Hash): int {.inline.} =
  rawGetKnownHCImpl()

proc rawGet[A](s: OrderedSet[A], key: A, hc: var Hash): int {.inline.} =
  rawGetImpl()

proc rawInsert[A](s: var OrderedSet[A], data: var OrderedKeyValuePairSeq[A],
                  key: A, hc: Hash, h: Hash) =
  rawInsertImpl()
  data[h].next = -1
  if s.first < 0: s.first = h
  if s.last >= 0: data[s.last].next = h
  s.last = h

proc enlarge[A](s: var OrderedSet[A]) =
  var n: OrderedKeyValuePairSeq[A]
  newSeq(n, len(s.data) * growthFactor)
  var h = s.first
  s.first = -1
  s.last = -1
  swap(s.data, n)
  while h >= 0:
    var nxt = n[h].next
    if isFilled(n[h].hcode):
      var j = -1 - rawGetKnownHC(s, n[h].key, n[h].hcode)
      rawInsert(s, s.data, n[h].key, n[h].hcode, j)
    h = nxt


proc exclImpl[A](s: var OrderedSet[A], key: A) : bool {. inline .} =
  var n: OrderedKeyValuePairSeq[A]
  newSeq(n, len(s.data))
  var h = s.first
  s.first = -1
  s.last = -1
  swap(s.data, n)
  let hc = genHash(key)
  result = true
  while h >= 0:
    var nxt = n[h].next
    if isFilled(n[h].hcode):
      if n[h].hcode == hc and n[h].key == key:
        dec s.counter
        result = false
      else:
        var j = -1 - rawGetKnownHC(s, n[h].key, n[h].hcode)
        rawInsert(s, s.data, n[h].key, n[h].hcode, j)
    h = nxt
