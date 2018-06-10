#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## The ``sets`` module implements an efficient `hash set`:idx: and
## ordered hash set.
##
## Hash sets are different from the `built in set type
## <manual.html#types-set-type>`_. Sets allow you to store any value that can be
## `hashed <hashes.html>`_ and they don't contain duplicate entries.
##
## **Note**: The data types declared here have *value semantics*: This means
## that ``=`` performs a copy of the set.

import
  hashes, math

{.pragma: myShallow.}
when not defined(nimhygiene):
  {.pragma: dirty.}

# For "integer-like A" that are too big for intsets/bit-vectors to be practical,
# it would be best to shrink hcode to the same size as the integer.  Larger
# codes should never be needed, and this can pack more entries per cache-line.
# Losing hcode entirely is also possible - if some element value is forbidden.
type
  KeyValuePair[A] = tuple[hcode: Hash, key: A]
  KeyValuePairSeq[A] = seq[KeyValuePair[A]]
  HashSet* {.myShallow.}[A] = object ## \
    ## A generic hash set.
    ##
    ## Use `init() <#init,HashSet[A],int>`_ or `initSet[type]() <#initSet>`_
    ## before calling other procs on it.
    data: KeyValuePairSeq[A]
    counter: int

{.deprecated: [TSet: HashSet].}

template default[T](t: typedesc[T]): T =
  ## Used by clear methods to get a default value.
  var v: T
  v

proc clear*[A](s: var HashSet[A]) =
  ## Clears the HashSet back to an empty state, without shrinking
  ## any of the existing storage. O(n) where n is the size of the hash bucket.
  s.counter = 0
  for i in 0..<s.data.len:
    s.data[i].hcode = 0
    s.data[i].key   = default(type(s.data[i].key))

# hcode for real keys cannot be zero.  hcode==0 signifies an empty slot.  These
# two procs retain clarity of that encoding without the space cost of an enum.
proc isEmpty(hcode: Hash): bool {.inline.} =
  result = hcode == 0

proc isFilled(hcode: Hash): bool {.inline.} =
  result = hcode != 0

proc isValid*[A](s: HashSet[A]): bool =
  ## Returns `true` if the set has been initialized with `initSet <#initSet>`_.
  ##
  ## Most operations over an uninitialized set will crash at runtime and
  ## `assert <system.html#assert>`_ in debug builds. You can use this proc in
  ## your own procs to verify that sets passed to your procs are correctly
  ## initialized. Example:
  ##
  ## .. code-block ::
  ##   proc savePreferences(options: HashSet[string]) =
  ##     assert options.isValid, "Pass an initialized set!"
  ##     # Do stuff here, may crash in release builds!
  result = not s.data.isNil

proc len*[A](s: HashSet[A]): int =
  ## Returns the number of keys in `s`.
  ##
  ## Due to an implementation detail you can call this proc on variables which
  ## have not been initialized yet. The proc will return zero as the length
  ## then. Example:
  ##
  ## .. code-block::
  ##
  ##   var values: HashSet[int]
  ##   assert(not values.isValid)
  ##   assert values.len == 0
  result = s.counter

proc card*[A](s: HashSet[A]): int =
  ## Alias for `len() <#len,TSet[A]>`_.
  ##
  ## Card stands for the `cardinality
  ## <http://en.wikipedia.org/wiki/Cardinality>`_ of a set.
  result = s.counter

iterator items*[A](s: HashSet[A]): A =
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
    if isFilled(s.data[h].hcode): yield s.data[h].key

proc hash*[A](s: HashSet[A]): Hash =
  ## hashing of HashSet
  assert s.isValid, "The set needs to be initialized."
  for h in 0..high(s.data):
    result = result xor s.data[h].hcode
  result = !$result

const
  growthFactor = 2

proc mustRehash(length, counter: int): bool {.inline.} =
  assert(length > counter)
  result = (length * 2 < counter * 3) or (length - counter < 4)

proc rightSize*(count: Natural): int {.inline.} =
  ## Return the value of `initialSize` to support `count` items.
  ##
  ## If more items are expected to be added, simply add that
  ## expected extra amount to the parameter before calling this.
  ##
  ## Internally, we want mustRehash(rightSize(x), x) == false.
  result = nextPowerOfTwo(count * 3 div 2  +  4)

proc nextTry(h, maxHash: Hash): Hash {.inline.} =
  result = (h + 1) and maxHash

template rawGetKnownHCImpl() {.dirty.} =
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

