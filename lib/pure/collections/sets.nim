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
##   `union <#union,SomeSet[A],SomeSet[A]>`_,
##   `intersection <#intersection,SomeSet[A],SomeSet[A]>`_,
##   `difference <#difference,SomeSet[A],SomeSet[A]>`_, and
##   `symmetric difference <#symmetricDifference,SomeSet[A],SomeSet[A]>`_
##
## .. code-block::
##   echo toHashSet([9, 5, 1])     # {9, 1, 5}
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
  hashes, math, concepts

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
  HashSet*[A] {.myShallow.} = object ## \
    ## A generic hash set.
    ##
    ## Use `init proc <#init,SomeSet[A],int>`_ or `initHashSet proc <#initHashSet,int>`_
    ## for initialization with some initial size.
    data: KeyValuePairSeq[A]
    counter: int

type
  OrderedKeyValuePair[A] = tuple[
    hcode: Hash, next: int, key: A]
  OrderedKeyValuePairSeq[A] = seq[OrderedKeyValuePair[A]]
  OrderedSet*[A] {.myShallow.} = object ## \
    ## A generic hash set that remembers insertion order.
    ##
    ## See `init proc <#init,SomeSet[A],int>`_ or `initOrderedSet proc
    ## <#initOrderedSet,int>`_ for initialization with some initial size.
    data: OrderedKeyValuePairSeq[A]
    counter, first, last: int

type
  SomeSet*[A] = HashSet[A] | OrderedSet[A]
    ## A union type representing `HashSet` or `OrderedSet` used in generic set
    ## procedure interfaces.

const
  defaultInitialSize* = 64

include setimpl

# ---------------------------------------------------------------------
# ------------------------ Forward declarations -----------------------
# ---------------------------------------------------------------------

proc init*[A](s: var SomeSet[A], initialSize: int = defaultInitialSize)
proc incl*[A, B](s: var SomeSet[A], key: B)

# ---------------------------------------------------------------------
# ------------------------------ HashSet ------------------------------
# ---------------------------------------------------------------------

proc initHashSet*[A](initialSize: int = defaultInitialSize): HashSet[A] =
  ## Wrapper around `init proc <#init,SomeSet[A],int>`_ for initialization of
  ## sets.
  ##
  ## Returns an empty hash set you can assign directly in ``var`` blocks in a
  ## single line.
  ##
  ## Starting from Nim v0.20, sets are initialized by default and it is
  ## not necessary to call this function explicitly.
  ##
  ## See also:
  ## * `toHashSet proc <#toHashSet,openArray[A]>`_ from `openArray[A]`
  ## * `toHashSet proc <#toHashSet,IterableLen[A]>`_ from any iterable sequence
  ##   having a `len` procedure
  runnableExamples:
    var a = initHashSet[int]()
    a.incl(3)
    assert len(a) == 1

  result.init(initialSize)

proc toHashSet*[A](keys: openArray[A]): HashSet[A] =
  ## Creates a new hash set that contains the members of the given
  ## collection (seq, array, or string) `keys`.
  ##
  ## Duplicates are removed.
  ##
  ## See also:
  ## * `initHashSet proc <#initHashSet,int>`_
  ## * `toHashSet proc <#toHashSet,IterableLen[A]>`_
  ## * `toOrderedSet proc <#toOrderedSet,openArray[A]>`_
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

proc toHashSet*[A](keys: IterableLen[A]): HashSet[A] =
  ## Creates a new hash set that contains the members of the given iterable
  ## sequence `keys`.
  ##
  ## Duplicates are removed.
  ##
  ## See also:
  ## * `initHashSet proc <#initHashSet,int>`_
  ## * `toHashSet proc <#toHashSet,openArray[A]>`_
  ## * `toOrderedSet proc <#toOrderedSet,IterableLen[A]>`_
  runnableExamples:
    let
      a = toHashSet(toHashSet([5, 3, 2]))
      b = toHashSet(toOrderedSet("abracadabra"))
    assert len(a) == 3
    ## a == {2, 3, 5}
    assert len(b) == 5
    ## b == {'a', 'b', 'c', 'd', 'r'}

  result = initHashSet[A](rightSize(keys.len))
  for key in items(keys): result.incl(key)

proc map*[A, B](data: HashSet[A], op: proc (x: A): B {.closure.}): HashSet[B] =
  ## Returns a new set after applying `op` proc on each of the elements of
  ##`data` set.
  ##
  ## You can use this proc to transform the elements from a set.
  ## 
  ## **See also:**
  ## * `map proc <#map,OrderedSet[A],proc(A)>`_ for `OrderedSet`
  runnableExamples:
    let
      a = toHashSet([1, 2, 3])
      b = a.map(proc (x: int): string = $x)
    assert b == toHashSet(["1", "2", "3"])

  for item in items(data): result.incl(op(item))

