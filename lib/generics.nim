#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2008 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains basic abstract data types.

type
  TListItem[T] = object
    next, prev: ref TListItem[T]
    data: T

  TList*[T] = ref TListItem[T]
#  TIndex*[T] = object

#proc succ*[T](i: TIndex[T]): TIndex[T] =
#  result = i.next

#proc pred*[T](i: TIndex[T]): TIndex[T] =
#  result = i.prev

#proc getIndex*[T](c: TList[T]): TIndex[TList[T]] =
#  return c

proc init*[T](c: var TList[T]) {.inline.} =
  c = nil

iterator items*[T](c: TList[T]): var T {.inline.} =
  var it = c
  while it != nil:
    yield it.data
    it = it.next

proc add*[T](c: var TList[T], item: T) {.inline.} =
  var it: ref TListItem[T]
  new(it)
  it.data = item
  it.prev = c.prev
  it.next = c.next
  c = it

proc incl*[T](c: var TList[T], item: T) =
  for i in items(c):
    if i == item: return
  add(c, item)

proc excl*[T](c: var TList[T], item: T) =
  var it: TList[T] = c
  while it != nil:
    if it.data == item:
      # remove from list
    it = it.next

proc del*[T](c: var TList[T], item: T) {.inline.} = excl(c, item)

proc hash*(p: pointer): int {.inline.} =
  # Returns the hash value of a pointer. This is very fast.
  return cast[TAddress](p) shr 3

proc hash*(x: int): int {.inline.} = return x
proc hash*(x: char): int {.inline.} = return ord(x)
proc hash*(x: bool): int {.inline.} = return ord(x)

proc hash*(s: string): int =
  # The generic hash table implementation work on a type `T` that has a hash
  # proc. Predefined for string, pointers, int, char, bool.
  var h = 0
  for i in 0..s.len-1:
    h = h +% Ord(s[i])
    h = h +% h shl 10
    h = h xor (h shr 6)
  h = h +% h shl 3
  h = h xor (h shr 11)
  h = h +% h shl 15
  result = h

proc isNil*(x: int): bool {.inline.} = return x == low(int)
proc nilValue*(x: int): int {.inline.} = return low(int)
proc nilValue*(x: pointer): pointer {.inline.} = return nil
proc nilValue*(x: string): string {.inline.} = return nil
proc nilValue*[T](x: seq[T]): seq[T] {.inline.} = return nil
proc nilValue*(x: float): float {.inline.} = return NaN

proc mustRehash(len, counter: int): bool =
  assert(len > counter)
  result = (len * 2 < counter * 3) or (len-counter < 4)

proc nextTry(h, maxHash: int): int {.inline.} =
  return ((5*%h) +% 1) and maxHash

type
  TPair*[TKey, TValue] = tuple[key: TKey, val: TValue]
  TTable*[TKey, TValue] =
      object of TObject ## A table which stores (key, value)
                        ## pairs. The used algorithm is hashing.
    d: seq[TPair[TKey, TValue]]
    counter: natural

const
  growthFactor = 2 # must be power of two

proc init*[TKey, TValue](t: var TTable[TKey, TValue], capacity: natural = 32) =
  t.d = [] # XXX
  setLen(t.d, capacity)

proc len*[TKey, TValue](t: TTable[TKey, TValue]): natural = return t.counter

iterator pairs*[TKey,TValue](t: TTable[TKey,TValue]): TPair[TKey, TValue] =
  for i in 0..t.d.len-1:
    if not isNil(t.d[i].key):
      yield (t.d[i].key, t.d[i].val)

proc TableRawGet[TKey, TValue](t: TTable[TKey, TValue], key: TKey): int =
  var h = hash(key) and high(t.d)
  while not isNil(t.d[h].key):
    if t.d[h].key == key: return h
    h = nextTry(h, high(t.d))
  return -1

proc `[]`*[TKey, TValue](t: TTable[TKey, TValue], key: TKey): TValue =
  var index = TableRawGet(t, key)
  return if index >= 0: t.d[index].val else: nilValue(t.d[0].val)

proc TableRawInsert[TKey, TValue](data: var seq[TPair[TKey, TValue]],
                                  key: TKey, val: TValue) =
  var h = hash(key) and high(data)
  while not isNil(data[h].key):
    assert(data[h].key != key)
    h = nextTry(h, high(data))
  assert(isNil(data[h].key))
  data[h].key = key
  data[h].val = val

proc TableEnlarge[TKey, TValue](t: var TTable[TKey, TValue]) =
  var n: seq[TPair[TKey,TValue]] = []
  setLen(n, len(t.d) * growthFactor) # XXX
  for i in 0..high(t.d):
    if not isNil(t.d[i].key):
      TableRawInsert(n, t.d[i].key, t.d[i].val)
  swap(t.d, n)

proc `[]=`*[TKey, TValue](t: var TTable[TKey, TValue], key: TKey, val: TValue) =
  var index = TableRawGet(t, key)
  if index >= 0:
    t.d[index].val = val
  else:
    if mustRehash(len(t.d), t.counter): TableEnlarge(t)
    TableRawInsert(t.d, key, val)
    inc(t.counter)

proc add*[TKey, TValue](t: var TTable[TKey, TValue], key: TKey, val: TValue) =
  if mustRehash(len(t.d), t.counter): TableEnlarge(t)
  TableRawInsert(t.d, key, val)
  inc(t.counter)

proc test =
  var
    t: TTable[string, int]
  init(t)
  t["key1"] = 1
  t["key2"] = 2
  t["key3"] = 3
  for key, val in pairs(t):
    echo(key & " = " & $val)

test()