template rawGetImpl() {.dirty.} =
  hc = hash(key)
  if hc == 0:       # This almost never taken branch should be very predictable.
    hc = 314159265  # Value doesn't matter; Any non-zero favorite is fine.
  rawGetKnownHCImpl()

template rawInsertImpl() {.dirty.} =
  data[h].key = key
  data[h].hcode = hc

proc rawGetKnownHC[A](s: HashSet[A], key: A, hc: Hash): int {.inline.} =
  rawGetKnownHCImpl()

proc rawGet[A](s: HashSet[A], key: A, hc: var Hash): int {.inline.} =
  rawGetImpl()

proc `[]`*[A](s: var HashSet[A], key: A): var A =
  ## returns the element that is actually stored in 's' which has the same
  ## value as 'key' or raises the ``KeyError`` exception. This is useful
  ## when one overloaded 'hash' and '==' but still needs reference semantics
  ## for sharing.
  assert s.isValid, "The set needs to be initialized."
  var hc: Hash
  var index = rawGet(s, key, hc)
  if index >= 0: result = s.data[index].key
  else:
    when compiles($key):
      raise newException(KeyError, "key not found: " & $key)
    else:
      raise newException(KeyError, "key not found")

proc mget*[A](s: var HashSet[A], key: A): var A {.deprecated.} =
  ## returns the element that is actually stored in 's' which has the same
  ## value as 'key' or raises the ``KeyError`` exception. This is useful
  ## when one overloaded 'hash' and '==' but still needs reference semantics
  ## for sharing. Use ```[]``` instead.
  s[key]

proc contains*[A](s: HashSet[A], key: A): bool =
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
  var hc: Hash
  var index = rawGet(s, key, hc)
  result = index >= 0

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

proc incl*[A](s: var HashSet[A], key: A) =
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

proc incl*[A](s: var HashSet[A], other: HashSet[A]) =
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

template doWhile(a, b) =
  while true:
    b
    if not a: break

template default[T](t: typedesc[T]): T =
  var v: T
  v

proc exclImpl[A](s: var HashSet[A], key: A) : bool {. inline .} =
  assert s.isValid, "The set needs to be initialized."
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

proc missingOrExcl*[A](s: var HashSet[A], key: A): bool =
  ## Excludes `key` in the set `s` and tells if `key` was removed from `s`.
  ##
  ## The difference with regards to the `excl() <#excl,TSet[A],A>`_ proc is
  ## that this proc returns `true` if `key` was not present in `s`. Example:
  ##
  ## .. code-block::
  ##  var s = toSet([2, 3, 6, 7])
  ##  assert s.missingOrExcl(4) == true
  ##  assert s.missingOrExcl(6) == false
  exclImpl(s, key)

proc excl*[A](s: var HashSet[A], key: A) =
  ## Excludes `key` from the set `s`.
  ##
  ## This doesn't do anything if `key` is not found in `s`. Example:
  ##
  ## .. code-block::
  ##   var s = toSet([2, 3, 6, 7])
  ##   s.excl(2)
  ##   s.excl(2)
  ##   assert s.len == 3
  discard exclImpl(s, key)

proc excl*[A](s: var HashSet[A], other: HashSet[A]) =
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
  for item in other: discard exclImpl(s, item)

proc containsOrIncl*[A](s: var HashSet[A], key: A): bool =
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

proc init*[A](s: var HashSet[A], initialSize=64) =
  ## Initializes a hash set.
  ##
  ## The `initialSize` parameter needs to be a power of two. You can use
  ## `math.nextPowerOfTwo() <math.html#nextPowerOfTwo>`_ or `rightSize` to
  ## guarantee that at runtime. All set variables must be initialized before
  ## use with other procs from this module with the exception of `isValid()
  ## <#isValid,TSet[A]>`_ and `len() <#len,TSet[A]>`_.
  ##
  ## You can call this proc on a previously initialized hash set, which will
  ## discard all its values. This might be more convenient than iterating over
  ## existing values and calling `excl() <#excl,TSet[A],A>`_ on them. Example:
  ##
  ## .. code-block ::
  ##   var a: HashSet[int]
  ##   a.init(4)
  ##   a.incl(2)
  ##   a.init
  ##   assert a.len == 0 and a.isValid
  assert isPowerOfTwo(initialSize)
  s.counter = 0
  newSeq(s.data, initialSize)

proc initSet*[A](initialSize=64): HashSet[A] =
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

