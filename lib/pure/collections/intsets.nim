#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## The ``intsets`` module implements an efficient `int` set implemented as a
## `sparse bit set`:idx:.
##
## **Note**: Currently the assignment operator ``=`` for ``IntSet``
## performs some rather meaningless shallow copy. Since Nim currently does
## not allow the assignment operator to be overloaded, use `assign proc
## <#assign,IntSet,IntSet>`_ to get a deep copy.
##
## **See also:**
## * `sets module <sets.html>`_ for more general hash sets


import
  hashes

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
  IntSet* = object       ## An efficient set of `int` implemented as a sparse bit set.
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

proc intSetGet(t: IntSet, key: int): PTrunk =
  var h = key and t.max
  var perturb = key
  while t.data[h] != nil:
    if t.data[h].key == key:
      return t.data[h]
    h = nextTry(h, t.max, perturb)
  result = nil

proc intSetRawInsert(t: IntSet, data: var TrunkSeq, desc: PTrunk) =
  var h = desc.key and t.max
  var perturb = desc.key
  while data[h] != nil:
    assert(data[h] != desc)
    h = nextTry(h, t.max, perturb)
  assert(data[h] == nil)
  data[h] = desc

proc intSetEnlarge(t: var IntSet) =
  var n: TrunkSeq
  var oldMax = t.max
  t.max = ((t.max + 1) * 2) - 1
  newSeq(n, t.max + 1)
  for i in countup(0, oldMax):
    if t.data[i] != nil: intSetRawInsert(t, n, t.data[i])
  swap(t.data, n)

proc intSetPut(t: var IntSet, key: int): PTrunk =
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

proc bitincl(s: var IntSet, key: int) {.inline.} =
  var ret: PTrunk
  var t = intSetPut(s, `shr`(key, TrunkShift))
  var u = key and TrunkMask
  t.bits[u shr IntShift] = t.bits[u shr IntShift] or
      (BitScalar(1) shl (u and IntMask))

proc exclImpl(s: var IntSet, key: int) =
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
    result.add($key)
  result.add("}")


iterator items*(s: IntSet): int {.inline.} =
  ## Iterates over any included element of `s`.
  if s.elems <= s.a.len:
    for i in 0..<s.elems:
      yield s.a[i]
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
            yield (r.key shl TrunkShift) or (i shl IntShift +% j)
          inc(j)
          w = w shr 1
        inc(i)
      r = r.next


proc initIntSet*: IntSet =
  ## Returns an empty IntSet.
  runnableExamples:
    var a = initIntSet()
    assert len(a) == 0

  # newSeq(result.data, InitIntSetSize)
  # result.max = InitIntSetSize-1
  result = IntSet(
    elems: 0,
    counter: 0,
    max: 0,
    head: nil,
    data: when defined(nimNoNilSeqs): @[] else: nil)
  #  a: array[0..33, int] # profiling shows that 34 elements are enough

proc contains*(s: IntSet, key: int): bool =
  ## Returns true if `key` is in `s`.
  ##
  ## This allows the usage of `in` operator.
  runnableExamples:
    var a = initIntSet()
    for x in [1, 3, 5]:
      a.incl(x)
    assert a.contains(3)
    assert 3 in a
    assert(not a.contains(8))
    assert 8 notin a

  if s.elems <= s.a.len:
    for i in 0..<s.elems:
      if s.a[i] == key: return true
  else:
    var t = intSetGet(s, `shr`(key, TrunkShift))
    if t != nil:
      var u = key and TrunkMask
      result = (t.bits[u shr IntShift] and
                (BitScalar(1) shl (u and IntMask))) != 0
    else:
      result = false

proc incl*(s: var IntSet, key: int) =
  ## Includes an element `key` in `s`.
  ##
  ## This doesn't do anything if `key` is already in `s`.
  ##
  ## See also:
  ## * `excl proc <#excl,IntSet,int>`_ for excluding an element
  ## * `incl proc <#incl,IntSet,IntSet>`_ for including other set
  ## * `containsOrIncl proc <#containsOrIncl,IntSet,int>`_
  runnableExamples:
    var a = initIntSet()
    a.incl(3)
    a.incl(3)
    assert len(a) == 1

  if s.elems <= s.a.len:
    for i in 0..<s.elems:
      if s.a[i] == key: return
    if s.elems < s.a.len:
      s.a[s.elems] = key
      inc s.elems
      return
    newSeq(s.data, InitIntSetSize)
    s.max = InitIntSetSize-1
    for i in 0..<s.elems:
      bitincl(s, s.a[i])
    s.elems = s.a.len + 1
    # fall through:
  bitincl(s, key)

