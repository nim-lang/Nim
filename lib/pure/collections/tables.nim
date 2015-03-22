#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## The ``tables`` module implements variants of an efficient `hash table`:idx:
## (also often named `dictionary`:idx: in other programming languages) that is
## a mapping from keys to values. ``Table`` is the usual hash table,
## ``OrderedTable`` is like ``Table`` but remembers insertion order
## and ``CountTable`` is a mapping from a key to its number of occurrences.
## For consistency with every other data type in Nim these have **value**
## semantics, this means that ``=`` performs a copy of the hash table.
## For **reference** semantics use the ``Ref`` variant: ``TableRef``,
## ``OrderedTableRef``, ``CountTableRef``.
##
## If you are using simple standard types like ``int`` or ``string`` for the
## keys of the table you won't have any problems, but as soon as you try to use
## a more complex object as a key you will be greeted by a strange compiler
## error::
##
##   Error: type mismatch: got (Person)
##   but expected one of:
##   hashes.hash(x: openarray[A]): THash
##   hashes.hash(x: int): THash
##   hashes.hash(x: float): THash
##   …
##
## What is happening here is that the types used for table keys require to have
## a ``hash()`` proc which will convert them to a `THash <hashes.html#THash>`_
## value, and the compiler is listing all the hash functions it knows.
## Additionally there has to be a ``==`` operator that provides the same
## semantics as its corresponding ``hash`` proc.
##
## After you add ``hash`` and ``==`` for your custom type everything will work.
## Currently however ``hash`` for objects is not defined, whereas
## ``system.==`` for objects does exist and performs a "deep" comparison (every
## field is compared) which is usually what you want. So in the following
## example implementing only ``hash`` suffices:
##
## .. code-block::
##   type
##     Person = object
##       firstName, lastName: string
##
##   proc hash(x: Person): THash =
##     ## Piggyback on the already available string hash proc.
##     ##
##     ## Without this proc nothing works!
##     result = x.firstName.hash !& x.lastName.hash
##     result = !$result
##
##   var
##     salaries = initTable[Person, int]()
##     p1, p2: Person
##
##   p1.firstName = "Jon"
##   p1.lastName = "Ross"
##   salaries[p1] = 30_000
##
##   p2.firstName = "소진"
##   p2.lastName = "박"
##   salaries[p2] = 45_000

import
  hashes, math

{.pragma: myShallow.}

type
  KeyValuePair[A, B] = tuple[hcode: THash, key: A, val: B]
  KeyValuePairSeq[A, B] = seq[KeyValuePair[A, B]]
  Table* {.myShallow.}[A, B] = object ## generic hash table
    data: KeyValuePairSeq[A, B]
    counter: int
  TableRef*[A,B] = ref Table[A, B]

{.deprecated: [TTable: Table, PTable: TableRef].}

when not defined(nimhygiene):
  {.pragma: dirty.}

# hcode for real keys cannot be zero.  hcode==0 signifies an empty slot.  These
# two procs retain clarity of that encoding without the space cost of an enum.
proc isEmpty(hcode: THash): bool {.inline.} =
  result = hcode == 0

proc isFilled(hcode: THash): bool {.inline.} =
  result = hcode != 0

proc len*[A, B](t: Table[A, B]): int =
  ## returns the number of keys in `t`.
  result = t.counter

iterator pairs*[A, B](t: Table[A, B]): (A, B) =
  ## iterates over any (key, value) pair in the table `t`.
  for h in 0..high(t.data):
    if isFilled(t.data[h].hcode): yield (t.data[h].key, t.data[h].val)

iterator mpairs*[A, B](t: var Table[A, B]): (A, var B) =
  ## iterates over any (key, value) pair in the table `t`. The values
  ## can be modified.
  for h in 0..high(t.data):
    if isFilled(t.data[h].hcode): yield (t.data[h].key, t.data[h].val)

iterator keys*[A, B](t: Table[A, B]): A =
  ## iterates over any key in the table `t`.
  for h in 0..high(t.data):
    if isFilled(t.data[h].hcode): yield t.data[h].key

iterator values*[A, B](t: Table[A, B]): B =
  ## iterates over any value in the table `t`.
  for h in 0..high(t.data):
    if isFilled(t.data[h].hcode): yield t.data[h].val

iterator mvalues*[A, B](t: var Table[A, B]): var B =
  ## iterates over any value in the table `t`. The values can be modified.
  for h in 0..high(t.data):
    if isFilled(t.data[h].hcode): yield t.data[h].val

const
  growthFactor = 2

proc mustRehash(length, counter: int): bool {.inline.} =
  assert(length > counter)
  result = (length * 2 < counter * 3) or (length - counter < 4)

proc rightSize*(count: int): int {.inline.} =
  ## Return the value of `initialSize` to support `count` items.
  ##
  ## If more items are expected to be added, simply add that
  ## expected extra amount to the parameter before calling this.
  ##
  ## Internally, we want mustRehash(rightSize(x), x) == false.
  result = nextPowerOfTwo(count * 3 div 2  +  4)

