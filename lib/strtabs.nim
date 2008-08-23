#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2008 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

##  The ``strtabs`` module implements an efficient hash table that is a mapping
##  from strings to strings. Supports a case-sensitive, case-insensitive and
##  style-insensitive mode. An efficient string substitution operator  ``%``
##  for the string table is also provided.
  
import 
  os, hashes, strutils

type 
  TStringTableMode* = enum    # describes the tables operation mode
    modeCaseSensitive,        # the table is case sensitive
    modeCaseInsensitive,      # the table is case insensitive
    modeStyleInsensitive      # the table is style insensitive
  TKeyValuePair = tuple[key, val: string]
  TKeyValuePairSeq = seq[TKeyValuePair]
  TStringTable* = object of TObject
    counter: int
    data: TKeyValuePairSeq
    mode: TStringTableMode

  PStringTable* = ref TStringTable ## use this type to declare string tables

proc newStringTable*(keyValuePairs: openarray[string], 
                     mode: TStringTableMode = modeCaseSensitive): PStringTable
  ## creates a new string table with given key value pairs.
  ## Example::
  ##   var mytab = newStringTable("key1", "val1", "key2", "val2", 
  ##                              modeCaseInsensitive)

proc newStringTable*(mode: TStringTableMode = modeCaseSensitive): PStringTable
  ## creates a new string table that is empty.
                     
proc `[]=`*(t: PStringTable, key, val: string)
  ## puts a (key, value)-pair into `t`.

proc `[]`*(t: PStringTable, key: string): string
  ## retrieves the value at ``t[key]``. If `key` is not in `t`, "" is returned
  ## and no exception is raised. One can check with ``hasKey`` whether the key
  ## exists.

proc hasKey*(t: PStringTable, key: string): bool
  ## returns true iff `key` is in the table `t`.

proc len*(t: PStringTable): int =
  ## returns the number of keys in `t`.
  result = t.counter

iterator pairs*(t: PStringTable): tuple[key, value: string] = 
  ## iterates over any (key, value) pair in the table `t`.
  for h in 0..high(t.data):
    if not isNil(t.data[h].key):
      yield (t.data[h].key, t.data[h].val)

type 
  TFormatFlag* = enum         # flags for the `%` operator
    useEnvironment,           # use environment variable if the ``$key``
                              # is not found in the table
    useEmpty,                 # use the empty string as a default, thus it
                              # won't throw an exception if ``$key`` is not
                              # in the table
    useKey                    # do not replace ``$key`` if it is not found
                              # in the table (or in the environment)

proc `%`*(f: string, t: PStringTable, flags: set[TFormatFlag] = {}): string
  ## The `%` operator for string tables.

# implementation

const 
  growthFactor = 2
  startSize = 64

proc newStringTable(mode: TStringTableMode = modeCaseSensitive): PStringTable = 
  new(result)
  result.mode = mode
  result.counter = 0
  result.data = []
  setlen(result.data, startSize) # XXX

proc newStringTable(keyValuePairs: openarray[string], 
                    mode: TStringTableMode = modeCaseSensitive): PStringTable = 
  result = newStringTable(mode)
  var i = 0
  while i < high(keyValuePairs): 
    result[keyValuePairs[i]] = keyValuePairs[i + 1]
    inc(i, 2)

proc myhash(t: PStringTable, key: string): THash = 
  case t.mode
  of modeCaseSensitive: result = hashes.hash(key)
  of modeCaseInsensitive: result = hashes.hashIgnoreCase(key)
  of modeStyleInsensitive: result = hashes.hashIgnoreStyle(key)
  
proc myCmp(t: PStringTable, a, b: string): bool = 
  case t.mode
  of modeCaseSensitive: result = cmp(a, b) == 0
  of modeCaseInsensitive: result = cmpIgnoreCase(a, b) == 0
  of modeStyleInsensitive: result = cmpIgnoreStyle(a, b) == 0
  
proc mustRehash(length, counter: int): bool = 
  assert(length > counter)
  result = (length * 2 < counter * 3) or (length - counter < 4)

const 
  EmptySeq = []

proc nextTry(h, maxHash: THash): THash = 
  result = ((5 * h) + 1) and maxHash # For any initial h in range(maxHash), repeating that maxHash times
                                     # generates each int in range(maxHash) exactly once (see any text on
                                     # random-number generation for proof).
  
proc RawGet(t: PStringTable, key: string): int = 
  var h: THash
  h = myhash(t, key) and high(t.data) # start with real hash value
  while not isNil(t.data[h].key): 
    if mycmp(t, t.data[h].key, key): 
      return h
    h = nextTry(h, high(t.data))
  result = - 1

proc `[]`(t: PStringTable, key: string): string = 
  var index: int
  index = RawGet(t, key)
  if index >= 0: result = t.data[index].val
  else: result = ""
  
proc hasKey(t: PStringTable, key: string): bool = 
  result = rawGet(t, key) >= 0

proc RawInsert(t: PStringTable, data: var TKeyValuePairSeq, key, val: string) = 
  var h: THash
  h = myhash(t, key) and high(data)
  while not isNil(data[h].key): 
    h = nextTry(h, high(data))
  data[h].key = key
  data[h].val = val

proc Enlarge(t: PStringTable) = 
  var n: TKeyValuePairSeq
  n = emptySeq
  setlen(n, len(t.data) * growthFactor)
  for i in countup(0, high(t.data)): 
    if not isNil(t.data[i].key): RawInsert(t, n, t.data[i].key, t.data[i].val)
  swap(t.data, n)

proc `[]=`(t: PStringTable, key, val: string) = 
  var index = RawGet(t, key)
  if index >= 0: 
    t.data[index].val = val
  else: 
    if mustRehash(len(t.data), t.counter): Enlarge(t)
    RawInsert(t, t.data, key, val)
    inc(t.counter)

proc RaiseFormatException(s: string) = 
  var e: ref EInvalidValue
  new(e)
  e.msg = "format string: key not found: " & s
  raise e

proc getValue(t: PStringTable, flags: set[TFormatFlag], key: string): string = 
  if hasKey(t, key): return t[key]
  if useEnvironment in flags: result = os.getEnv(key)
  else: result = ""
  if (result == ""): 
    if useKey in flags: result = '$' & key
    elif not (useEmpty in flags): raiseFormatException(key)
  
proc `%`(f: string, t: PStringTable, flags: set[TFormatFlag] = {}): string = 
  const 
    PatternChars = {'a'..'z', 'A'..'Z', '0'..'9', '_', '\x80'..'\xFF'}
  var 
    i, j: int
    key: string
  result = ""
  i = strStart
  while i <= len(f) + strStart - 1: 
    if f[i] == '$': 
      case f[i + 1]
      of '$': 
        add(result, '$')
        inc(i, 2)
      of '{': 
        j = i + 1
        while (j <= len(f) + strStart - 1) and (f[j] != '}'): inc(j)
        key = copy(f, i + 2, j - 1)
        result = result & getValue(t, flags, key)
        i = j + 1
      of 'a'..'z', 'A'..'Z', '\x80'..'\xFF', '_': 
        j = i + 1
        while (j <= len(f) + strStart - 1) and (f[j] in PatternChars): inc(j)
        key = copy(f, i+1, j - 1)
        result = result & getValue(t, flags, key)
        i = j
      else: 
        add(result, f[i])
        inc(i)
    else: 
      add(result, f[i])
      inc(i)
  