proc initSet*[A](initialSize = defaultInitialSize): HashSet[A] {.deprecated:
     "Deprecated since v0.20, use 'initHashSet'".} = initHashSet[A](initialSize)

proc toSet*[A](keys: openArray[A]): HashSet[A] {.deprecated:
     "Deprecated since v0.20, use 'toHashSet'".} = toHashSet[A](keys)

# ---------------------------------------------------------------------
# --------------------------- OrderedSet ------------------------------
# ---------------------------------------------------------------------

proc initOrderedSet*[A](initialSize: int = defaultInitialSize): OrderedSet[A] =
  ## Wrapper around `init proc <#init,SomeSet[A],int>`_ for initialization of
  ## ordered hash sets.
  ##
  ## Returns an empty ordered hash set you can assign directly in ``var`` blocks
  ## in a single line.
  ##
  ## Starting from Nim v0.20, sets are initialized by default and it is
  ## not necessary to call this function explicitly.
  ##
  ## See also:
  ## * `toOrderedSet proc <#toOrderedSet,openArray[A]>`_ from `openArray[A]`
  ## * `toOrderedSet proc <#toOrderedSet,IterableLen[A]>`_ from any iterable
  ##   sequence having a `len` procedure
  runnableExamples:
    var a = initOrderedSet[int]()
    a.incl(3)
    assert len(a) == 1

  result.init(initialSize)

proc isValid*[A](s: SomeSet[A]): bool {.deprecated:
     "Deprecated since v0.20; sets are initialized by default".} =
  ## Returns `true` if the set has been initialized (with `initHashSet proc
  ## <#initHashSet,int>`_, `initOrderedSet proc <#initOrderedSet,int>`_, or
  ## `init proc <#init,SomeSet[A],int>`_).
  ##
  ## **Examples:**
  ##
  ## .. code-block ::
  ##   proc savePreferences(options: HashSet[string]) =
  ##     assert options.isValid, "Pass an initialized set!"
  ##     # Do stuff here, may crash in release builds!
  result = s.data.len > 0

proc toOrderedSet*[A](keys: openArray[A]): OrderedSet[A] =
  ## Creates a new ordered set that contains the members of the given
  ## collection (seq, array, or string) `keys`.
  ##
  ## Duplicates are removed.
  ##
  ## See also:
  ## * `initOrderedSet proc <#initOrderedSet,int>`_
  ## * `toHashSet proc <#toHashSet,openArray[A]>`_
  ## * `toOrderedSet proc <#toOrderedSet,IterableLen[A]>`_
  runnableExamples:
    let
      a = toOrderedSet([5, 3, 2])
      b = toOrderedSet("abracadabra")
    assert len(a) == 3
    ## a == {5, 3, 2} # different than in HashSet
    assert len(b) == 5
    ## b == {'a', 'b', 'r', 'c', 'd'} # different than in HashSet

  result.init(rightSize(keys.len))
  for key in items(keys): result.incl(key)

proc toOrderedSet*[A](keys: IterableLen[A]): OrderedSet[A] =
  ## Creates a new ordered set that contains the members of the given iterable
  ## sequence `keys`.
  ##
  ## Duplicates are removed.
  ##
  ## See also:
  ## * `initOrderedSet proc <#initOrderedSet,int>`_
  ## * `toHashSet proc <#toHashSet,IterableLen[A]>`_
  ## * `toOrderedSet proc <#toOrderedSet,openArray[A]>`_
  runnableExamples:
    let
      a = toOrderedSet(toHashSet([5, 3, 2]))
      b = toOrderedSet(toOrderedSet("abracadabra"))
    assert len(a) == 3
    ## a == {2, 3, 5} # like in HashSet
    assert len(b) == 5
    ## b == {'a', 'b', 'r', 'c', 'd'} # different than in HashSet

  result.init(rightSize(keys.len))
  for key in items(keys): result.incl(key)

proc map*[A, B](data: OrderedSet[A], op: proc (x: A): B {.closure.}):
    OrderedSet[B] =
  ## Returns a new set after applying `op` proc on each of the elements of
  ##`data` set.
  ##
  ## You can use this proc to transform the elements from a set.
  ## 
  ## **See also:**
  ## * `map proc <#map,HashSet[A],proc(A)>`_ for `HashSet`
  runnableExamples:
    let
      a = toOrderedSet([1, 2, 3])
      b = a.map(proc (x: int): string = $x)
    assert b == toOrderedSet(["1", "2", "3"])

  for item in items(data): result.incl(op(item))

# ---------------------------------------------------------------------
# --------------------------- SomeSet ------------------------------
# ---------------------------------------------------------------------

