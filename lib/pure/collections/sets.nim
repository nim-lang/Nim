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
  TSet* {.final, myShallow.}[A] = object ## \
    ## A generic hash set.
    ##
    ## Use `init() <#init,TSet[A]>`_ or `initSet[type]() <#initSet>`_ before
    ## calling other procs on it.
    data: TKeyValuePairSeq[A]
    counter: int

proc isValid*[A](s: TSet[A]): bool =
  ## Returns `true` if the set has been initialized with `initSet <#initSet>`_.
  ##
  ## Most operations over an uninitialized set will crash at runtime and
  ## `assert <system.html#assert>`_ in debug builds. You can use this proc in
  ## your own methods to verify that sets passed to your procs are correctly
  ## initialized. Example:
  ##
  ## .. code-block :: nimrod
  ##   proc savePreferences(options: TSet[string]) =
  ##     assert options.isValid, "Pass an initialized set!"
  ##     # Do stuff here, may crash in release builds!
  result = not s.data.isNil

proc len*[A](s: TSet[A]): int =
  ## returns the number of keys in `s`.
  result = s.counter

proc card*[A](s: TSet[A]): int =
  ## alias for `len`.
  result = s.counter

iterator items*[A](s: TSet[A]): A =
  ## iterates over any key in the table `t`.
  assert s.isValid, "The set needs to be initialized."
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
  assert s.isValid, "The set needs to be initialized."
  var index = rawGet(s, key)
  if index >= 0: result = t.data[index].key
  else: raise newException(EInvalidKey, "key not found: " & $key)

proc contains*[A](s: TSet[A], key: A): bool =
  ## returns true iff `key` is in `s`.
  assert s.isValid, "The set needs to be initialized."
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
  assert s.isValid, "The set needs to be initialized."
  inclImpl()

proc incl*[A](s: var TSet[A], other: TSet[A]) =
  ## includes everything in `other` in `s`
  assert s.isValid, "The set `s` needs to be initialized."
  assert other.isValid, "The set `other` needs to be initialized."
  for item in other: incl(s, item)

proc excl*[A](s: var TSet[A], key: A) =
  ## excludes `key` from the set `s`.
  assert s.isValid, "The set needs to be initialized."
  var index = rawGet(s, key)
  if index >= 0:
    s.data[index].slot = seDeleted
    dec(s.counter)

proc excl*[A](s: var TSet[A], other: TSet[A]) =
  ## excludes everything in `other` from `s`.
  assert s.isValid, "The set `s` needs to be initialized."
  assert other.isValid, "The set `other` needs to be initialized."
  for item in other: excl(s, item)

proc containsOrIncl*[A](s: var TSet[A], key: A): bool =
  ## returns true if `s` contains `key`, otherwise `key` is included in `s`
  ## and false is returned.
  assert s.isValid, "The set needs to be initialized."
  containsOrInclImpl()

proc init*[A](s: var TSet[A], initialSize=64) =
  ## Initializes a hash set.
  ##
  ## The `initialSize` parameter needs to be a power of too. You can use
  ## `math.nextPowerOfTwo() <math.html#nextPowerOfTwo>`_ to guarantee that at
  ## runtime. All set variables have to be initialized before you can use them
  ## with other procs from this module with the exception of `isValid()
  ## <#isValid,TSet[A]>`_ and `len() <#len,TSet[A]>`_.
  ##
  ## You can call this method on a previously initialized hash set, which will
  ## discard all its values. This might be more convenient than iterating over
  ## existing values and calling `excl() <#excl,TSet[A],A>`_ on them. Example:
  ##
  ## .. code-block ::
  ##   var a: TSet[int]
  ##   a.init(4)
  ##   a.incl(2)
  ##   a.init
  ##   assert a.len == 0 and a.isValid
  assert isPowerOfTwo(initialSize)
  s.counter = 0
  newSeq(s.data, initialSize)

proc initSet*[A](initialSize=64): TSet[A] =
  ## Convenience wrapper around `init() <#init,TSet[A]>`_.
  ##
  ## Returns an empty hash set you can assign directly in ``var`` blocks in a
  ## single line. Example:
  ##
  ## .. code-block ::
  ##   var a = initSet[int](4)
  ##   a.incl(2)
  result.init(initialSize)

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
  assert s.isValid, "The set needs to be initialized."
  dollarImpl()

proc union*[A](s1, s2: TSet[A]): TSet[A] =
  ## returns a new set of all items that are contained in at
  ## least one of `s1` and `s2`
  assert s1.isValid, "The set `s1` needs to be initialized."
  assert s2.isValid, "The set `s2` needs to be initialized."
  result = s1
  incl(result, s2)

proc intersection*[A](s1, s2: TSet[A]): TSet[A] =
  ## returns a new set of all items that are contained in both `s1` and `s2`
  assert s1.isValid, "The set `s1` needs to be initialized."
  assert s2.isValid, "The set `s2` needs to be initialized."
  result = initSet[A](min(s1.data.len, s2.data.len))
  for item in s1:
    if item in s2: incl(result, item)

