#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2008 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements efficient computations of hash values for diverse
## Nimrod types.

import 
  strutils

type 
  THash* = int ## a hash value; hash tables using these values should 
               ## always have a size of a power of two and can use the ``and``
               ## operator instead of ``mod`` for truncation of the hash value.

proc concHash(h: THash, val: int): THash {.inline.} = 
  result = h +% val
  result = result +% result shl 10
  result = result xor (result shr 6)

proc finishHash(h: THash): THash {.inline.} = 
  result = h +% h shl 3
  result = result xor (result shr 11)
  result = result +% result shl 15

proc hashData*(Data: Pointer, Size: int): THash = 
  ## hashes an array of bytes of size `size`
  var 
    h: THash
    p: cstring
    i, s: int
  h = 0
  p = cast[cstring](Data)
  i = 0
  s = size
  while s > 0: 
    h = concHash(h, ord(p[i]))
    Inc(i)
    Dec(s)
  result = finishHash(h)

proc hash*(x: Pointer): THash {.inline.} = 
  ## efficient hashing of pointers
  result = (cast[THash](x)) shr 3 # skip the alignment
  
proc hash*(x: int): THash {.inline.} = 
  ## efficient hashing of integers
  result = x

proc hash*(x: int64): THash {.inline.} = 
  ## efficient hashing of integers
  result = toU32(x)

proc hash*(x: char): THash {.inline.} = 
  ## efficient hashing of characters
  result = ord(x)

proc hash*(x: string): THash = 
  ## efficient hashing of strings
  var h: THash
  h = 0
  for i in 0..x.len-1: 
    h = concHash(h, ord(x[i]))
  result = finishHash(h)
  
proc hashIgnoreStyle*(x: string): THash = 
  ## efficient hashing of strings; style is ignored
  var 
    h: THash
    c: Char
  h = 0
  for i in 0..x.len-1: 
    c = x[i]
    if c == '_': 
      continue                # skip _
    if c in {'A'..'Z'}: 
      c = chr(ord(c) + (ord('a') - ord('A'))) # toLower()
    h = concHash(h, ord(c))
  result = finishHash(h)

proc hashIgnoreCase*(x: string): THash = 
  ## efficient hashing of strings; case is ignored
  var 
    h: THash
    c: Char
  h = 0
  for i in 0..x.len-1: 
    c = x[i]
    if c in {'A'..'Z'}: 
      c = chr(ord(c) + (ord('a') - ord('A'))) # toLower()
    h = concHash(h, ord(c))
  result = finishHash(h)
