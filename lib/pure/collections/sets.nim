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
## Common usages of sets:
## * removing duplicates from a container by converting it with `toHashSet proc
##   <#toHashSet,openArray[A]>`_ (see also `sequtils.deduplicate proc
##   <sequtils.html#deduplicate,openArray[T],bool>`_)
## * membership testing
## * mathematical operations on two sets, such as
##   `union <#union,HashSet[A],HashSet[A]>`_,
##   `intersection <#intersection,HashSet[A],HashSet[A]>`_,
##   `difference <#difference,HashSet[A],HashSet[A]>`_, and
##   `symmetric difference <#symmetricDifference,HashSet[A],HashSet[A]>`_
##
## .. code-block::
##   echo toHashSet([9, 5, 1])         # {9, 1, 5}
##   echo toOrderedSet([9, 5, 1])  # {9, 5, 1}
##
##   let
##     s1 = toHashSet([9, 5, 1])
##     s2 = toHashSet([3, 5, 7])
##
##   echo s1 + s2    # {9, 1, 3, 5, 7}
##   echo s1 - s2    # {1, 9}
##   echo s1 * s2    # {5}
##   echo s1 -+- s2  # {9, 1, 3, 7}
##
##
## Note: The data types declared here have *value semantics*: This means
## that ``=`` performs a copy of the set.
##
## **See also:**
## * `intsets module <intsets.html>`_ for efficient int sets
## * `tables module <tables.html>`_ for hash tables


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
  HashSet* {.myShallow.} [A] = object ## \
    ## A generic hash set.
    ##
    ## Use `init proc <#init,HashSet[A],int>`_ or `initHashSet proc <#initHashSet,int>`_
    ## before calling other procs on it.
    data: KeyValuePairSeq[A]
    counter: int


# ---------------------- helpers -----------------------------------

const growthFactor = 2

when not defined(nimHasDefault):
  template default[T](t: typedesc[T]): T =
    ## Used by clear methods to get a default value.
    var v: T
    v

# hcode for real keys cannot be zero.  hcode==0 signifies an empty slot.  These
# two procs retain clarity of that encoding without the space cost of an enum.
proc isEmpty(hcode: Hash): bool {.inline.} =
  result = hcode == 0

proc isFilled(hcode: Hash): bool {.inline.} =
  result = hcode != 0

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

template genHash(key: typed): Hash =
  var hc = hash(key)
  if hc == 0:       # This almost never taken branch should be very predictable.
    hc = 314159265  # Value doesn't matter; Any non-zero favorite is fine.
  hc

template rawGetImpl() {.dirty.} =
  hc = genHash(key)
  rawGetKnownHCImpl()

template rawInsertImpl() {.dirty.} =
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

proc mustRehash(length, counter: int): bool {.inline.} =
  assert(length > counter)
  result = (length * 2 < counter * 3) or (length - counter < 4)

template dollarImpl() {.dirty.} =
  result = "{"
  for key in items(s):
    if result.len > 1: result.add(", ")
    result.addQuoted(key)
  result.add("}")

proc rightSize*(count: Natural): int {.inline.}








# ---------------------------------------------------------------------
# ------------------------------ HashSet ------------------------------
# ---------------------------------------------------------------------


proc init*[A](s: var HashSet[A], initialSize=64) =
  ## Initializes a hash set.
  ##
  ## The `initialSize` parameter needs to be a power of two (default: 64).
  ## If you need to accept runtime values for this, you can use
  ## `math.nextPowerOfTwo proc <math.html#nextPowerOfTwo>`_ or `rightSize proc
  ## <#rightSize,Natural>`_ from this module.
  ##
  ## All set variables must be initialized before
  ## use with other procs from this module, with the exception of `isValid proc
  ## <#isValid,HashSet[A]>`_ and `len() <#len,HashSet[A]>`_.
  ##
  ## You can call this proc on a previously initialized hash set, which will
  ## discard all its values. This might be more convenient than iterating over
  ## existing values and calling `excl() <#excl,HashSet[A],A>`_ on them.
  ##
  ## See also:
  ## * `initHashSet proc <#initHashSet,int>`_
  ## * `toHashSet proc <#toHashSet,openArray[A]>`_
  runnableExamples:
    var a: HashSet[int]
    assert(not a.isValid)
    init(a)
    assert a.isValid

  assert isPowerOfTwo(initialSize)
  s.counter = 0
  newSeq(s.data, initialSize)

proc initHashSet*[A](initialSize=64): HashSet[A] =
  ## Wrapper around `init proc <#init,HashSet[A],int>`_ for initialization of
  ## hash sets.
  ##
  ## Returns an empty hash set you can assign directly in ``var`` blocks in a
  ## single line.
  ##
  ## See also:
  ## * `toHashSet proc <#toHashSet,openArray[A]>`_
  runnableExamples:
    var a = initHashSet[int]()
    assert a.isValid
    a.incl(3)
    assert len(a) == 1
  result.init(initialSize)

