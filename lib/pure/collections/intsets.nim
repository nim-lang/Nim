#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## The ``intsets`` module implements an efficient int set implemented as a
## `sparse bit set`:idx:.
## **Note**: Since Nim currently does not allow the assignment operator to
## be overloaded, ``=`` for int sets performs some rather meaningless shallow
## copy; use ``assign`` to get a deep copy.

import
  hashes, math

type
  BitScalar = int

const
  InitIntSetSize = 8         # must be a power of two!
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
    next: PTrunk             # all nodes are connected with this pointer
    key: int                 # start address at bit 0
    bits: array[0..IntsPerTrunk - 1, BitScalar] # a bit vector

  TrunkSeq = seq[PTrunk]
  IntSet* = object ## an efficient set of 'int' implemented as a sparse bit set
    elems: int # only valid for small numbers
    counter, max: int
    head: PTrunk
    data: TrunkSeq
    a: array[0..33, int] # profiling shows that 34 elements are enough

{.deprecated: [TIntSet: IntSet, TTrunk: Trunk, TTrunkSeq: TrunkSeq].}

proc mustRehash(length, counter: int): bool {.inline.} =
  assert(length > counter)
  result = (length * 2 < counter * 3) or (length - counter < 4)

proc nextTry(h, maxHash: Hash): Hash {.inline.} =
  result = ((5 * h) + 1) and maxHash

proc intSetGet(t: IntSet, key: int): PTrunk =
  var h = key and t.max
  while t.data[h] != nil:
    if t.data[h].key == key:
      return t.data[h]
    h = nextTry(h, t.max)
  result = nil

proc intSetRawInsert(t: IntSet, data: var TrunkSeq, desc: PTrunk) =
  var h = desc.key and t.max
  while data[h] != nil:
    assert(data[h] != desc)
    h = nextTry(h, t.max)
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
  while t.data[h] != nil:
    if t.data[h].key == key:
      return t.data[h]
    h = nextTry(h, t.max)
  if mustRehash(t.max + 1, t.counter): intSetEnlarge(t)
  inc(t.counter)
  h = key and t.max
  while t.data[h] != nil: h = nextTry(h, t.max)
  assert(t.data[h] == nil)
  new(result)
  result.next = t.head
  result.key = key
  t.head = result
  t.data[h] = result

proc contains*(s: IntSet, key: int): bool =
  ## returns true iff `key` is in `s`.
  if s.elems <= s.a.len:
    for i in 0..<s.elems:
      if s.a[i] == key: return true
  else:
    var t = intSetGet(s, `shr`(key, TrunkShift))
    if t != nil:
      var u = key and TrunkMask
      result = (t.bits[`shr`(u, IntShift)] and `shl`(1, u and IntMask)) != 0
    else:
      result = false

iterator items*(s: IntSet): int {.inline.} =
  ## iterates over any included element of `s`.
  if s.elems <= s.a.len:
    for i in 0..<s.elems:
      yield s.a[i]
  else:
    var r = s.head
    while r != nil:
      var i = 0
      while i <= high(r.bits):
        var w = r.bits[i]
        # taking a copy of r.bits[i] here is correct, because
        # modifying operations are not allowed during traversation
        var j = 0
        while w != 0:         # test all remaining bits for zero
          if (w and 1) != 0:  # the bit is set!
            yield (r.key shl TrunkShift) or (i shl IntShift +% j)
          inc(j)
          w = w shr 1
        inc(i)
      r = r.next

proc bitincl(s: var IntSet, key: int) {.inline.} =
  var t = intSetPut(s, `shr`(key, TrunkShift))
  var u = key and TrunkMask
  t.bits[`shr`(u, IntShift)] = t.bits[`shr`(u, IntShift)] or
      `shl`(1, u and IntMask)

proc incl*(s: var IntSet, key: int) =
  ## includes an element `key` in `s`.
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
  for item in other: incl(s, item)

proc exclImpl(s: var IntSet, key: int) =
  if s.elems <= s.a.len:
    for i in 0..<s.elems:
      if s.a[i] == key:
        s.a[i] = s.a[s.elems-1]
        dec s.elems
        return
  else:
    var t = intSetGet(s, `shr`(key, TrunkShift))
    if t != nil:
      var u = key and TrunkMask
      t.bits[`shr`(u, IntShift)] = t.bits[`shr`(u, IntShift)] and
          not `shl`(1, u and IntMask)

proc excl*(s: var IntSet, key: int) =
  ## excludes `key` from the set `s`.
  exclImpl(s, key)

proc excl*(s: var IntSet, other: IntSet) =
  ## Excludes all elements from `other` from `s`.
  for item in other: excl(s, item)

