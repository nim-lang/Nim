#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Shared table support for Nim. Use plain old non GC'ed keys and values or
## you'll be in trouble. Uses a single lock to protect the table, lockfree
## implementations welcome but if lock contention is so high that you need a
## lockfree hash table, you're doing it wrong.

import
  hashes, math, locks

include "system/inclrtl"

type
  KeyValuePair[A, B] = tuple[hcode: Hash, key: A, val: B]
  KeyValuePairSeq[A, B] = ptr array[10_000_000, KeyValuePair[A, B]]
  SharedTable* [A, B] = object ## generic hash SharedTable
    data: KeyValuePairSeq[A, B]
    counter, dataLen: int
    lock: Lock

template maxHash(t): untyped = t.dataLen-1

include tableimpl

template st_maybeRehashPutImpl(enlarge) {.dirty.} =
  if mustRehash(t.dataLen, t.counter):
    enlarge(t)
    index = rawGetKnownHC(t, key, hc)
  index = -1 - index                  # important to transform for mgetOrPutImpl
  rawInsert(t, t.data, key, val, hc, index)
  inc(t.counter)

proc enlarge[A, B](t: var SharedTable[A, B]) =
  let oldSize = t.dataLen
  let size = oldSize * growthFactor
  var n = cast[KeyValuePairSeq[A, B]](allocShared0(
                                      sizeof(KeyValuePair[A, B]) * size))
  t.dataLen = size
  swap(t.data, n)
  for i in 0..<oldSize:
    let eh = n[i].hcode
    if isFilled(eh):
      var j: Hash = eh and maxHash(t)
      while isFilled(t.data[j].hcode):
        j = nextTry(j, maxHash(t))
      rawInsert(t, t.data, n[i].key, n[i].val, eh, j)
  deallocShared(n)

template withLock(t, x: untyped) =
  acquire(t.lock)
  x
  release(t.lock)

template withValue*[A, B](t: var SharedTable[A, B], key: A,
                          value, body: untyped) =
  ## retrieves the value at ``t[key]``.
  ## `value` can be modified in the scope of the ``withValue`` call.
  ##
  ## .. code-block:: nim
  ##
  ##   sharedTable.withValue(key, value) do:
  ##     # block is executed only if ``key`` in ``t``
  ##     # value is threadsafe in block
  ##     value.name = "username"
  ##     value.uid = 1000
  ##
  acquire(t.lock)
  try:
    var hc: Hash
    var index = rawGet(t, key, hc)
    let hasKey = index >= 0
    if hasKey:
      var value {.inject.} = addr(t.data[index].val)
      body
  finally:
    release(t.lock)

template withValue*[A, B](t: var SharedTable[A, B], key: A,
                          value, body1, body2: untyped) =
  ## retrieves the value at ``t[key]``.
  ## `value` can be modified in the scope of the ``withValue`` call.
  ##
  ## .. code-block:: nim
  ##
  ##   sharedTable.withValue(key, value) do:
  ##     # block is executed only if ``key`` in ``t``
  ##     # value is threadsafe in block
  ##     value.name = "username"
  ##     value.uid = 1000
  ##   do:
  ##     # block is executed when ``key`` not in ``t``
  ##     raise newException(KeyError, "Key not found")
  ##
  acquire(t.lock)
  try:
    var hc: Hash
    var index = rawGet(t, key, hc)
    let hasKey = index >= 0
    if hasKey:
      var value {.inject.} = addr(t.data[index].val)
      body1
    else:
      body2
  finally:
    release(t.lock)

proc mget*[A, B](t: var SharedTable[A, B], key: A): var B =
  ## retrieves the value at ``t[key]``. The value can be modified.
  ## If `key` is not in `t`, the ``KeyError`` exception is raised.
  withLock t:
    var hc: Hash
    var index = rawGet(t, key, hc)
    let hasKey = index >= 0
    if hasKey: result = t.data[index].val
  if not hasKey:
    when compiles($key):
      raise newException(KeyError, "key not found: " & $key)
    else:
      raise newException(KeyError, "key not found")