proc init*[A](s: var SomeSet[A], initialSize: int = defaultInitialSize) =
  ## Initializes a set.
  ##
  ## The `initialSize` parameter needs to be a power of two (default: 64).
  ## If you need to accept runtime values for this, you can use
  ## `math.nextPowerOfTwo proc <math.html#nextPowerOfTwo,int>`_ or
  ## `rightSize proc <#rightSize,Natural>`_ from this module.
  ##
  ## Starting from Nim v0.20, sets are initialized by default and it is
  ## not necessary to call this function explicitly.
  ##
  ## You can call this proc on a previously initialized set, which will
  ## discard all its values. This might be more convenient than iterating over
  ## existing values and calling `excl() <#excl,SomeSet[A],A>`_ on them.
  ##
  ## See also:
  ## * `initHashSet proc <#initHashSet,int>`_
  ## * `initOrderedSet proc <#initOrderedSet,int>`_
  ## * `toHashSet proc <#toHashSet,openArray[A]>`_ from `openArray[A]`
  ## * `toHashSet proc <#toHashSet,IterableLen[A]>`_ from any iterable sequence
  ##   having a `len` procedure
  ## * `toOrderedSet proc <#toOrderedSet,openArray[A]>`_ from `openArray[A]`
  ## * `toOrderedSet proc <#toOrderedSet,IterableLen[A]>`_ from any iterable
  ##   sequence having a `len` procedure
  runnableExamples:
    var a: HashSet[int]
    assert(not a.isValid)
    init(a)

  initImpl(s, initialSize)

proc `[]`*[A](s: var SomeSet[A], key: A): var A =
  ## Returns the element that is actually stored in `s` which has the same
  ## value as `key` or raises the ``KeyError`` exception.
  ##
  ## This is useful when one overloaded `hash` and `==` but still needs
  ## reference semantics for sharing.
  ##
  ## See also:
  ## * `[] <#[],SomeSet[A],A>`_
  getEx()

proc `[]`*[A](s: SomeSet[A], key: A): A =
  ## Returns the element that is actually stored in `s` which has the same
  ## value as `key` or raises the ``KeyError`` exception.
  ##
  ## This is useful when one overloaded `hash` and `==` but still needs
  ## reference semantics for sharing.
  ##
  ## See also:
  ## * `[] <#[],var SomeSet[A],A>`_
  getEx()

proc contains*[A](s: SomeSet[A], key: A): bool =
  ## Returns true if `key` is in `s`.
  ##
  ## This allows the usage of `in` operator.
  ##
  ## See also:
  ## * `incl proc <#incl,SomeSet[A],B>`_ for including an element or iterable
  ##   sequence of elements
  ## * `containsOrIncl proc <#containsOrIncl,SomeSet[A],A>`_
  runnableExamples:
    var values = initHashSet[int]()
    assert(not values.contains(2))
    assert 2 notin values

    values.incl(2)
    assert values.contains(2)
    assert 2 in values

  var hc: Hash
  var index = rawGet(s, key, hc)
  result = index >= 0

proc incl*[A, B](s: var SomeSet[A], key: B) =
  ## `key` must be of type `A` or `Iterable[A]`. Includes an element `key` or
  ## all items of `key` in the set `s`.
  ##
  ## This doesn't do anything if `key` is already in `s`.
  ##
  ## See also:
  ## * `excl proc <#excl,SomeSet[A],B>`_ for excluding an element or iterable
  ##   sequence of elements.
  ## * `containsOrIncl proc <#containsOrIncl,SomeSet[A],A>`_
  runnableExamples:
    var values = initHashSet[int]()
    values.incl(2)
    values.incl(2)
    assert values.len == 1

  when key is A:
    inclImpl()
  elif key is Iterable[A]:
    for item in items(key): incl(s, item)
  else:
    {.fatal: "The type of `key` must be the type of the set elements or " &
             "`Iterable` from it.".}

iterator items*[A](s: SomeSet[A]): A =
  ## Iterates over elements of the set `s`.
  ##
  ## If you need a sequence with the elements you can use `sequtils.toSeq
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

  when s is HashSet[A]:
    hashSetItemsImpl()
  elif s is OrderedSet[A]:
    orderedSetItemsImpl()
  else:
    {.fatal: "The type of `key` must be the type of the set elements or " &
             "`Iterable` from it.".}

iterator pairs*[A](s: SomeSet[A]): tuple[a: int, b: A] =
  ## Iterates through (position, value) tuples of set `s`.
  runnableExamples:
    let a = toOrderedSet("abracadabra")
    var p = newSeq[(int, char)]()
    for x in pairs(a):
      p.add(x)
    assert p == @[(0, 'a'), (1, 'b'), (2, 'r'), (3, 'c'), (4, 'd')]

  when s is HashSet[A]:
    hashSetPairsImpl()
  elif s is OrderedSet[A]:
    orderedSetPairsImpl()
  else:
    {.fatal: "Unknown set type."}