proc isValid*[A](s: HashSet[A]): bool =
  ## Returns `true` if the set has been initialized (with `initHashSet proc
  ## <#initHashSet,int>`_ or `init proc <#init,HashSet[A],int>`_).
  ##
  ## Most operations over an uninitialized set will crash at runtime and
  ## `assert <system.html#assert>`_ in debug builds. You can use this proc in
  ## your own procs to verify that sets passed to your procs are correctly
  ## initialized.
  ##
  ## **Examples:**
  ##
  ## .. code-block ::
  ##   proc savePreferences(options: HashSet[string]) =
  ##     assert options.isValid, "Pass an initialized set!"
  ##     # Do stuff here, may crash in release builds!
  result = s.data.len > 0

proc `[]`*[A](s: var HashSet[A], key: A): var A =
  ## Returns the element that is actually stored in `s` which has the same
  ## value as `key` or raises the ``KeyError`` exception.
  ##
  ## This is useful when one overloaded `hash` and `==` but still needs
  ## reference semantics for sharing.
  assert s.isValid, "The set needs to be initialized."
  var hc: Hash
  var index = rawGet(s, key, hc)
  if index >= 0: result = s.data[index].key
  else:
    when compiles($key):
      raise newException(KeyError, "key not found: " & $key)
    else:
      raise newException(KeyError, "key not found")

proc contains*[A](s: HashSet[A], key: A): bool =
  ## Returns true if `key` is in `s`.
  ##
  ## This allows the usage of `in` operator.
  ##
  ## See also:
  ## * `incl proc <#incl,HashSet[A],A>`_
  ## * `containsOrIncl proc <#containsOrIncl,HashSet[A],A>`_
  runnableExamples:
    var values = initHashSet[int]()
    assert(not values.contains(2))
    assert 2 notin values

    values.incl(2)
    assert values.contains(2)
    assert 2 in values

  assert s.isValid, "The set needs to be initialized."
  var hc: Hash
  var index = rawGet(s, key, hc)
  result = index >= 0

proc incl*[A](s: var HashSet[A], key: A) =
  ## Includes an element `key` in `s`.
  ##
  ## This doesn't do anything if `key` is already in `s`.
  ##
  ## See also:
  ## * `excl proc <#excl,HashSet[A],A>`_ for excluding an element
  ## * `incl proc <#incl,HashSet[A],HashSet[A]>`_ for including other set
  ## * `containsOrIncl proc <#containsOrIncl,HashSet[A],A>`_
  runnableExamples:
    var values = initHashSet[int]()
    values.incl(2)
    values.incl(2)
    assert values.len == 1

  assert s.isValid, "The set needs to be initialized."
  inclImpl()

proc incl*[A](s: var HashSet[A], other: HashSet[A]) =
  ## Includes all elements from `other` set into `s` (must be declared as `var`).
  ##
  ## This is the in-place version of `s + other <#+,HashSet[A],HashSet[A]>`_.
  ##
  ## See also:
  ## * `excl proc <#excl,HashSet[A],HashSet[A]>`_ for excluding other set
  ## * `incl proc <#incl,HashSet[A],A>`_ for including an element
  ## * `containsOrIncl proc <#containsOrIncl,HashSet[A],A>`_
  runnableExamples:
    var
      values = toHashSet([1, 2, 3])
      others = toHashSet([3, 4, 5])
    values.incl(others)
    assert values.len == 5

  assert s.isValid, "The set `s` needs to be initialized."
  assert other.isValid, "The set `other` needs to be initialized."
  for item in other: incl(s, item)

proc toHashSet*[A](keys: openArray[A]): HashSet[A] =
  ## Creates a new hash set that contains the members of the given
  ## collection (seq, array, or string) `keys`.
  ##
  ## Duplicates are removed.
  ##
  ## See also:
  ## * `initHashSet proc <#initHashSet,int>`_
  runnableExamples:
    let
      a = toHashSet([5, 3, 2])
      b = toHashSet("abracadabra")
    assert len(a) == 3
    ## a == {2, 3, 5}
    assert len(b) == 5
    ## b == {'a', 'b', 'c', 'd', 'r'}

  result = initHashSet[A](rightSize(keys.len))
  for key in items(keys): result.incl(key)

proc initSet*[A](initialSize=64): HashSet[A] {.deprecated:
     "Deprecated since v0.20, use `initHashSet`"} = initHashSet[A](initialSize)
  ## Deprecated since v0.20, use `initHashSet`.

proc toSet*[A](keys: openArray[A]): HashSet[A] {.deprecated:
     "Deprecated since v0.20, use `toHashSet`"} = toHashSet[A](keys)
  ## Deprecated since v0.20, use `toHashSet`.

iterator items*[A](s: HashSet[A]): A =
  ## Iterates over elements of the set `s`.
  ##
  ## If you need a sequence with the elelments you can use `sequtils.toSeq
  ## template <sequtils.html#toSeq.t,untyped>`_.
  ##
  ## .. code-block::
  ##   type
  ##     pair = tuple[a, b: int]
  ##   var
  ##     a, b = initHashSet[pair]()
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

