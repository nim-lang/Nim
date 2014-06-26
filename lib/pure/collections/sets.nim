#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## The ``sets`` module implements an efficient hash set and ordered hash set.
##
## **Note**: The data types declared here have *value semantics*: This means
## that ``=`` performs a copy of the set.

import
  os, hashes, math

{.pragma: myShallow.}
when not defined(nimhygiene):
  {.pragma: dirty.}

type
  TSlotEnum = enum seEmpty, seFilled, seDeleted
  TKeyValuePair[A] = tuple[slot: TSlotEnum, key: A]
  TKeyValuePairSeq[A] = seq[TKeyValuePair[A]]
  TSet* {.final, myShallow.}[A] = object ## a generic hash set
    data: TKeyValuePairSeq[A]
    counter: int

proc len*[A](s: TSet[A]): int =
  ## returns the number of keys in `s`.
  result = s.counter

proc card*[A](s: TSet[A]): int =
  ## alias for `len`.
  result = s.counter

iterator items*[A](s: TSet[A]): A =
  ## iterates over any key in the table `t`.
  for h in 0..high(s.data):
    if s.data[h].slot == seFilled: yield s.data[h].key

const
  growthFactor = 2

proc mustRehash(length, counter: int): bool {.inline.} =
  assert(length > counter)
  result = (length * 2 < counter * 3) or (length - counter < 4)

proc nextTry(h, maxHash: THash): THash {.inline.} =
  result = ((5 * h) + 1) and maxHash

template rawGetImpl() {.dirty.} =
  var h: THash = hash(key) and high(s.data) # start with real hash value
  while s.data[h].slot != seEmpty:
    if s.data[h].key == key and s.data[h].slot == seFilled:
      return h
    h = nextTry(h, high(s.data))
  result = -1

template rawInsertImpl() {.dirty.} =
  var h: THash = hash(key) and high(data)
  while data[h].slot == seFilled:
    h = nextTry(h, high(data))
  data[h].key = key
  data[h].slot = seFilled

proc rawGet[A](s: TSet[A], key: A): int =
  rawGetImpl()

proc mget*[A](s: var TSet[A], key: A): var A =
  ## returns the element that is actually stored in 's' which has the same
  ## value as 'key' or raises the ``EInvalidKey`` exception. This is useful
  ## when one overloaded 'hash' and '==' but still needs reference semantics
  ## for sharing.
  var index = rawGet(s, key)
  if index >= 0: result = t.data[index].key
  else: raise newException(EInvalidKey, "key not found: " & $key)

proc contains*[A](s: TSet[A], key: A): bool =
  ## returns true iff `key` is in `s`.
  var index = rawGet(s, key)
  result = index >= 0

proc rawInsert[A](s: var TSet[A], data: var TKeyValuePairSeq[A], key: A) =
  rawInsertImpl()

proc enlarge[A](s: var TSet[A]) =
  var n: TKeyValuePairSeq[A]
  newSeq(n, len(s.data) * growthFactor)
  for i in countup(0, high(s.data)):
    if s.data[i].slot == seFilled: rawInsert(s, n, s.data[i].key)
  swap(s.data, n)

template inclImpl() {.dirty.} =
  var index = rawGet(s, key)
  if index < 0:
    if mustRehash(len(s.data), s.counter): enlarge(s)
    rawInsert(s, s.data, key)
    inc(s.counter)

template containsOrInclImpl() {.dirty.} =
  var index = rawGet(s, key)
  if index >= 0:
    result = true
  else:
    if mustRehash(len(s.data), s.counter): enlarge(s)
    rawInsert(s, s.data, key)
    inc(s.counter)

proc incl*[A](s: var TSet[A], key: A) =
  ## includes an element `key` in `s`.
  inclImpl()

proc incl*[A](s: var TSet[A], other: TSet[A]) =
  ## includes everything in `other` in `s`
  for item in other: incl(s, item)

proc excl*[A](s: var TSet[A], key: A) =
  ## excludes `key` from the set `s`.
  var index = rawGet(s, key)
  if index >= 0:
    s.data[index].slot = seDeleted
    dec(s.counter)

proc excl*[A](s: var TSet[A], other: TSet[A]) =
  ## excludes everything in `other` from `s`.
  for item in other: excl(s, item)

proc containsOrIncl*[A](s: var TSet[A], key: A): bool =
  ## returns true if `s` contains `key`, otherwise `key` is included in `s`
  ## and false is returned.
  containsOrInclImpl()

proc initSet*[A](initialSize=64): TSet[A] =
  ## creates a new hash set that is empty. `initialSize` needs to be
  ## a power of two.
  assert isPowerOfTwo(initialSize)
  result.counter = 0
  newSeq(result.data, initialSize)

proc toSet*[A](keys: openArray[A]): TSet[A] =
  ## creates a new hash set that contains the given `keys`.
  result = initSet[A](nextPowerOfTwo(keys.len+10))
  for key in items(keys): result.incl(key)

template dollarImpl(): stmt {.dirty.} =
  result = "{"
  for key in items(s):
    if result.len > 1: result.add(", ")
    result.add($key)
  result.add("}")

proc `$`*[A](s: TSet[A]): string =
  ## The `$` operator for hash sets.
  dollarImpl()

