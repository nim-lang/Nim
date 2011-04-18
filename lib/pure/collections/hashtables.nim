#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2011 Andreas Rumpf, Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## The ``hashtables`` module implements an efficient hash table that is
## a mapping from keys to values.

import
  os, hashes, strutils

type
  TKeyValuePair[A, B] = tuple[key: A, val: B]
  TKeyValuePairSeq[A, B] = seq[TKeyValuePair[A, B]]
  THashTable*[A, B] = object of TObject
    counter: int
    data: TKeyValuePairSeq[A, B]

  PHashTable*[A, B] = ref THashTable[A, B] ## use this type to declare tables

proc len*[A, B](t: PHashTable[A, B]): int =
  ## returns the number of keys in `t`.
  result = t.counter

iterator pairs*[A, B](t: PHashTable[A, B]): tuple[key: A, val: B] =
  ## iterates over any (key, value) pair in the table `t`.
  for h in 0..high(t.data):
    if not isNil(t.data[h].key) and not isNil(t.data[h].val):
      yield (t.data[h].key, t.data[h].val)

const
  growthFactor = 2
  startSize = 64

proc myhash[A](key: A): THash =
  result = hashes.hash(key)

proc myCmp[A](key: A, key2: A): bool =
  result = cmp(key, key2) == 0

proc mustRehash(length, counter: int): bool =
  assert(length > counter)
  result = (length * 2 < counter * 3) or (length - counter < 4)

proc nextTry(h, maxHash: THash): THash {.inline.} =
  result = ((5 * h) + 1) and maxHash

proc RawGet[A, B](t: PHashTable[A, B], key: A): int =
  var h: THash = myhash(key) and high(t.data) # start with real hash value
  while not isNil(t.data[h].key) and not isNil(t.data[h].val):
    if mycmp(t.data[h].key, key):
      return h
    h = nextTry(h, high(t.data))
  result = -1

proc `[]`*[A, B](t: PHashTable[A, B], key: A): B =
  ## retrieves the value at ``t[key]``. If `key` is not in `t`,
  ## default empty value for the type `B` is returned
  ## and no exception is raised. One can check with ``hasKey`` whether the key
  ## exists.
  var index = RawGet(t, key)
  if index >= 0: result = t.data[index].val

proc hasKey*[A, B](t: PHashTable[A, B], key: A): bool =
  ## returns true iff `key` is in the table `t`.
  result = rawGet(t, key) >= 0

proc RawInsert[A, B](t: PHashTable[A, B], data: var TKeyValuePairSeq[A, B],
                     key: A, val: B) =
  var h: THash = myhash(key) and high(data)
  while not isNil(data[h].key):
    h = nextTry(h, high(data))
  data[h].key = key
  data[h].val = val

proc Enlarge[A, B](t: PHashTable[A, B]) =
  var n: TKeyValuePairSeq[A, B]
  newSeq(n, len(t.data) * growthFactor)
  for i in countup(0, high(t.data)):
    if not isNil(t.data[i].key): RawInsert(t, n, t.data[i].key, t.data[i].val)
  swap(t.data, n)

proc `[]=`*[A, B](t: PHashTable[A, B], key: A, val: B) =
  ## puts a (key, value)-pair into `t`.
  var index = RawGet(t, key)
  if index >= 0:
    t.data[index].val = val
  else:
    if mustRehash(len(t.data), t.counter): Enlarge(t)
    RawInsert(t, t.data, key, val)
    inc(t.counter)

proc default[T](): T = nil

proc del*[A, B](t: PHashTable[A, B], key: A) =
  ## deletes `key` from hash table `t`.
  var index = RawGet(t, key)
  if index >= 0:
    t.data[index].key = default[A]()
  else:
    raise newException(EInvalidIndex, "Key not found.")

proc newHashTable*[A, B](): PHashTable[A, B] =
  ## creates a new string table that is empty.
  new(result)
  result.counter = 0
  newSeq(result.data, startSize)

proc `$`*[A, B](t: PHashTable[A, B]): string =
  ## The `$` operator for string tables.
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

when isMainModule:
  var table = newHashTable[string, float]()
  table["test"] = 1.2345
  table["111"] = 1.000043
  echo table
  table.del("111")
  echo table
  echo repr(table["111"])
  echo(repr(table["1212"]))
  table["111"] = 1.5
  table["011"] = 67.9
  echo table
  table.del("test")
  table.del("111")
  echo table


  echo hash("test")
  echo hash("test")