proc containsOrIncl*[A](s: var SomeSet[A], key: A): bool =
  ## Includes `key` in the set `s` and tells if `key` was already in `s`.
  ##
  ## The difference with regards to the `incl proc <#incl,SomeSet[A],B>`_ is
  ## that this proc returns `true` if `s` already contained `key`. The
  ## proc will return `false` if `key` was added as a new value to `s` during
  ## this call.
  ##
  ## See also:
  ## * `incl proc <#incl,SomeSet[A],B>`_ for including an element or iterable
  ##   sequence of elements
  ## * `missingOrExcl proc <#missingOrExcl,SomeSet[A],A>`_
  runnableExamples:
    var values = initHashSet[int]()
    assert values.containsOrIncl(2) == false
    assert values.containsOrIncl(2) == true
    assert values.containsOrIncl(3) == false

  containsOrInclImpl()

proc excl*[A, B](s: var SomeSet[A], key: B) =
  ## `key` must be of type `A` or `Iterable[A]`. Excludes an element `key` or
  ## all items of `key` from the set `s`.
  ##
  ## This doesn't do anything if `key` is not found in `s`.
  ##
  ## See also:
  ## * `incl proc <#incl,SomeSet[A],B>`_ for including an element or an iterable
  ##   sequence of elements.
  ## * `missingOrExcl proc <#missingOrExcl,SomeSet[A],A>`_
  runnableExamples:
    var s = toHashSet([2, 3, 6, 7])
    s.excl(2)
    s.excl(2)
    assert s.len == 3

  when key is A:
    discard exclImpl(s, key)
  elif key is Iterable[A]:
    for item in items(key): excl(s, item)
  else:
    {.fatal: "The type of `key` must be the type of the set elements or " &
             "`Iterable` from it.".}

proc missingOrExcl*[A](s: var SomeSet[A], key: A): bool =
  ## Excludes `key` in the set `s` and tells if `key` was already missing from `s`.
  ##
  ## The difference with regards to the `excl proc <#excl,SomeSet[A],B>`_ is
  ## that this proc returns `true` if `key` was missing from `s`.
  ## The proc will return `false` if `key` was in `s` and it was removed
  ## during this call.
  ##
  ## See also:
  ## * `excl proc <#excl,SomeSet[A],B>`_ for excluding an element or iterable
  ##   sequence of elements
  ## * `containsOrIncl proc <#containsOrIncl,SomeSet[A],A>`_
  runnableExamples:
    var s = toHashSet([2, 3, 6, 7])
    assert s.missingOrExcl(4) == true
    assert s.missingOrExcl(6) == false
    assert s.missingOrExcl(6) == true

  exclImpl(s, key)

proc pop*[A](s: var SomeSet[A]): A =
  ## Remove and return an arbitrary element from the set `s`.
  ##
  ## Raises KeyError if the set `s` is empty.
  ##
  ## See also:
  ## * `clear proc <#clear,SomeSet[A]>`_
  runnableExamples:
    var s = toHashSet([2, 1])
    assert [s.pop, s.pop] in [[1, 2], [2,1]] # order unspecified
    doAssertRaises(KeyError, echo s.pop)

  for item in items(s):
    result = item
    excl(s, item)
    return result
  raise newException(KeyError, "set is empty")

proc clear*[A](s: var SomeSet[A]) =
  ## Clears the HashSet back to an empty state, without shrinking
  ## any of the existing storage.
  ##
  ## `O(n)` operation, where `n` is the size of the hash bucket.
  ##
  ## See also:
  ## * `pop proc <#pop,SomeSet[A]>`_
  runnableExamples:
    var s = toHashSet([3, 5, 7])
    clear(s)
    assert len(s) == 0

  when s is HashSet[A]:
    hashSetClearImpl()
  elif s is OrderedSet[A]:
    orderedSetClearImpl()
  else:
    {.fatal: "Unknown set type."}

proc len*[A](s: SomeSet[A]): int =
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

proc card*[A](s: SomeSet[A]): int =
  ## Alias for `len() <#len,SomeSet[A]>`_.
  ##
  ## Card stands for the `cardinality
  ## <http://en.wikipedia.org/wiki/Cardinality>`_ of a set.
  result = s.counter

