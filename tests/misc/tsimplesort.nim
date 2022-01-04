discard """
  output: '''true'''
"""

import hashes, math

{.pragma: myShallow.}

type
  TSlotEnum = enum seEmpty, seFilled, seDeleted
  TKeyValuePair[A, B] = tuple[slot: TSlotEnum, key: A, val: B]
  TKeyValuePairSeq[A, B] = seq[TKeyValuePair[A, B]]
  TTable* {.final, myShallow.}[A, B] = object
    data: TKeyValuePairSeq[A, B]
    counter: int

proc len*[A, B](t: TTable[A, B]): int =
  ## returns the number of keys in `t`.
  result = t.counter

iterator pairs*[A, B](t: TTable[A, B]): tuple[key: A, val: B] =
  ## iterates over any (key, value) pair in the table `t`.
  for h in 0..high(t.data):
    if t.data[h].slot == seFilled: yield (t.data[h].key, t.data[h].val)

iterator keys*[A, B](t: TTable[A, B]): A =
  ## iterates over any key in the table `t`.
  for h in 0..high(t.data):
    if t.data[h].slot == seFilled: yield t.data[h].key

iterator values*[A, B](t: TTable[A, B]): B =
  ## iterates over any value in the table `t`.
  for h in 0..high(t.data):
    if t.data[h].slot == seFilled: yield t.data[h].val

const
  growthFactor = 2

proc mustRehash(length, counter: int): bool {.inline.} =
  assert(length > counter)
  result = (length * 2 < counter * 3) or (length - counter < 4)

proc nextTry(h, maxHash: Hash): Hash {.inline.} =
  result = ((5 * h) + 1) and maxHash

template rawGetImpl() =
  var h: Hash = hash(key) and high(t.data) # start with real hash value
  while t.data[h].slot != seEmpty:
    if t.data[h].key == key and t.data[h].slot == seFilled:
      return h
    h = nextTry(h, high(t.data))
  result = -1

template rawInsertImpl() =
  var h: Hash = hash(key) and high(data)
  while data[h].slot == seFilled:
    h = nextTry(h, high(data))
  data[h].key = key
  data[h].val = val
  data[h].slot = seFilled

proc rawGet[A, B](t: TTable[A, B], key: A): int =
  rawGetImpl()

proc `[]`*[A, B](t: TTable[A, B], key: A): B =
  ## retrieves the value at ``t[key]``. If `key` is not in `t`,
  ## default empty value for the type `B` is returned
  ## and no exception is raised. One can check with ``hasKey`` whether the key
  ## exists.
  var index = rawGet(t, key)
  if index >= 0: result = t.data[index].val

proc hasKey*[A, B](t: TTable[A, B], key: A): bool =
  ## returns true iff `key` is in the table `t`.
  result = rawGet(t, key) >= 0

proc rawInsert[A, B](t: var TTable[A, B], data: var TKeyValuePairSeq[A, B],
                     key: A, val: B) =
  rawInsertImpl()

proc enlarge[A, B](t: var TTable[A, B]) =
  var n: TKeyValuePairSeq[A, B]
  newSeq(n, len(t.data) * growthFactor)
  for i in countup(0, high(t.data)):
    if t.data[i].slot == seFilled: rawInsert(t, n, t.data[i].key, t.data[i].val)
  swap(t.data, n)

template putImpl() =
  var index = rawGet(t, key)
  if index >= 0:
    t.data[index].val = val
  else:
    if mustRehash(len(t.data), t.counter): enlarge(t)
    rawInsert(t, t.data, key, val)
    inc(t.counter)

proc `[]=`*[A, B](t: var TTable[A, B], key: A, val: B) =
  ## puts a (key, value)-pair into `t`.
  putImpl()

proc del*[A, B](t: var TTable[A, B], key: A) =
  ## deletes `key` from hash table `t`.
  var index = rawGet(t, key)
  if index >= 0:
    t.data[index].slot = seDeleted
    dec(t.counter)

proc initTable*[A, B](initialSize=64): TTable[A, B] =
  ## creates a new hash table that is empty. `initialSize` needs to be
  ## a power of two.
  assert isPowerOfTwo(initialSize)
  result.counter = 0
  newSeq(result.data, initialSize)

proc toTable*[A, B](pairs: openArray[tuple[key: A,
                    val: B]]): TTable[A, B] =
  ## creates a new hash table that contains the given `pairs`.
  result = initTable[A, B](nextPowerOfTwo(pairs.len+10))
  for key, val in items(pairs): result[key] = val

template dollarImpl(): typed =
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

proc `$`*[A, B](t: TTable[A, B]): string =
  ## The `$` operator for hash tables.
  dollarImpl()

# ------------------------------ count tables -------------------------------

type
  TCountTable* {.final, myShallow.}[
      A] = object ## table that counts the number of each key
    data: seq[tuple[key: A, val: int]]
    counter: int

proc len*[A](t: TCountTable[A]): int =
  ## returns the number of keys in `t`.
  result = t.counter

iterator pairs*[A](t: TCountTable[A]): tuple[key: A, val: int] =
  ## iterates over any (key, value) pair in the table `t`.
  for h in 0..high(t.data):
    if t.data[h].val != 0: yield (t.data[h].key, t.data[h].val)