proc containsOrIncl*[A](s: var HashSet[A], key: A): bool =
  ## Includes `key` in the set `s` and tells if `key` was already in `s`.
  ##
  ## The difference with regards to the `incl proc <#incl,HashSet[A],A>`_ is
  ## that this proc returns `true` if `s` already contained `key`. The
  ## proc will return `false` if `key` was added as a new value to `s` during
  ## this call.
  ##
  ## See also:
  ## * `incl proc <#incl,HashSet[A],A>`_ for including an element
  ## * `incl proc <#incl,HashSet[A],HashSet[A]>`_ for including other set
  ## * `missingOrExcl proc <#missingOrExcl,HashSet[A],A>`_
  runnableExamples:
    var values = initHashSet[int]()
    assert values.containsOrIncl(2) == false
    assert values.containsOrIncl(2) == true
    assert values.containsOrIncl(3) == false

  assert s.isValid, "The set needs to be initialized."
  containsOrInclImpl()

proc excl*[A](s: var HashSet[A], key: A) =
  ## Excludes `key` from the set `s`.
  ##
  ## This doesn't do anything if `key` is not found in `s`.
  ##
  ## See also:
  ## * `incl proc <#incl,HashSet[A],A>`_ for including an element
  ## * `excl proc <#excl,HashSet[A],HashSet[A]>`_ for excluding other set
  ## * `missingOrExcl proc <#missingOrExcl,HashSet[A],A>`_
  runnableExamples:
    var s = toHashSet([2, 3, 6, 7])
    s.excl(2)
    s.excl(2)
    assert s.len == 3
  discard exclImpl(s, key)

proc excl*[A](s: var HashSet[A], other: HashSet[A]) =
  ## Excludes all elements of `other` set from `s`.
  ##
  ## This is the in-place version of `s - other <#-,HashSet[A],HashSet[A]>`_.
  ##
  ## See also:
  ## * `incl proc <#incl,HashSet[A],HashSet[A]>`_ for including other set
  ## * `excl proc <#excl,HashSet[A],A>`_ for excluding an element
  ## * `missingOrExcl proc <#missingOrExcl,HashSet[A],A>`_
  runnableExamples:
    var
      numbers = toHashSet([1, 2, 3, 4, 5])
      even = toHashSet([2, 4, 6, 8])
    numbers.excl(even)
    assert len(numbers) == 3
    ## numbers == {1, 3, 5}

  assert s.isValid, "The set `s` needs to be initialized."
  assert other.isValid, "The set `other` needs to be initialized."
  for item in other: discard exclImpl(s, item)

proc missingOrExcl*[A](s: var HashSet[A], key: A): bool =
  ## Excludes `key` in the set `s` and tells if `key` was already missing from `s`.
  ##
  ## The difference with regards to the `excl proc <#excl,HashSet[A],A>`_ is
  ## that this proc returns `true` if `key` was missing from `s`.
  ## The proc will return `false` if `key` was in `s` and it was removed
  ## during this call.
  ##
  ## See also:
  ## * `excl proc <#excl,HashSet[A],A>`_ for excluding an element
  ## * `excl proc <#excl,HashSet[A],HashSet[A]>`_ for excluding other set
  ## * `containsOrIncl proc <#containsOrIncl,HashSet[A],A>`_
  runnableExamples:
    var s = toHashSet([2, 3, 6, 7])
    assert s.missingOrExcl(4) == true
    assert s.missingOrExcl(6) == false
    assert s.missingOrExcl(6) == true
  exclImpl(s, key)

proc pop*[A](s: var HashSet[A]): A =
  ## Remove and return an arbitrary element from the set `s`.
  ##
  ## Raises KeyError if the set `s` is empty.
  ##
  ## See also:
  ## * `clear proc <#clear,HashSet[A]>`_
  runnableExamples:
    var s = toHashSet([2, 1])
    assert s.pop == 1
    assert s.pop == 2
    doAssertRaises(KeyError, echo s.pop)

  for h in 0..high(s.data):
    if isFilled(s.data[h].hcode):
      result = s.data[h].key
      excl(s, result)
      return result
  raise newException(KeyError, "set is empty")

proc clear*[A](s: var HashSet[A]) =
  ## Clears the HashSet back to an empty state, without shrinking
  ## any of the existing storage.
  ##
  ## `O(n)` operation, where `n` is the size of the hash bucket.
  ##
  ## See also:
  ## * `pop proc <#pop,HashSet[A]>`_
  runnableExamples:
    var s = toHashSet([3, 5, 7])
    clear(s)
    assert len(s) == 0

  s.counter = 0
  for i in 0..<s.data.len:
    s.data[i].hcode = 0
    s.data[i].key = default(type(s.data[i].key))

proc len*[A](s: HashSet[A]): int =
  ## Returns the number of elements in `s`.
  ##
  ## Due to an implementation detail you can call this proc on variables which
  ## have not been initialized yet. The proc will return zero as the length
  ## then.
  runnableExamples:
    var a: HashSet[string]
    assert len(a) == 0
    let s = toHashSet([3, 5, 7])
    assert len(s) == 3
  result = s.counter

