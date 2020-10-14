#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## The ``ordsets`` module implements an efficient `Ordinal` set implemented as a
## `sparse bit set`:idx:.
##
## Supported `A: Ordinal` types include enums and distincts with int base.
##
## **Note**: Currently the assignment operator ``=`` for ``OrdSet[A]``
## performs some rather meaningless shallow copy. Since Nim currently does
## not allow the assignment operator to be overloaded, use `assign proc
## <#assign,OrdinalSet[A],OrdinalSet[A]>`_ to get a deep copy.
##
## **See also:**
## * `sets module <sets.html>`_ for more general hash sets

import std/private/since
import hashes

type
  BitScalar = uint

const
  InitIntSetSize = 8              # must be a power of two!
  TrunkShift = 9
  BitsPerTrunk = 1 shl TrunkShift # needs to be a power of 2 and
                                  # divisible by 64
  TrunkMask = BitsPerTrunk - 1
  IntsPerTrunk = BitsPerTrunk div (sizeof(BitScalar) * 8)
  IntShift = 5 + ord(sizeof(BitScalar) == 8) # 5 or 6, depending on int width
  IntMask = 1 shl IntShift - 1

type
  PTrunk = ref Trunk
  Trunk = object
    next: PTrunk                                # all nodes are connected with this pointer
    key: int                                    # start address at bit 0
    bits: array[0..IntsPerTrunk - 1, BitScalar] # a bit vector

  TrunkSeq = seq[PTrunk]

  ## An efficient set of `Ordinal` implemented as a sparse bit set.
  OrdSet*[A: Ordinal] = object
    elems: int           # only valid for small numbers
    counter, max: int
    head: PTrunk
    data: TrunkSeq
    a: array[0..33, int] # profiling shows that 34 elements are enough

proc mustRehash[T](t: T): bool {.inline.} =
  let length = t.max + 1
  assert length > t.counter
  result = (length * 2 < t.counter * 3) or (length - t.counter < 4)

proc nextTry(h, maxHash: Hash, perturb: var Hash): Hash {.inline.} =
  const PERTURB_SHIFT = 5
  var perturb2 = cast[uint](perturb) shr PERTURB_SHIFT
  perturb = cast[Hash](perturb2)
  result = ((5*h) + 1 + perturb) and maxHash

proc intSetGet[A](t: OrdSet[A], key: int): PTrunk =
  var h = key and t.max
  var perturb = key
  while t.data[h] != nil:
    if t.data[h].key == key:
      return t.data[h]
    h = nextTry(h, t.max, perturb)
  result = nil

proc intSetRawInsert[A](t: OrdSet[A], data: var TrunkSeq, desc: PTrunk) =
  var h = desc.key and t.max
  var perturb = desc.key
  while data[h] != nil:
    assert(data[h] != desc)
    h = nextTry(h, t.max, perturb)
  assert(data[h] == nil)
  data[h] = desc

proc intSetEnlarge[A](t: var OrdSet[A]) =
  var n: TrunkSeq
  var oldMax = t.max
  t.max = ((t.max + 1) * 2) - 1
  newSeq(n, t.max + 1)
  for i in countup(0, oldMax):
    if t.data[i] != nil: intSetRawInsert(t, n, t.data[i])
  swap(t.data, n)

proc intSetPut[A](t: var OrdSet[A], key: int): PTrunk =
  var h = key and t.max
  var perturb = key
  while t.data[h] != nil:
    if t.data[h].key == key:
      return t.data[h]
    h = nextTry(h, t.max, perturb)
  if mustRehash(t): intSetEnlarge(t)
  inc(t.counter)
  h = key and t.max
  perturb = key
  while t.data[h] != nil: h = nextTry(h, t.max, perturb)
  assert(t.data[h] == nil)
  new(result)
  result.next = t.head
  result.key = key
  t.head = result
  t.data[h] = result

proc bitincl[A](s: var OrdSet[A], key: int) {.inline.} =
  var ret: PTrunk
  var t = intSetPut(s, `shr`(key, TrunkShift))
  var u = key and TrunkMask
  t.bits[u shr IntShift] = t.bits[u shr IntShift] or
      (BitScalar(1) shl (u and IntMask))

