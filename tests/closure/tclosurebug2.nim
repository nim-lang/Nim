import hashes, math

type
  TSlotEnum = enum seEmpty, seFilled, seDeleted
  TKeyValuePair[A, B] = tuple[slot: TSlotEnum, key: A, val: B]
  TKeyValuePairSeq[A, B] = seq[TKeyValuePair[A, B]]

  TOrderedKeyValuePair[A, B] = tuple[
    slot: TSlotEnum, next: int, key: A, val: B]
  TOrderedKeyValuePairSeq[A, B] = seq[TOrderedKeyValuePair[A, B]]
  TOrderedTable*[A, B] = object ## table that remembers insertion order
    data: TOrderedKeyValuePairSeq[A, B]
    counter, first, last: int

const
  growthFactor = 2

proc mustRehash(length, counter: int): bool {.inline.} =
  assert(length > counter)
  result = (length * 2 < counter * 3) or (length - counter < 4)

proc nextTry(h, maxHash: THash): THash {.inline.} =
  result = ((5 * h) + 1) and maxHash

template rawGetImpl() {.dirty.} =
  var h: THash = hash(key) and high(t.data) # start with real hash value
  while t.data[h].slot != seEmpty:
    if t.data[h].key == key and t.data[h].slot == seFilled:
      return h
    h = nextTry(h, high(t.data))
  result = -1

template rawInsertImpl() {.dirty.} =
  var h: THash = hash(key) and high(data)
  while data[h].slot == seFilled:
    h = nextTry(h, high(data))
  data[h].key = key
  data[h].val = val
  data[h].slot = seFilled

template AddImpl() {.dirty.} =
  if mustRehash(len(t.data), t.counter): Enlarge(t)
  RawInsert(t, t.data, key, val)
  inc(t.counter)

template PutImpl() {.dirty.} =
  var index = RawGet(t, key)
  if index >= 0:
    t.data[index].val = val
  else:
    AddImpl()

proc len*[A, B](t: TOrderedTable[A, B]): int {.inline.} =
  ## returns the number of keys in `t`.
  result = t.counter

template forAllOrderedPairs(yieldStmt: stmt) {.dirty, immediate.} =
  var h = t.first
  while h >= 0:
    var nxt = t.data[h].next
    if t.data[h].slot == seFilled: yieldStmt
    h = nxt

iterator pairs*[A, B](t: TOrderedTable[A, B]): tuple[key: A, val: B] =
  ## iterates over any (key, value) pair in the table `t` in insertion
  ## order.
  forAllOrderedPairs:
    yield (t.data[h].key, t.data[h].val)

iterator mpairs*[A, B](t: var TOrderedTable[A, B]): tuple[key: A, val: var B] =
  ## iterates over any (key, value) pair in the table `t` in insertion
  ## order. The values can be modified.
  forAllOrderedPairs:
    yield (t.data[h].key, t.data[h].val)

iterator keys*[A, B](t: TOrderedTable[A, B]): A =
  ## iterates over any key in the table `t` in insertion order.
  forAllOrderedPairs:
    yield t.data[h].key

iterator values*[A, B](t: TOrderedTable[A, B]): B =
  ## iterates over any value in the table `t` in insertion order.
  forAllOrderedPairs:
    yield t.data[h].val

iterator mvalues*[A, B](t: var TOrderedTable[A, B]): var B =
  ## iterates over any value in the table `t` in insertion order. The values
  ## can be modified.
  forAllOrderedPairs:
    yield t.data[h].val

proc RawGet[A, B](t: TOrderedTable[A, B], key: A): int =
  rawGetImpl()

proc `[]`*[A, B](t: TOrderedTable[A, B], key: A): B =
  ## retrieves the value at ``t[key]``. If `key` is not in `t`,
  ## default empty value for the type `B` is returned
  ## and no exception is raised. One can check with ``hasKey`` whether the key
  ## exists.
  var index = RawGet(t, key)
  if index >= 0: result = t.data[index].val

proc mget*[A, B](t: var TOrderedTable[A, B], key: A): var B =
  ## retrieves the value at ``t[key]``. The value can be modified.
  ## If `key` is not in `t`, the ``EInvalidKey`` exception is raised.
  var index = RawGet(t, key)
  if index >= 0: result = t.data[index].val
  else: raise newException(EInvalidKey, "key not found: " & $key)

proc hasKey*[A, B](t: TOrderedTable[A, B], key: A): bool =
  ## returns true iff `key` is in the table `t`.
  result = rawGet(t, key) >= 0

proc RawInsert[A, B](t: var TOrderedTable[A, B], 
                     data: var TOrderedKeyValuePairSeq[A, B],
                     key: A, val: B) =
  rawInsertImpl()
  data[h].next = -1
  if t.first < 0: t.first = h
  if t.last >= 0: data[t.last].next = h
  t.last = h

proc Enlarge[A, B](t: var TOrderedTable[A, B]) =
  var n: TOrderedKeyValuePairSeq[A, B]
  newSeq(n, len(t.data) * growthFactor)
  var h = t.first
  t.first = -1
  t.last = -1
  while h >= 0:
    var nxt = t.data[h].next
    if t.data[h].slot == seFilled: 
      RawInsert(t, n, t.data[h].key, t.data[h].val)
    h = nxt
  swap(t.data, n)

proc `[]=`*[A, B](t: var TOrderedTable[A, B], key: A, val: B) =
  ## puts a (key, value)-pair into `t`.
  putImpl()

proc add*[A, B](t: var TOrderedTable[A, B], key: A, val: B) =
  ## puts a new (key, value)-pair into `t` even if ``t[key]`` already exists.
  AddImpl()

proc initOrderedTable*[A, B](initialSize=64): TOrderedTable[A, B] =
  ## creates a new ordered hash table that is empty. `initialSize` needs to be
  ## a power of two.
  assert isPowerOfTwo(initialSize)
  result.counter = 0
  result.first = -1
  result.last = -1
  newSeq(result.data, initialSize)

proc toOrderedTable*[A, B](pairs: openarray[tuple[key: A, 
                           val: B]]): TOrderedTable[A, B] =
  ## creates a new ordered hash table that contains the given `pairs`.
  result = initOrderedTable[A, B](nextPowerOfTwo(pairs.len+10))
  for key, val in items(pairs): result[key] = val

proc sort*[A, B](t: var TOrderedTable[A,B], 
                 cmp: proc (x, y: tuple[key: A, val: B]): int {.closure.}) =
  ## sorts the ordered table so that the entry with the highest counter comes
  ## first. This is destructive (with the advantage of being efficient)! 
  ## You must not modify `t` afterwards!
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
      #echo(t.data.len, " ", j, " - ", h)
      #echo(repr(t.data[j-h]))
      proc rawCmp(x, y: TOrderedKeyValuePair[A, B]): int =
        if x.slot in {seEmpty, seDeleted} and y.slot in {seEmpty, seDeleted}:
          return 0
        elif x.slot in {seEmpty, seDeleted}:
          return -1
        elif y.slot in {seEmpty, seDeleted}:
          return 1
        else:
          let item1 = (x.key, x.val)
          let item2 = (y.key, y.val)
          return cmp(item1, item2)
      
      while rawCmp(t.data[j-h], t.data[j]) <= 0:
        swap(t.data[j], t.data[j-h])
        j = j-h
        if j < h: break
    if h == 1: break