proc incl*(s: var IntSet, other: IntSet) =
  ## Includes all elements from `other` into `s`.
  ##
  ## This is the in-place version of `s + other <#+,IntSet,IntSet>`_.
  ##
  ## See also:
  ## * `excl proc <#excl,IntSet,IntSet>`_ for excluding other set
  ## * `incl proc <#incl,IntSet,int>`_ for including an element
  ## * `containsOrIncl proc <#containsOrIncl,IntSet,int>`_
  runnableExamples:
    var
      a = initIntSet()
      b = initIntSet()
    a.incl(1)
    b.incl(5)
    a.incl(b)
    assert len(a) == 2
    assert 5 in a

  for item in other: incl(s, item)

proc containsOrIncl*(s: var IntSet, key: int): bool =
  ## Includes `key` in the set `s` and tells if `key` was already in `s`.
  ##
  ## The difference with regards to the `incl proc <#incl,IntSet,int>`_ is
  ## that this proc returns `true` if `s` already contained `key`. The
  ## proc will return `false` if `key` was added as a new value to `s` during
  ## this call.
  ##
  ## See also:
  ## * `incl proc <#incl,IntSet,int>`_ for including an element
  ## * `missingOrExcl proc <#missingOrExcl,IntSet,int>`_
  runnableExamples:
    var a = initIntSet()
    assert a.containsOrIncl(3) == false
    assert a.containsOrIncl(3) == true
    assert a.containsOrIncl(4) == false

  if s.elems <= s.a.len:
    for i in 0..<s.elems:
      if s.a[i] == key:
        return true
    incl(s, key)
    result = false
  else:
    var t = intSetGet(s, `shr`(key, TrunkShift))
    if t != nil:
      var u = key and TrunkMask
      result = (t.bits[u shr IntShift] and BitScalar(1) shl (u and IntMask)) != 0
      if not result:
        t.bits[u shr IntShift] = t.bits[u shr IntShift] or
            (BitScalar(1) shl (u and IntMask))
    else:
      incl(s, key)
      result = false

proc excl*(s: var IntSet, key: int) =
  ## Excludes `key` from the set `s`.
  ##
  ## This doesn't do anything if `key` is not found in `s`.
  ##
  ## See also:
  ## * `incl proc <#incl,IntSet,int>`_ for including an element
  ## * `excl proc <#excl,IntSet,IntSet>`_ for excluding other set
  ## * `missingOrExcl proc <#missingOrExcl,IntSet,int>`_
  runnableExamples:
    var a = initIntSet()
    a.incl(3)
    a.excl(3)
    a.excl(3)
    a.excl(99)
    assert len(a) == 0
  exclImpl(s, key)

proc excl*(s: var IntSet, other: IntSet) =
  ## Excludes all elements from `other` from `s`.
  ##
  ## This is the in-place version of `s - other <#-,IntSet,IntSet>`_.
  ##
  ## See also:
  ## * `incl proc <#incl,IntSet,IntSet>`_ for including other set
  ## * `excl proc <#excl,IntSet,int>`_ for excluding an element
  ## * `missingOrExcl proc <#missingOrExcl,IntSet,int>`_
  runnableExamples:
    var
      a = initIntSet()
      b = initIntSet()
    a.incl(1)
    a.incl(5)
    b.incl(5)
    a.excl(b)
    assert len(a) == 1
    assert 5 notin a

  for item in other: excl(s, item)

proc len*(s: IntSet): int {.inline.} =
  ## Returns the number of elements in `s`.
  if s.elems < s.a.len:
    result = s.elems
  else:
    result = 0
    for _ in s:
      inc(result)

