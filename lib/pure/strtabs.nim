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
## style-insensitive mode.

runnableExamples:
  var t = newStringTable()
  t["name"] = "John"
  t["city"] = "Monaco"
  doAssert t.len == 2
  doAssert t.hasKey "name"
  doAssert "name" in t

## String tables can be created from a table constructor:
runnableExamples:
  var t = {"name": "John", "city": "Monaco"}.newStringTable

## When using the style insensitive mode (``modeStyleInsensitive``),
## all letters are compared case insensitively within the ASCII range
## and underscores are ignored.
runnableExamples:
  var x = newStringTable(modeStyleInsensitive)
  x["first_name"] = "John"
  x["LastName"] = "Doe"

  doAssert x["firstName"] == "John"
  doAssert x["last_name"] == "Doe"

## An efficient string substitution operator
## `% <#%25,string,StringTableRef,set[FormatFlag]>`_ for the string table
## is also provided.
runnableExamples:
  var t = {"name": "John", "city": "Monaco"}.newStringTable
  doAssert "${name} lives in ${city}" % t == "John lives in Monaco"

## **See also:**
## * `tables module <tables.html>`_ for general hash tables
## * `sharedtables module<sharedtables.html>`_ for shared hash table support
## * `strutils module<strutils.html>`_ for common string functions
## * `json module<json.html>`_ for table-like structure which allows
##   heterogeneous members

import std/private/since

import
  hashes, strutils

when defined(js) or defined(nimscript) or defined(Standalone):
  {.pragma: rtlFunc.}
else:
  {.pragma: rtlFunc, rtl.}
  import os

include "system/inclrtl"

type
  StringTableMode* = enum ## Describes the tables operation mode.
    modeCaseSensitive,    ## the table is case sensitive
    modeCaseInsensitive,  ## the table is case insensitive
    modeStyleInsensitive  ## the table is style insensitive
  KeyValuePair = tuple[key, val: string, hasValue: bool]
  KeyValuePairSeq = seq[KeyValuePair]
  StringTableObj* = object of RootObj
    counter: int
    data: KeyValuePairSeq
    mode: StringTableMode

  StringTableRef* = ref StringTableObj

  FormatFlag* = enum ## Flags for the `%` operator.
    useEnvironment,  ## Use environment variable if the ``$key``
                     ## is not found in the table.
                     ## Does nothing when using `js` target.
    useEmpty,        ## Use the empty string as a default, thus it
                     ## won't throw an exception if ``$key`` is not
                     ## in the table.
    useKey           ## Do not replace ``$key`` if it is not found
                     ## in the table (or in the environment).

const
  growthFactor = 2
  startSize = 64

proc mode*(t: StringTableRef): StringTableMode {.inline.} = t.mode

iterator pairs*(t: StringTableRef): tuple[key, value: string] =
  ## Iterates over every `(key, value)` pair in the table `t`.
  for h in 0..high(t.data):
    if t.data[h].hasValue:
      yield (t.data[h].key, t.data[h].val)

iterator keys*(t: StringTableRef): string =
  ## Iterates over every key in the table `t`.
  for h in 0..high(t.data):
    if t.data[h].hasValue:
      yield t.data[h].key

iterator values*(t: StringTableRef): string =
  ## Iterates over every value in the table `t`.
  for h in 0..high(t.data):
    if t.data[h].hasValue:
      yield t.data[h].val


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
  result = (h + 1) and maxHash

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
    raise newException(KeyError, "key not found: " & key)


proc len*(t: StringTableRef): int {.rtlFunc, extern: "nst$1".} =
  ## Returns the number of keys in `t`.
  result = t.counter

proc `[]`*(t: StringTableRef, key: string): var string {.
           rtlFunc, extern: "nstTake".} =
  ## Retrieves the location at ``t[key]``.
  ##
  ## If `key` is not in `t`, the ``KeyError`` exception is raised.
  ## One can check with `hasKey proc <#hasKey,StringTableRef,string>`_
  ## whether the key exists.
  ##
  ## See also:
  ## * `getOrDefault proc <#getOrDefault,StringTableRef,string,string>`_
  ## * `[]= proc <#[]=,StringTableRef,string,string>`_ for inserting a new
  ##   (key, value) pair in the table
  ## * `hasKey proc <#hasKey,StringTableRef,string>`_ for checking if a key
  ##   is in the table
  runnableExamples:
    var t = {"name": "John", "city": "Monaco"}.newStringTable
    doAssert t["name"] == "John"
    doAssertRaises(KeyError):
      echo t["occupation"]
  get(t, key)

