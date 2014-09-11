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
## Hash sets are different from the `built in set type
## <manual.html#set-type>`_. Sets allow you to store any value that can be
## `hashed <hashes.html>`_ and they don't contain duplicate entries.
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
    ## Use `init() <#init,TSet[A],int>`_ or `initSet[type]() <#initSet>`_
    ## before calling other procs on it.
    data: TKeyValuePairSeq[A]
    counter: int

proc isValid*[A](s: TSet[A]): bool =
  ## Returns `true` if the set has been initialized with `initSet <#initSet>`_.
  ##
  ## Most operations over an uninitialized set will crash at runtime and
  ## `assert <system.html#assert>`_ in debug builds. You can use this proc in
  ## your own procs to verify that sets passed to your procs are correctly
  ## initialized. Example:
  ##
  ## .. code-block :: nimrod
  ##   proc savePreferences(options: TSet[string]) =
  ##     assert options.isValid, "Pass an initialized set!"
  ##     # Do stuff here, may crash in release builds!
  result = not s.data.isNil

proc len*[A](s: TSet[A]): int =
  ## Returns the number of keys in `s`.
  ##
  ## Due to an implementation detail you can call this proc on variables which
  ## have not been initialized yet. The proc will return zero as the length
  ## then. Example:
  ##
  ## .. code-block::
  ##
  ##   var values: TSet[int]
  ##   assert(not values.isValid)
  ##   assert values.len == 0
  result = s.counter

proc card*[A](s: TSet[A]): int =
  ## Alias for `len() <#len,TSet[A]>`_.
  ##
  ## Card stands for the `cardinality
  ## <http://en.wikipedia.org/wiki/Cardinality>`_ of a set.
  result = s.counter

iterator items*[A](s: TSet[A]): A =
  ## Iterates over keys in the set `s`.
  ##
  ## If you need a sequence with the keys you can use `sequtils.toSeq()
  ## <sequtils.html#toSeq>`_ on the iterator. Usage example:
  ##
  ## .. code-block::
  ##   type
  ##     pair = tuple[a, b: int]
  ##   var
  ##     a, b = initSet[pair]()
  ##   a.incl((2, 3))
  ##   a.incl((3, 2))
  ##   a.incl((2, 3))
  ##   for x, y in a.items:
  ##     b.incl((x - 2, y + 1))
  ##   assert a.len == 2
  ##   echo b
  ##   # --> {(a: 1, b: 3), (a: 0, b: 4)}
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
  if index >= 0: result = s.data[index].key
  else: raise newException(EInvalidKey, "key not found: " & $key)

proc contains*[A](s: TSet[A], key: A): bool =
  ## Returns true iff `key` is in `s`.
  ##
  ## Example:
  ##
  ## .. code-block::
  ##   var values = initSet[int]()
  ##   assert(not values.contains(2))
  ##   values.incl(2)
  ##   assert values.contains(2)
  ##   values.excl(2)
  ##   assert(not values.contains(2))
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
  ## Includes an element `key` in `s`.
  ##
  ## This doesn't do anything if `key` is already in `s`. Example:
  ##
  ## .. code-block::
  ##   var values = initSet[int]()
  ##   values.incl(2)
  ##   values.incl(2)
  ##   assert values.len == 1
  assert s.isValid, "The set needs to be initialized."
  inclImpl()

proc incl*[A](s: var TSet[A], other: TSet[A]) =
  ## Includes all elements from `other` into `s`.
  ##
  ## Example:
  ##
  ## .. code-block::
  ##   var values = initSet[int]()
  ##   values.incl(2)
  ##   var others = toSet([6, 7])
  ##   values.incl(others)
  ##   assert values.len == 3
  assert s.isValid, "The set `s` needs to be initialized."
  assert other.isValid, "The set `other` needs to be initialized."
  for item in other: incl(s, item)