proc difference*[A](s1, s2: TSet[A]): TSet[A] =
  ## returns a new set of all items that are contained in `s1`, but not in `s2`
  assert s1.isValid, "The set `s1` needs to be initialized."
  assert s2.isValid, "The set `s2` needs to be initialized."
  result = initSet[A]()
  for item in s1:
    if not contains(s2, item):
      incl(result, item)

proc symmetricDifference*[A](s1, s2: TSet[A]): TSet[A] =
  ## returns a new set of all items that are contained in either
  ## `s1` or `s2`, but not both
  assert s1.isValid, "The set `s1` needs to be initialized."
  assert s2.isValid, "The set `s2` needs to be initialized."
  result = s1
  for item in s2:
    if containsOrIncl(result, item): excl(result, item)

proc `+`*[A](s1, s2: TSet[A]): TSet[A] {.inline.} =
  ## alias for `union`
  result = union(s1, s2)

proc `*`*[A](s1, s2: TSet[A]): TSet[A] {.inline.} =
  ## alias for `intersection`
  result = intersection(s1, s2)

proc `-`*[A](s1, s2: TSet[A]): TSet[A] {.inline.} =
  ## alias for `difference`
  result = difference(s1, s2)

proc `-+-`*[A](s1, s2: TSet[A]): TSet[A] {.inline.} =
  ## alias for `symmetricDifference`
  result = symmetricDifference(s1, s2)

proc disjoint*[A](s1, s2: TSet[A]): bool =
  ## returns true iff `s1` and `s2` have no items in common
  assert s1.isValid, "The set `s1` needs to be initialized."
  assert s2.isValid, "The set `s2` needs to be initialized."
  for item in s1:
    if item in s2: return false
  return true

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

# ------------------------------ ordered set ------------------------------

type
  TOrderedKeyValuePair[A] = tuple[
    slot: TSlotEnum, next: int, key: A]
  TOrderedKeyValuePairSeq[A] = seq[TOrderedKeyValuePair[A]]
  TOrderedSet* {.
      final, myShallow.}[A] = object ## \
    ## A generic hash set that remembers insertion order.
    ##
    ## Use `init() <#init,TOrderedSet[A]>`_ or `initOrderedSet[type]()
    ## <#initOrderedSet>`_ before calling other procs on it.
    data: TOrderedKeyValuePairSeq[A]
    counter, first, last: int

proc isValid*[A](s: TOrderedSet[A]): bool =
  ## Returns `true` if the ordered set has been initialized with `initSet
  ## <#initOrderedSet>`_.
  ##
  ## Most operations over an uninitialized ordered set will crash at runtime
  ## and `assert <system.html#assert>`_ in debug builds. You can use this proc
  ## in your own methods to verify that ordered sets passed to your procs are
  ## correctly initialized. Example:
  ##
  ## .. code-block :: nimrod
  ##   proc saveTarotCards(cards: TOrderedSet[int]) =
  ##     assert cards.isValid, "Pass an initialized set!"
  ##     # Do stuff here, may crash in release builds!
  result = not s.data.isNil

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
  assert s.isValid, "The set needs to be initialized."
  forAllOrderedPairs:
    yield s.data[h].key

proc rawGet[A](s: TOrderedSet[A], key: A): int =
  rawGetImpl()

proc contains*[A](s: TOrderedSet[A], key: A): bool =
  ## returns true iff `key` is in `s`.
  assert s.isValid, "The set needs to be initialized."
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
  assert s.isValid, "The set needs to be initialized."
  inclImpl()

proc incl*[A](s: var TSet[A], other: TOrderedSet[A]) =
  ## includes everything in `other` in `s`
  assert s.isValid, "The set `s` needs to be initialized."
  assert other.isValid, "The set `other` needs to be initialized."
  for item in other: incl(s, item)

proc containsOrIncl*[A](s: var TOrderedSet[A], key: A): bool =
  ## returns true if `s` contains `key`, otherwise `key` is included in `s`
  ## and false is returned.
  assert s.isValid, "The set needs to be initialized."
  containsOrInclImpl()

proc init*[A](s: var TOrderedSet[A], initialSize=64) =
  ## Initializes an ordered hash set.
  ##
  ## The `initialSize` parameter needs to be a power of too. You can use
  ## `math.nextPowerOfTwo() <math.html#nextPowerOfTwo>`_ to guarantee that at
  ## runtime. All set variables have to be initialized before you can use them
  ## with other procs from this module with the exception of `isValid()
  ## <#isValid,TOrderedSet[A]>`_ and `len() <#len,TOrderedSet[A]>`_.
  ##
  ## You can call this method on a previously initialized ordered hash set to
  ## discard its values. At the moment this is the only method to remove
  ## elements from an ordered hash set. Example:
  ##
  ## .. code-block ::
  ##   var a: TOrderedSet[int]
  ##   a.init(4)
  ##   a.incl(2)
  ##   a.init
  ##   assert a.len == 0 and a.isValid
  assert isPowerOfTwo(initialSize)
  s.counter = 0
  s.first = -1
  s.last = -1
  newSeq(s.data, initialSize)