proc card*[A](s: HashSet[A]): int =
  ## Alias for `len() <#len,HashSet[A]>`_.
  ##
  ## Card stands for the `cardinality
  ## <http://en.wikipedia.org/wiki/Cardinality>`_ of a set.
  result = s.counter


proc union*[A](s1, s2: HashSet[A]): HashSet[A] =
  ## Returns the union of the sets `s1` and `s2`.
  ##
  ## The same as `s1 + s2 <#+,HashSet[A],HashSet[A]>`_.
  ##
  ## The union of two sets is represented mathematically as *A ∪ B* and is the
  ## set of all objects that are members of `s1`, `s2` or both.
  ##
  ## See also:
  ## * `intersection proc <#intersection,HashSet[A],HashSet[A]>`_
  ## * `difference proc <#difference,HashSet[A],HashSet[A]>`_
  ## * `symmetricDifference proc <#symmetricDifference,HashSet[A],HashSet[A]>`_
  runnableExamples:
    let
      a = toHashSet(["a", "b"])
      b = toHashSet(["b", "c"])
      c = union(a, b)
    assert c == toHashSet(["a", "b", "c"])

  assert s1.isValid, "The set `s1` needs to be initialized."
  assert s2.isValid, "The set `s2` needs to be initialized."
  result = s1
  incl(result, s2)

proc intersection*[A](s1, s2: HashSet[A]): HashSet[A] =
  ## Returns the intersection of the sets `s1` and `s2`.
  ##
  ## The same as `s1 * s2 <#*,HashSet[A],HashSet[A]>`_.
  ##
  ## The intersection of two sets is represented mathematically as *A ∩ B* and
  ## is the set of all objects that are members of `s1` and `s2` at the same
  ## time.
  ##
  ## See also:
  ## * `union proc <#union,HashSet[A],HashSet[A]>`_
  ## * `difference proc <#difference,HashSet[A],HashSet[A]>`_
  ## * `symmetricDifference proc <#symmetricDifference,HashSet[A],HashSet[A]>`_
  runnableExamples:
    let
      a = toHashSet(["a", "b"])
      b = toHashSet(["b", "c"])
      c = intersection(a, b)
    assert c == toHashSet(["b"])

  assert s1.isValid, "The set `s1` needs to be initialized."
  assert s2.isValid, "The set `s2` needs to be initialized."
  result = initHashSet[A](min(s1.data.len, s2.data.len))
  for item in s1:
    if item in s2: incl(result, item)

proc difference*[A](s1, s2: HashSet[A]): HashSet[A] =
  ## Returns the difference of the sets `s1` and `s2`.
  ##
  ## The same as `s1 - s2 <#-,HashSet[A],HashSet[A]>`_.
  ##
  ## The difference of two sets is represented mathematically as *A \ B* and is
  ## the set of all objects that are members of `s1` and not members of `s2`.
  ##
  ## See also:
  ## * `union proc <#union,HashSet[A],HashSet[A]>`_
  ## * `intersection proc <#intersection,HashSet[A],HashSet[A]>`_
  ## * `symmetricDifference proc <#symmetricDifference,HashSet[A],HashSet[A]>`_
  runnableExamples:
    let
      a = toHashSet(["a", "b"])
      b = toHashSet(["b", "c"])
      c = difference(a, b)
    assert c == toHashSet(["a"])

  assert s1.isValid, "The set `s1` needs to be initialized."
  assert s2.isValid, "The set `s2` needs to be initialized."
  result = initHashSet[A]()
  for item in s1:
    if not contains(s2, item):
      incl(result, item)

proc symmetricDifference*[A](s1, s2: HashSet[A]): HashSet[A] =
  ## Returns the symmetric difference of the sets `s1` and `s2`.
  ##
  ## The same as `s1 -+- s2 <#-+-,HashSet[A],HashSet[A]>`_.
  ##
  ## The symmetric difference of two sets is represented mathematically as *A △
  ## B* or *A ⊖ B* and is the set of all objects that are members of `s1` or
  ## `s2` but not both at the same time.
  ##
  ## See also:
  ## * `union proc <#union,HashSet[A],HashSet[A]>`_
  ## * `intersection proc <#intersection,HashSet[A],HashSet[A]>`_
  ## * `difference proc <#difference,HashSet[A],HashSet[A]>`_
  runnableExamples:
    let
      a = toHashSet(["a", "b"])
      b = toHashSet(["b", "c"])
      c = symmetricDifference(a, b)
    assert c == toHashSet(["a", "c"])

  assert s1.isValid, "The set `s1` needs to be initialized."
  assert s2.isValid, "The set `s2` needs to be initialized."
  result = s1
  for item in s2:
    if containsOrIncl(result, item): excl(result, item)

proc `+`*[A](s1, s2: HashSet[A]): HashSet[A] {.inline.} =
  ## Alias for `union(s1, s2) <#union,HashSet[A],HashSet[A]>`_.
  result = union(s1, s2)