proc union*[A](s1, s2: SomeSet[A]): SomeSet[A] =
  ## Returns the union of the sets `s1` and `s2`.
  ##
  ## The same as `s1 + s2 <#+,SomeSet[A],SomeSet[A]>`_.
  ##
  ## The union of two sets is represented mathematically as *A ∪ B* and is the
  ## set of all objects that are members of `s1`, `s2` or both.
  ##
  ## See also:
  ## * `intersection proc <#intersection,SomeSet[A],SomeSet[A]>`_
  ## * `difference proc <#difference,SomeSet[A],SomeSet[A]>`_
  ## * `symmetricDifference proc <#symmetricDifference,SomeSet[A],SomeSet[A]>`_
  runnableExamples:
    let
      a = toHashSet(["a", "b"])
      b = toHashSet(["b", "c"])
      c = union(a, b)
    assert c == toHashSet(["a", "b", "c"])

  result = s1
  incl(result, s2)

proc intersection*[A](s1, s2: SomeSet[A]): SomeSet[A] =
  ## Returns the intersection of the sets `s1` and `s2`.
  ##
  ## The same as `s1 * s2 <#*,SomeSet[A],SomeSet[A]>`_.
  ##
  ## The intersection of two sets is represented mathematically as *A ∩ B* and
  ## is the set of all objects that are members of `s1` and `s2` at the same
  ## time.
  ##
  ## See also:
  ## * `union proc <#union,SomeSet[A],SomeSet[A]>`_
  ## * `difference proc <#difference,SomeSet[A],SomeSet[A]>`_
  ## * `symmetricDifference proc <#symmetricDifference,SomeSet[A],SomeSet[A]>`_
  runnableExamples:
    let
      a = toHashSet(["a", "b"])
      b = toHashSet(["b", "c"])
      c = intersection(a, b)
    assert c == toHashSet(["b"])

  result.init(max(min(s1.data.len, s2.data.len), 2))
  for item in s1:
    if item in s2: incl(result, item)

proc difference*[A](s1, s2: SomeSet[A]): SomeSet[A] =
  ## Returns the difference of the sets `s1` and `s2`.
  ##
  ## The same as `s1 - s2 <#-,SomeSet[A],SomeSet[A]>`_.
  ##
  ## The difference of two sets is represented mathematically as *A ∖ B* and is
  ## the set of all objects that are members of `s1` and not members of `s2`.
  ##
  ## See also:
  ## * `union proc <#union,SomeSet[A],SomeSet[A]>`_
  ## * `intersection proc <#intersection,SomeSet[A],SomeSet[A]>`_
  ## * `symmetricDifference proc <#symmetricDifference,SomeSet[A],SomeSet[A]>`_
  runnableExamples:
    let
      a = toHashSet(["a", "b"])
      b = toHashSet(["b", "c"])
      c = difference(a, b)
    assert c == toHashSet(["a"])

  for item in s1:
    if not contains(s2, item):
      incl(result, item)

proc symmetricDifference*[A](s1, s2: SomeSet[A]): SomeSet[A] =
  ## Returns the symmetric difference of the sets `s1` and `s2`.
  ##
  ## The same as `s1 -+- s2 <#-+-,SomeSet[A],SomeSet[A]>`_.
  ##
  ## The symmetric difference of two sets is represented mathematically as *A △
  ## B* or *A ⊖ B* and is the set of all objects that are members of `s1` or
  ## `s2` but not both at the same time.
  ##
  ## See also:
  ## * `union proc <#union,SomeSet[A],SomeSet[A]>`_
  ## * `intersection proc <#intersection,SomeSet[A],SomeSet[A]>`_
  ## * `difference proc <#difference,SomeSet[A],SomeSet[A]>`_
  runnableExamples:
    let
      a = toHashSet(["a", "b"])
      b = toHashSet(["b", "c"])
      c = symmetricDifference(a, b)
    assert c == toHashSet(["a", "c"])

  result = s1
  for item in s2:
    if containsOrIncl(result, item): excl(result, item)

proc `+`*[A](s1, s2: SomeSet[A]): SomeSet[A] {.inline.} =
  ## Alias for `union(s1, s2) <#union,SomeSet[A],SomeSet[A]>`_.
  result = union(s1, s2)

proc `*`*[A](s1, s2: SomeSet[A]): SomeSet[A] {.inline.} =
  ## Alias for `intersection(s1, s2) <#intersection,SomeSet[A],SomeSet[A]>`_.
  result = intersection(s1, s2)

proc `-`*[A](s1, s2: SomeSet[A]): SomeSet[A] {.inline.} =
  ## Alias for `difference(s1, s2) <#difference,SomeSet[A],SomeSet[A]>`_.
  result = difference(s1, s2)

proc `-+-`*[A](s1, s2: SomeSet[A]): SomeSet[A] {.inline.} =
  ## Alias for `symmetricDifference(s1, s2)
  ## <#symmetricDifference,SomeSet[A],SomeSet[A]>`_.
  result = symmetricDifference(s1, s2)