proc initOrderedSet*[A](initialSize=64): TOrderedSet[A] =
  ## Convenience wrapper around `init() <#init,TOrderedSet[A]>`_.
  ##
  ## Returns an empty ordered hash set you can assign directly in ``var``
  ## blocks in a single line. Example:
  ##
  ## .. code-block ::
  ##   var a = initOrderedSet[int](4)
  ##   a.incl(2)
  result.init(initialSize)

proc toOrderedSet*[A](keys: openArray[A]): TOrderedSet[A] =
  ## creates a new ordered hash set that contains the given `keys`.
  result = initOrderedSet[A](nextPowerOfTwo(keys.len+10))
  for key in items(keys): result.incl(key)

proc `$`*[A](s: TOrderedSet[A]): string =
  ## The `$` operator for ordered hash sets.
  assert s.isValid, "The set needs to be initialized."
  dollarImpl()

proc testModule() =
  ## Internal micro test to validate docstrings and such.
  block isValidTest:
    var options: TSet[string]
    proc savePreferences(options: TSet[string]) =
      assert options.isValid, "Pass an initialized set!"
    options = initSet[string]()
    options.savePreferences

  block lenTest:
    var values: TSet[int]
    assert(not values.isValid)
    assert values.len == 0
    assert values.card == 0

  block setIterator:
    type pair = tuple[a, b: int]
    var a, b = initSet[pair]()
    a.incl((2, 3))
    a.incl((3, 2))
    a.incl((2, 3))
    for x, y in a.items:
      b.incl((x - 2, y + 1))
    assert a.len == b.card
    assert a.len == 2
    echo b

  block setContains:
    var values = initSet[int]()
    assert(not values.contains(2))
    values.incl(2)
    assert values.contains(2)
    values.excl(2)
    assert(not values.contains(2))

  block toSeqAndString:
    var a = toSet[int]([2, 4, 5])
    var b = initSet[int]()
    for x in [2, 4, 5]: b.incl(x)
    assert($a == $b)

  block setOperations:
    var
      a = toset[string](["a", "b"])
      b = toset[string](["b", "c"])
      c = union(a, b)
    assert c == toSet[string](["a", "b", "c"])
    var d = intersection(a, b)
    assert d == toSet[string](["b"])
    var e = difference(a, b)
    assert e == toSet[string](["a"])
    var f = symmetricDifference(a, b)
    assert f == toSet[string](["a", "c"])
    assert d < a and d < b
    assert((a < a) == false)
    assert d <= a and d <= b
    assert((a <= a))
    # Alias test.
    assert a + b == toSet[string](["a", "b", "c"])
    assert a * b == toSet[string](["b"])
    assert a - b == toSet[string](["a"])
    assert a -+- b == toSet[string](["a", "c"])
    assert disjoint(a, b) == false
    assert disjoint(a, b - a) == true

  block mapSet:
    var a = toSet[int]([1, 2, 3])
    var b = a.map(proc (x: int): string = $x)
    assert b == toSet[string](["1", "2", "3"])

  block isValidTest:
    var cards: TOrderedSet[string]
    proc saveTarotCards(cards: TOrderedSet[string]) =
      assert cards.isValid, "Pass an initialized set!"
    cards = initOrderedSet[string]()
    cards.saveTarotCards

  block lenTest:
    var values: TOrderedSet[int]
    assert(not values.isValid)
    assert values.len == 0
    assert values.card == 0

  block setIterator:
    type pair = tuple[a, b: int]
    var a, b = initOrderedSet[pair]()
    a.incl((2, 3))
    a.incl((3, 2))
    a.incl((2, 3))
    for x, y in a.items:
      b.incl((x - 2, y + 1))
    assert a.len == b.card
    assert a.len == 2

  block setContains:
    var values = initOrderedSet[int]()
    assert(not values.contains(2))
    values.incl(2)
    assert values.contains(2)

  block toSeqAndString:
    var a = toOrderedSet[int]([2, 4, 5])
    var b = initOrderedSet[int]()
    for x in [2, 4, 5]: b.incl(x)
    assert($a == $b)
    # assert(a == b) # https://github.com/Araq/Nimrod/issues/1413

  block initBlocks:
    var a: TOrderedSet[int]
    a.init(4)
    a.incl(2)
    a.init
    assert a.len == 0 and a.isValid
    a = initOrderedSet[int](4)
    a.incl(2)
    assert a.len == 1

    var b: TSet[int]
    b.init(4)
    b.incl(2)
    b.init
    assert b.len == 0 and b.isValid
    b = initSet[int](4)
    b.incl(2)
    assert b.len == 1

  echo "Micro tests run successfully."

when isMainModule and not defined(release): testModule()