proc missingOrExcl*(s: var IntSet, key: int): bool =
  ## Excludes `key` in the set `s` and tells if `key` was already missing from `s`.
  ##
  ## The difference with regards to the `excl proc <#excl,IntSet,int>`_ is
  ## that this proc returns `true` if `key` was missing from `s`.
  ## The proc will return `false` if `key` was in `s` and it was removed
  ## during this call.
  ##
  ## See also:
  ## * `excl proc <#excl,IntSet,int>`_ for excluding an element
  ## * `excl proc <#excl,IntSet,IntSet>`_ for excluding other set
  ## * `containsOrIncl proc <#containsOrIncl,IntSet,int>`_
  runnableExamples:
    var a = initIntSet()
    a.incl(5)
    assert a.missingOrExcl(5) == false
    assert a.missingOrExcl(5) == true

  var count = s.len
  exclImpl(s, key)
  result = count == s.len

proc clear*(result: var IntSet) =
  ## Clears the IntSet back to an empty state.
  runnableExamples:
    var a = initIntSet()
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

proc isNil*(x: IntSet): bool {.inline.} = x.head.isNil and x.elems == 0

proc assign*(dest: var IntSet, src: IntSet) =
  ## Copies `src` to `dest`.
  ## `dest` does not need to be initialized by `initIntSet proc <#initIntSet>`_.
  runnableExamples:
    var
      a = initIntSet()
      b = initIntSet()
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

proc union*(s1, s2: IntSet): IntSet =
  ## Returns the union of the sets `s1` and `s2`.
  ##
  ## The same as `s1 + s2 <#+,IntSet,IntSet>`_.
  runnableExamples:
    var
      a = initIntSet()
      b = initIntSet()
    a.incl(1); a.incl(2); a.incl(3)
    b.incl(3); b.incl(4); b.incl(5)
    assert union(a, b).len == 5
    ## {1, 2, 3, 4, 5}

  result.assign(s1)
  incl(result, s2)

proc intersection*(s1, s2: IntSet): IntSet =
  ## Returns the intersection of the sets `s1` and `s2`.
  ##
  ## The same as `s1 * s2 <#*,IntSet,IntSet>`_.
  runnableExamples:
    var
      a = initIntSet()
      b = initIntSet()
    a.incl(1); a.incl(2); a.incl(3)
    b.incl(3); b.incl(4); b.incl(5)
    assert intersection(a, b).len == 1
    ## {3}

  result = initIntSet()
  for item in s1:
    if contains(s2, item):
      incl(result, item)

proc difference*(s1, s2: IntSet): IntSet =
  ## Returns the difference of the sets `s1` and `s2`.
  ##
  ## The same as `s1 - s2 <#-,IntSet,IntSet>`_.
  runnableExamples:
    var
      a = initIntSet()
      b = initIntSet()
    a.incl(1); a.incl(2); a.incl(3)
    b.incl(3); b.incl(4); b.incl(5)
    assert difference(a, b).len == 2
    ## {1, 2}

  result = initIntSet()
  for item in s1:
    if not contains(s2, item):
      incl(result, item)

proc symmetricDifference*(s1, s2: IntSet): IntSet =
  ## Returns the symmetric difference of the sets `s1` and `s2`.
  runnableExamples:
    var
      a = initIntSet()
      b = initIntSet()
    a.incl(1); a.incl(2); a.incl(3)
    b.incl(3); b.incl(4); b.incl(5)
    assert symmetricDifference(a, b).len == 4
    ## {1, 2, 4, 5}

  result.assign(s1)
  for item in s2:
    if containsOrIncl(result, item): excl(result, item)

proc `+`*(s1, s2: IntSet): IntSet {.inline.} =
  ## Alias for `union(s1, s2) <#union,IntSet,IntSet>`_.
  result = union(s1, s2)

proc `*`*(s1, s2: IntSet): IntSet {.inline.} =
  ## Alias for `intersection(s1, s2) <#intersection,IntSet,IntSet>`_.
  result = intersection(s1, s2)

proc `-`*(s1, s2: IntSet): IntSet {.inline.} =
  ## Alias for `difference(s1, s2) <#difference,IntSet,IntSet>`_.
  result = difference(s1, s2)

proc disjoint*(s1, s2: IntSet): bool =
  ## Returns true if the sets `s1` and `s2` have no items in common.
  runnableExamples:
    var
      a = initIntSet()
      b = initIntSet()
    a.incl(1); a.incl(2)
    b.incl(2); b.incl(3)
    assert disjoint(a, b) == false
    b.excl(2)
    assert disjoint(a, b) == true

  for item in s1:
    if contains(s2, item):
      return false
  return true