proc `*`*[A](s1, s2: HashSet[A]): HashSet[A] {.inline.} =
  ## Alias for `intersection(s1, s2) <#intersection,HashSet[A],HashSet[A]>`_.
  result = intersection(s1, s2)

proc `-`*[A](s1, s2: HashSet[A]): HashSet[A] {.inline.} =
  ## Alias for `difference(s1, s2) <#difference,HashSet[A],HashSet[A]>`_.
  result = difference(s1, s2)

proc `-+-`*[A](s1, s2: HashSet[A]): HashSet[A] {.inline.} =
  ## Alias for `symmetricDifference(s1, s2)
  ## <#symmetricDifference,HashSet[A],HashSet[A]>`_.
  result = symmetricDifference(s1, s2)

proc disjoint*[A](s1, s2: HashSet[A]): bool =
  ## Returns `true` if the sets `s1` and `s2` have no items in common.
  runnableExamples:
    let
      a = toHashSet(["a", "b"])
      b = toHashSet(["b", "c"])
    assert disjoint(a, b) == false
    assert disjoint(a, b - a) == true

  assert s1.isValid, "The set `s1` needs to be initialized."
  assert s2.isValid, "The set `s2` needs to be initialized."
  for item in s1:
    if item in s2: return false
  return true

proc `<`*[A](s, t: HashSet[A]): bool =
  ## Returns true if `s` is a strict or proper subset of `t`.
  ##
  ## A strict or proper subset `s` has all of its members in `t` but `t` has
  ## more elements than `s`.
  runnableExamples:
    let
      a = toHashSet(["a", "b"])
      b = toHashSet(["b", "c"])
      c = intersection(a, b)
    assert c < a and c < b
    assert(not (a < a))
  s.counter != t.counter and s <= t

proc `<=`*[A](s, t: HashSet[A]): bool =
  ## Returns true if `s` is a subset of `t`.
  ##
  ## A subset `s` has all of its members in `t` and `t` doesn't necessarily
  ## have more members than `s`. That is, `s` can be equal to `t`.
  runnableExamples:
    let
      a = toHashSet(["a", "b"])
      b = toHashSet(["b", "c"])
      c = intersection(a, b)
    assert c <= a and c <= b
    assert a <= a

  result = false
  if s.counter > t.counter: return
  result = true
  for item in items(s):
    if not(t.contains(item)):
      result = false
      return

proc `==`*[A](s, t: HashSet[A]): bool =
  ## Returns true if both `s` and `t` have the same members and set size.
  runnableExamples:
    var
      a = toHashSet([1, 2])
      b = toHashSet([2, 1])
    assert a == b
  s.counter == t.counter and s <= t

proc map*[A, B](data: HashSet[A], op: proc (x: A): B {.closure.}): HashSet[B] =
  ## Returns a new set after applying `op` pric on each of the elements of
  ##`data` set.
  ##
  ## You can use this proc to transform the elements from a set.
  runnableExamples:
    let
      a = toHashSet([1, 2, 3])
      b = a.map(proc (x: int): string = $x)
    assert b == toHashSet(["1", "2", "3"])

  result = initHashSet[B]()
  for item in items(data): result.incl(op(item))

proc hash*[A](s: HashSet[A]): Hash =
  ## Hashing of HashSet.
  assert s.isValid, "The set needs to be initialized."
  for h in 0..high(s.data):
    result = result xor s.data[h].hcode
  result = !$result

proc `$`*[A](s: HashSet[A]): string =
  ## Converts the set `s` to a string, mostly for logging and printing purposes.
  ##
  ## Don't use this proc for serialization, the representation may change at
  ## any moment and values are not escaped.
  ##
  ## **Examples:**
  ##
  ## .. code-block::
  ##   echo toHashSet([2, 4, 5])
  ##   # --> {2, 4, 5}
  ##   echo toHashSet(["no", "esc'aping", "is \" provided"])
  ##   # --> {no, esc'aping, is " provided}
  assert s.isValid, "The set needs to be initialized."
  dollarImpl()

proc rightSize*(count: Natural): int {.inline.} =
  ## Return the value of `initialSize` to support `count` items.
  ##
  ## If more items are expected to be added, simply add that
  ## expected extra amount to the parameter before calling this.
  ##
  ## Internally, we want `mustRehash(rightSize(x), x) == false`.
  result = nextPowerOfTwo(count * 3 div 2  +  4)







# ---------------------------------------------------------------------
# --------------------------- OrderedSet ------------------------------
# ---------------------------------------------------------------------

type
  OrderedKeyValuePair[A] = tuple[
    hcode: Hash, next: int, key: A]
  OrderedKeyValuePairSeq[A] = seq[OrderedKeyValuePair[A]]
  OrderedSet* {.myShallow.} [A] = object ## \
    ## A generic hash set that remembers insertion order.
    ##
    ## Use `init proc <#init,OrderedSet[A],int>`_ or `initOrderedSet proc
    ## <#initOrderedSet,int>`_ before calling other procs on it.
    data: OrderedKeyValuePairSeq[A]
    counter, first, last: int


# ---------------------- helpers -----------------------------------