proc nextTry(h, maxHash: THash): THash {.inline.} =
  result = (h + 1) and maxHash

template rawGetKnownHCImpl() {.dirty.} =
  var h: THash = hc and high(t.data)   # start with real hash value
  while isFilled(t.data[h].hcode):
    # Compare hc THEN key with boolean short circuit. This makes the common case
    # zero ==key's for missing (e.g.inserts) and exactly one ==key for present.
    # It does slow down succeeding lookups by one extra THash cmp&and..usually
    # just a few clock cycles, generally worth it for any non-integer-like A.
    if t.data[h].hcode == hc and t.data[h].key == key:
      return h
    h = nextTry(h, high(t.data))
  result = -1 - h                   # < 0 => MISSING; insert idx = -1 - result

template rawGetImpl() {.dirty.} =
  hc = hash(key)
  if hc == 0:       # This almost never taken branch should be very predictable.
    hc = 314159265  # Value doesn't matter; Any non-zero favorite is fine.
  rawGetKnownHCImpl()

template rawGetDeepImpl() {.dirty.} =   # Search algo for unconditional add
  hc = hash(key)
  if hc == 0:
    hc = 314159265
  var h: THash = hc and high(t.data)
  while isFilled(t.data[h].hcode):
    h = nextTry(h, high(t.data))
  result = h

template rawInsertImpl() {.dirty.} =
  data[h].key = key
  data[h].val = val
  data[h].hcode = hc

proc rawGetKnownHC[A, B](t: Table[A, B], key: A, hc: THash): int {.inline.} =
  rawGetKnownHCImpl()

proc rawGetDeep[A, B](t: Table[A, B], key: A, hc: var THash): int {.inline.} =
  rawGetDeepImpl()

proc rawGet[A, B](t: Table[A, B], key: A, hc: var THash): int {.inline.} =
  rawGetImpl()

proc `[]`*[A, B](t: Table[A, B], key: A): B =
  ## retrieves the value at ``t[key]``. If `key` is not in `t`,
  ## default empty value for the type `B` is returned
  ## and no exception is raised. One can check with ``hasKey`` whether the key
  ## exists.
  var hc: THash
  var index = rawGet(t, key, hc)
  if index >= 0: result = t.data[index].val

proc mget*[A, B](t: var Table[A, B], key: A): var B =
  ## retrieves the value at ``t[key]``. The value can be modified.
  ## If `key` is not in `t`, the ``KeyError`` exception is raised.
  var hc: THash
  var index = rawGet(t, key, hc)
  if index >= 0: result = t.data[index].val
  else:
    when compiles($key):
      raise newException(KeyError, "key not found: " & $key)
    else:
      raise newException(KeyError, "key not found")

iterator allValues*[A, B](t: Table[A, B]; key: A): B =
  ## iterates over any value in the table `t` that belongs to the given `key`.
  var h: THash = hash(key) and high(t.data)
  while isFilled(t.data[h].hcode):
    if t.data[h].key == key:
      yield t.data[h].val
    h = nextTry(h, high(t.data))

proc hasKey*[A, B](t: Table[A, B], key: A): bool =
  ## returns true iff `key` is in the table `t`.
  var hc: THash
  result = rawGet(t, key, hc) >= 0

proc rawInsert[A, B](t: var Table[A, B], data: var KeyValuePairSeq[A, B],
                     key: A, val: B, hc: THash, h: THash) =
  rawInsertImpl()

proc enlarge[A, B](t: var Table[A, B]) =
  var n: KeyValuePairSeq[A, B]
  newSeq(n, len(t.data) * growthFactor)
  swap(t.data, n)
  for i in countup(0, high(n)):
    if isFilled(n[i].hcode):
      var j = -1 - rawGetKnownHC(t, n[i].key, n[i].hcode)
      rawInsert(t, t.data, n[i].key, n[i].val, n[i].hcode, j)

template addImpl() {.dirty.} =
  if mustRehash(len(t.data), t.counter): enlarge(t)
  var hc: THash
  var j = rawGetDeep(t, key, hc)
  rawInsert(t, t.data, key, val, hc, j)
  inc(t.counter)

template maybeRehashPutImpl() {.dirty.} =
  if mustRehash(len(t.data), t.counter):
    enlarge(t)
    index = rawGetKnownHC(t, key, hc)
  index = -1 - index                  # important to transform for mgetOrPutImpl
  rawInsert(t, t.data, key, val, hc, index)
  inc(t.counter)

template putImpl() {.dirty.} =
  var hc: THash
  var index = rawGet(t, key, hc)
  if index >= 0: t.data[index].val = val
  else: maybeRehashPutImpl()

template mgetOrPutImpl() {.dirty.} =
  var hc: THash
  var index = rawGet(t, key, hc)
  if index < 0: maybeRehashPutImpl()    # not present: insert (flipping index)
  result = t.data[index].val            # either way return modifiable val

template hasKeyOrPutImpl() {.dirty.} =
  var hc: THash
  var index = rawGet(t, key, hc)
  if index < 0:
    result = false
    maybeRehashPutImpl()
  else: result = true

