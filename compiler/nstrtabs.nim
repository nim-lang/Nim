#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# String tables.

import 
  os, nhashes, strutils

type 
  TStringTableMode* = enum 
    modeCaseSensitive,        # the table is case sensitive
    modeCaseInsensitive,      # the table is case insensitive
    modeStyleInsensitive      # the table is style insensitive
  TKeyValuePair* = tuple[key, val: string]
  TKeyValuePairSeq* = seq[TKeyValuePair]
  TStringTable* = object of TObject
    counter*: int
    data*: TKeyValuePairSeq
    mode*: TStringTableMode

  PStringTable* = ref TStringTable

proc newStringTable*(keyValuePairs: openarray[string], 
                     mode: TStringTableMode = modeCaseSensitive): PStringTable
proc put*(t: PStringTable, key, val: string)
proc get*(t: PStringTable, key: string): string
proc hasKey*(t: PStringTable, key: string): bool
proc length*(t: PStringTable): int
type 
  TFormatFlag* = enum 
    useEnvironment,           # use environment variable if the ``$key``
                              # is not found in the table
    useEmpty,                 # use the empty string as a default, thus it
                              # won't throw an exception if ``$key`` is not
                              # in the table
    useKey                    # do not replace ``$key`` if it is not found
                              # in the table (or in the environment)
  TFormatFlags* = set[TFormatFlag]

proc `%`*(f: string, t: PStringTable, flags: TFormatFlags = {}): string
# implementation

const 
  growthFactor = 2
  startSize = 64

proc newStringTable(keyValuePairs: openarray[string], 
                    mode: TStringTableMode = modeCaseSensitive): PStringTable = 
  new(result)
  result.mode = mode
  result.counter = 0
  newSeq(result.data, startSize)
  var i = 0
  while i < high(keyValuePairs): 
    put(result, keyValuePairs[i], keyValuePairs[i + 1])
    inc(i, 2)

proc myhash(t: PStringTable, key: string): THash = 
  case t.mode
  of modeCaseSensitive: result = nhashes.GetHashStr(key)
  of modeCaseInsensitive: result = nhashes.GetHashStrCI(key)
  of modeStyleInsensitive: result = nhashes.getNormalizedHash(key)
  
proc myCmp(t: PStringTable, a, b: string): bool = 
  case t.mode
  of modeCaseSensitive: result = cmp(a, b) == 0
  of modeCaseInsensitive: result = cmpIgnoreCase(a, b) == 0
  of modeStyleInsensitive: result = cmpIgnoreStyle(a, b) == 0
  
proc mustRehash(length, counter: int): bool = 
  assert(length > counter)
  result = (length * 2 < counter * 3) or (length - counter < 4)

proc length(t: PStringTable): int = 
  result = t.counter

proc nextTry(h, maxHash: THash): THash = 
  result = ((5 * h) + 1) and maxHash
  # For any initial h in range(maxHash), repeating that maxHash times
  # generates each int in range(maxHash) exactly once (see any text on
  # random-number generation for proof).
  
proc RawGet(t: PStringTable, key: string): int = 
  var h = myhash(t, key) and high(t.data) # start with real hash value
  while not isNil(t.data[h].key): 
    if mycmp(t, t.data[h].key, key): 
      return h
    h = nextTry(h, high(t.data))
  result = - 1

proc get(t: PStringTable, key: string): string = 
  var index = RawGet(t, key)
  if index >= 0: result = t.data[index].val
  else: result = ""
  
proc hasKey(t: PStringTable, key: string): bool = 
  result = rawGet(t, key) >= 0

proc RawInsert(t: PStringTable, data: var TKeyValuePairSeq, key, val: string) = 
  var h = myhash(t, key) and high(data)
  while not isNil(data[h].key): 
    h = nextTry(h, high(data))
  data[h].key = key
  data[h].val = val

proc Enlarge(t: PStringTable) = 
  var n: TKeyValuePairSeq
  newSeq(n, len(t.data) * growthFactor)
  for i in countup(0, high(t.data)): 
    if not isNil(t.data[i].key): RawInsert(t, n, t.data[i].key, t.data[i].val)
  swap(t.data, n)

proc Put(t: PStringTable, key, val: string) = 
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

proc getValue(t: PStringTable, flags: TFormatFlags, key: string): string = 
  if hasKey(t, key): return get(t, key)
  if useEnvironment in flags: result = os.getEnv(key)
  else: result = ""
  if result.len == 0: 
    if useKey in flags: result = '$' & key
    elif not (useEmpty in flags): raiseFormatException(key)
  
proc `%`(f: string, t: PStringTable, flags: TFormatFlags = {}): string = 
  const 
    PatternChars = {'a'..'z', 'A'..'Z', '0'..'9', '_', '\x80'..'\xFF'}
  result = ""
  var i = 0
  while i <= len(f) + 0 - 1: 
    if f[i] == '$': 
      case f[i + 1]
      of '$': 
        add(result, '$')
        inc(i, 2)
      of '{': 
        var j = i + 1
        while (j <= len(f) + 0 - 1) and (f[j] != '}'): inc(j)
        var key = substr(f, i + 2 + 0 - 1, j - 1 + 0 - 1)
        add(result, getValue(t, flags, key))
        i = j + 1
      of 'a'..'z', 'A'..'Z', '\x80'..'\xFF', '_': 
        var j = i + 1
        while (j <= len(f) + 0 - 1) and (f[j] in PatternChars): inc(j)
        var key = substr(f, i + 1 + 0 - 1, j - 1 + 0 - 1)
        add(result, getValue(t, flags, key))
        i = j
      else: 
        add(result, f[i])
        inc(i)
    else: 
      add(result, f[i])
      inc(i)
  
