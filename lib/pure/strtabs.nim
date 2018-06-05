#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## The ``strtabs`` module implements an efficient hash table that is a mapping
## from strings to strings. Supports a case-sensitive, case-insensitive and
## style-insensitive mode. An efficient string substitution operator  ``%``
## for the string table is also provided.

import
  hashes, strutils

when defined(js):
  {.pragma: rtlFunc.}
else:
  {.pragma: rtlFunc, rtl.}
  import os
  include "system/inclrtl"

type
  StringTableMode* = enum     ## describes the tables operation mode
    modeCaseSensitive,        ## the table is case sensitive
    modeCaseInsensitive,      ## the table is case insensitive
    modeStyleInsensitive      ## the table is style insensitive
  KeyValuePair = tuple[key, val: string, hasValue: bool]
  KeyValuePairSeq = seq[KeyValuePair]
  StringTableObj* = object of RootObj
    counter: int
    data: KeyValuePairSeq
    mode: StringTableMode

  StringTableRef* = ref StringTableObj ## use this type to declare string tables

proc len*(t: StringTableRef): int {.rtlFunc, extern: "nst$1".} =
  ## returns the number of keys in `t`.
  result = t.counter

iterator pairs*(t: StringTableRef): tuple[key, value: string] =
  ## iterates over every (key, value) pair in the table `t`.
  for h in 0..high(t.data):
    if t.data[h].hasValue:
      yield (t.data[h].key, t.data[h].val)

iterator keys*(t: StringTableRef): string =
  ## iterates over every key in the table `t`.
  for h in 0..high(t.data):
    if t.data[h].hasValue:
      yield t.data[h].key

iterator values*(t: StringTableRef): string =
  ## iterates over every value in the table `t`.
  for h in 0..high(t.data):
    if t.data[h].hasValue:
      yield t.data[h].val

type
  FormatFlag* = enum          ## flags for the `%` operator
    useEnvironment,           ## use environment variable if the ``$key``
                              ## is not found in the table. Does nothing when using `js` target.
    useEmpty,                 ## use the empty string as a default, thus it
                              ## won't throw an exception if ``$key`` is not
                              ## in the table
    useKey                    ## do not replace ``$key`` if it is not found
                              ## in the table (or in the environment)

const
  growthFactor = 2
  startSize = 64

proc myhash(t: StringTableRef, key: string): Hash =
  case t.mode
  of modeCaseSensitive: result = hashes.hash(key)
  of modeCaseInsensitive: result = hashes.hashIgnoreCase(key)
  of modeStyleInsensitive: result = hashes.hashIgnoreStyle(key)

proc myCmp(t: StringTableRef, a, b: string): bool =
  case t.mode
  of modeCaseSensitive: result = cmp(a, b) == 0
  of modeCaseInsensitive: result = cmpIgnoreCase(a, b) == 0
  of modeStyleInsensitive: result = cmpIgnoreStyle(a, b) == 0

proc mustRehash(length, counter: int): bool =
  assert(length > counter)
  result = (length * 2 < counter * 3) or (length - counter < 4)

proc nextTry(h, maxHash: Hash): Hash {.inline.} =
  result = ((5 * h) + 1) and maxHash

proc rawGet(t: StringTableRef, key: string): int =
  var h: Hash = myhash(t, key) and high(t.data) # start with real hash value
  while t.data[h].hasValue:
    if myCmp(t, t.data[h].key, key):
      return h
    h = nextTry(h, high(t.data))
  result = - 1

template get(t: StringTableRef, key: string) =
  var index = rawGet(t, key)
  if index >= 0: result = t.data[index].val
  else:
    when compiles($key):
      raise newException(KeyError, "key not found: " & $key)
    else:
      raise newException(KeyError, "key not found")

proc `[]`*(t: StringTableRef, key: string): var string {.
           rtlFunc, extern: "nstTake".} =
  ## retrieves the location at ``t[key]``. If `key` is not in `t`, the
  ## ``KeyError`` exception is raised. One can check with ``hasKey`` whether
  ## the key exists.
  get(t, key)

proc getOrDefault*(t: StringTableRef; key: string, default: string = ""): string =
  var index = rawGet(t, key)
  if index >= 0: result = t.data[index].val
  else: result = default

proc hasKey*(t: StringTableRef, key: string): bool {.rtlFunc, extern: "nst$1".} =
  ## returns true iff `key` is in the table `t`.
  result = rawGet(t, key) >= 0

proc contains*(t: StringTableRef, key: string): bool =
  ## alias of `hasKey` for use with the `in` operator.
  return hasKey(t, key)

proc rawInsert(t: StringTableRef, data: var KeyValuePairSeq, key, val: string) =
  var h: Hash = myhash(t, key) and high(data)
  while data[h].hasValue:
    h = nextTry(h, high(data))
  data[h].key = key
  data[h].val = val
  data[h].hasValue = true

