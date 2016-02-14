#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## The ``gentabs`` module implements an efficient hash table that is a
## key-value mapping. The keys are required to be strings, but the values
## may be any Nim or user defined type. This module supports matching
## of keys in case-sensitive, case-insensitive and style-insensitive modes.
##
## **Warning:** This module is deprecated, new code shouldn't use it!

{.deprecated.}

import
  os, hashes, strutils

type
  GenTableMode* = enum     ## describes the table's key matching mode
    modeCaseSensitive,     ## case sensitive matching of keys
    modeCaseInsensitive,   ## case insensitive matching of keys
    modeStyleInsensitive   ## style sensitive matching of keys

  GenKeyValuePair[T] = tuple[key: string, val: T]
  GenKeyValuePairSeq[T] = seq[GenKeyValuePair[T]]
  GenTable*[T] = object of RootObj
    counter: int
    data: GenKeyValuePairSeq[T]
    mode: GenTableMode

  PGenTable*[T] = ref GenTable[T]     ## use this type to declare hash tables

{.deprecated: [TGenTableMode: GenTableMode, TGenKeyValuePair: GenKeyValuePair,
              TGenKeyValuePairSeq: GenKeyValuePairSeq, TGenTable: GenTable].}

const
  growthFactor = 2
  startSize = 64


proc len*[T](tbl: PGenTable[T]): int {.inline.} =
  ## returns the number of keys in `tbl`.
  result = tbl.counter

iterator pairs*[T](tbl: PGenTable[T]): tuple[key: string, value: T] =
  ## iterates over any (key, value) pair in the table `tbl`.
  for h in 0..high(tbl.data):
    if not isNil(tbl.data[h].key):
      yield (tbl.data[h].key, tbl.data[h].val)

proc myhash[T](tbl: PGenTable[T], key: string): Hash =
  case tbl.mode
  of modeCaseSensitive: result = hashes.hash(key)
  of modeCaseInsensitive: result = hashes.hashIgnoreCase(key)
  of modeStyleInsensitive: result = hashes.hashIgnoreStyle(key)

proc myCmp[T](tbl: PGenTable[T], a, b: string): bool =
  case tbl.mode
  of modeCaseSensitive: result = cmp(a, b) == 0
  of modeCaseInsensitive: result = cmpIgnoreCase(a, b) == 0
  of modeStyleInsensitive: result = cmpIgnoreStyle(a, b) == 0

proc mustRehash(length, counter: int): bool =
  assert(length > counter)
  result = (length * 2 < counter * 3) or (length - counter < 4)

proc newGenTable*[T](mode: GenTableMode): PGenTable[T] =
  ## creates a new generic hash table that is empty.
  new(result)
  result.mode = mode
  result.counter = 0
  newSeq(result.data, startSize)

proc nextTry(h, maxHash: Hash): Hash {.inline.} =
  result = ((5 * h) + 1) and maxHash

proc rawGet[T](tbl: PGenTable[T], key: string): int =
  var h: Hash
  h = myhash(tbl, key) and high(tbl.data) # start with real hash value
  while not isNil(tbl.data[h].key):
    if myCmp(tbl, tbl.data[h].key, key):
      return h
    h = nextTry(h, high(tbl.data))
  result = - 1

proc rawInsert[T](tbl: PGenTable[T], data: var GenKeyValuePairSeq[T],
                  key: string, val: T) =
  var h: Hash
  h = myhash(tbl, key) and high(data)
  while not isNil(data[h].key):
    h = nextTry(h, high(data))
  data[h].key = key
  data[h].val = val

proc enlarge[T](tbl: PGenTable[T]) =
  var n: GenKeyValuePairSeq[T]
  newSeq(n, len(tbl.data) * growthFactor)
  for i in countup(0, high(tbl.data)):
    if not isNil(tbl.data[i].key):
      rawInsert[T](tbl, n, tbl.data[i].key, tbl.data[i].val)
  swap(tbl.data, n)