proc exclImpl[A](s: var OrdSet[A], key: int) =
  if s.elems <= s.a.len:
    for i in 0..<s.elems:
      if s.a[i] == key:
        s.a[i] = s.a[s.elems-1]
        dec s.elems
        return
  else:
    var t = intSetGet(s, key shr TrunkShift)
    if t != nil:
      var u = key and TrunkMask
      t.bits[u shr IntShift] = t.bits[u shr IntShift] and
          not(BitScalar(1) shl (u and IntMask))

template dollarImpl(): untyped =
  result = "{"
  for key in items(s):
    if result.len > 1: result.add(", ")
    result.add($(ord(key)))
  result.add("}")

iterator items*[A](s: OrdSet[A]): A {.inline.} =
  ## Iterates over any included element of `s`.
  if s.elems <= s.a.len:
    for i in 0..<s.elems:
      yield A(s.a[i])
  else:
    var r = s.head
    while r != nil:
      var i = 0
      while i <= high(r.bits):
        var w: uint = r.bits[i]
        # taking a copy of r.bits[i] here is correct, because
        # modifying operations are not allowed during traversation
        var j = 0
        while w != 0: # test all remaining bits for zero
          if (w and 1) != 0: # the bit is set!
            yield A((r.key shl TrunkShift) or (i shl IntShift +% j))
          inc(j)
          w = w shr 1
        inc(i)
      r = r.next

proc initOrdSet*[A]: OrdSet[A] =
  ## Returns an empty OrdSet[A].
  ## A must be an ordinal equivalent type: int | enum | distinct int
  ##
  ## See also:
  ## * `toOrdSet[A] proc <#toOrdSet[A],openArray[int]>`_
  runnableExamples:
    var a = initOrdSet[int]()
    assert len(a) == 0

    type id = distinct int
    var ids = initOrdSet[id]()
    ids.incl(3.id)
    #assert 3.id in ids #Type safe: `3 in ids` wouldn't compile

  result = OrdSet[A](
    elems: 0,
    counter: 0,
    max: 0,
    head: nil,
    data: when defined(nimNoNilSeqs): @[] else: nil)
  #  a: array[0..33, int] # profiling shows that 34 elements are enough

proc contains*[A](s: OrdSet[A], key: A): bool =
  ## Returns true if `key` is in `s`.
  ##
  ## This allows the usage of `in` operator.
  runnableExamples:
    type ABCD = enum A, B, C, D

    var a = initOrdSet[int]()
    for x in [1, 3, 5]:
      a.incl(x)
    assert a.contains(3)
    assert 3 in a
    assert(not a.contains(8))
    assert 8 notin a

    var letters = initOrdSet[ABCD]()
    for x in [A, C]:
      letters.incl(x)
    assert A in letters
    assert C in letters
    assert B notin letters

  if s.elems <= s.a.len:
    for i in 0..<s.elems:
      if s.a[i] == ord(key): return true
  else:
    var t = intSetGet(s, `shr`(ord(key), TrunkShift))
    if t != nil:
      var u = ord(key) and TrunkMask
      result = (t.bits[u shr IntShift] and
                (BitScalar(1) shl (u and IntMask))) != 0
    else:
      result = false

proc incl*[A](s: var OrdSet[A], key: A) =
  ## Includes an element `key` in `s`.
  ##
  ## This doesn't do anything if `key` is already in `s`.
  ##
  ## See also:
  ## * `excl proc <#excl,OrdSet[A],A>`_ for excluding an element
  ## * `incl proc <#incl,OrdSet[A],OrdSet[A]>`_ for including other set
  ## * `containsOrIncl proc <#containsOrIncl,OrdSet[A],A>`_
  runnableExamples:
    var a = initOrdSet[int]()
    a.incl(3)
    a.incl(3)
    assert len(a) == 1

  if s.elems <= s.a.len:
    for i in 0..<s.elems:
      if s.a[i] == ord(key): return
    if s.elems < s.a.len:
      s.a[s.elems] = ord(key)
      inc s.elems
      return
    newSeq(s.data, InitIntSetSize)
    s.max = InitIntSetSize-1
    for i in 0..<s.elems:
      bitincl(s, s.a[i])
    s.elems = s.a.len + 1
    # fall through:
  bitincl(s, ord(key))