proc getOrDefault*(t: StringTableRef; key: string,
    default: string = ""): string =
  ## Retrieves the location at ``t[key]``.
  ##
  ## If `key` is not in `t`, the default value is returned (if not specified,
  ## it is an empty string (`""`)).
  ##
  ## See also:
  ## * `[] proc <#[],StringTableRef,string>`_ for retrieving a value of a key
  ## * `hasKey proc <#hasKey,StringTableRef,string>`_ for checking if a key
  ##   is in the table
  ## * `[]= proc <#[]=,StringTableRef,string,string>`_ for inserting a new
  ##   (key, value) pair in the table
  runnableExamples:
    var t = {"name": "John", "city": "Monaco"}.newStringTable
    doAssert t.getOrDefault("name") == "John"
    doAssert t.getOrDefault("occupation") == ""
    doAssert t.getOrDefault("occupation", "teacher") == "teacher"
    doAssert t.getOrDefault("name", "Paul") == "John"

  var index = rawGet(t, key)
  if index >= 0: result = t.data[index].val
  else: result = default

proc hasKey*(t: StringTableRef, key: string): bool {.rtlFunc,
    extern: "nst$1".} =
  ## Returns true if `key` is in the table `t`.
  ##
  ## See also:
  ## * `getOrDefault proc <#getOrDefault,StringTableRef,string,string>`_
  ## * `contains proc <#contains,StringTableRef,string>`_
  runnableExamples:
    var t = {"name": "John", "city": "Monaco"}.newStringTable
    doAssert t.hasKey("name")
    doAssert not t.hasKey("occupation")
  result = rawGet(t, key) >= 0

proc contains*(t: StringTableRef, key: string): bool =
  ## Alias of `hasKey proc <#hasKey,StringTableRef,string>`_ for use with
  ## the `in` operator.
  runnableExamples:
    var t = {"name": "John", "city": "Monaco"}.newStringTable
    doAssert "name" in t
    doAssert "occupation" notin t
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
    if t.data[i].hasValue: rawInsert(t, n, move t.data[i].key, move t.data[i].val)
  swap(t.data, n)

proc `[]=`*(t: StringTableRef, key, val: string) {.
  rtlFunc, extern: "nstPut".} =
  ## Inserts a `(key, value)` pair into `t`.
  ##
  ## See also:
  ## * `[] proc <#[],StringTableRef,string>`_ for retrieving a value of a key
  ## * `del proc <#del,StringTableRef,string>`_ for removing a key from the table
  runnableExamples:
    var t = {"name": "John", "city": "Monaco"}.newStringTable
    t["occupation"] = "teacher"
    doAssert t.hasKey("occupation")

  var index = rawGet(t, key)
  if index >= 0:
    t.data[index].val = val
  else:
    if mustRehash(len(t.data), t.counter): enlarge(t)
    rawInsert(t, t.data, key, val)
    inc(t.counter)

proc newStringTable*(mode: StringTableMode): owned(StringTableRef) {.
  rtlFunc, extern: "nst$1", noSideEffect.} =
  ## Creates a new empty string table.
  ##
  ## See also:
  ## * `newStringTable(keyValuePairs) proc
  ##   <#newStringTable,varargs[tuple[string,string]],StringTableMode>`_
  new(result)
  result.mode = mode
  result.counter = 0
  newSeq(result.data, startSize)

proc newStringTable*(keyValuePairs: varargs[string],
                     mode: StringTableMode): owned(StringTableRef) {.
  rtlFunc, extern: "nst$1WithPairs", noSideEffect.} =
  ## Creates a new string table with given `key, value` string pairs.
  ##
  ## `StringTableMode` must be specified.
  runnableExamples:
    var mytab = newStringTable("key1", "val1", "key2", "val2",
                               modeCaseInsensitive)

  result = newStringTable(mode)
  var i = 0
  while i < high(keyValuePairs):
    {.noSideEffect.}:
      result[keyValuePairs[i]] = keyValuePairs[i + 1]
    inc(i, 2)