proc excl*[A](s: var TSet[A], key: A) =
  ## Excludes `key` from the set `s`.
  ##
  ## This doesn't do anything if `key` is not found in `s`. Example:
  ##
  ## .. code-block::
  ##   var s = toSet([2, 3, 6, 7])
  ##   s.excl(2)
  ##   s.excl(2)
  ##   assert s.len == 3
  assert s.isValid, "The set needs to be initialized."
  var index = rawGet(s, key)
  if index >= 0:
    s.data[index].slot = seDeleted
    dec(s.counter)

proc excl*[A](s: var TSet[A], other: TSet[A]) =
  ## Excludes everything in `other` from `s`.
  ##
  ## Example:
  ##
  ## .. code-block::
  ##   var
  ##     numbers = toSet([1, 2, 3, 4, 5])
  ##     even = toSet([2, 4, 6, 8])
  ##   numbers.excl(even)
  ##   echo numbers
  ##   # --> {1, 3, 5}
  assert s.isValid, "The set `s` needs to be initialized."
  assert other.isValid, "The set `other` needs to be initialized."
  for item in other: excl(s, item)

proc containsOrIncl*[A](s: var TSet[A], key: A): bool =
  ## Includes `key` in the set `s` and tells if `key` was added to `s`.
  ##
  ## The difference with regards to the `incl() <#incl,TSet[A],A>`_ proc is
  ## that this proc returns `true` if `key` was already present in `s`. The
  ## proc will return false if `key` was added as a new value to `s` during
  ## this call. Example:
  ##
  ## .. code-block::
  ##   var values = initSet[int]()
  ##   assert values.containsOrIncl(2) == false
  ##   assert values.containsOrIncl(2) == true
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
  ## You can call this proc on a previously initialized hash set, which will
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
  ## Wrapper around `init() <#init,TSet[A],int>`_ for initialization of hash
  ## sets.
  ##
  ## Returns an empty hash set you can assign directly in ``var`` blocks in a
  ## single line. Example:
  ##
  ## .. code-block ::
  ##   var a = initSet[int](4)
  ##   a.incl(2)
  result.init(initialSize)

proc toSet*[A](keys: openArray[A]): TSet[A] =
  ## Creates a new hash set that contains the given `keys`.
  ##
  ## Example:
  ##
  ## .. code-block::
  ##   var numbers = toSet([1, 2, 3, 4, 5])
  ##   assert numbers.contains(2)
  ##   assert numbers.contains(4)
  result = initSet[A](nextPowerOfTwo(keys.len+10))
  for key in items(keys): result.incl(key)

template dollarImpl(): stmt {.dirty.} =
  result = "{"
  for key in items(s):
    if result.len > 1: result.add(", ")
    result.add($key)
  result.add("}")

proc `$`*[A](s: TSet[A]): string =
  ## Converts the set `s` to a string, mostly for logging purposes.
  ##
  ## Don't use this proc for serialization, the representation may change at
  ## any moment and values are not escaped. Example:
  ##
  ## Example:
  ##
  ## .. code-block::
  ##   echo toSet([2, 4, 5])
  ##   # --> {2, 4, 5}
  ##   echo toSet(["no", "esc'aping", "is \" provided"])
  ##   # --> {no, esc'aping, is " provided}
  assert s.isValid, "The set needs to be initialized."
  dollarImpl()

proc union*[A](s1, s2: TSet[A]): TSet[A] =
  ## Returns the union of the sets `s1` and `s2`.
  ##
  ## The union of two sets is represented mathematically as *A ∪ B* and is the
  ## set of all objects that are members of `s1`, `s2` or both. Example:
  ##
  ## .. code-block::
  ##   var
  ##     a = toSet(["a", "b"])
  ##     b = toSet(["b", "c"])
  ##     c = union(a, b)
  ##   assert c == toSet(["a", "b", "c"])
  assert s1.isValid, "The set `s1` needs to be initialized."
  assert s2.isValid, "The set `s2` needs to be initialized."
  result = s1
  incl(result, s2)