proc missingOrExcl*(s: var IntSet, key: int) : bool =
  ## returns true if `s` does not contain `key`, otherwise
  ## `key` is removed from `s` and false is returned.
  var count = s.elems
  exclImpl(s, key)
  result = count == s.elems 

proc containsOrIncl*(s: var IntSet, key: int): bool =
  ## returns true if `s` contains `key`, otherwise `key` is included in `s`
  ## and false is returned.
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
      result = (t.bits[`shr`(u, IntShift)] and `shl`(1, u and IntMask)) != 0
      if not result:
        t.bits[`shr`(u, IntShift)] = t.bits[`shr`(u, IntShift)] or
            `shl`(1, u and IntMask)
    else:
      incl(s, key)
      result = false

proc initIntSet*: IntSet =
  ## creates a new int set that is empty.

  #newSeq(result.data, InitIntSetSize)
  #result.max = InitIntSetSize-1
  result.data = nil
  result.max = 0
  result.counter = 0
  result.head = nil
  result.elems = 0

proc clear*(result: var IntSet) =
  #setLen(result.data, InitIntSetSize)
  #for i in 0..InitIntSetSize-1: result.data[i] = nil
  #result.max = InitIntSetSize-1
  result.data = nil
  result.max = 0
  result.counter = 0
  result.head = nil
  result.elems = 0

proc isNil*(x: IntSet): bool {.inline.} = x.head.isNil and x.elems == 0

proc assign*(dest: var IntSet, src: IntSet) =
  ## copies `src` to `dest`. `dest` does not need to be initialized by
  ## `initIntSet`.
  if src.elems <= src.a.len:
    dest.data = nil
    dest.max = 0
    dest.counter = src.counter
    dest.head = nil
    dest.elems = src.elems
    dest.a = src.a
  else:
    dest.counter = src.counter
    dest.max = src.max
    newSeq(dest.data, src.data.len)

    var it = src.head
    while it != nil:

      var h = it.key and dest.max
      while dest.data[h] != nil: h = nextTry(h, dest.max)
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
  result.assign(s1)
  incl(result, s2)

proc intersection*(s1, s2: IntSet): IntSet =
  ## Returns the intersection of the sets `s1` and `s2`.
  result = initIntSet()
  for item in s1:
    if contains(s2, item):
      incl(result, item)

proc difference*(s1, s2: IntSet): IntSet =
  ## Returns the difference of the sets `s1` and `s2`.
  result = initIntSet()
  for item in s1:
    if not contains(s2, item):
      incl(result, item)

proc symmetricDifference*(s1, s2: IntSet): IntSet =
  ## Returns the symmetric difference of the sets `s1` and `s2`.
  result.assign(s1)
  for item in s2:
    if containsOrIncl(result, item): excl(result, item)

proc `+`*(s1, s2: IntSet): IntSet {.inline.} =
  ## Alias for `union(s1, s2) <#union>`_.
  result = union(s1, s2)

proc `*`*(s1, s2: IntSet): IntSet {.inline.} =
  ## Alias for `intersection(s1, s2) <#intersection>`_.
  result = intersection(s1, s2)

proc `-`*(s1, s2: IntSet): IntSet {.inline.} =
  ## Alias for `difference(s1, s2) <#difference>`_.
  result = difference(s1, s2)

proc disjoint*(s1, s2: IntSet): bool =
  ## Returns true iff the sets `s1` and `s2` have no items in common.
  for item in s1:
    if contains(s2, item):
      return false
  return true

proc len*(s: IntSet): int {.inline.} =
  ## Returns the number of keys in `s`.
  if s.elems < s.a.len:
    result = s.elems
  else:
    result = 0
    for _ in s:
      inc(result)

proc card*(s: IntSet): int {.inline.} = 
  ## alias for `len() <#len>` _.
  result = s.len()

proc `<=`*(s1, s2: IntSet): bool =
  ## Returns true iff `s1` is subset of `s2`.
  for item in s1:
    if not s2.contains(item):
      return false
  return true

proc `<`*(s1, s2: IntSet): bool =
  ## Returns true iff `s1` is proper subset of `s2`.
  return s1 <= s2 and not (s2 <= s1)

proc `==`*(s1, s2: IntSet): bool =
  ## Returns true if both `s` and `t` have the same members and set size.
  return s1 <= s2 and s2 <= s1

template dollarImpl(): untyped =
  result = "{"
  for key in items(s):
    if result.len > 1: result.add(", ")
    result.add($key)
  result.add("}")

proc `$`*(s: IntSet): string =
  ## The `$` operator for int sets.
  dollarImpl()

proc empty*(s: IntSet): bool {.inline, deprecated.} =
  ## returns true if `s` is empty. This is safe to call even before
  ## the set has been initialized with `initIntSet`. Note this never
  ## worked reliably and so is deprecated.
  result = s.counter == 0

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