template forAllOrderedPairs(yieldStmt: untyped) {.dirty.} =
  var h = s.first
  var idx = 0
  while h >= 0:
    var nxt = s.data[h].next
    if isFilled(s.data[h].hcode):
      yieldStmt
      inc(idx)
    h = nxt

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

proc isValid*[A](s: OrderedSet[A]): bool

proc exclImpl[A](s: var OrderedSet[A], key: A) : bool {. inline .} =
  assert s.isValid, "The set needs to be initialized."
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



# -----------------------------------------------------------------------



proc init*[A](s: var OrderedSet[A], initialSize=64) =
  ## Initializes an ordered hash set.
  ##
  ## The `initialSize` parameter needs to be a power of two (default: 64).
  ## If you need to accept runtime values for this, you can use
  ## `math.nextPowerOfTwo proc <math.html#nextPowerOfTwo>`_ or `rightSize proc
  ## <#rightSize,Natural>`_ from this module.
  ##
  ## All set variables must be initialized before
  ## use with other procs from this module, with the exception of `isValid proc
  ## <#isValid,HashSet[A]>`_ and `len() <#len,HashSet[A]>`_.
  ##
  ## You can call this proc on a previously initialized hash set, which will
  ## discard all its values. This might be more convenient than iterating over
  ## existing values and calling `excl() <#excl,HashSet[A],A>`_ on them.
  ##
  ## See also:
  ## * `initOrderedSet proc <#initOrderedSet,int>`_
  ## * `toOrderedSet proc <#toOrderedSet,openArray[A]>`_
  runnableExamples:
    var a: OrderedSet[int]
    assert(not a.isValid)
    init(a)
    assert a.isValid

  assert isPowerOfTwo(initialSize)
  s.counter = 0
  s.first = -1
  s.last = -1
  newSeq(s.data, initialSize)

proc initOrderedSet*[A](initialSize=64): OrderedSet[A] =
  ## Wrapper around `init proc <#init,OrderedSet[A],int>`_ for initialization of
  ## ordered hash sets.
  ##
  ## Returns an empty ordered hash set you can assign directly in ``var`` blocks
  ## in a single line.
  ##
  ## See also:
  ## * `toOrderedSet proc <#toOrderedSet,openArray[A]>`_
  runnableExamples:
    var a = initOrderedSet[int]()
    assert a.isValid
    a.incl(3)
    assert len(a) == 1
  result.init(initialSize)

proc toOrderedSet*[A](keys: openArray[A]): OrderedSet[A] =
  ## Creates a new hash set that contains the members of the given
  ## collection (seq, array, or string) `keys`.
  ##
  ## Duplicates are removed.
  ##
  ## See also:
  ## * `initOrderedSet proc <#initOrderedSet,int>`_
  runnableExamples:
    let
      a = toOrderedSet([5, 3, 2])
      b = toOrderedSet("abracadabra")
    assert len(a) == 3
    ## a == {5, 3, 2} # different than in HashSet
    assert len(b) == 5
    ## b == {'a', 'b', 'r', 'c', 'd'} # different than in HashSet

  result = initOrderedSet[A](rightSize(keys.len))
  for key in items(keys): result.incl(key)

proc isValid*[A](s: OrderedSet[A]): bool =
  ## Returns `true` if the set has been initialized (with `initHashSet proc
  ## <#initOrderedSet,int>`_ or `init proc <#init,OrderedSet[A],int>`_).
  ##
  ## Most operations over an uninitialized set will crash at runtime and
  ## `assert <system.html#assert>`_ in debug builds. You can use this proc in
  ## your own procs to verify that sets passed to your procs are correctly
  ## initialized.
  ##
  ## **Examples:**
  ##
  ## .. code-block ::
  ##   proc savePreferences(options: OrderedSet[string]) =
  ##     assert options.isValid, "Pass an initialized set!"
  ##     # Do stuff here, may crash in release builds!
  result = s.data.len > 0

proc contains*[A](s: OrderedSet[A], key: A): bool =
  ## Returns true if `key` is in `s`.
  ##
  ## This allows the usage of `in` operator.
  ##
  ## See also:
  ## * `incl proc <#incl,OrderedSet[A],A>`_
  ## * `containsOrIncl proc <#containsOrIncl,OrderedSet[A],A>`_
  runnableExamples:
    var values = initOrderedSet[int]()
    assert(not values.contains(2))
    assert 2 notin values

    values.incl(2)
    assert values.contains(2)
    assert 2 in values

  assert s.isValid, "The set needs to be initialized."
  var hc: Hash
  var index = rawGet(s, key, hc)
  result = index >= 0

proc incl*[A](s: var OrderedSet[A], key: A) =
  ## Includes an element `key` in `s`.
  ##
  ## This doesn't do anything if `key` is already in `s`.
  ##
  ## See also:
  ## * `excl proc <#excl,OrderedSet[A],A>`_ for excluding an element
  ## * `incl proc <#incl,HashSet[A],OrderedSet[A]>`_ for including other set
  ## * `containsOrIncl proc <#containsOrIncl,OrderedSet[A],A>`_
  runnableExamples:
    var values = initOrderedSet[int]()
    values.incl(2)
    values.incl(2)
    assert values.len == 1

  assert s.isValid, "The set needs to be initialized."
  inclImpl()