proc mgetOrPut*[A, B](t: var Table[A, B], key: A, val: B): var B =
  ## retrieves value at ``t[key]`` or puts ``val`` if not present, either way
  ## returning a value which can be modified.
  mgetOrPutImpl()

proc hasKeyOrPut*[A, B](t: var Table[A, B], key: A, val: B): bool =
  ## returns true iff `key` is in the table, otherwise inserts `value`.
  hasKeyOrPutImpl()

proc `[]=`*[A, B](t: var Table[A, B], key: A, val: B) =
  ## puts a (key, value)-pair into `t`.
  putImpl()

proc add*[A, B](t: var Table[A, B], key: A, val: B) =
  ## puts a new (key, value)-pair into `t` even if ``t[key]`` already exists.
  addImpl()

template doWhile(a: expr, b: stmt): stmt =
  while true:
    b
    if not a: break

proc del*[A, B](t: var Table[A, B], key: A) =
  ## deletes `key` from hash table `t`.
  var hc: THash
  var i = rawGet(t, key, hc)
  let msk = high(t.data)
  if i >= 0:
    t.data[i].hcode = 0
    dec(t.counter)
    while true:         # KnuthV3 Algo6.4R adapted for i=i+1 instead of i=i-1
      var j = i         # The correctness of this depends on (h+1) in nextTry,
      var r = j         # though may be adaptable to other simple sequences.
      t.data[i].hcode = 0              # mark current EMPTY
      doWhile ((i >= r and r > j) or (r > j and j > i) or (j > i and i >= r)):
        i = (i + 1) and msk            # increment mod table size
        if isEmpty(t.data[i].hcode):   # end of collision cluster; So all done
          return
        r = t.data[i].hcode and msk    # "home" location of key@i
      shallowCopy(t.data[j], t.data[i]) # data[j] will be marked EMPTY next loop

proc initTable*[A, B](initialSize=64): Table[A, B] =
  ## creates a new hash table that is empty.
  ##
  ## `initialSize` needs to be a power of two. If you need to accept runtime
  ## values for this you could use the ``nextPowerOfTwo`` proc from the
  ## `math <math.html>`_ module or the ``rightSize`` proc from this module.
  assert isPowerOfTwo(initialSize)
  result.counter = 0
  newSeq(result.data, initialSize)

proc toTable*[A, B](pairs: openArray[(A,
                    B)]): Table[A, B] =
  ## creates a new hash table that contains the given `pairs`.
  result = initTable[A, B](rightSize(pairs.len))
  for key, val in items(pairs): result[key] = val

template dollarImpl(): stmt {.dirty.} =
  if t.len == 0:
    result = "{:}"
  else:
    result = "{"
    for key, val in pairs(t):
      if result.len > 1: result.add(", ")
      result.add($key)
      result.add(": ")
      result.add($val)
    result.add("}")

proc `$`*[A, B](t: Table[A, B]): string =
  ## The `$` operator for hash tables.
  dollarImpl()

template equalsImpl() =
  if s.counter == t.counter:
    # different insertion orders mean different 'data' seqs, so we have
    # to use the slow route here:
    for key, val in s:
      # prefix notation leads to automatic dereference in case of PTable
      if not t.hasKey(key): return false
      if t[key] != val: return false
    return true

proc `==`*[A, B](s, t: Table[A, B]): bool =
  equalsImpl()

proc indexBy*[A, B, C](collection: A, index: proc(x: B): C): Table[C, B] =
  ## Index the collection with the proc provided.
  # TODO: As soon as supported, change collection: A to collection: A[B]
  result = initTable[C, B]()
  for item in collection:
    result[index(item)] = item

proc len*[A, B](t: TableRef[A, B]): int =
  ## returns the number of keys in `t`.
  result = t.counter

iterator pairs*[A, B](t: TableRef[A, B]): (A, B) =
  ## iterates over any (key, value) pair in the table `t`.
  for h in 0..high(t.data):
    if isFilled(t.data[h].hcode): yield (t.data[h].key, t.data[h].val)

iterator mpairs*[A, B](t: TableRef[A, B]): (A, var B) =
  ## iterates over any (key, value) pair in the table `t`. The values
  ## can be modified.
  for h in 0..high(t.data):
    if isFilled(t.data[h].hcode): yield (t.data[h].key, t.data[h].val)

iterator keys*[A, B](t: TableRef[A, B]): A =
  ## iterates over any key in the table `t`.
  for h in 0..high(t.data):
    if isFilled(t.data[h].hcode): yield t.data[h].key

iterator values*[A, B](t: TableRef[A, B]): B =
  ## iterates over any value in the table `t`.
  for h in 0..high(t.data):
    if isFilled(t.data[h].hcode): yield t.data[h].val

iterator mvalues*[A, B](t: TableRef[A, B]): var B =
  ## iterates over any value in the table `t`. The values can be modified.
  for h in 0..high(t.data):
    if isFilled(t.data[h].hcode): yield t.data[h].val