proc hasKey*[T](tbl: PGenTable[T], key: string): bool =
  ## returns true iff `key` is in the table `tbl`.
  result = rawGet(tbl, key) >= 0

proc `[]`*[T](tbl: PGenTable[T], key: string): T =
  ## retrieves the value at ``tbl[key]``. If `key` is not in `tbl`,
  ## default(T) is returned and no exception is raised. One can check
  ## with ``hasKey`` whether the key exists.
  var index = rawGet(tbl, key)
  if index >= 0: result = tbl.data[index].val

proc `[]=`*[T](tbl: PGenTable[T], key: string, val: T) =
  ## puts a (key, value)-pair into `tbl`.
  var index = rawGet(tbl, key)
  if index >= 0:
    tbl.data[index].val = val
  else:
    if mustRehash(len(tbl.data), tbl.counter): enlarge(tbl)
    rawInsert(tbl, tbl.data, key, val)
    inc(tbl.counter)


when isMainModule:
  #
  # Verify tables of integer values (string keys)
  #
  var x = newGenTable[int](modeCaseInsensitive)
  x["one"]   = 1
  x["two"]   = 2
  x["three"] = 3
  x["four"]  = 4
  x["five"]  = 5
  assert(len(x) == 5)             # length procedure works
  assert(x["one"] == 1)           # case-sensitive lookup works
  assert(x["ONE"] == 1)           # case-insensitive should work for this table
  assert(x["one"]+x["two"] == 3)  # make sure we're getting back ints
  assert(x.hasKey("one"))         # hasKey should return 'true' for a key
                                  # of "one"...
  assert(not x.hasKey("NOPE"))    # ...but key "NOPE" is not in the table.
  for k,v in pairs(x):            # make sure the 'pairs' iterator works
    assert(x[k]==v)

  #
  # Verify a table of user-defined types
  #
  type
    MyType = tuple[first, second: string] # a pair of strings
  {.deprecated: [TMyType: MyType].}

  var y = newGenTable[MyType](modeCaseInsensitive) # hash table where each
                                                    # value is MyType tuple

  #var junk: MyType = ("OK", "Here")

  #echo junk.first, " ", junk.second

  y["Hello"] = ("Hello", "World")
  y["Goodbye"] = ("Goodbye", "Everyone")
  #y["Hello"] = MyType( ("Hello", "World") )
  #y["Goodbye"] = MyType( ("Goodbye", "Everyone") )

  assert( not isNil(y["Hello"].first) )
  assert( y["Hello"].first == "Hello" )
  assert( y["Hello"].second == "World" )

  #
  # Verify table of tables
  #
  var z: PGenTable[ PGenTable[int] ] # hash table where each value is
                                     # a hash table of ints

  z = newGenTable[PGenTable[int]](modeCaseInsensitive)
  z["first"] = newGenTable[int](modeCaseInsensitive)
  z["first"]["one"] = 1
  z["first"]["two"] = 2
  z["first"]["three"] = 3

  z["second"] = newGenTable[int](modeCaseInsensitive)
  z["second"]["red"] = 10
  z["second"]["blue"] = 20

  assert(len(z) == 2)               # length of outer table
  assert(len(z["first"]) == 3)      # length of "first" table
  assert(len(z["second"]) == 2)     # length of "second" table
  assert( z["first"]["one"] == 1)   # retrieve from first inner table
  assert( z["second"]["red"] == 10) # retrieve from second inner table

  when false:
    # disabled: depends on hash order:
    var output = ""
    for k, v in pairs(z):
      output.add( "$# ($#) ->\L" % [k,$len(v)] )
      for k2,v2 in pairs(v):
        output.add( "  $# <-> $#\L" % [k2,$v2] )

    let expected = unindent """
      first (3) ->
        two <-> 2
        three <-> 3
        one <-> 1
      second (2) ->
        red <-> 10
        blue <-> 20
    """
    assert output == expected