proc intersection*[A](s1, s2: TSet[A]): TSet[A] =
  ## Returns the intersection of the sets `s1` and `s2`.
  ##
  ## The intersection of two sets is represented mathematically as *A ∩ B* and
  ## is the set of all objects that are members of `s1` and `s2` at the same
  ## time. Example:
  ##
  ## .. code-block::
  ##   var
  ##     a = toSet(["a", "b"])
  ##     b = toSet(["b", "c"])
  ##     c = intersection(a, b)
  ##   assert c == toSet(["b"])
  assert s1.isValid, "The set `s1` needs to be initialized."
  assert s2.isValid, "The set `s2` needs to be initialized."
  result = initSet[A](min(s1.data.len, s2.data.len))
  for item in s1:
    if item in s2: incl(result, item)

proc difference*[A](s1, s2: TSet[A]): TSet[A] =
  ## Returns the difference of the sets `s1` and `s2`.
  ##
  ## The difference of two sets is represented mathematically as *A \ B* and is
  ## the set of all objects that are members of `s1` and not members of `s2`.
  ## Example:
  ##
  ## .. code-block::
  ##   var
  ##     a = toSet(["a", "b"])
  ##     b = toSet(["b", "c"])
  ##     c = difference(a, b)
  ##   assert c == toSet(["a"])
  assert s1.isValid, "The set `s1` needs to be initialized."
  assert s2.isValid, "The set `s2` needs to be initialized."
  result = initSet[A]()
  for item in s1:
    if not contains(s2, item):
      incl(result, item)

proc symmetricDifference*[A](s1, s2: TSet[A]): TSet[A] =
  ## Returns the symmetric difference of the sets `s1` and `s2`.
  ##
  ## The symmetric difference of two sets is represented mathematically as *A △
  ## B* or *A ⊖ B* and is the set of all objects that are members of `s1` or
  ## `s2` but not both at the same time. Example:
  ##
  ## .. code-block::
  ##   var
  ##     a = toSet(["a", "b"])
  ##     b = toSet(["b", "c"])
  ##     c = symmetricDifference(a, b)
  ##   assert c == toSet(["a", "c"])
  assert s1.isValid, "The set `s1` needs to be initialized."
  assert s2.isValid, "The set `s2` needs to be initialized."
  result = s1
  for item in s2:
    if containsOrIncl(result, item): excl(result, item)

proc `+`*[A](s1, s2: TSet[A]): TSet[A] {.inline.} =
  ## Alias for `union(s1, s2) <#union>`_.
  result = union(s1, s2)

proc `*`*[A](s1, s2: TSet[A]): TSet[A] {.inline.} =
  ## Alias for `intersection(s1, s2) <#intersection>`_.
  result = intersection(s1, s2)

proc `-`*[A](s1, s2: TSet[A]): TSet[A] {.inline.} =
  ## Alias for `difference(s1, s2) <#difference>`_.
  result = difference(s1, s2)

proc `-+-`*[A](s1, s2: TSet[A]): TSet[A] {.inline.} =
  ## Alias for `symmetricDifference(s1, s2) <#symmetricDifference>`_.
  result = symmetricDifference(s1, s2)

proc disjoint*[A](s1, s2: TSet[A]): bool =
  ## Returns true iff the sets `s1` and `s2` have no items in common.
  ##
  ## Example:
  ##
  ## .. code-block::
  ##   var
  ##     a = toSet(["a", "b"])
  ##     b = toSet(["b", "c"])
  ##   assert disjoint(a, b) == false
  ##   assert disjoint(a, b - a) == true
  assert s1.isValid, "The set `s1` needs to be initialized."
  assert s2.isValid, "The set `s2` needs to be initialized."
  for item in s1:
    if item in s2: return false
  return true