proc card*(s: IntSet): int {.inline.} =
  ## Alias for `len() <#len,IntSet>`_.
  result = s.len()

proc `<=`*(s1, s2: IntSet): bool =
  ## Returns true if `s1` is subset of `s2`.
  ##
  ## A subset `s1` has all of its elements in `s2`, and `s2` doesn't necessarily
  ## have more elements than `s1`. That is, `s1` can be equal to `s2`.
  runnableExamples:
    var
      a = initIntSet()
      b = initIntSet()
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

proc `<`*(s1, s2: IntSet): bool =
  ## Returns true if `s1` is proper subset of `s2`.
  ##
  ## A strict or proper subset `s1` has all of its elements in `s2`, but `s2` has
  ## more elements than `s1`.
  runnableExamples:
    var
      a = initIntSet()
      b = initIntSet()
    a.incl(1)
    b.incl(1); b.incl(2)
    assert a < b
    a.incl(2)
    assert(not (a < b))
  return s1 <= s2 and not (s2 <= s1)

proc `==`*(s1, s2: IntSet): bool =
  ## Returns true if both `s1` and `s2` have the same elements and set size.
  return s1 <= s2 and s2 <= s1

proc `$`*(s: IntSet): string =
  ## The `$` operator for int sets.
  ##
  ## Converts the set `s` to a string, mostly for logging and printing purposes.
  dollarImpl()



when isMainModule:
  import sequtils, algorithm

  var x = initIntSet()
  x.incl(1)
  x.incl(2)
  x.incl(7)
  x.incl(1056)

  x.incl(1044)
  x.excl(1044)

  assert x.containsOrIncl(888) == false
  assert 888 in x
  assert x.containsOrIncl(888) == true

  assert x.missingOrExcl(888) == false
  assert 888 notin x
  assert x.missingOrExcl(888) == true

  var xs = toSeq(items(x))
  xs.sort(cmp[int])
  assert xs == @[1, 2, 7, 1056]

  var y: IntSet
  assign(y, x)
  var ys = toSeq(items(y))
  ys.sort(cmp[int])
  assert ys == @[1, 2, 7, 1056]

  assert x == y

  var z: IntSet
  for i in 0..1000:
    incl z, i
    assert z.len() == i+1
  for i in 0..1000:
    assert z.contains(i)

  var w = initIntSet()
  w.incl(1)
  w.incl(4)
  w.incl(50)
  w.incl(1001)
  w.incl(1056)

  var xuw = x.union(w)
  var xuws = toSeq(items(xuw))
  xuws.sort(cmp[int])
  assert xuws == @[1, 2, 4, 7, 50, 1001, 1056]

  var xiw = x.intersection(w)
  var xiws = toSeq(items(xiw))
  xiws.sort(cmp[int])
  assert xiws == @[1, 1056]

  var xdw = x.difference(w)
  var xdws = toSeq(items(xdw))
  xdws.sort(cmp[int])
  assert xdws == @[2, 7]

  var xsw = x.symmetricDifference(w)
  var xsws = toSeq(items(xsw))
  xsws.sort(cmp[int])
  assert xsws == @[2, 4, 7, 50, 1001]

  x.incl(w)
  xs = toSeq(items(x))
  xs.sort(cmp[int])
  assert xs == @[1, 2, 4, 7, 50, 1001, 1056]

  assert w <= x

  assert w < x

  assert(not disjoint(w, x))

  var u = initIntSet()
  u.incl(3)
  u.incl(5)
  u.incl(500)
  assert disjoint(u, x)

  var v = initIntSet()
  v.incl(2)
  v.incl(50)

  x.excl(v)
  xs = toSeq(items(x))
  xs.sort(cmp[int])
  assert xs == @[1, 4, 7, 1001, 1056]

  proc bug12366 =
    var
      x = initIntSet()
      y = initIntSet()
      n = 3584

    for i in 0..n:
      x.incl(i)
      y.incl(i)

    let z = symmetricDifference(x, y)
    doAssert z.len == 0
    doAssert $z == "{}"

  bug12366()