proc `[]`*[A, B](t: TableRef[A, B], key: A): B =
  ## retrieves the value at ``t[key]``. If `key` is not in `t`,
  ## default empty value for the type `B` is returned
  ## and no exception is raised. One can check with ``hasKey`` whether the key
  ## exists.
  result = t[][key]

proc mget*[A, B](t: TableRef[A, B], key: A): var B =
  ## retrieves the value at ``t[key]``. The value can be modified.
  ## If `key` is not in `t`, the ``EInvalidKey`` exception is raised.
  t[].mget(key)

proc mgetOrPut*[A, B](t: TableRef[A, B], key: A, val: B): var B =
  ## retrieves value at ``t[key]`` or puts ``val`` if not present, either way
  ## returning a value which can be modified.
  t[].mgetOrPut(key, val)

proc hasKeyOrPut*[A, B](t: var TableRef[A, B], key: A, val: B): bool =
  ## returns true iff `key` is in the table, otherwise inserts `value`.
  t[].hasKeyOrPut(key, val)

proc hasKey*[A, B](t: TableRef[A, B], key: A): bool =
  ## returns true iff `key` is in the table `t`.
  result = t[].hasKey(key)

proc `[]=`*[A, B](t: TableRef[A, B], key: A, val: B) =
  ## puts a (key, value)-pair into `t`.
  t[][key] = val

proc add*[A, B](t: TableRef[A, B], key: A, val: B) =
  ## puts a new (key, value)-pair into `t` even if ``t[key]`` already exists.
  t[].add(key, val)

proc del*[A, B](t: TableRef[A, B], key: A) =
  ## deletes `key` from hash table `t`.
  t[].del(key)

proc newTable*[A, B](initialSize=64): TableRef[A, B] =
  new(result)
  result[] = initTable[A, B](initialSize)

proc newTable*[A, B](pairs: openArray[(A, B)]): TableRef[A, B] =
  ## creates a new hash table that contains the given `pairs`.
  new(result)
  result[] = toTable[A, B](pairs)

proc `$`*[A, B](t: TableRef[A, B]): string =
  ## The `$` operator for hash tables.
  dollarImpl()

proc `==`*[A, B](s, t: TableRef[A, B]): bool =
  if isNil(s): result = isNil(t)
  elif isNil(t): result = false
  else: equalsImpl()

proc newTableFrom*[A, B, C](collection: A, index: proc(x: B): C): TableRef[C, B] =
  ## Index the collection with the proc provided.
  # TODO: As soon as supported, change collection: A to collection: A[B]
  result = newTable[C, B]()
  for item in collection:
    result[index(item)] = item

# ------------------------------ ordered table ------------------------------

type
  OrderedKeyValuePair[A, B] = tuple[
    hcode: THash, next: int, key: A, val: B]
  OrderedKeyValuePairSeq[A, B] = seq[OrderedKeyValuePair[A, B]]
  OrderedTable* {.
      myShallow.}[A, B] = object ## table that remembers insertion order
    data: OrderedKeyValuePairSeq[A, B]
    counter, first, last: int
  OrderedTableRef*[A, B] = ref OrderedTable[A, B]

{.deprecated: [TOrderedTable: OrderedTable, POrderedTable: OrderedTableRef].}

proc len*[A, B](t: OrderedTable[A, B]): int {.inline.} =
  ## returns the number of keys in `t`.
  result = t.counter

template forAllOrderedPairs(yieldStmt: stmt) {.dirty, immediate.} =
  var h = t.first
  while h >= 0:
    var nxt = t.data[h].next
    if isFilled(t.data[h].hcode): yieldStmt
    h = nxt

iterator pairs*[A, B](t: OrderedTable[A, B]): (A, B) =
  ## iterates over any (key, value) pair in the table `t` in insertion
  ## order.
  forAllOrderedPairs:
    yield (t.data[h].key, t.data[h].val)

iterator mpairs*[A, B](t: var OrderedTable[A, B]): (A, var B) =
  ## iterates over any (key, value) pair in the table `t` in insertion
  ## order. The values can be modified.
  forAllOrderedPairs:
    yield (t.data[h].key, t.data[h].val)

iterator keys*[A, B](t: OrderedTable[A, B]): A =
  ## iterates over any key in the table `t` in insertion order.
  forAllOrderedPairs:
    yield t.data[h].key

iterator values*[A, B](t: OrderedTable[A, B]): B =
  ## iterates over any value in the table `t` in insertion order.
  forAllOrderedPairs:
    yield t.data[h].val

iterator mvalues*[A, B](t: var OrderedTable[A, B]): var B =
  ## iterates over any value in the table `t` in insertion order. The values
  ## can be modified.
  forAllOrderedPairs:
    yield t.data[h].val

proc rawGetKnownHC[A, B](t: OrderedTable[A, B], key: A, hc: THash): int =
  rawGetKnownHCImpl()

proc rawGetDeep[A, B](t: OrderedTable[A, B], key: A, hc: var THash): int {.inline.} =
  rawGetDeepImpl()

proc rawGet[A, B](t: OrderedTable[A, B], key: A, hc: var THash): int =
  rawGetImpl()

