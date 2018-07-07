discard """
  output: '''true'''
"""

import tables
from hashes import Hash

# Test with int
block:
  var t = initTable[int,int]()
  t[0] = 42
  t[1] = t[0] + 1
  assert(t[0] == 42)
  assert(t[1] == 43)
  let t2 = {1: 1, 2: 2}.toTable
  assert(t2[2] == 2)

# Test with char
block:
  var t = initTable[char,int]()
  t['0'] = 42
  t['1'] = t['0'] + 1
  assert(t['0'] == 42)
  assert(t['1'] == 43)
  let t2 = {'1': 1, '2': 2}.toTable
  assert(t2['2'] == 2)

# Test with enum
block:
  type
    E = enum eA, eB, eC
  var t = initTable[E,int]()
  t[eA] = 42
  t[eB] = t[eA] + 1
  assert(t[eA] == 42)
  assert(t[eB] == 43)
  let t2 = {eA: 1, eB: 2}.toTable
  assert(t2[eB] == 2)

# Test with range
block:
  type
    R = range[1..10]
  var t = initTable[R,int]() # causes warning, why?
  t[1] = 42 # causes warning, why?
  t[2] = t[1] + 1
  assert(t[1] == 42)
  assert(t[2] == 43)
  let t2 = {1.R: 1, 2.R: 2}.toTable
  assert(t2[2.R] == 2)

# Test which combines the generics for tuples + ordinals
block:
  type
    E = enum eA, eB, eC
  var t = initTable[(string, E, int, char), int]()
  t[("a", eA, 0, '0')] = 42
  t[("b", eB, 1, '1')] = t[("a", eA, 0, '0')] + 1
  assert(t[("a", eA, 0, '0')] == 42)
  assert(t[("b", eB, 1, '1')] == 43)
  let t2 = {("a", eA, 0, '0'): 1, ("b", eB, 1, '1'): 2}.toTable
  assert(t2[("b", eB, 1, '1')] == 2)

# Test to check if overloading is possible
# Unfortunately, this does not seem to work for int
# The same test with a custom hash(s: string) does
# work though.
block:
  proc hash(x: int): Hash {.inline.} =
    echo "overloaded hash"
    result = x
  var t = initTable[int, int]()
  t[0] = 0

# Check hashability of all integer types (issue #5429)
block:
  let intTables = (
    newTable[int, string](),
    newTable[int8, string](),
    newTable[int16, string](),
    newTable[int32, string](),
    newTable[int64, string](),
    newTable[uint, string](),
    newTable[uint8, string](),
    newTable[uint16, string](),
    newTable[uint32, string](),
    newTable[uint64, string](),
  )

echo "true"