proc newStringTable*(keyValuePairs: varargs[tuple[key, val: string]],
    mode: StringTableMode = modeCaseSensitive): owned(StringTableRef) {.
    rtlFunc, extern: "nst$1WithTableConstr", noSideEffect.} =
  ## Creates a new string table with given `(key, value)` tuple pairs.
  ##
  ## The default mode is case sensitive.
  runnableExamples:
    var
      mytab1 = newStringTable({"key1": "val1", "key2": "val2"}, modeCaseInsensitive)
      mytab2 = newStringTable([("key3", "val3"), ("key4", "val4")])

  result = newStringTable(mode)
  for key, val in items(keyValuePairs):
    {.noSideEffect.}:
      result[key] = val

proc raiseFormatException(s: string) =
  raise newException(ValueError, "format string: key not found: " & s)

proc getValue(t: StringTableRef, flags: set[FormatFlag], key: string): string =
  if hasKey(t, key): return t.getOrDefault(key)
  when defined(js) or defined(nimscript) or defined(Standalone):
    result = ""
  else:
    if useEnvironment in flags: result = getEnv(key)
    else: result = ""
  if result.len == 0:
    if useKey in flags: result = '$' & key
    elif useEmpty notin flags: raiseFormatException(key)

proc clear*(s: StringTableRef, mode: StringTableMode) {.
  rtlFunc, extern: "nst$1".} =
  ## Resets a string table to be empty again, perhaps altering the mode.
  ##
  ## See also:
  ## * `del proc <#del,StringTableRef,string>`_ for removing a key from the table
  runnableExamples:
    var t = {"name": "John", "city": "Monaco"}.newStringTable
    clear(t, modeCaseSensitive)
    doAssert len(t) == 0
    doAssert "name" notin t
    doAssert "city" notin t
  s.mode = mode
  s.counter = 0
  s.data.setLen(startSize)
  for i in 0..<s.data.len:
    s.data[i].hasValue = false

proc clear*(s: StringTableRef) {.since: (1, 1).} =
  ## Resets a string table to be empty again without changing the mode.
  s.clear(s.mode)

proc del*(t: StringTableRef, key: string) =
  ## Removes `key` from `t`.
  ##
  ## See also:
  ## * `clear proc <#clear,StringTableRef,StringTableMode>`_ for resetting a
  ##   table to be empty
  ## * `[]= proc <#[]=,StringTableRef,string,string>`_ for inserting a new
  ##   (key, value) pair in the table
  runnableExamples:
    var t = {"name": "John", "city": "Monaco"}.newStringTable
    t.del("name")
    doAssert len(t) == 1
    doAssert "name" notin t
    doAssert "city" in t

  # Impl adapted from `tableimpl.delImplIdx`
  var i = rawGet(t, key)
  let msk = high(t.data)
  if i >= 0:
    dec(t.counter)
    block outer:
      while true: # KnuthV3 Algo6.4R adapted for i=i+1 instead of i=i-1
        var j = i # The correctness of this depends on (h+1) in nextTry,
        var r = j # though may be adaptable to other simple sequences.
        t.data[i].hasValue = false # mark current EMPTY
        t.data[i].key = ""
        t.data[i].val = ""
        while true:
          i = (i + 1) and msk # increment mod table size
          if not t.data[i].hasValue: # end of collision cluster; So all done
            break outer
          r = t.myhash(t.data[i].key) and msk # "home" location of key@i
          if not ((i >= r and r > j) or (r > j and j > i) or (j > i and i >= r)):
            break
        when defined(js):
          t.data[j] = t.data[i]
        elif defined(gcDestructors):
          t.data[j] = move t.data[i]
        else:
          shallowCopy(t.data[j], t.data[i]) # data[j] will be marked EMPTY next loop

proc `$`*(t: StringTableRef): string {.rtlFunc, extern: "nstDollar".} =
  ## The `$` operator for string tables. Used internally when calling
  ## `echo` on a table.
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

proc `%`*(f: string, t: StringTableRef, flags: set[FormatFlag] = {}): string {.
  rtlFunc, extern: "nstFormat".} =
  ## The `%` operator for string tables.
  runnableExamples:
    var t = {"name": "John", "city": "Monaco"}.newStringTable
    doAssert "${name} lives in ${city}" % t == "John lives in Monaco"

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