proc disjoint*[A](s1, s2: SomeSet[A]): bool =
  ## Returns `true` if the sets `s1` and `s2` have no items in common.
  runnableExamples:
    let
      a = toHashSet(["a", "b"])
      b = toHashSet(["b", "c"])
    assert disjoint(a, b) == false
    assert disjoint(a, b - a) == true

  for item in s1:
    if item in s2: return false
  return true

proc `<`*[A](s, t: SomeSet[A]): bool =
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

proc `<=`*[A](s, t: SomeSet[A]): bool =
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

proc `==`*[A](s, t: SomeSet[A]): bool =
  ## Returns true if both `s` and `t` have the same members and set size.
  runnableExamples:
    let
      a = toHashSet([1, 2])
      b = toHashSet([2, 1])
      c = toOrderedSet([1, 2])
      d = toOrderedSet([2, 1])
    assert a == b
    assert(not (c == d))

  when s is HashSet[A]:
    hashSetEqualImpl()
  elif s is OrderedSet[A]:
    orderedSetEqualImpl()
  else:
    {.fatal: "Unknown set type."}

proc hash*[A](s: SomeSet[A]): Hash =
  ## Hashing of a set.
  when s is HashSet[A]:
    hashSetHashImpl()
  elif s is OrderedSet[A]:
    orderedSetHashImpl()
  else:
    {.fatal: "Unknown set type."}

proc `$`*[A](s: SomeSet[A]): string =
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
  dollarImpl()

# -----------------------------------------------------------------------

