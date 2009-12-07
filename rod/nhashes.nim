#
#
#           The Nimrod Compiler
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import 
  strutils

const 
  SmallestSize* = (1 shl 3) - 1
  DefaultSize* = (1 shl 11) - 1
  BiggestSize* = (1 shl 28) - 1

type 
  THash* = int
  PHash* = ref THash
  THashFunc* = proc (str: cstring): THash

proc GetHash*(str: cstring): THash
proc GetHashCI*(str: cstring): THash
proc GetDataHash*(Data: Pointer, Size: int): THash
proc hashPtr*(p: Pointer): THash
proc GetHashStr*(s: string): THash
proc GetHashStrCI*(s: string): THash
proc getNormalizedHash*(s: string): THash
  #function nextPowerOfTwo(x: int): int;
proc concHash*(h: THash, val: int): THash
proc finishHash*(h: THash): THash
# implementation

proc nextPowerOfTwo(x: int): int = 
  result = x -% 1 # complicated, to make it a nop if sizeof(int) == 4,
                  # because shifting more than 31 bits is undefined in C
  result = result or (result shr ((sizeof(int) - 4) * 8))
  result = result or (result shr 16)
  result = result or (result shr 8)
  result = result or (result shr 4)
  result = result or (result shr 2)
  result = result or (result shr 1)
  Inc(result)

proc concHash(h: THash, val: int): THash = 
  result = h +% val
  result = result +% result shl 10
  result = result xor (result shr 6)

proc finishHash(h: THash): THash = 
  result = h +% h shl 3
  result = result xor (result shr 11)
  result = result +% result shl 15

proc GetDataHash(Data: Pointer, Size: int): THash = 
  var 
    h: THash
    p: cstring
    i, s: int
  h = 0
  p = cast[cstring](Data)
  i = 0
  s = size
  while s > 0: 
    h = h +% ord(p[i])
    h = h +% h shl 10
    h = h xor (h shr 6)
    Inc(i)
    Dec(s)
  h = h +% h shl 3
  h = h xor (h shr 11)
  h = h +% h shl 15
  result = THash(h)

proc hashPtr(p: Pointer): THash = 
  result = (cast[THash](p)) shr 3 # skip the alignment
  
proc GetHash(str: cstring): THash = 
  var 
    h: THash
    i: int
  h = 0
  i = 0
  while str[i] != '\0': 
    h = h +% ord(str[i])
    h = h +% h shl 10
    h = h xor (h shr 6)
    Inc(i)
  h = h +% h shl 3
  h = h xor (h shr 11)
  h = h +% h shl 15
  result = THash(h)

proc GetHashStr(s: string): THash = 
  var h: THash
  h = 0
  for i in countup(1, len(s)): 
    h = h +% ord(s[i])
    h = h +% h shl 10
    h = h xor (h shr 6)
  h = h +% h shl 3
  h = h xor (h shr 11)
  h = h +% h shl 15
  result = THash(h)

proc getNormalizedHash(s: string): THash = 
  var 
    h: THash
    c: Char
  h = 0
  for i in countup(0, len(s) + 0 - 1): 
    c = s[i]
    if c == '_': 
      continue                # skip _
    if c in {'A'..'Z'}: 
      c = chr(ord(c) + (ord('a') - ord('A'))) # toLower()
    h = h +% ord(c)
    h = h +% h shl 10
    h = h xor (h shr 6)
  h = h +% h shl 3
  h = h xor (h shr 11)
  h = h +% h shl 15
  result = THash(h)

proc GetHashStrCI(s: string): THash = 
  var 
    h: THash
    c: Char
  h = 0
  for i in countup(0, len(s) + 0 - 1): 
    c = s[i]
    if c in {'A'..'Z'}: 
      c = chr(ord(c) + (ord('a') - ord('A'))) # toLower()
    h = h +% ord(c)
    h = h +% h shl 10
    h = h xor (h shr 6)
  h = h +% h shl 3
  h = h xor (h shr 11)
  h = h +% h shl 15
  result = THash(h)

proc GetHashCI(str: cstring): THash = 
  var 
    h: THash
    c: Char
    i: int
  h = 0
  i = 0
  while str[i] != '\0': 
    c = str[i]
    if c in {'A'..'Z'}: 
      c = chr(ord(c) + (ord('a') - ord('A'))) # toLower()
    h = h +% ord(c)
    h = h +% h shl 10
    h = h xor (h shr 6)
    Inc(i)
  h = h +% h shl 3
  h = h xor (h shr 11)
  h = h +% h shl 15
  result = THash(h)