proc `<`*[A](s, t: TSet[A]): bool =
  ## Returns true if `s` is a strict or proper subset of `t`.
  ##
  ## A strict or proper subset `s` has all of its members in `t` but `t` has
  ## more elements than `s`. Example:
  ##
  ## .. code-block::
  ##   var
  ##     a = toSet(["a", "b"])
  ##     b = toSet(["b", "c"])
  ##     c = intersection(a, b)
  ##   assert c < a and c < b
  ##   assert((a < a) == false)
  s.counter != t.counter and s <= t

proc `<=`*[A](s, t: TSet[A]): bool =
  ## Returns true if `s` is subset of `t`.
  ##
  ## A subset `s` has all of its members in `t` and `t` doesn't necessarily
  ## have more members than `s`. That is, `s` can be equal to `t`. Example:
  ##
  ## .. code-block::
  ##   var
  ##     a = toSet(["a", "b"])
  ##     b = toSet(["b", "c"])
  ##     c = intersection(a, b)
  ##   assert c <= a and c <= b
  ##   assert((a <= a))
  result = false
  if s.counter > t.counter: return
  result = true
  for item in s:
    if not(t.contains(item)):
      result = false
      return

proc `==`*[A](s, t: TSet[A]): bool =
  ## Returns true if both `s` and `t` have the same members and set size.
  ##
  ## Example:
  ##
  ## .. code-block::
  ##   var
  ##     a = toSet([1, 2])
  ##     b = toSet([1])
  ##   b.incl(2)
  ##   assert a == b
  s.counter == t.counter and s <= t

proc map*[A, B](data: TSet[A], op: proc (x: A): B {.closure.}): TSet[B] =
  ## Returns a new set after applying `op` on each of the elements of `data`.
  ##
  ## You can use this proc to transform the elements from a set. Example:
  ##
  ## .. code-block::
  ##   var a = toSet([1, 2, 3])
  ##   var b = a.map(proc (x: int): string = $x)
  ##   assert b == toSet(["1", "2", "3"])
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
    ## Use `init() <#init,TOrderedSet[A],int>`_ or `initOrderedSet[type]()
    ## <#initOrderedSet>`_ before calling other procs on it.
    data: TOrderedKeyValuePairSeq[A]
    counter, first, last: int

proc isValid*[A](s: TOrderedSet[A]): bool =
  ## Returns `true` if the ordered set has been initialized with `initSet
  ## <#initOrderedSet>`_.
  ##
  ## Most operations over an uninitialized ordered set will crash at runtime
  ## and `assert <system.html#assert>`_ in debug builds. You can use this proc
  ## in your own procs to verify that ordered sets passed to your procs are
  ## correctly initialized. Example:
  ##
  ## .. code-block :: nimrod
  ##   proc saveTarotCards(cards: TOrderedSet[int]) =
  ##     assert cards.isValid, "Pass an initialized set!"
  ##     # Do stuff here, may crash in release builds!
  result = not s.data.isNil

proc len*[A](s: TOrderedSet[A]): int {.inline.} =
  ## Returns the number of keys in `s`.
  ##
  ## Due to an implementation detail you can call this proc on variables which
  ## have not been initialized yet. The proc will return zero as the length
  ## then. Example:
  ##
  ## .. code-block::
  ##
  ##   var values: TOrderedSet[int]
  ##   assert(not values.isValid)
  ##   assert values.len == 0
  result = s.counter

proc card*[A](s: TOrderedSet[A]): int {.inline.} =
  ## Alias for `len() <#len,TOrderedSet[A]>`_.
  ##
  ## Card stands for the `cardinality
  ## <http://en.wikipedia.org/wiki/Cardinality>`_ of a set.
  result = s.counter

template forAllOrderedPairs(yieldStmt: stmt) {.dirty, immediate.} =
  var h = s.first
  while h >= 0:
    var nxt = s.data[h].next
    if s.data[h].slot == seFilled: yieldStmt
    h = nxt