proc toSet*[A](keys: openArray[A]): HashSet[A] =
  ## Creates a new hash set that contains the given `keys`.
  ##
  ## Example:
  ##
  ## .. code-block::
  ##   var numbers = toSet([1, 2, 3, 4, 5])
  ##   assert numbers.contains(2)
  ##   assert numbers.contains(4)
  result = initSet[A](rightSize(keys.len))
  for key in items(keys): result.incl(key)

template dollarImpl() {.dirty.} =
  result = "{"
  for key in items(s):
    if result.len > 1: result.add(", ")
    result.addQuoted(key)
  result.add("}")

proc `$`*[A](s: HashSet[A]): string =
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

proc union*[A](s1, s2: HashSet[A]): HashSet[A] =
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

proc intersection*[A](s1, s2: HashSet[A]): HashSet[A] =
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

proc difference*[A](s1, s2: HashSet[A]): HashSet[A] =
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

proc symmetricDifference*[A](s1, s2: HashSet[A]): HashSet[A] =
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

proc `+`*[A](s1, s2: HashSet[A]): HashSet[A] {.inline.} =
  ## Alias for `union(s1, s2) <#union>`_.
  result = union(s1, s2)

proc `*`*[A](s1, s2: HashSet[A]): HashSet[A] {.inline.} =
  ## Alias for `intersection(s1, s2) <#intersection>`_.
  result = intersection(s1, s2)

proc `-`*[A](s1, s2: HashSet[A]): HashSet[A] {.inline.} =
  ## Alias for `difference(s1, s2) <#difference>`_.
  result = difference(s1, s2)

proc `-+-`*[A](s1, s2: HashSet[A]): HashSet[A] {.inline.} =
  ## Alias for `symmetricDifference(s1, s2) <#symmetricDifference>`_.
  result = symmetricDifference(s1, s2)

proc disjoint*[A](s1, s2: HashSet[A]): bool =
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

proc `<`*[A](s, t: HashSet[A]): bool =
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

proc `<=`*[A](s, t: HashSet[A]): bool =
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

proc `==`*[A](s, t: HashSet[A]): bool =
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

proc map*[A, B](data: HashSet[A], op: proc (x: A): B {.closure.}): HashSet[B] =
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
  OrderedKeyValuePair[A] = tuple[
    hcode: Hash, next: int, key: A]
  OrderedKeyValuePairSeq[A] = seq[OrderedKeyValuePair[A]]
  OrderedSet* {.myShallow.}[A] = object ## \
    ## A generic hash set that remembers insertion order.
    ##
    ## Use `init() <#init,OrderedSet[A],int>`_ or `initOrderedSet[type]()
    ## <#initOrderedSet>`_ before calling other procs on it.
    data: OrderedKeyValuePairSeq[A]
    counter, first, last: int

{.deprecated: [TOrderedSet: OrderedSet].}

proc clear*[A](s: var OrderedSet[A]) =
  ## Clears the OrderedSet back to an empty state, without shrinking
  ## any of the existing storage. O(n) where n is the size of the hash bucket.
  s.counter = 0
  s.first = -1
  s.last = -1
  for i in 0..<s.data.len:
    s.data[i].hcode = 0
    s.data[i].next = 0
    s.data[i].key = default(type(s.data[i].key))


proc isValid*[A](s: OrderedSet[A]): bool =
  ## Returns `true` if the ordered set has been initialized with `initSet
  ## <#initOrderedSet>`_.
  ##
  ## Most operations over an uninitialized ordered set will crash at runtime
  ## and `assert <system.html#assert>`_ in debug builds. You can use this proc
  ## in your own procs to verify that ordered sets passed to your procs are
  ## correctly initialized. Example:
  ##
  ## .. code-block::
  ##   proc saveTarotCards(cards: OrderedSet[int]) =
  ##     assert cards.isValid, "Pass an initialized set!"
  ##     # Do stuff here, may crash in release builds!
  result = not s.data.isNil

proc len*[A](s: OrderedSet[A]): int {.inline.} =
  ## Returns the number of keys in `s`.
  ##
  ## Due to an implementation detail you can call this proc on variables which
  ## have not been initialized yet. The proc will return zero as the length
  ## then. Example:
  ##
  ## .. code-block::
  ##
  ##   var values: OrderedSet[int]
  ##   assert(not values.isValid)
  ##   assert values.len == 0
  result = s.counter