proc enlarge(t: StringTableRef) =
  var n: KeyValuePairSeq
  newSeq(n, len(t.data) * growthFactor)
  for i in countup(0, high(t.data)):
    if t.data[i].hasValue: rawInsert(t, n, t.data[i].key, t.data[i].val)
  swap(t.data, n)

proc `[]=`*(t: StringTableRef, key, val: string) {.rtlFunc, extern: "nstPut".} =
  ## puts a (key, value)-pair into `t`.
  var index = rawGet(t, key)
  if index >= 0:
    t.data[index].val = val
  else:
    if mustRehash(len(t.data), t.counter): enlarge(t)
    rawInsert(t, t.data, key, val)
    inc(t.counter)

proc raiseFormatException(s: string) =
  var e: ref ValueError
  new(e)
  e.msg = "format string: key not found: " & s
  raise e

proc getValue(t: StringTableRef, flags: set[FormatFlag], key: string): string =
  if hasKey(t, key): return t.getOrDefault(key)
  # hm difficult: assume safety in taint mode here. XXX This is dangerous!
  when defined(js):
    result = ""
  else:
    if useEnvironment in flags: result = os.getEnv(key).string
    else: result = ""
  if result.len == 0:
    if useKey in flags: result = '$' & key
    elif useEmpty notin flags: raiseFormatException(key)

proc newStringTable*(mode: StringTableMode): StringTableRef {.
  rtlFunc, extern: "nst$1".} =
  ## creates a new string table that is empty.
  new(result)
  result.mode = mode
  result.counter = 0
  newSeq(result.data, startSize)

proc clear*(s: StringTableRef, mode: StringTableMode) {.
  rtlFunc, extern: "nst$1".} =
  ## resets a string table to be empty again.
  s.mode = mode
  s.counter = 0
  s.data.setLen(startSize)
  for i in 0..<s.data.len:
    s.data[i].hasValue = false

proc newStringTable*(keyValuePairs: varargs[string],
                     mode: StringTableMode): StringTableRef {.
  rtlFunc, extern: "nst$1WithPairs".} =
  ## creates a new string table with given key value pairs.
  ## Example::
  ##   var mytab = newStringTable("key1", "val1", "key2", "val2",
  ##                              modeCaseInsensitive)
  result = newStringTable(mode)
  var i = 0
  while i < high(keyValuePairs):
    result[keyValuePairs[i]] = keyValuePairs[i + 1]
    inc(i, 2)

proc newStringTable*(keyValuePairs: varargs[tuple[key, val: string]],
                     mode: StringTableMode = modeCaseSensitive): StringTableRef {.
  rtlFunc, extern: "nst$1WithTableConstr".} =
  ## creates a new string table with given key value pairs.
  ## Example::
  ##   var mytab = newStringTable({"key1": "val1", "key2": "val2"},
  ##                              modeCaseInsensitive)
  result = newStringTable(mode)
  for key, val in items(keyValuePairs): result[key] = val

proc `%`*(f: string, t: StringTableRef, flags: set[FormatFlag] = {}): string {.
  rtlFunc, extern: "nstFormat".} =
  ## The `%` operator for string tables.
  const
    PatternChars = {'a'..'z', 'A'..'Z', '0'..'9', '_', '\x80'..'\xFF'}
  result = ""
  var i = 0
  while i < len(f):
    if f[i] == '$':
      case f[i+1]
      of '$':
        add(result, '$')
        inc(i, 2)
      of '{':
        var j = i + 1
        while j < f.len and f[j] != '}': inc(j)
        add(result, getValue(t, flags, substr(f, i+2, j-1)))
        i = j + 1
      of 'a'..'z', 'A'..'Z', '\x80'..'\xFF', '_':
        var j = i + 1
        while j < f.len and f[j] in PatternChars: inc(j)
        add(result, getValue(t, flags, substr(f, i+1, j-1)))
        i = j
      else:
        add(result, f[i])
        inc(i)
    else:
      add(result, f[i])
      inc(i)

proc `$`*(t: StringTableRef): string {.rtlFunc, extern: "nstDollar".} =
  ## The `$` operator for string tables.
  if t.len == 0:
    result = "{:}"
  else:
    result = "{"
    for key, val in pairs(t):
      if result.len > 1: result.add(", ")
      result.add(key)
      result.add(": ")
      result.add(val)
    result.add("}")

when isMainModule:
  var x = {"k": "v", "11": "22", "565": "67"}.newStringTable
  assert x["k"] == "v"
  assert x["11"] == "22"
  assert x["565"] == "67"
  x["11"] = "23"
  assert x["11"] == "23"

  x.clear(modeCaseInsensitive)
  x["11"] = "22"
  assert x["11"] == "22"