proc incl*[A](s: var OrdSet[A], other: OrdSet[A]) =
  ## Includes all elements from `other` into `s`.
  ##
  ## This is the in-place version of `s + other <#+,OrdSet[A],OrdSet[A]>`_.
  ##
  ## See also:
  ## * `excl proc <#excl,OrdSet[A],OrdSet[A]>`_ for excluding other set
  ## * `incl proc <#incl,OrdSet[A],A>`_ for including an element
  ## * `containsOrIncl proc <#containsOrIncl,OrdSet[A],A>`_
  runnableExamples:
    var
      a = initOrdSet[int]()
      b = initOrdSet[int]()
    a.incl(1)
    b.incl(5)
    a.incl(b)
    assert len(a) == 2
    assert 5 in a

  for item in other: incl(s, item)

proc toOrdSet*[A](x: openArray[A]): OrdSet[A] {.since: (1, 3).} =
  ## Creates a new OrdSet[A] that contains the elements of `x`.
  ##
  ## Duplicates are removed.
  ##
  ## See also:
  ## * `initOrdSet[A] proc <#initOrdSet[A]>`_
  runnableExamples:
    var
      a = toOrdSet([5, 6, 7])
      b = toOrdSet(@[1, 8, 8, 8])
    assert len(a) == 3
    assert len(b) == 2

  result = initOrdSet[A]()
  for item in x:
    result.incl(item)

proc containsOrIncl*[A](s: var OrdSet[A], key: A): bool =
  ## Includes `key` in the set `s` and tells if `key` was already in `s`.
  ##
  ## The difference with regards to the `incl proc <#incl,OrdSet[A],A>`_ is
  ## that this proc returns `true` if `s` already contained `key`. The
  ## proc will return `false` if `key` was added as a new value to `s` during
  ## this call.
  ##
  ## See also:
  ## * `incl proc <#incl,OrdSet[A],A>`_ for including an element
  ## * `missingOrExcl proc <#missingOrExcl,OrdSet[A],A>`_
  runnableExamples:
    var a = initOrdSet[int]()
    assert a.containsOrIncl(3) == false
    assert a.containsOrIncl(3) == true
    assert a.containsOrIncl(4) == false

  if s.elems <= s.a.len:
    for i in 0..<s.elems:
      if s.a[i] == ord(key):
        return true
    incl(s, key)
    result = false
  else:
    var t = intSetGet(s, `shr`(ord(key), TrunkShift))
    if t != nil:
      var u = ord(key) and TrunkMask
      result = (t.bits[u shr IntShift] and BitScalar(1) shl (u and IntMask)) != 0
      if not result:
        t.bits[u shr IntShift] = t.bits[u shr IntShift] or
            (BitScalar(1) shl (u and IntMask))
    else:
      incl(s, key)
      result = false

proc excl*[A](s: var OrdSet[A], key: A) =
  ## Excludes `key` from the set `s`.
  ##
  ## This doesn't do anything if `key` is not found in `s`.
  ##
  ## See also:
  ## * `incl proc <#incl,OrdSet[A],A>`_ for including an element
  ## * `excl proc <#excl,OrdSet[A],OrdSet[A]>`_ for excluding other set
  ## * `missingOrExcl proc <#missingOrExcl,OrdSet[A],A>`_
  runnableExamples:
    var a = initOrdSet[int]()
    a.incl(3)
    a.excl(3)
    a.excl(3)
    a.excl(99)
    assert len(a) == 0
  exclImpl[A](s, cast[int](key))

proc excl*[A](s: var OrdSet[A], other: OrdSet[A]) =
  ## Excludes all elements from `other` from `s`.
  ##
  ## This is the in-place version of `s - other <#-,OrdSet[A],OrdSet[A]>`_.
  ##
  ## See also:
  ## * `incl proc <#incl,OrdSet[A],OrdSet[A]>`_ for including other set
  ## * `excl proc <#excl,OrdSet[A],A>`_ for excluding an element
  ## * `missingOrExcl proc <#missingOrExcl,OrdSet[A],A>`_
  runnableExamples:
    var
      a = initOrdSet[int]()
      b = initOrdSet[int]()
    a.incl(1)
    a.incl(5)
    b.incl(5)
    a.excl(b)
    assert len(a) == 1
    assert 5 notin a

  for item in other:
    excl(s, item)

proc len*[A](s: OrdSet[A]): int {.inline.} =
  ## Returns the number of elements in `s`.
  if s.elems < s.a.len:
    result = s.elems
  else:
    result = 0
    for _ in s:
      inc(result)