proc `[]`*[A, B](t: OrderedTable[A, B], key: A): B =
  ## retrieves the value at ``t[key]``. If `key` is not in `t`,
  ## default empty value for the type `B` is returned
  ## and no exception is raised. One can check with ``hasKey`` whether the key
  ## exists.
  var hc: THash
  var index = rawGet(t, key, hc)
  if index >= 0: result = t.data[index].val

proc mget*[A, B](t: var OrderedTable[A, B], key: A): var B =
  ## retrieves the value at ``t[key]``. The value can be modified.
  ## If `key` is not in `t`, the ``EInvalidKey`` exception is raised.
  var hc: THash
  var index = rawGet(t, key, hc)
  if index >= 0: result = t.data[index].val
  else: raise newException(KeyError, "key not found: " & $key)

proc hasKey*[A, B](t: OrderedTable[A, B], key: A): bool =
  ## returns true iff `key` is in the table `t`.
  var hc: THash
  result = rawGet(t, key, hc) >= 0

proc rawInsert[A, B](t: var OrderedTable[A, B],
                     data: var OrderedKeyValuePairSeq[A, B],
                     key: A, val: B, hc: THash, h: THash) =
  rawInsertImpl()
  data[h].next = -1
  if t.first < 0: t.first = h
  if t.last >= 0: data[t.last].next = h
  t.last = h

proc enlarge[A, B](t: var OrderedTable[A, B]) =
  var n: OrderedKeyValuePairSeq[A, B]
  newSeq(n, len(t.data) * growthFactor)
  var h = t.first
  t.first = -1
  t.last = -1
  swap(t.data, n)
  while h >= 0:
    var nxt = n[h].next
    if isFilled(n[h].hcode):
      var j = -1 - rawGetKnownHC(t, n[h].key, n[h].hcode)
      rawInsert(t, t.data, n[h].key, n[h].val, n[h].hcode, j)
    h = nxt

proc `[]=`*[A, B](t: var OrderedTable[A, B], key: A, val: B) =
  ## puts a (key, value)-pair into `t`.
  putImpl()

proc add*[A, B](t: var OrderedTable[A, B], key: A, val: B) =
  ## puts a new (key, value)-pair into `t` even if ``t[key]`` already exists.
  addImpl()

proc mgetOrPut*[A, B](t: var OrderedTable[A, B], key: A, val: B): var B =
  ## retrieves value at ``t[key]`` or puts ``value`` if not present, either way
  ## returning a value which can be modified.
  mgetOrPutImpl()

proc hasKeyOrPut*[A, B](t: var OrderedTable[A, B], key: A, val: B): bool =
  ## returns true iff `key` is in the table, otherwise inserts `value`.
  hasKeyOrPutImpl()

proc initOrderedTable*[A, B](initialSize=64): OrderedTable[A, B] =
  ## creates a new ordered hash table that is empty.
  ##
  ## `initialSize` needs to be a power of two. If you need to accept runtime
  ## values for this you could use the ``nextPowerOfTwo`` proc from the
  ## `math <math.html>`_ module or the ``rightSize`` proc from this module.
  assert isPowerOfTwo(initialSize)
  result.counter = 0
  result.first = -1
  result.last = -1
  newSeq(result.data, initialSize)

proc toOrderedTable*[A, B](pairs: openArray[(A,
                           B)]): OrderedTable[A, B] =
  ## creates a new ordered hash table that contains the given `pairs`.
  result = initOrderedTable[A, B](rightSize(pairs.len))
  for key, val in items(pairs): result[key] = val

proc `$`*[A, B](t: OrderedTable[A, B]): string =
  ## The `$` operator for ordered hash tables.
  dollarImpl()

proc sort*[A, B](t: var OrderedTable[A, B],
                 cmp: proc (x,y: (A, B)): int) =
  ## sorts `t` according to `cmp`. This modifies the internal list
  ## that kept the insertion order, so insertion order is lost after this
  ## call but key lookup and insertions remain possible after `sort` (in
  ## contrast to the `sort` for count tables).
  var list = t.first
  var
    p, q, e, tail, oldhead: int
    nmerges, psize, qsize, i: int
  if t.counter == 0: return
  var insize = 1
  while true:
    p = list; oldhead = list
    list = -1; tail = -1; nmerges = 0
    while p >= 0:
      inc(nmerges)
      q = p
      psize = 0
      i = 0
      while i < insize:
        inc(psize)
        q = t.data[q].next
        if q < 0: break
        inc(i)
      qsize = insize
      while psize > 0 or (qsize > 0 and q >= 0):
        if psize == 0:
          e = q; q = t.data[q].next; dec(qsize)
        elif qsize == 0 or q < 0:
          e = p; p = t.data[p].next; dec(psize)
        elif cmp((t.data[p].key, t.data[p].val),
                 (t.data[q].key, t.data[q].val)) <= 0:
          e = p; p = t.data[p].next; dec(psize)
        else:
          e = q; q = t.data[q].next; dec(qsize)
        if tail >= 0: t.data[tail].next = e
        else: list = e
        tail = e
      p = q
    t.data[tail].next = -1
    if nmerges <= 1: break
    insize = insize * 2
  t.first = list
  t.last = tail