iterator items*[A](s: TOrderedSet[A]): A =
  ## Iterates over keys in the ordered set `s` in insertion order.
  ##
  ## If you need a sequence with the keys you can use `sequtils.toSeq()
  ## <sequtils.html#toSeq>`_ on the iterator. Usage example:
  ##
  ## .. code-block::
  ##   var a = initOrderedSet[int]()
  ##   for value in [9, 2, 1, 5, 1, 8, 4, 2]:
  ##     a.incl(value)
  ##   for value in a.items:
  ##     echo "Got ", value
  ##   # --> Got 9
  ##   # --> Got 2
  ##   # --> Got 1
  ##   # --> Got 5
  ##   # --> Got 8
  ##   # --> Got 4
  assert s.isValid, "The set needs to be initialized."
  forAllOrderedPairs:
    yield s.data[h].key

proc rawGet[A](s: TOrderedSet[A], key: A): int =
  rawGetImpl()

proc contains*[A](s: TOrderedSet[A], key: A): bool =
  ## Returns true iff `key` is in `s`.
  ##
  ## Example:
  ##
  ## .. code-block::
  ##   var values = initOrderedSet[int]()
  ##   assert(not values.contains(2))
  ##   values.incl(2)
  ##   assert values.contains(2)
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
  ## Includes an element `key` in `s`.
  ##
  ## This doesn't do anything if `key` is already in `s`. Example:
  ##
  ## .. code-block::
  ##   var values = initOrderedSet[int]()
  ##   values.incl(2)
  ##   values.incl(2)
  ##   assert values.len == 1
  assert s.isValid, "The set needs to be initialized."
  inclImpl()

proc incl*[A](s: var TSet[A], other: TOrderedSet[A]) =
  ## Includes all elements from `other` into `s`.
  ##
  ## Example:
  ##
  ## .. code-block::
  ##   var values = initOrderedSet[int]()
  ##   values.incl(2)
  ##   var others = toOrderedSet([6, 7])
  ##   values.incl(others)
  ##   assert values.len == 3
  assert s.isValid, "The set `s` needs to be initialized."
  assert other.isValid, "The set `other` needs to be initialized."
  for item in other: incl(s, item)

proc containsOrIncl*[A](s: var TOrderedSet[A], key: A): bool =
  ## Includes `key` in the set `s` and tells if `key` was added to `s`.
  ##
  ## The difference with regards to the `incl() <#incl,TOrderedSet[A],A>`_ proc
  ## is that this proc returns `true` if `key` was already present in `s`. The
  ## proc will return false if `key` was added as a new value to `s` during
  ## this call. Example:
  ##
  ## .. code-block::
  ##   var values = initOrderedSet[int]()
  ##   assert values.containsOrIncl(2) == false
  ##   assert values.containsOrIncl(2) == true
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
  ## You can call this proc on a previously initialized ordered hash set to
  ## discard its values. At the moment this is the only proc to remove elements
  ## from an ordered hash set. Example:
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
  ## Wrapper around `init() <#init,TOrderedSet[A],int>`_ for initialization of
  ## ordered hash sets.
  ##
  ## Returns an empty ordered hash set you can assign directly in ``var``
  ## blocks in a single line. Example:
  ##
  ## .. code-block ::
  ##   var a = initOrderedSet[int](4)
  ##   a.incl(2)
  result.init(initialSize)

proc toOrderedSet*[A](keys: openArray[A]): TOrderedSet[A] =
  ## Creates a new ordered hash set that contains the given `keys`.
  ##
  ## Example:
  ##
  ## .. code-block::
  ##   var numbers = toOrderedSet([1, 2, 3, 4, 5])
  ##   assert numbers.contains(2)
  ##   assert numbers.contains(4)
  result = initOrderedSet[A](nextPowerOfTwo(keys.len+10))
  for key in items(keys): result.incl(key)