proc card*[A](s: OrderedSet[A]): int {.inline.} =
  ## Alias for `len() <#len,TOrderedSet[A]>`_.
  ##
  ## Card stands for the `cardinality
  ## <http://en.wikipedia.org/wiki/Cardinality>`_ of a set.
  result = s.counter

template forAllOrderedPairs(yieldStmt: untyped) {.dirty.} =
  var h = s.first
  var idx = 0
  while h >= 0:
    var nxt = s.data[h].next
    if isFilled(s.data[h].hcode):
      yieldStmt
      inc(idx)
    h = nxt

iterator items*[A](s: OrderedSet[A]): A =
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

proc hash*[A](s: OrderedSet[A]): Hash =
  ## hashing of OrderedSet
  assert s.isValid, "The set needs to be initialized."
  forAllOrderedPairs:
    result = result !& s.data[h].hcode
  result = !$result

iterator pairs*[A](s: OrderedSet[A]): tuple[a: int, b: A] =
  assert s.isValid, "The set needs to be initialized"
  forAllOrderedPairs:
    yield (idx, s.data[h].key)

proc rawGetKnownHC[A](s: OrderedSet[A], key: A, hc: Hash): int {.inline.} =
  rawGetKnownHCImpl()

proc rawGet[A](s: OrderedSet[A], key: A, hc: var Hash): int {.inline.} =
  rawGetImpl()

proc contains*[A](s: OrderedSet[A], key: A): bool =
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
  var hc: Hash
  var index = rawGet(s, key, hc)
  result = index >= 0

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

proc incl*[A](s: var OrderedSet[A], key: A) =
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

proc incl*[A](s: var HashSet[A], other: OrderedSet[A]) =
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

proc exclImpl[A](s: var OrderedSet[A], key: A) : bool {. inline .} =
  assert s.isValid, "The set needs to be initialized."
  var hc: Hash
  var i = rawGet(s, key, hc)
  var msk = high(s.data)
  result = true

  if i >= 0:
    result = false
    # Fix ordering
    if s.first == i:
      s.first = s.data[i].next
    else:
      var itr = s.first
      while true:
        if (s.data[itr].next == i):
          s.data[itr].next = s.data[i].next
          if s.last == i:
            s.last = itr
          break
        itr = s.data[itr].next

    dec(s.counter)
    while true:         # KnuthV3 Algo6.4R adapted for i=i+1 instead of i=i-1
      var j = i         # The correctness of this depends on (h+1) in nextTry,
      var r = j         # though may be adaptable to other simple sequences.
      s.data[i].hcode = 0              # mark current EMPTY
      s.data[i].key = default(type(s.data[i].key))
      s.data[i].next = 0
      doWhile((i >= r and r > j) or (r > j and j > i) or (j > i and i >= r)):
        i = (i + 1) and msk            # increment mod table size
        if isEmpty(s.data[i].hcode):   # end of collision cluster; So all done
          return
        r = s.data[i].hcode and msk    # "home" location of key@i
      shallowCopy(s.data[j], s.data[i]) # data[i] will be marked EMPTY next loop

proc missingOrExcl*[A](s: var OrderedSet[A], key: A): bool =
  ## Excludes `key` in the set `s` and tells if `key` was removed from `s`. Efficiency: O(n).
  ##
  ## The difference with regards to the `excl() <#excl,TOrderedSet[A],A>`_ proc is
  ## that this proc returns `true` if `key` was not present in `s`. Example:
  ##
  ## .. code-block::
  ##  var s = toOrderedSet([2, 3, 6, 7])
  ##  assert s.missingOrExcl(4) == true
  ##  assert s.missingOrExcl(6) == false
  exclImpl(s, key)


proc excl*[A](s: var OrderedSet[A], key: A) =
  ## Excludes `key` from the set `s`. Efficiency: O(n).
  ##
  ## This doesn't do anything if `key` is not found in `s`. Example:
  ##
  ## .. code-block::
  ##   var s = toOrderedSet([2, 3, 6, 7])
  ##   s.excl(2)
  ##   s.excl(2)
  ##   assert s.len == 3
  discard exclImpl(s, key)

proc containsOrIncl*[A](s: var OrderedSet[A], key: A): bool =
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