proc missingOrExcl*[A](s: var OrdSet[A], key: A): bool =
  ## Excludes `key` in the set `s` and tells if `key` was already missing from `s`.
  ##
  ## The difference with regards to the `excl proc <#excl,OrdSet[A],A>`_ is
  ## that this proc returns `true` if `key` was missing from `s`.
  ## The proc will return `false` if `key` was in `s` and it was removed
  ## during this call.
  ##
  ## See also:
  ## * `excl proc <#excl,OrdSet[A],A>`_ for excluding an element
  ## * `excl proc <#excl,OrdSet[A],OrdSet[A]>`_ for excluding other set
  ## * `containsOrIncl proc <#containsOrIncl,OrdSet[A],A>`_
  runnableExamples:
    var a = initOrdSet[int]()
    a.incl(5)
    assert a.missingOrExcl(5) == false
    assert a.missingOrExcl(5) == true

  var count = s.len
  exclImpl(s, cast[int](key))
  result = count == s.len

proc clear*[A](result: var OrdSet[A]) =
  ## Clears the OrdSet[A] back to an empty state.
  runnableExamples:
    var a = initOrdSet[int]()
    a.incl(5)
    a.incl(7)
    clear(a)
    assert len(a) == 0

  # setLen(result.data, InitIntSetSize)
  # for i in 0..InitIntSetSize-1: result.data[i] = nil
  # result.max = InitIntSetSize-1
  when defined(nimNoNilSeqs):
    result.data = @[]
  else:
    result.data = nil
  result.max = 0
  result.counter = 0
  result.head = nil
  result.elems = 0

proc isNil*[A](x: OrdSet[A]): bool {.inline.} = x.head.isNil and x.elems == 0

proc assign*[A](dest: var OrdSet[A], src: OrdSet[A]) =
  ## Copies `src` to `dest`.
  ## `dest` does not need to be initialized by `initOrdSet[A] proc <#initOrdSet[A]>`_.
  runnableExamples:
    var
      a = initOrdSet[int]()
      b = initOrdSet[int]()
    b.incl(5)
    b.incl(7)
    a.assign(b)
    assert len(a) == 2

  if src.elems <= src.a.len:
    when defined(nimNoNilSeqs):
      dest.data = @[]
    else:
      dest.data = nil
    dest.max = 0
    dest.counter = src.counter
    dest.head = nil
    dest.elems = src.elems
    dest.a = src.a
  else:
    dest.counter = src.counter
    dest.max = src.max
    dest.elems = src.elems
    newSeq(dest.data, src.data.len)

    var it = src.head
    while it != nil:
      var h = it.key and dest.max
      var perturb = it.key
      while dest.data[h] != nil: h = nextTry(h, dest.max, perturb)
      assert(dest.data[h] == nil)
      var n: PTrunk
      new(n)
      n.next = dest.head
      n.key = it.key
      n.bits = it.bits
      dest.head = n
      dest.data[h] = n
      it = it.next

proc union*[A](s1, s2: OrdSet[A]): OrdSet[A] =
  ## Returns the union of the sets `s1` and `s2`.
  ##
  ## The same as `s1 + s2 <#+,OrdSet[A],OrdSet[A]>`_.
  runnableExamples:
    var
      a = initOrdSet[int]()
      b = initOrdSet[int]()
    a.incl(1); a.incl(2); a.incl(3)
    b.incl(3); b.incl(4); b.incl(5)
    assert union(a, b).len == 5
    ## {1, 2, 3, 4, 5}

  result.assign(s1)
  incl(result, s2)

proc intersection*[A](s1, s2: OrdSet[A]): OrdSet[A] =
  ## Returns the intersection of the sets `s1` and `s2`.
  ##
  ## The same as `s1 * s2 <#*,OrdSet[A],OrdSet[A]>`_.
  runnableExamples:
    var
      a = initOrdSet[int]()
      b = initOrdSet[int]()
    a.incl(1); a.incl(2); a.incl(3)
    b.incl(3); b.incl(4); b.incl(5)
    assert intersection(a, b).len == 1
    ## {3}

  result = initOrdSet[A]()
  for item in s1:
    if contains(s2, item):
      incl(result, item)

proc difference*[A](s1, s2: OrdSet[A]): OrdSet[A] =
  ## Returns the difference of the sets `s1` and `s2`.
  ##
  ## The same as `s1 - s2 <#-,OrdSet[A],OrdSet[A]>`_.
  runnableExamples:
    var
      a = initOrdSet[int]()
      b = initOrdSet[int]()
    a.incl(1); a.incl(2); a.incl(3)
    b.incl(3); b.incl(4); b.incl(5)
    assert difference(a, b).len == 2
    ## {1, 2}

  result = initOrdSet[A]()
  for item in s1:
    if not contains(s2, item):
      incl(result, item)