when isMainModule:
  import sequtils, algorithm, sugar

  template defineTestTypes(SetType) =
    type
      `SetType "Value"` {.inject.} = object
        fields: SetType[`SetType "Value"`]

    iterator items(value: `SetType "Value"`): `SetType "Value"` =
      for v in items(value.fields):
        yield v

    proc hash(value: `SetType "Value"`): Hash =
      for v in items(value):
        result = result !& hash(v)
      result = !$result

  defineTestTypes(HashSet)
  defineTestTypes(OrderedSet)

  proc testModule() =
    ## Internal micro test to validate docstrings and such.
    block isValidTest: # isValid is deprecated
      template testIsValid(SetType) =
        var options: SetType[string]
        proc savePreferences(options: SetType[string]) =
          doAssert options.isValid, "Pass an initialized set!"
        options.init()
        options.savePreferences

      testIsValid(HashSet)
      testIsValid(OrderedSet)

    block lenTest:
      template testLen(SetType) =
        var values: HashSet[int]
        doAssert(not values.isValid)
        doAssert values.len == 0
        doAssert values.card == 0

      testLen(HashSet)
      testLen(OrderedSet)

    block setIterator:
      template testSetIterator(SetType) =
        type pair = tuple[a, b: int]
        var a, b: SetType[pair]
        a.incl((2, 3))
        a.incl((3, 2))
        a.incl((2, 3))
        for x, y in a.items:
          b.incl((x - 2, y + 1))
        doAssert a.len == b.card
        doAssert a.len == 2

      testSetIterator(HashSet)
      testSetIterator(OrderedSet)

    block setContains:
      template testSetContains(SetType) =
        var values: SetType[int]
        doAssert(not values.contains(2))
        values.incl(2)
        doAssert values.contains(2)
        values.excl(2)
        doAssert(not values.contains(2))

        values.incl(4)
        var others = `"to" SetType`([6, 7])
        values.incl(others)
        doAssert values.len == 3

        values.init
        doAssert not values.containsOrIncl(2)
        doAssert values.containsOrIncl(2)
        var
          a = `"to" SetType`([1, 2])
          b = `"to" SetType`([1])
        b.incl(2)
        doAssert a == b

      testSetContains(HashSet)
      testSetContains(OrderedSet)

    block exclusions:
      template testExclusions(SetType) =
        var s = `"to" SetType`([2, 3, 6, 7])
        s.excl(2)
        s.excl(2)
        doAssert s.len == 3

        var
          numbers = `"to" SetType`([1, 2, 3, 4, 5])
          even = `"to" SetType`([2, 4, 6, 8])
        numbers.excl(even)
        doAssert numbers == `"to" SetType`([1, 3, 5])
      
      testExclusions(HashSet)
      testExclusions(OrderedSet)

    block toSeqAndString:
      template testToSeqAndString(SetType) =
        var a = `"to" SetType`([2, 7, 5])
        var b = `"init" SetType`[int](rightSize(a.len))
        for x in [2, 7, 5]: b.incl(x)
        doAssert $a == $b
        doAssert a == b # https://github.com/Araq/Nim/issues/1413

      testToSeqAndString(HashSet)
      testToSeqAndString(OrderedSet)

    block setOperations:
      template testSetOperations(SetType) =
        var
          a = `"to" SetType`(["a", "b"])
          b = `"to" SetType`(["b", "c"])
          c = union(a, b)
        doAssert c == `"to" SetType`(["a", "b", "c"])
        var d = intersection(a, b)
        doAssert d == `"to" SetType`(["b"])
        var e = difference(a, b)
        doAssert e == `"to" SetType`(["a"])
        var f = symmetricDifference(a, b)
        doAssert f == `"to" SetType`(["a", "c"])
        doAssert d < a and d < b
        doAssert not (a < a)
        doAssert d <= a and d <= b
        doAssert a <= a
        # Alias test.
        doAssert a + b == `"to" SetType`(["a", "b", "c"])
        doAssert a * b == `"to" SetType`(["b"])
        doAssert a - b == `"to" SetType`(["a"])
        doAssert a -+- b == `"to" SetType`(["a", "c"])
        doAssert not disjoint(a, b)
        doAssert disjoint(a, b - a)

      testSetOperations(HashSet)
      testSetOperations(OrderedSet)

    block mapSet:
      template testMapSet(SetType) =
        var a = `"to" SetType`([1, 2, 3])
        var b = a.map(proc (x: int): string = $x)
        doAssert b == `"to" SetType`(["1", "2", "3"])

      testMapSet(HashSet)
      testMapSet(OrderedSet)

    block setPairsIterator:
      template testPairsIterator(SetType) =
        var s = `"to" SetType`([1, 3, 5, 7])
        var items = newSeq[tuple[a: int, b: int]]()
        for idx, item in s: items.add((idx, item))
        when SetType is OrderedSet:
          doAssert items == @[(0, 1), (1, 3), (2, 5), (3, 7)]
        else:
          doAssert items.map((x) => x.a).sorted == @[0, 1, 2, 3]
          doAssert items.map((x) => x.b).sorted == @[1, 3, 5, 7]

      testPairsIterator(HashSet)
      testPairsIterator(OrderedSet)

    block exclusions:
      template testExclusions(SetType) = 
        var s = `"to" SetType`([1, 2, 3, 6, 7, 4])
        s.excl(3)
        s.excl(3)
        s.excl(1)
        s.excl(4)
        doAssert s == `"to" SetType`([2, 6, 7])

      testExclusions(HashSet)
      testExclusions(HashSet)

    block: #9005
      template test9005(SetType) =
        var s: SetType[(int, int)]
        for i in 0 .. 30: incl(s, (i, 0))
        for i in 0 .. 30: excl(s, (i, 0))
        doAssert s.len == 0

      test9005(HashSet)
      test9005(OrderedSet)

    block initBlocks:
      template testInitBlocks(SetType) =
        var a: SetType[int]
        a.init(4)
        a.incl(2)
        a.init
        doAssert a.len == 0 and a.isValid
        a = `"init" SetType`[int](4)
        a.incl(2)
        doAssert a.len == 1

      testInitBlocks(HashSet)
      testInitBlocks(OrderedSet)

    block:
      type FakeTable = object
        dataLen: int
        counter: int
        countDeleted: int

      var t: FakeTable
      for i in 0 .. 32:
        var s = rightSize(i)
        t.dataLen = s
        t.counter = i
        doAssert s > i and not mustRehash(t),
          "performance issue: rightSize() will not elide enlarge() at: " & $i

    block missingOrExcl:
      template testMissingOrExcl(SetType) =
        var s = `"to" SetType`([2, 3, 6, 7])
        doAssert s.missingOrExcl(4)
        doAssert not s.missingOrExcl(6)

      testMissingOrExcl(HashSet)
      testMissingOrExcl(OrderedSet)

    block equality:
      template testEquality(SetType) =
        type pair = tuple[a, b: int]

        var aa: SetType[pair]
        var bb: SetType[pair]

        var x = (a: 1, b: 2)
        var y = (a: 3, b: 4)

        aa.incl(x)
        aa.incl(y)

        bb.incl(x)
        bb.incl(y)
        doAssert aa == bb

      testEquality(HashSet)
      testEquality(OrderedSet)

    block setsWithoutInit:
      template testSetsWithoutInit(SetType) =
        var
          a: SetType[int]
          b: SetType[int]
          c: SetType[int]
          d: SetType[int]
          e: SetType[int]

        doAssert not a.containsOrIncl(3)
        doAssert a.contains(3)
        doAssert a.len == 1
        doAssert a.containsOrIncl(3)
        a.incl(3)
        doAssert a.len == 1
        a.incl(6)
        doAssert a.len == 2

        b.incl(5)
        doAssert b.len == 1
        b.excl(5)
        b.excl(c)
        doAssert b.missingOrExcl(5)
        doAssert b.disjoint(c)

        d = b + c
        doAssert d.len == 0
        d = b * c
        doAssert d.len == 0
        d = b - c
        doAssert d.len == 0
        d = b -+- c
        doAssert d.len == 0

        doAssert not (d < e)
        doAssert d <= e
        doAssert d == e

      testSetsWithoutInit(HashSet)
      testSetsWithoutInit(OrderedSet)

    block setToSetConversions:
      template testSetToSetConversions(SetType1, SetType2) =
        let
          set1 = `"to" HashSet`([1, 5])
          set2 = `"to" OrderedSet`(set1)
        doAssert set2.len == 2
        doAssert set2.contains(1)
        doAssert set2.contains(5)

      testSetToSetConversions(HashSet, OrderedSet)
      testSetToSetConversions(OrderedSet, HashSet)

    block setIncludesIterable:
      template testSetIncludesIterable(SetType) =
        var values = `"to" SetType`([1, 2, 3])
        let
          hashSet = toHashSet([3, 4, 5])
          orderedSet = toOrderedSet([5, 6, 7])
          sequence = toSeq([7, 8, 9])
          arr = [9, 10, 11]
        values.incl(hashSet)
        values.incl(orderedSet)
        values.incl(sequence)
        values.incl(arr)
        doAssert values == `"to" SetType`([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])

      testSetIncludesIterable(HashSet)
      testSetIncludesIterable(OrderedSet)

    block setExcludesIterable:
      template testSetExcludesIterable(SetType) =
        var numbers = `"to" SetType`(
          [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14])
        let
          evenHashSet= toHashSet([2, 4])
          evenOrderedSet = toOrderedSet([6, 8])
          evenSequence = toSeq([10, 12])
          evenArray = [14, 16]
        numbers.excl(evenHashSet)
        numbers.excl(evenOrderedSet)
        numbers.excl(evenSequence)
        numbers.excl(evenArray)
        doAssert numbers == `"to" SetType`([1, 3, 5, 7, 9, 11, 13])

      testSetExcludesIterable(HashSet)
      testSetExcludesIterable(OrderedSet)

    block setPop:
      template testSetPop(SetType) =
        var
          initialSet = `"to" SetType`("abracadabra")
          fillSet: SetType[char]
        # without `dup` will be get by `ref`.
        # This bug is unreproducible in smaller example.
        let expectedSet = initialSet.dup

        doAssert initialSet.card != 0
        for i in 1 .. expectedSet.len:
          fillSet.incl(initialSet.pop())
        doAssert initialSet.card == 0
        doAssert fillSet == expectedSet

      testSetPop(HashSet)
      testSetPop(OrderedSet)

    block notAllGenericParametersForToSet:
      # After adding `IterableLen` concept overload for `toHashSet` and
      # `toOrderedSet` procedures the concept parameter is threated as second
      # implicit generic parameters, but the compiler expects all or none of the
      # generic parameters to be given explicitly. This will break the old code
      # which gives only one generic parameter. For that reason the old
      # overload with `openArray` must be retained at least until partial
      # generic parameters match is implemented in the compiler. The test below
      # is intended to fail if someone mistakenly removes `openArray` overload.

      doAssert compiles(toHashSet[string](["test"]))
      doAssert compiles(toOrderedSet[string](["test"]))

    block inclExclWithRecursiveType:
      # When separate overloads of `incl` and `excl` for single element `A` and
      # for `Iterable[A]` are present this causes an ambiguous call problem with
      # sets containing elements from the same type like this to which they are
      # fields of and an `items` iterator yielding elements from the same type
      # which it iterates. Such types are present in some Nim libraries like
      # `ggplot` for example. For that reason a single generic overload must be
      # used and the right implementation to be selected with `when`.
      #
      # .. code-block::
      #   type
      #     Value = object
      #       fields: HashSet[Value]
      #   
      #   iterator items(value: Value): Value =
      #     for v in items(value.fields):
      #       yield v

      template testInclExclWithRecursiveType(SetType) =
        let v1 = `SetType "Value"`(
          fields: `"init" SetType`[`SetType "Value"`]())
        var v2 = `SetType "Value"`(fields: [v1].`"to" SetType`())

        doAssert v2.fields.len == 1
        doAssert v2.fields[v1] == v1
        v2.fields.excl(v1)
        doAssert v2.fields.len == 0

      testInclExclWithRecursiveType(HashSet)
      testInclExclWithRecursiveType(OrderedSet)

    when not defined(testing):
      echo "Micro tests run successfully."

  testModule()