proc incl*[A](s: var HashSet[A], other: OrderedSet[A]) =
  ## Includes all elements from the OrderedSet `other` into
  ## HashSet `s` (must be declared as `var`).
  ##
  ## See also:
  ## * `incl proc <#incl,OrderedSet[A],A>`_ for including an element
  ## * `containsOrIncl proc <#containsOrIncl,OrderedSet[A],A>`_
  runnableExamples:
    var
      values = toHashSet([1, 2, 3])
      others = toOrderedSet([3, 4, 5])
    values.incl(others)
    assert values.len == 5
  assert s.isValid, "The set `s` needs to be initialized."
  assert other.isValid, "The set `other` needs to be initialized."
  for item in items(other): incl(s, item)

proc containsOrIncl*[A](s: var OrderedSet[A], key: A): bool =
  ## Includes `key` in the set `s` and tells if `key` was already in `s`.
  ##
  ## The difference with regards to the `incl proc <#incl,OrderedSet[A],A>`_ is
  ## that this proc returns `true` if `s` already contained `key`. The
  ## proc will return false if `key` was added as a new value to `s` during
  ## this call.
  ##
  ## See also:
  ## * `incl proc <#incl,OrderedSet[A],A>`_ for including an element
  ## * `missingOrExcl proc <#missingOrExcl,OrderedSet[A],A>`_
  runnableExamples:
    var values = initOrderedSet[int]()
    assert values.containsOrIncl(2) == false
    assert values.containsOrIncl(2) == true
    assert values.containsOrIncl(3) == false

  assert s.isValid, "The set needs to be initialized."
  containsOrInclImpl()

proc excl*[A](s: var OrderedSet[A], key: A) =
  ## Excludes `key` from the set `s`. Efficiency: `O(n)`.
  ##
  ## This doesn't do anything if `key` is not found in `s`.
  ##
  ## See also:
  ## * `incl proc <#incl,OrderedSet[A],A>`_ for including an element
  ## * `missingOrExcl proc <#missingOrExcl,OrderedSet[A],A>`_
  runnableExamples:
    var s = toOrderedSet([2, 3, 6, 7])
    s.excl(2)
    s.excl(2)
    assert s.len == 3
  discard exclImpl(s, key)

proc missingOrExcl*[A](s: var OrderedSet[A], key: A): bool =
  ## Excludes `key` in the set `s` and tells if `key` was already missing from `s`.
  ## Efficiency: O(n).
  ##
  ## The difference with regards to the `excl proc <#excl,OrderedSet[A],A>`_ is
  ## that this proc returns `true` if `key` was missing from `s`.
  ## The proc will return `false` if `key` was in `s` and it was removed
  ## during this call.
  ##
  ## See also:
  ## * `excl proc <#excl,OrderedSet[A],A>`_
  ## * `containsOrIncl proc <#containsOrIncl,OrderedSet[A],A>`_
  runnableExamples:
    var s = toOrderedSet([2, 3, 6, 7])
    assert s.missingOrExcl(4) == true
    assert s.missingOrExcl(6) == false
    assert s.missingOrExcl(6) == true
  exclImpl(s, key)

proc clear*[A](s: var OrderedSet[A]) =
  ## Clears the OrderedSet back to an empty state, without shrinking
  ## any of the existing storage.
  ##
  ## `O(n)` operation where `n` is the size of the hash bucket.
  runnableExamples:
    var s = toOrderedSet([3, 5, 7])
    clear(s)
    assert len(s) == 0

  s.counter = 0
  s.first = -1
  s.last = -1
  for i in 0..<s.data.len:
    s.data[i].hcode = 0
    s.data[i].next = 0
    s.data[i].key = default(type(s.data[i].key))

proc len*[A](s: OrderedSet[A]): int {.inline.} =
  ## Returns the number of elements in `s`.
  ##
  ## Due to an implementation detail you can call this proc on variables which
  ## have not been initialized yet. The proc will return zero as the length
  ## then.
  runnableExamples:
    var a: OrderedSet[string]
    assert len(a) == 0
    let s = toHashSet([3, 5, 7])
    assert len(s) == 3
  result = s.counter

proc card*[A](s: OrderedSet[A]): int {.inline.} =
  ## Alias for `len() <#len,OrderedSet[A]>`_.
  ##
  ## Card stands for the `cardinality
  ## <http://en.wikipedia.org/wiki/Cardinality>`_ of a set.
  result = s.counter

proc `==`*[A](s, t: OrderedSet[A]): bool =
  ## Equality for ordered sets.
  runnableExamples:
    let
      a = toOrderedSet([1, 2])
      b = toOrderedSet([2, 1])
    assert(not (a == b))

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

proc hash*[A](s: OrderedSet[A]): Hash =
  ## Hashing of OrderedSet.
  assert s.isValid, "The set needs to be initialized."
  forAllOrderedPairs:
    result = result !& s.data[h].hcode
  result = !$result

