#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## The ``hashtabs`` module implements an efficient generic hash
## table/dictionary data type. 

import
  hashes

const
  growthFactor = 2
  startSize = 8
  sham = sizeof(THash)*8-2 # shift amount
  mask = 0b11 shl sham
  usedSlot = 0b10 shl sham
  delSlot =  0b01 shl sham
  emptySlot = 0

type
  TTable*[TKey, TValue] = object
    counter: int
    data: seq[tuple[key: TKey, val: TValue, h: THash]]

proc init*(t: var TTable, size = startSize) =
  t.counter = 0
  newSeq(t.data, size)

proc markUsed(h: THash): THash {.inline.} =
  return h and not mask or usedSlot

proc len*(t: TTable): int {.inline.} =
  ## returns the number of keys in `t`.
  result = t.counter

proc mustRehash(length, counter: int): bool =
  assert(length > counter)
  result = (length * 2 < counter * 3) or (length - counter < 4)

proc nextTry(h, maxHash: THash): THash {.inline.} =
  result = ((5 * h) + 1) and maxHash

template eq(a, b: expr): expr = a == b

proc rawGet(t: TTable, key: TKey, fullhash: THash): int =
  var h = fullhash and high(t.data)
  while (t.data[h].h and mask) != 0:
    # If it is a deleted entry, the comparison with ``markUsed(fullhash)``
    # fails, so there is no need to check for this explicitely.
    if t.data[h].h == markUsed(fullhash) and eq(t.data[h].key, key): return h
    h = nextTry(h, high(t.data))
  result = - 1

proc `[]`*(t: TTable, key: TKey): TValue =
  ## retrieves the value at ``t[key]``. If `key` is not in `t`,
  ## `EInvalidValue` is raised.
  var index = rawGet(t, key, hash(key))
  if index >= 0: result = t.data[index].val
  else:
    var e: ref EInvalidValue
    new(e)
    e.msg = "invalid key: " & $key
    raise e

proc hasKey*(t: TTable, key: TKey): bool =
  ## returns true iff `key` is in the table `t`.
  result = rawGet(t, key) >= 0

proc rawInsert[TKey, TValue](
               data: var seq[tuple[key: TKey, val: TValue, h: THash]],
               tup: tuple[key: TKey, val: TValue, h: THash]) =
  var h = tup.h and high(data)
  while (data[h].h and mask) == usedSlot: h = nextTry(h, high(data))
  data[h] = tup

proc enlarge(t: var TTable) =
  var n: seq[tuple[key: TKey, val: TValue, h: THash]]
  newSeq(n, len(t.data) * growthFactor)
  for i in 0..high(t.data):
    if (t.data[i].h and mask) == usedSlot: rawInsert(n, t.data[i])
  swap(t.data, n)

proc `[]=`*(t: var TTable, key: TKey, val: TValue) =
  ## puts a (key, value)-pair into `t`.
  var fullhash = hash(key)
  var index = rawGet(t, key, fullhash)
  if index >= 0:
    t.data[index].val = val
  else:
    if mustRehash(len(t.data), t.counter): enlarge(t)
    rawInsert(t.data, (key, val, markUsed(fullhash)))
    inc(t.counter)

proc add*(t: var TTable, key: TKey, val: TValue) =
  ## puts a (key, value)-pair into `t`, but does not check if key already
  ## exists.
  if mustRehash(len(t.data), t.counter): enlarge(t)
  rawInsert(t.data, (key, val, markUsed(hash(key))))
  inc(t.counter)

proc del*(t: var TTable, key: TKey) =
  ## deletes a (key, val)-pair in `t`.
  var index = rawGet(t, key)
  if index >= 0:
    t.data[index].h = delSlot

proc delAll*(t: var TTable, key: TKey) =
  ## deletes all (key, val)-pairs in `t`.
  while true:
    var index = rawGet(t, key)
    if index < 0: break
    t.data[index].h = delSlot

iterator pairs*(t: TTable): tuple[key: TKey, value: TValue] =
  ## iterates over any (key, value) pair in the table `t`.
  for h in 0..high(t.data):
    if (t.data[h].h and mask) == usedSlot:
      yield (t.data[h].key, t.data[h].val)

iterator keys*(t: TTable): TKey =
  ## iterate over any key in the table `t`. If key occurs multiple times, it
  ## is yielded multiple times.
  for h in 0..high(t.data):
    if (t.data[h].h and mask) == usedSlot:
      yield t.data[h].key

iterator values*(t: TTable): TValue =
  ## iterate over any value in the table `t`. 
  for h in 0..high(t.data):
    if (t.data[h].h and mask) == usedSlot:
      yield t.data[h].val

iterator values*(t: TTable, key: TKey): TValue =
  ## iterate over any value associated with `key` in `t`.
  var fullhash = hash(key)
  var h = fullhash and high(t.data)
  while (t.data[h].h and mask) != 0:
    # If it is a deleted entry, the comparison with ``markUsed(fullhash)``
    # fails, so there is no need to check for this explicitely.
    if t.data[h].h == markUsed(fullhash) and eq(t.data[h].key, key): 
      yield t.data[h].val
    h = nextTry(h, high(t.data))

proc `$`*[KeyToStr=`$`, ValueToStr=`$`](t: TTable): string =
  ## turns the table into its string representation. `$` must be available
  ## for TKey and TValue for this to work.
  if t.len == 0:
    result = "{:}"
  else:
    result = "{"
    var i = 0
    for k, v in pairs(t):
      if i > 0: add(result, ", ")
      add(result, KeyToStr(k))
      add(result, ": ")
      add(result, ValueToStr(v))
      inc(i)
    add(result, "}")