proc mgetOrPut*[A, B](t: var SharedTable[A, B], key: A, val: B): var B =
  ## retrieves value at ``t[key]`` or puts ``val`` if not present, either way
  ## returning a value which can be modified. **Note**: This is inherently
  ## unsafe in the context of multi-threading since it returns a pointer
  ## to ``B``.
  withLock t:
    mgetOrPutImpl(enlarge)

proc hasKeyOrPut*[A, B](t: var SharedTable[A, B], key: A, val: B): bool =
  ## returns true iff `key` is in the table, otherwise inserts `value`.
  withLock t:
    hasKeyOrPutImpl(enlarge)

proc withKey*[A, B](t: var SharedTable[A, B], key: A,
                    mapper: proc(key: A, val: var B, pairExists: var bool)) =
  ## Computes a new mapping for the ``key`` with the specified ``mapper``
  ## procedure.
  ##
  ## The ``mapper`` takes 3 arguments:
  ##
  ## 1. ``key`` - the current key, if it exists, or the key passed to
  ##    ``withKey`` otherwise;
  ## 2. ``val`` - the current value, if the key exists, or default value
  ##    of the type otherwise;
  ## 3. ``pairExists`` - ``true`` if the key exists, ``false`` otherwise.
  ##
  ## The ``mapper`` can can modify ``val`` and ``pairExists`` values to change
  ## the mapping of the key or delete it from the table.
  ## When adding a value, make sure to set ``pairExists`` to ``true`` along
  ## with modifying the ``val``.
  ##
  ## The operation is performed atomically and other operations on the table
  ## will be blocked while the ``mapper`` is invoked, so it should be short and
  ## simple.
  ##
  ## Example usage:
  ##
  ## .. code-block:: nim
  ##
  ##   # If value exists, decrement it.
  ##   # If it becomes zero or less, delete the key
  ##   t.withKey(1'i64) do (k: int64, v: var int, pairExists: var bool):
  ##     if pairExists:
  ##       dec v
  ##       if v <= 0:
  ##         pairExists = false
  withLock t:
    var hc: Hash
    var index = rawGet(t, key, hc)

    var pairExists = index >= 0
    if pairExists:
      mapper(t.data[index].key, t.data[index].val, pairExists)
      if not pairExists:
        delImplIdx(t, index)
    else:
      var val: B
      mapper(key, val, pairExists)
      if pairExists:
        st_maybeRehashPutImpl(enlarge)

proc `[]=`*[A, B](t: var SharedTable[A, B], key: A, val: B) =
  ## puts a (key, value)-pair into `t`.
  withLock t:
    putImpl(enlarge)

proc add*[A, B](t: var SharedTable[A, B], key: A, val: B) =
  ## puts a new (key, value)-pair into `t` even if ``t[key]`` already exists.
  ## This can introduce duplicate keys into the table!
  withLock t:
    addImpl(enlarge)

proc del*[A, B](t: var SharedTable[A, B], key: A) =
  ## deletes `key` from hash table `t`.
  withLock t:
    delImpl()

proc init*[A, B](t: var SharedTable[A, B], initialSize=64) =
  ## creates a new hash table that is empty.
  ##
  ## `initialSize` needs to be a power of two. If you need to accept runtime
  ## values for this you could use the ``nextPowerOfTwo`` proc from the
  ## `math <math.html>`_ module or the ``rightSize`` proc from this module.
  assert isPowerOfTwo(initialSize)
  t.counter = 0
  t.dataLen = initialSize
  t.data = cast[KeyValuePairSeq[A, B]](allocShared0(
                                      sizeof(KeyValuePair[A, B]) * initialSize))
  initLock t.lock

proc deinitSharedTable*[A, B](t: var SharedTable[A, B]) =
  deallocShared(t.data)
  deinitLock t.lock

proc initSharedTable*[A, B](initialSize=64): SharedTable[A, B] {.deprecated.} =
  ## Deprecated. Use `init` instead.
  ## This is not posix compliant, may introduce undefined behavior.
  assert isPowerOfTwo(initialSize)
  result.counter = 0
  result.dataLen = initialSize
  result.data = cast[KeyValuePairSeq[A, B]](allocShared0(
                                     sizeof(KeyValuePair[A, B]) * initialSize))
  initLock result.lock