proc `$`*[A](s: TOrderedSet[A]): string =
  ## Converts the ordered hash set `s` to a string, mostly for logging purposes.
  ##
  ## Don't use this proc for serialization, the representation may change at
  ## any moment and values are not escaped. Example:
  ##
  ## Example:
  ##
  ## .. code-block::
  ##   echo toOrderedSet([2, 4, 5])
  ##   # --> {2, 4, 5}
  ##   echo toOrderedSet(["no", "esc'aping", "is \" provided"])
  ##   # --> {no, esc'aping, is " provided}
  assert s.isValid, "The set needs to be initialized."
  dollarImpl()

proc `==`*[A](s, t: TOrderedSet[A]): bool =
  ## Equality for ordered sets.
  if s.counter != t.counter: return false
  var h = s.first
  var g = s.first
  var compared = 0
  while h >= 0 and g >= 0:
    var nxh = s.data[h].next
    var nxg = t.data[g].next
    if s.data[h].slot == seFilled and s.data[g].slot == seFilled:
      if s.data[h].key == s.data[g].key:
        inc compared
      else:
        return false
    h = nxh
    g = nxg
  result = compared == s.counter

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
    #echo b

  block setContains:
    var values = initSet[int]()
    assert(not values.contains(2))
    values.incl(2)
    assert values.contains(2)
    values.excl(2)
    assert(not values.contains(2))

    values.incl(4)
    var others = toSet([6, 7])
    values.incl(others)
    assert values.len == 3

    values.init
    assert values.containsOrIncl(2) == false
    assert values.containsOrIncl(2) == true
    var
      a = toSet([1, 2])
      b = toSet([1])
    b.incl(2)
    assert a == b

  block exclusions:
    var s = toSet([2, 3, 6, 7])
    s.excl(2)
    s.excl(2)
    assert s.len == 3

    var
      numbers = toSet([1, 2, 3, 4, 5])
      even = toSet([2, 4, 6, 8])
    numbers.excl(even)
    #echo numbers
    # --> {1, 3, 5}

  block toSeqAndString:
    var a = toSet([2, 4, 5])
    var b = initSet[int]()
    for x in [2, 4, 5]: b.incl(x)
    assert($a == $b)
    #echo a
    #echo toSet(["no", "esc'aping", "is \" provided"])

  #block orderedToSeqAndString:
  #  echo toOrderedSet([2, 4, 5])
  #  echo toOrderedSet(["no", "esc'aping", "is \" provided"])

  block setOperations:
    var
      a = toSet(["a", "b"])
      b = toSet(["b", "c"])
      c = union(a, b)
    assert c == toSet(["a", "b", "c"])
    var d = intersection(a, b)
    assert d == toSet(["b"])
    var e = difference(a, b)
    assert e == toSet(["a"])
    var f = symmetricDifference(a, b)
    assert f == toSet(["a", "c"])
    assert d < a and d < b
    assert((a < a) == false)
    assert d <= a and d <= b
    assert((a <= a))
    # Alias test.
    assert a + b == toSet(["a", "b", "c"])
    assert a * b == toSet(["b"])
    assert a - b == toSet(["a"])
    assert a -+- b == toSet(["a", "c"])
    assert disjoint(a, b) == false
    assert disjoint(a, b - a) == true

  block mapSet:
    var a = toSet([1, 2, 3])
    var b = a.map(proc (x: int): string = $x)
    assert b == toSet(["1", "2", "3"])

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

  #block orderedSetIterator:
  #  var a = initOrderedSet[int]()
  #  for value in [9, 2, 1, 5, 1, 8, 4, 2]:
  #    a.incl(value)
  #  for value in a.items:
  #    echo "Got ", value

  block setContains:
    var values = initOrderedSet[int]()
    assert(not values.contains(2))
    values.incl(2)
    assert values.contains(2)

  block toSeqAndString:
    var a = toOrderedSet([2, 4, 5])
    var b = initOrderedSet[int]()
    for x in [2, 4, 5]: b.incl(x)
    assert($a == $b)
    assert(a == b) # https://github.com/Araq/Nimrod/issues/1413

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