proc init*[A](s: var OrderedSet[A], initialSize=64) =
  ## Initializes an ordered hash set.
  ##
  ## The `initialSize` parameter needs to be a power of two. You can use
  ## `math.nextPowerOfTwo() <math.html#nextPowerOfTwo>`_ or `rightSize` to
  ## guarantee that at runtime. All set variables must be initialized before
  ## use with other procs from this module with the exception of `isValid()
  ## <#isValid,TOrderedSet[A]>`_ and `len() <#len,TOrderedSet[A]>`_.
  ##
  ## You can call this proc on a previously initialized ordered hash set to
  ## discard its values. At the moment this is the only proc to remove elements
  ## from an ordered hash set. Example:
  ##
  ## .. code-block ::
  ##   var a: OrderedSet[int]
  ##   a.init(4)
  ##   a.incl(2)
  ##   a.init
  ##   assert a.len == 0 and a.isValid
  assert isPowerOfTwo(initialSize)
  s.counter = 0
  s.first = -1
  s.last = -1
  newSeq(s.data, initialSize)

proc initOrderedSet*[A](initialSize=64): OrderedSet[A] =
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

proc toOrderedSet*[A](keys: openArray[A]): OrderedSet[A] =
  ## Creates a new ordered hash set that contains the given `keys`.
  ##
  ## Example:
  ##
  ## .. code-block::
  ##   var numbers = toOrderedSet([1, 2, 3, 4, 5])
  ##   assert numbers.contains(2)
  ##   assert numbers.contains(4)
  result = initOrderedSet[A](rightSize(keys.len))
  for key in items(keys): result.incl(key)

proc `$`*[A](s: OrderedSet[A]): string =
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

proc `==`*[A](s, t: OrderedSet[A]): bool =
  ## Equality for ordered sets.
  if s.counter != t.counter: return false
  var h = s.first
  var g = t.first
  var compared = 0
  while h >= 0 and g >= 0:
    var nxh = s.data[h].next
    var nxg = t.data[g].next
    if isFilled(s.data[h].hcode) and isFilled(t.data[g].hcode):
      if s.data[h].key == t.data[g].key:
        inc compared
      else:
        return false
    h = nxh
    g = nxg
  result = compared == s.counter

when isMainModule and not defined(release):
  proc testModule() =
    ## Internal micro test to validate docstrings and such.
    block isValidTest:
      var options: HashSet[string]
      proc savePreferences(options: HashSet[string]) =
        assert options.isValid, "Pass an initialized set!"
      options = initSet[string]()
      options.savePreferences

    block lenTest:
      var values: HashSet[int]
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
      var cards: OrderedSet[string]
      proc saveTarotCards(cards: OrderedSet[string]) =
        assert cards.isValid, "Pass an initialized set!"
      cards = initOrderedSet[string]()
      cards.saveTarotCards

    block lenTest:
      var values: OrderedSet[int]
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

    block setPairsIterator:
      var s = toOrderedSet([1, 3, 5, 7])
      var items = newSeq[tuple[a: int, b: int]]()
      for idx, item in s: items.add((idx, item))
      assert items == @[(0, 1), (1, 3), (2, 5), (3, 7)]

    block exclusions:
      var s = toOrderedSet([1, 2, 3, 6, 7, 4])

      s.excl(3)
      s.excl(3)
      s.excl(1)
      s.excl(4)

      var items = newSeq[int]()
      for item in s: items.add item
      assert items == @[2, 6, 7]

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
      assert(a == b) # https://github.com/Araq/Nim/issues/1413

    block initBlocks:
      var a: OrderedSet[int]
      a.init(4)
      a.incl(2)
      a.init
      assert a.len == 0 and a.isValid
      a = initOrderedSet[int](4)
      a.incl(2)
      assert a.len == 1

      var b: HashSet[int]
      b.init(4)
      b.incl(2)
      b.init
      assert b.len == 0 and b.isValid
      b = initSet[int](4)
      b.incl(2)
      assert b.len == 1

    for i in 0 .. 32:
      var s = rightSize(i)
      if s <= i or mustRehash(s, i):
        echo "performance issue: rightSize() will not elide enlarge() at ", i

    block missingOrExcl:
      var s = toOrderedSet([2, 3, 6, 7])
      assert s.missingOrExcl(4) == true
      assert s.missingOrExcl(6) == false

    block orderedSetEquality:
      type pair = tuple[a, b: int]

      var aa = initOrderedSet[pair]()
      var bb = initOrderedSet[pair]()

      var x = (a:1,b:2)
      var y = (a:3,b:4)

      aa.incl(x)
      aa.incl(y)

      bb.incl(x)
      bb.incl(y)
      assert aa == bb

    when not defined(testing):
      echo "Micro tests run successfully."

  testModule()