proc symmetricDifference*[A](s1, s2: OrdSet[A]): OrdSet[A] =
  ## Returns the symmetric difference of the sets `s1` and `s2`.
  runnableExamples:
    var
      a = initOrdSet[int]()
      b = initOrdSet[int]()
    a.incl(1); a.incl(2); a.incl(3)
    b.incl(3); b.incl(4); b.incl(5)
    assert symmetricDifference(a, b).len == 4
    ## {1, 2, 4, 5}

  result.assign(s1)
  for item in s2:
    if containsOrIncl(result, item): excl(result, item)

proc `+`*[A](s1, s2: OrdSet[A]): OrdSet[A] {.inline.} =
  ## Alias for `union(s1, s2) <#union,OrdSet[A],OrdSet[A]>`_.
  result = union(s1, s2)

proc `*`*[A](s1, s2: OrdSet[A]): OrdSet[A] {.inline.} =
  ## Alias for `intersection(s1, s2) <#intersection,OrdSet[A],OrdSet[A]>`_.
  result = intersection(s1, s2)

proc `-`*[A](s1, s2: OrdSet[A]): OrdSet[A] {.inline.} =
  ## Alias for `difference(s1, s2) <#difference,OrdSet[A],OrdSet[A]>`_.
  result = difference(s1, s2)

proc disjoint*[A](s1, s2: OrdSet[A]): bool =
  ## Returns true if the sets `s1` and `s2` have no items in common.
  runnableExamples:
    var
      a = initOrdSet[int]()
      b = initOrdSet[int]()
    a.incl(1); a.incl(2)
    b.incl(2); b.incl(3)
    assert disjoint(a, b) == false
    b.excl(2)
    assert disjoint(a, b) == true

  for item in s1:
    if contains(s2, item):
      return false
  return true

proc card*[A](s: OrdSet[A]): int {.inline.} =
  ## Alias for `len() <#len,OrdSet[A]>`_.
  result = s.len()

proc `<=`*[A](s1, s2: OrdSet[A]): bool =
  ## Returns true if `s1` is subset of `s2`.
  ##
  ## A subset `s1` has all of its elements in `s2`, and `s2` doesn't necessarily
  ## have more elements than `s1`. That is, `s1` can be equal to `s2`.
  runnableExamples:
    var
      a = initOrdSet[int]()
      b = initOrdSet[int]()
    a.incl(1)
    b.incl(1); b.incl(2)
    assert a <= b
    a.incl(2)
    assert a <= b
    a.incl(3)
    assert(not (a <= b))

  for item in s1:
    if not s2.contains(item):
      return false
  return true

proc `<`*[A](s1, s2: OrdSet[A]): bool =
  ## Returns true if `s1` is proper subset of `s2`.
  ##
  ## A strict or proper subset `s1` has all of its elements in `s2`, but `s2` has
  ## more elements than `s1`.
  runnableExamples:
    var
      a = initOrdSet[int]()
      b = initOrdSet[int]()
    a.incl(1)
    b.incl(1); b.incl(2)
    assert a < b
    a.incl(2)
    assert(not (a < b))
  return s1 <= s2 and not (s2 <= s1)

proc `==`*[A](s1, s2: OrdSet[A]): bool =
  ## Returns true if both `s1` and `s2` have the same elements and set size.
  return s1 <= s2 and s2 <= s1

proc `$`*[A](s: OrdSet[A]): string =
  ## The `$` operator for int sets.
  ##
  ## Converts the set `s` to a string, mostly for logging and printing purposes.
  dollarImpl()