proc len*[A, B](t: OrderedTableRef[A, B]): int {.inline.} =
  ## returns the number of keys in `t`.
  result = t.counter

template forAllOrderedPairs(yieldStmt: stmt) {.dirty, immediate.} =
  var h = t.first
  while h >= 0:
    var nxt = t.data[h].next
    if isFilled(t.data[h].hcode): yieldStmt
    h = nxt

iterator pairs*[A, B](t: OrderedTableRef[A, B]): (A, B) =
  ## iterates over any (key, value) pair in the table `t` in insertion
  ## order.
  forAllOrderedPairs:
    yield (t.data[h].key, t.data[h].val)

iterator mpairs*[A, B](t: OrderedTableRef[A, B]): (A, var B) =
  ## iterates over any (key, value) pair in the table `t` in insertion
  ## order. The values can be modified.
  forAllOrderedPairs:
    yield (t.data[h].key, t.data[h].val)

iterator keys*[A, B](t: OrderedTableRef[A, B]): A =
  ## iterates over any key in the table `t` in insertion order.
  forAllOrderedPairs:
    yield t.data[h].key

iterator values*[A, B](t: OrderedTableRef[A, B]): B =
  ## iterates over any value in the table `t` in insertion order.
  forAllOrderedPairs:
    yield t.data[h].val

iterator mvalues*[A, B](t: OrderedTableRef[A, B]): var B =
  ## iterates over any value in the table `t` in insertion order. The values
  ## can be modified.
  forAllOrderedPairs:
    yield t.data[h].val

proc `[]`*[A, B](t: OrderedTableRef[A, B], key: A): B =
  ## retrieves the value at ``t[key]``. If `key` is not in `t`,
  ## default empty value for the type `B` is returned
  ## and no exception is raised. One can check with ``hasKey`` whether the key
  ## exists.
  result = t[][key]

proc mget*[A, B](t: OrderedTableRef[A, B], key: A): var B =
  ## retrieves the value at ``t[key]``. The value can be modified.
  ## If `key` is not in `t`, the ``EInvalidKey`` exception is raised.
  result = t[].mget(key)

proc mgetOrPut*[A, B](t: OrderedTableRef[A, B], key: A, val: B): var B =
  ## retrieves value at ``t[key]`` or puts ``val`` if not present, either way
  ## returning a value which can be modified.
  result = t[].mgetOrPut(key, val)

proc hasKeyOrPut*[A, B](t: var OrderedTableRef[A, B], key: A, val: B): bool =
  ## returns true iff `key` is in the table, otherwise inserts `val`.
  result = t[].hasKeyOrPut(key, val)

proc hasKey*[A, B](t: OrderedTableRef[A, B], key: A): bool =
  ## returns true iff `key` is in the table `t`.
  result = t[].hasKey(key)

proc `[]=`*[A, B](t: OrderedTableRef[A, B], key: A, val: B) =
  ## puts a (key, value)-pair into `t`.
  t[][key] = val

proc add*[A, B](t: OrderedTableRef[A, B], key: A, val: B) =
  ## puts a new (key, value)-pair into `t` even if ``t[key]`` already exists.
  t[].add(key, val)

proc newOrderedTable*[A, B](initialSize=64): OrderedTableRef[A, B] =
  ## creates a new ordered hash table that is empty.
  ##
  ## `initialSize` needs to be a power of two. If you need to accept runtime
  ## values for this you could use the ``nextPowerOfTwo`` proc from the
  ## `math <math.html>`_ module or the ``rightSize`` proc from this module.
  new(result)
  result[] = initOrderedTable[A, B]()

proc newOrderedTable*[A, B](pairs: openArray[(A, B)]): OrderedTableRef[A, B] =
  ## creates a new ordered hash table that contains the given `pairs`.
  result = newOrderedTable[A, B](rightSize(pairs.len))
  for key, val in items(pairs): result[key] = val

proc `$`*[A, B](t: OrderedTableRef[A, B]): string =
  ## The `$` operator for ordered hash tables.
  dollarImpl()

proc sort*[A, B](t: OrderedTableRef[A, B],
                 cmp: proc (x,y: (A, B)): int) =
  ## sorts `t` according to `cmp`. This modifies the internal list
  ## that kept the insertion order, so insertion order is lost after this
  ## call but key lookup and insertions remain possible after `sort` (in
  ## contrast to the `sort` for count tables).
  t[].sort(cmp)

# ------------------------------ count tables -------------------------------

type
  CountTable* {.myShallow.}[
      A] = object ## table that counts the number of each key
    data: seq[tuple[key: A, val: int]]
    counter: int
  CountTableRef*[A] = ref CountTable[A]

{.deprecated: [TCountTable: CountTable, PCountTable: CountTableRef].}

proc len*[A](t: CountTable[A]): int =
  ## returns the number of keys in `t`.
  result = t.counter

iterator pairs*[A](t: CountTable[A]): (A, int) =
  ## iterates over any (key, value) pair in the table `t`.
  for h in 0..high(t.data):
    if t.data[h].val != 0: yield (t.data[h].key, t.data[h].val)