iterator keys*[A](t: TCountTable[A]): A =
  ## iterates over any key in the table `t`.
  for h in 0..high(t.data):
    if t.data[h].val != 0: yield t.data[h].key

iterator values*[A](t: TCountTable[A]): int =
  ## iterates over any value in the table `t`.
  for h in 0..high(t.data):
    if t.data[h].val != 0: yield t.data[h].val

proc RawGet[A](t: TCountTable[A], key: A): int =
  var h: Hash = hash(key) and high(t.data) # start with real hash value
  while t.data[h].val != 0:
    if t.data[h].key == key: return h
    h = nextTry(h, high(t.data))
  result = -1

proc `[]`*[A](t: TCountTable[A], key: A): int =
  ## retrieves the value at ``t[key]``. If `key` is not in `t`,
  ## 0 is returned. One can check with ``hasKey`` whether the key
  ## exists.
  var index = RawGet(t, key)
  if index >= 0: result = t.data[index].val

proc hasKey*[A](t: TCountTable[A], key: A): bool =
  ## returns true iff `key` is in the table `t`.
  result = rawGet(t, key) >= 0

proc rawInsert[A](t: TCountTable[A], data: var seq[tuple[key: A, val: int]],
                  key: A, val: int) =
  var h: Hash = hash(key) and high(data)
  while data[h].val != 0: h = nextTry(h, high(data))
  data[h].key = key
  data[h].val = val

proc enlarge[A](t: var TCountTable[A]) =
  var n: seq[tuple[key: A, val: int]]
  newSeq(n, len(t.data) * growthFactor)
  for i in countup(0, high(t.data)):
    if t.data[i].val != 0: rawInsert(t, n, t.data[i].key, t.data[i].val)
  swap(t.data, n)

proc `[]=`*[A](t: var TCountTable[A], key: A, val: int) =
  ## puts a (key, value)-pair into `t`. `val` has to be positive.
  assert val > 0
  putImpl()

proc initCountTable*[A](initialSize=64): TCountTable[A] =
  ## creates a new count table that is empty. `initialSize` needs to be
  ## a power of two.
  assert isPowerOfTwo(initialSize)
  result.counter = 0
  newSeq(result.data, initialSize)

proc toCountTable*[A](keys: openArray[A]): TCountTable[A] =
  ## creates a new count table with every key in `keys` having a count of 1.
  result = initCountTable[A](nextPowerOfTwo(keys.len+10))
  for key in items(keys): result[key] = 1

proc `$`*[A](t: TCountTable[A]): string =
  ## The `$` operator for count tables.
  dollarImpl()

proc inc*[A](t: var TCountTable[A], key: A, val = 1) =
  ## increments `t[key]` by `val`.
  var index = RawGet(t, key)
  if index >= 0:
    inc(t.data[index].val, val)
  else:
    if mustRehash(len(t.data), t.counter): enlarge(t)
    rawInsert(t, t.data, key, val)
    inc(t.counter)

proc smallest*[A](t: TCountTable[A]): tuple[key: A, val: int] =
  ## returns the largest (key,val)-pair. Efficiency: O(n)
  assert t.len > 0
  var minIdx = 0
  for h in 1..high(t.data):
    if t.data[h].val > 0 and t.data[minIdx].val > t.data[h].val: minIdx = h
  result.key = t.data[minIdx].key
  result.val = t.data[minIdx].val

proc largest*[A](t: TCountTable[A]): tuple[key: A, val: int] =
  ## returns the (key,val)-pair with the largest `val`. Efficiency: O(n)
  assert t.len > 0
  var maxIdx = 0
  for h in 1..high(t.data):
    if t.data[maxIdx].val < t.data[h].val: maxIdx = h
  result.key = t.data[maxIdx].key
  result.val = t.data[maxIdx].val

proc sort*[A](t: var TCountTable[A]) =
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
        var xyz = t.data[j]
        t.data[j] = t.data[j-h]
        t.data[j-h] = xyz
        j = j-h
        if j < h: break
    if h == 1: break


const
  data = {
    "34": 123456, "12": 789,
    "90": 343, "0": 34404,
    "1": 344004, "2": 344774,
    "3": 342244, "4": 3412344,
    "5": 341232144, "6": 34214544,
    "7": 3434544, "8": 344544,
    "9": 34435644, "---00": 346677844,
    "10": 34484, "11": 34474, "19": 34464,
    "20": 34454, "30": 34141244, "40": 344114,
    "50": 344490, "60": 344491, "70": 344492,
    "80": 344497}

proc countTableTest1 =
  var s = initTable[string, int](64)
  for key, val in items(data): s[key] = val
  var w: tuple[key: string, val: int] #type(otherCountTable.data[0])

  var t = initCountTable[string]()
  for k, v in items(data): t.inc(k)
  for k in t.keys: assert t[k] == 1
  t.inc("90", 3)
  t.inc("12", 2)
  t.inc("34", 1)
  assert t.largest()[0] == "90"
  t.sort()

  var i = 0
  for k, v in t.pairs:
    case i
    of 0: assert k == "90" and v == 4
    of 1: assert k == "12" and v == 3
    of 2: assert k == "34" and v == 2
    else: break
    inc i

countTableTest1()
echo true