when isMainModule:
  import sequtils, algorithm

  var y = initOrdSet[int]()
  y.incl(1)
  y.incl(2)
  y.incl(7)
  y.incl(1056)

  y.incl(1044)
  y.excl(1044)

  assert y == [1, 2, 7, 1056].toOrdSet

  assert y.containsOrIncl(888) == false
  assert 888 in y
  assert y.containsOrIncl(888) == true

  assert y.missingOrExcl(888) == false
  assert 888 notin y
  assert y.missingOrExcl(888) == true

  template genericTests(typ: typedesc, x: typed) =
    block:
      proc typSeq(s: seq[int]): seq[`typ`] = s.map(proc (i: int): `typ` = `typ`(i))
      x.incl(`typ`(1))
      x.incl(`typ`(2))
      x.incl(`typ`(7))
      x.incl(`typ`(1056))

      x.incl(`typ`(1044))
      x.excl(`typ`(1044))

      assert x == typSeq(@[1, 2, 7, 1056]).toOrdSet

      assert x.containsOrIncl(`typ`(888)) == false
      assert `typ`(888) in x
      assert x.containsOrIncl(`typ`(888)) == true

      assert x.missingOrExcl(`typ`(888)) == false
      assert `typ`(888) notin x
      assert x.missingOrExcl(`typ`(888)) == true

      var xs = toSeq(items(x))
      xs.sort(cmp[`typ`])
      assert xs == typSeq(@[1, 2, 7, 1056])

      var y: OrdSet[`typ`]
      assign(y, x)
      var ys = toSeq(items(y))
      ys.sort(cmp[`typ`])
      assert ys == typSeq(@[1, 2, 7, 1056])

      assert x == y

      var z: OrdSet[`typ`]
      for i in 0..1000:
        incl z, `typ`(i)
        assert z.len() == i+1
      for i in 0..1000:
        assert z.contains(`typ`(i))

      var w = initOrdSet[`typ`]()
      w.incl(`typ`(1))
      w.incl(`typ`(4))
      w.incl(`typ`(50))
      w.incl(`typ`(1001))
      w.incl(`typ`(1056))

      var xuw = x.union(w)
      var xuws = toSeq(items(xuw))
      xuws.sort(cmp)
      assert xuws == typSeq(@[1, 2, 4, 7, 50, 1001, 1056])

      var xiw = x.intersection(w)
      var xiws = toSeq(items(xiw))
      xiws.sort(cmp)
      assert xiws == @[`typ`(1), `typ`(1056)]

      var xdw = x.difference(w)
      var xdws = toSeq(items(xdw))
      xdws.sort(cmp[`typ`])
      assert xdws == @[`typ`(2), `typ`(7)]

      var xsw = x.symmetricDifference(w)
      var xsws = toSeq(items(xsw))
      xsws.sort(cmp[`typ`])
      assert xsws == typSeq(@[2, 4, 7, 50, 1001])

      x.incl(w)
      xs = toSeq(items(x))
      xs.sort(cmp[`typ`])
      assert xs == typSeq(@[1, 2, 4, 7, 50, 1001, 1056])

      assert w <= x

      assert w < x

      assert(not disjoint(w, x))

      var u = initOrdSet[`typ`]()
      u.incl(`typ`(3))
      u.incl(`typ`(5))
      u.incl(`typ`(500))
      assert disjoint(u, x)

      var v = initOrdSet[`typ`]()
      v.incl(`typ`(2))
      v.incl(`typ`(50))

      x.excl(v)
      xs = toSeq(items(x))
      xs.sort(cmp[`typ`])
      assert xs == typSeq(@[1, 4, 7, 1001, 1056])

      proc bug12366 =
        var

          x = initOrdSet[`typ`]()
          y = initOrdSet[`typ`]()
          n = 3584

        for i in 0..n:
          x.incl(`typ`(i))
          y.incl(`typ`(i))

        let z = symmetricDifference(x, y)
        doAssert z.len == 0
        doAssert $z == "{}"

      bug12366()

  var legacy = initOrdSet[int]()
  genericTests(int, legacy)

  var intGenericInit = initOrdSet[int]()
  genericTests(int, intGenericInit)

  # Test distincts
  type id = distinct int
  proc cmp(a: id, b: id): int {.borrow.}
  proc `==`(a: id, b: id): bool {.borrow.}
  proc `<`(a: id, b: id): bool {.borrow.}

  var idSet = initOrdSet[id]()
  genericTests(id, idSet)

  assert union(idSet, initOrdSet[id]()) == idSet

  #Should fail
  #var nonSupportedTypeParam: OrdSet[string]

  # mixing sets of different types doesn't compile
  #assert union(idSet, initOrdSet[int]()) == idSet # KO! typesafe

  #Should fail
  type nonIntDistinct = distinct string
  #initOrdSet[nonIntDistinct]().incl("not typesafe") #KO!

  # Test enums
  type enumABCD = enum A, B, C, D
  var letterSet = initOrdSet[enumABCD]()

  for x in [A, C]:
    letterSet.incl(x)

  assert A in letterSet
  assert B notin letterSet
  assert C in letterSet
  assert D notin letterSet