iterator mpairs*[A](t: var CountTable[A]): (A, var int) =
  ## iterates over any (key, value) pair in the table `t`. The values can
  ## be modified.
  for h in 0..high(t.data):
    if t.data[h].val != 0: yield (t.data[h].key, t.data[h].val)

iterator keys*[A](t: CountTable[A]): A =
  ## iterates over any key in the table `t`.
  for h in 0..high(t.data):
    if t.data[h].val != 0: yield t.data[h].key

iterator values*[A](t: CountTable[A]): int =
  ## iterates over any value in the table `t`.
  for h in 0..high(t.data):
    if t.data[h].val != 0: yield t.data[h].val

iterator mvalues*[A](t: CountTable[A]): var int =
  ## iterates over any value in the table `t`. The values can be modified.
  for h in 0..high(t.data):
    if t.data[h].val != 0: yield t.data[h].val

proc rawGet[A](t: CountTable[A], key: A): int =
  var h: THash = hash(key) and high(t.data) # start with real hash value
  while t.data[h].val != 0:
    if t.data[h].key == key: return h
    h = nextTry(h, high(t.data))
  result = -1 - h                   # < 0 => MISSING; insert idx = -1 - result

proc `[]`*[A](t: CountTable[A], key: A): int =
  ## retrieves the value at ``t[key]``. If `key` is not in `t`,
  ## 0 is returned. One can check with ``hasKey`` whether the key
  ## exists.
  var index = rawGet(t, key)
  if index >= 0: result = t.data[index].val

proc mget*[A](t: var CountTable[A], key: A): var int =
  ## retrieves the value at ``t[key]``. The value can be modified.
  ## If `key` is not in `t`, the ``EInvalidKey`` exception is raised.
  var index = rawGet(t, key)
  if index >= 0: result = t.data[index].val
  else: raise newException(KeyError, "key not found: " & $key)

proc hasKey*[A](t: CountTable[A], key: A): bool =
  ## returns true iff `key` is in the table `t`.
  result = rawGet(t, key) >= 0

proc rawInsert[A](t: CountTable[A], data: var seq[tuple[key: A, val: int]],
                  key: A, val: int) =
  var h: THash = hash(key) and high(data)
  while data[h].val != 0: h = nextTry(h, high(data))
  data[h].key = key
  data[h].val = val

proc enlarge[A](t: var CountTable[A]) =
  var n: seq[tuple[key: A, val: int]]
  newSeq(n, len(t.data) * growthFactor)
  for i in countup(0, high(t.data)):
    if t.data[i].val != 0: rawInsert(t, n, t.data[i].key, t.data[i].val)
  swap(t.data, n)

proc `[]=`*[A](t: var CountTable[A], key: A, val: int) =
  ## puts a (key, value)-pair into `t`. `val` has to be positive.
  assert val > 0
  var h = rawGet(t, key)
  if h >= 0:
    t.data[h].val = val
  else:
    h = -1 - h
    t.data[h].key = key
    t.data[h].val = val

proc initCountTable*[A](initialSize=64): CountTable[A] =
  ## creates a new count table that is empty.
  ##
  ## `initialSize` needs to be a power of two. If you need to accept runtime
  ## values for this you could use the ``nextPowerOfTwo`` proc from the
  ## `math <math.html>`_ module or the ``rightSize`` proc in this module.
  assert isPowerOfTwo(initialSize)
  result.counter = 0
  newSeq(result.data, initialSize)

proc toCountTable*[A](keys: openArray[A]): CountTable[A] =
  ## creates a new count table with every key in `keys` having a count of 1.
  result = initCountTable[A](rightSize(keys.len))
  for key in items(keys): result[key] = 1

proc `$`*[A](t: CountTable[A]): string =
  ## The `$` operator for count tables.
  dollarImpl()

proc inc*[A](t: var CountTable[A], key: A, val = 1) =
  ## increments `t[key]` by `val`.
  var index = rawGet(t, key)
  if index >= 0:
    inc(t.data[index].val, val)
  else:
    if mustRehash(len(t.data), t.counter): enlarge(t)
    rawInsert(t, t.data, key, val)
    inc(t.counter)

proc smallest*[A](t: CountTable[A]): tuple[key: A, val: int] =
  ## returns the largest (key,val)-pair. Efficiency: O(n)
  assert t.len > 0
  var minIdx = 0
  for h in 1..high(t.data):
    if t.data[h].val > 0 and t.data[minIdx].val > t.data[h].val: minIdx = h
  result.key = t.data[minIdx].key
  result.val = t.data[minIdx].val

proc largest*[A](t: CountTable[A]): tuple[key: A, val: int] =
  ## returns the (key,val)-pair with the largest `val`. Efficiency: O(n)
  assert t.len > 0
  var maxIdx = 0
  for h in 1..high(t.data):
    if t.data[maxIdx].val < t.data[h].val: maxIdx = h
  result.key = t.data[maxIdx].key
  result.val = t.data[maxIdx].val