proc union*[A](s1, s2: TSet[A]): TSet[A] =
  ## returns a new set of all items that are contained in at
  ## least one of `s1` and `s2`
  result = s1
  incl(result, s2)

proc intersection*[A](s1, s2: TSet[A]): TSet[A] =
  ## returns a new set of all items that are contained in both `s1` and `s2`
  result = initSet[A](min(s1.data.len, s2.data.len))
  for item in s1:
    if item in s2: incl(result, item)

proc symmetricDifference*[A](s1, s2: TSet[A]): TSet[A] =
  ## returns a new set of all items that are contained in either
  ## `s1` or `s2`, but not both
  result = s1
  for item in s2:
    if containsOrIncl(result, item): excl(result, item)

proc `+`*[A](s1, s2: TSet[A]): TSet[A] {.inline.} =
  ## alias for `union`
  result = union(s1, s2)

proc `*`*[A](s1, s2: TSet[A]): TSet[A] {.inline.} =
  ## alias for `intersection`
  result = intersection(s1, s2)

proc `-+-`*[A](s1, s2: TSet[A]): TSet[A] {.inline.} =
  ## alias for `symmetricDifference`
  result = symmetricDifference(s1, s2)

proc disjoint*[A](s1, s2: TSet[A]): bool =
  ## returns true iff `s1` and `s2` have no items in common
  for item in s1:
    if item in s2: return false
  return true

# ------------------------------ ordered set ------------------------------

type
  TOrderedKeyValuePair[A] = tuple[
    slot: TSlotEnum, next: int, key: A]
  TOrderedKeyValuePairSeq[A] = seq[TOrderedKeyValuePair[A]]
  TOrderedSet* {.
      final, myShallow.}[A] = object ## set that remembers insertion order
    data: TOrderedKeyValuePairSeq[A]
    counter, first, last: int

proc len*[A](s: TOrderedSet[A]): int {.inline.} =
  ## returns the number of keys in `s`.
  result = s.counter

proc card*[A](s: TOrderedSet[A]): int {.inline.} =
  ## alias for `len`.
  result = s.counter

template forAllOrderedPairs(yieldStmt: stmt) {.dirty, immediate.} =
  var h = s.first
  while h >= 0:
    var nxt = s.data[h].next
    if s.data[h].slot == seFilled: yieldStmt
    h = nxt

iterator items*[A](s: TOrderedSet[A]): A =
  ## iterates over any key in the set `s` in insertion order.
  forAllOrderedPairs:
    yield s.data[h].key

proc rawGet[A](s: TOrderedSet[A], key: A): int =
  rawGetImpl()

proc contains*[A](s: TOrderedSet[A], key: A): bool =
  ## returns true iff `key` is in `s`.
  var index = rawGet(s, key)
  result = index >= 0

proc rawInsert[A](s: var TOrderedSet[A], 
                  data: var TOrderedKeyValuePairSeq[A], key: A) =
  rawInsertImpl()
  data[h].next = -1
  if s.first < 0: s.first = h
  if s.last >= 0: data[s.last].next = h
  s.last = h

proc enlarge[A](s: var TOrderedSet[A]) =
  var n: TOrderedKeyValuePairSeq[A]
  newSeq(n, len(s.data) * growthFactor)
  var h = s.first
  s.first = -1
  s.last = -1
  while h >= 0:
    var nxt = s.data[h].next
    if s.data[h].slot == seFilled: 
      rawInsert(s, n, s.data[h].key)
    h = nxt
  swap(s.data, n)

proc incl*[A](s: var TOrderedSet[A], key: A) =
  ## includes an element `key` in `s`.
  inclImpl()

proc incl*[A](s: var TSet[A], other: TOrderedSet[A]) =
  ## includes everything in `other` in `s`
  for item in other: incl(s, item)

proc containsOrIncl*[A](s: var TOrderedSet[A], key: A): bool =
  ## returns true if `s` contains `key`, otherwise `key` is included in `s`
  ## and false is returned.
  containsOrInclImpl()

proc initOrderedSet*[A](initialSize=64): TOrderedSet[A] =
  ## creates a new ordered hash set that is empty. `initialSize` needs to be
  ## a power of two.
  assert isPowerOfTwo(initialSize)
  result.counter = 0
  result.first = -1
  result.last = -1
  newSeq(result.data, initialSize)

proc toOrderedSet*[A](keys: openArray[A]): TOrderedSet[A] =
  ## creates a new ordered hash set that contains the given `keys`.
  result = initOrderedSet[A](nextPowerOfTwo(keys.len+10))
  for key in items(keys): result.incl(key)

proc `$`*[A](s: TOrderedSet[A]): string =
  ## The `$` operator for ordered hash sets.
  dollarImpl()

proc `<`*[A](s, t: TSet[A]): bool =
  ## Is s a strict subset of t?
  s.counter != t.counter and s <= t

proc `<=`*[A](s, t: TSet[A]): bool =
  ## Is s a subset of t?
  result = false
  if s.counter > t.counter: return
  result = true
  for item in s:
    if not(t.contains(item)):
      result = false
      return
      
proc `==`*[A](s, t: TSet[A]): bool =
  s.counter == t.counter and s <= t

proc map*[A, B](data: TSet[A], op: proc (x: A): B {.closure.}): TSet[B] =
  result = initSet[B]()
  for item in data: result.incl(op(item))