proc `$`*[A](s: OrderedSet[A]): string =
  ## Converts the ordered hash set `s` to a string, mostly for logging and
  ## printing purposes.
  ##
  ## Don't use this proc for serialization, the representation may change at
  ## any moment and values are not escaped.
  ##
  ## **Examples:**
  ##
  ## .. code-block::
  ##   echo toOrderedSet([2, 4, 5])
  ##   # --> {2, 4, 5}
  ##   echo toOrderedSet(["no", "esc'aping", "is \" provided"])
  ##   # --> {no, esc'aping, is " provided}
  assert s.isValid, "The set needs to be initialized."
  dollarImpl()



iterator items*[A](s: OrderedSet[A]): A =
  ## Iterates over keys in the ordered set `s` in insertion order.
  ##
  ## If you need a sequence with the elelments you can use `sequtils.toSeq
  ## template <sequtils.html#toSeq.t,untyped>`_.
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


iterator pairs*[A](s: OrderedSet[A]): tuple[a: int, b: A] =
  ## Iterates through (position, value) tuples of OrderedSet `s`.
  runnableExamples:
    let a = toOrderedSet("abracadabra")
    var p = newSeq[(int, char)]()
    for x in pairs(a):
      p.add(x)
    assert p == @[(0, 'a'), (1, 'b'), (2, 'r'), (3, 'c'), (4, 'd')]

  assert s.isValid, "The set needs to be initialized"
  forAllOrderedPairs:
    yield (idx, s.data[h].key)



# -----------------------------------------------------------------------



when isMainModule and not defined(release):
  proc testModule() =
    ## Internal micro test to validate docstrings and such.
    block isValidTest:
      var options: HashSet[string]
      proc savePreferences(options: HashSet[string]) =
        assert options.isValid, "Pass an initialized set!"
      options = initHashSet[string]()
      options.savePreferences

    block lenTest:
      var values: HashSet[int]
      assert(not values.isValid)
      assert values.len == 0
      assert values.card == 0

    block setIterator:
      type pair = tuple[a, b: int]
      var a, b = initHashSet[pair]()
      a.incl((2, 3))
      a.incl((3, 2))
      a.incl((2, 3))
      for x, y in a.items:
        b.incl((x - 2, y + 1))
      assert a.len == b.card
      assert a.len == 2
      #echo b

    block setContains:
      var values = initHashSet[int]()
      assert(not values.contains(2))
      values.incl(2)
      assert values.contains(2)
      values.excl(2)
      assert(not values.contains(2))

      values.incl(4)
      var others = toHashSet([6, 7])
      values.incl(others)
      assert values.len == 3

      values.init
      assert values.containsOrIncl(2) == false
      assert values.containsOrIncl(2) == true
      var
        a = toHashSet([1, 2])
        b = toHashSet([1])
      b.incl(2)
      assert a == b

    block exclusions:
      var s = toHashSet([2, 3, 6, 7])
      s.excl(2)
      s.excl(2)
      assert s.len == 3

      var
        numbers = toHashSet([1, 2, 3, 4, 5])
        even = toHashSet([2, 4, 6, 8])
      numbers.excl(even)
      #echo numbers
      # --> {1, 3, 5}

    block toSeqAndString:
      var a = toHashSet([2, 4, 5])
      var b = initHashSet[int]()
      for x in [2, 4, 5]: b.incl(x)
      assert($a == $b)
      #echo a
      #echo toHashSet(["no", "esc'aping", "is \" provided"])

    #block orderedToSeqAndString:
    #  echo toOrderedSet([2, 4, 5])
    #  echo toOrderedSet(["no", "esc'aping", "is \" provided"])

    block setOperations:
      var
        a = toHashSet(["a", "b"])
        b = toHashSet(["b", "c"])
        c = union(a, b)
      assert c == toHashSet(["a", "b", "c"])
      var d = intersection(a, b)
      assert d == toHashSet(["b"])
      var e = difference(a, b)
      assert e == toHashSet(["a"])
      var f = symmetricDifference(a, b)
      assert f == toHashSet(["a", "c"])
      assert d < a and d < b
      assert((a < a) == false)
      assert d <= a and d <= b
      assert((a <= a))
      # Alias test.
      assert a + b == toHashSet(["a", "b", "c"])
      assert a * b == toHashSet(["b"])
      assert a - b == toHashSet(["a"])
      assert a -+- b == toHashSet(["a", "c"])
      assert disjoint(a, b) == false
      assert disjoint(a, b - a) == true

    block mapSet:
      var a = toHashSet([1, 2, 3])
      var b = a.map(proc (x: int): string = $x)
      assert b == toHashSet(["1", "2", "3"])

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

    block: #9005
      var s = initOrderedSet[(int, int)]()
      for i in 0 .. 30: incl(s, (i, 0))
      for i in 0 .. 30: excl(s, (i, 0))
      doAssert s.len == 0

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
      b = initHashSet[int](4)
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