proc sort*[A](t: var CountTable[A]) =
  ## sorts the count table so that the entry with the highest counter comes
  ## first. This is destructive! You must not modify `t` afterwards!
  ## You can use the iterators `pairs`,  `keys`, and `values` to iterate over
  ## `t` in the sorted order.

  # we use shellsort here; fast enough and simple
  var h = 1
  while true:
    h = 3 * h + 1
    if h >= high(t.data): break
  while true:
    h = h div 3
    for i in countup(h, high(t.data)):
      var j = i
      while t.data[j-h].val <= t.data[j].val:
        swap(t.data[j], t.data[j-h])
        j = j-h
        if j < h: break
    if h == 1: break

proc len*[A](t: CountTableRef[A]): int =
  ## returns the number of keys in `t`.
  result = t.counter

iterator pairs*[A](t: CountTableRef[A]): (A, int) =
  ## iterates over any (key, value) pair in the table `t`.
  for h in 0..high(t.data):
    if t.data[h].val != 0: yield (t.data[h].key, t.data[h].val)

iterator mpairs*[A](t: CountTableRef[A]): (A, var int) =
  ## iterates over any (key, value) pair in the table `t`. The values can
  ## be modified.
  for h in 0..high(t.data):
    if t.data[h].val != 0: yield (t.data[h].key, t.data[h].val)

iterator keys*[A](t: CountTableRef[A]): A =
  ## iterates over any key in the table `t`.
  for h in 0..high(t.data):
    if t.data[h].val != 0: yield t.data[h].key

iterator values*[A](t: CountTableRef[A]): int =
  ## iterates over any value in the table `t`.
  for h in 0..high(t.data):
    if t.data[h].val != 0: yield t.data[h].val

iterator mvalues*[A](t: CountTableRef[A]): var int =
  ## iterates over any value in the table `t`. The values can be modified.
  for h in 0..high(t.data):
    if t.data[h].val != 0: yield t.data[h].val

proc `[]`*[A](t: CountTableRef[A], key: A): int =
  ## retrieves the value at ``t[key]``. If `key` is not in `t`,
  ## 0 is returned. One can check with ``hasKey`` whether the key
  ## exists.
  result = t[][key]

proc mget*[A](t: CountTableRef[A], key: A): var int =
  ## retrieves the value at ``t[key]``. The value can be modified.
  ## If `key` is not in `t`, the ``EInvalidKey`` exception is raised.
  result = t[].mget(key)

proc hasKey*[A](t: CountTableRef[A], key: A): bool =
  ## returns true iff `key` is in the table `t`.
  result = t[].hasKey(key)

proc `[]=`*[A](t: CountTableRef[A], key: A, val: int) =
  ## puts a (key, value)-pair into `t`. `val` has to be positive.
  assert val > 0
  t[][key] = val

proc newCountTable*[A](initialSize=64): CountTableRef[A] =
  ## creates a new count table that is empty.
  ##
  ## `initialSize` needs to be a power of two. If you need to accept runtime
  ## values for this you could use the ``nextPowerOfTwo`` proc from the
  ## `math <math.html>`_ module or the ``rightSize`` method in this module.
  new(result)
  result[] = initCountTable[A](initialSize)

proc newCountTable*[A](keys: openArray[A]): CountTableRef[A] =
  ## creates a new count table with every key in `keys` having a count of 1.
  result = newCountTable[A](rightSize(keys.len))
  for key in items(keys): result[key] = 1

proc `$`*[A](t: CountTableRef[A]): string =
  ## The `$` operator for count tables.
  dollarImpl()

proc inc*[A](t: CountTableRef[A], key: A, val = 1) =
  ## increments `t[key]` by `val`.
  t[].inc(key, val)

proc smallest*[A](t: CountTableRef[A]): (A, int) =
  ## returns the largest (key,val)-pair. Efficiency: O(n)
  t[].smallest

proc largest*[A](t: CountTableRef[A]): (A, int) =
  ## returns the (key,val)-pair with the largest `val`. Efficiency: O(n)
  t[].largest

proc sort*[A](t: CountTableRef[A]) =
  ## sorts the count table so that the entry with the highest counter comes
  ## first. This is destructive! You must not modify `t` afterwards!
  ## You can use the iterators `pairs`,  `keys`, and `values` to iterate over
  ## `t` in the sorted order.
  t[].sort

when isMainModule:
  type
    Person = object
      firstName, lastName: string

  proc hash(x: Person): THash =
    ## Piggyback on the already available string hash proc.
    ##
    ## Without this proc nothing works!
    result = x.firstName.hash !& x.lastName.hash
    result = !$result

  var
    salaries = initTable[Person, int]()
    p1, p2: Person
  p1.firstName = "Jon"
  p1.lastName = "Ross"
  salaries[p1] = 30_000
  p2.firstName = "소진"
  p2.lastName = "박"
  salaries[p2] = 45_000
  var
    s2 = initOrderedTable[Person, int]()
    s3 = initCountTable[Person]()
  s2[p1] = 30_000
  s2[p2] = 45_000
  s3[p1] = 30_000
  s3[p2] = 45_000
