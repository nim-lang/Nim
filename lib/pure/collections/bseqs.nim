#
#
#            Nim's Runtime Library
#        (c) Copyright 2022 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## An implementation of a dynamic array of Bytes in Nim
## The underlying implementation uses a `seq`.

runnableExamples:
  var
    bs1 = [189u8, 65u8, 234u8, 120u8].toBSeq
    bs2 = "Hello world !".toBSeq
    bs3 = @:0b01000101101011001
    bs4 = @:0b11101100111000110
    bs5 = bs3 xor bs4

  assert $bs1 == "Bytes Sequence: <BD 41 EA 78>"
  assert bs2.toHex == "48656C6C6F20776F726C642021"
  assert bs5.toBin == "000000010101001010011111"

import strutils
import algorithm

type
  BSeq* {.inheritable.} = object
    data: seq[byte]

proc initBSeq*(initialSize = 0, initialValue: byte = 0): BSeq =
  ## Creates a new Bytes Sequence of `initialSize` items
  ## 
  ## If `initialValue` is not defined,
  ## the BSeq is filled with 0s
  var sq = newSeq[byte](initialSize)

  if initialValue != 0:
    for i in 0..(initialSize - 1) :
      sq[i] = initialValue
  result.data = sq

proc len*(bs: BSeq):int =
  ## Returns the number of items in `bs`
  return bs.data.len

proc `[]`*(bs: BSeq, i: Natural): byte =
  ## Accesses the `i`-th item of `bs`
  return bs.data[i]

proc `[]`*(bs: var BSeq, i: Natural): var byte =
  ## Returns a mutable ref to the `i`-th item of `bs`
  return bs.data[i]

proc `[]=`*(bs: var BSeq, i: Natural, val: byte) = 
    ## Sets the `i`-th item of `bs` to `val`
    bs.data[i] = val

proc `[]`*(bs: BSeq, i: BackwardsIndex): byte =
  ## Accesses the backwards indexed `i`-th item of `bs`
  return bs.data[i]

proc `[]`*(bs: var BSeq, i: BackwardsIndex): var byte =
  ## Returns a mutable ref to the backwards
  ## indexed `i`-th item of `bs`
  return bs.data[i]

proc `[]=`*(bs: var BSeq, i: BackwardsIndex, val: byte) =
  ## Sets the backwards indexed `i`-th item of `bs`
  ## to val
  bs.data[i] = val

iterator items*(bs: BSeq): byte =
  ## Yields every item of `bs`
  for val in bs.data:
    yield val

iterator mitems*(bs: var BSeq): var byte =
  ## Yields every item of `bs` as a mutable ref
  for val in mitems bs.data:
    yield val

iterator pairs*(bs: BSeq): tuple[key: int, val: byte] =
  ## Yields every `(position, value)`-pair of `bs`.
  for i, val in bs.data:
    yield (key: i, val: val)

proc contains*(bs: BSeq, item: byte): bool =
  ## Returns true if `item` is in `bs` or false if not found.
  return bs.data.contains item

# The different versions of the `digest` proc transform
# several data types into a common `seq[byte]` representation
# Which will serve in other functions

proc digest(data: char): seq[byte] =
  return @[data.byte]

proc digest(data: string): seq[byte] =
  return cast[seq[byte]](data)

proc digest(data: SomeInteger): seq[byte] =
  var temp = data
  while temp > 0:
    result.insert uint8 (temp mod 256), 0
    temp = (temp shr 8)

proc addFirst*[T](bs: var BSeq, bs2: sink BSeq) =
  ## Prepends another Byte sequence to `bs`
  bs.data = bs2.data & bs.data

proc addFirst*(bs: var BSeq, data: SomeInteger | string | char) =
  ## Prepends an integer, a string, or a char to `bs`
  bs.data = digest(data) & bs.data

proc addFirst*(bs: var BSeq, arr: sink openArray[uint8]) =
  ## Prepends an openArray of bytes to `bs`
  bs.data = @arr & bs.data

proc addLast*(bs: var BSeq, bs2: sink BSeq) =
  ## Appends another Byte sequence to `bs`
  bs.data &= bs2.data

proc addLast*(bs: var BSeq, data: SomeInteger | string | char) =
  ## Appends an integer, a string, or a char to `bs`
  bs.data &= digest data

proc addLast*(bs: var BSeq, arr: sink openArray[uint8]) =
  ## Appends an openArray of bytes to `bs`
  bs.data &= @arr

proc insert*(bs: var BSeq, b: byte, index: Natural) =
  ## Inserts a byte at the `index`-th position, in `bs`
  bs.data.insert(b, index)

proc delete*(bs: var BSeq, index: Natural) =
  ## Deletes the `index`-th byte of `bs`
  bs.data.delete index

proc toBSeq*(data: SomeInteger | string | char): BSeq =
  ## Converts an integer, a string or a char, into a Byte Sequence
  result.data = digest data

proc toBSeq*(arr: sink openArray[uint8]): BSeq =
  ## Converts an openArray of bytes into a Byte Sequence
  result.data = @arr

template `@:`*(val: typed):BSeq = toBSeq(val)
  ## An operator that serves as shortcut to Build Byte Sequences
  ## From other types

proc `and`*(bs1: sink BSeq, bs2: sink BSeq): BSeq =
  ## Performs a binary `and` between two Byte sequences
  var
    arr:seq[byte]
    mx = max(bs1.len, bs2.len)
    mn = min(bs1.len, bs2.len)
    toup = 1
  for i in countdown(mx - 1, 0):
    if toup <= mn:
      arr.insert (bs1[bs1.len - toup] and bs2[bs2.len - toup]), 0
    else:
      arr.insert 0u8, 0
    toup += 1
  return @:arr

proc `or`*(bs1: sink BSeq, bs2: sink BSeq): BSeq =
  ## Performs a binary `or` between two Byte sequences
  var
    arr:seq[byte]
    mx = max(bs1.len, bs2.len)
    mn = min(bs1.len, bs2.len)
    bs:BSeq
    toup = 1
  
  if bs1.len >=  bs2.len:
    bs = bs1
  else:
    bs = bs2

  for i in countdown(mx - 1, 0):
    if toup <= mn:
      arr.insert (bs1[bs1.len - toup] or bs2[bs2.len - toup]), 0
    else:
      arr.insert bs[bs.len - toup], 0
    toup += 1
  return @:arr

proc `xor`*(bs1: sink BSeq, bs2: sink BSeq): BSeq =
  ## Performs a binary `xor` between two Byte sequences
  var
    arr:seq[byte]
    mx = max(bs1.len, bs2.len)
    mn = min(bs1.len, bs2.len)
    bs:BSeq
    toup = 1
  
  if bs1.len >=  bs2.len:
    bs = bs1
  else:
    bs = bs2

  for i in countdown(mx - 1, 0):
    if toup <= mn:
      arr.insert (bs1[bs1.len - toup] xor bs2[bs2.len - toup]), 0
    else:
      arr.insert bs[bs.len - toup], 0
    toup += 1
  return @:arr

proc toBin*(bs: BSeq): string =
  ## Returns a binary representation of `bs` as a string
  for i in bs:
    result &= toBin(int i, 8)

proc toOct*(bs: BSeq): string =
  ## Returns an octal representation of `bs` as a string
  var
    to3 = 0
    temps = [0, 0, 0]
    temp: int
    arr: seq[string]
  for i in countdown(bs.len - 1, 0):
    temps[to3] = bs.data[i].int
    to3 += 1

    if to3 == 3:
      temp = temp or temps[2]
      temp = temp shl 8
      temp = temp or temps[1]
      temp = temp shl 8
      temp = temp or temps[0]
      arr.add temp.toOct(8)
      temps = [0, 0, 0]
      temp = 0
      to3 = 0

  if to3 == 2:
    temp = temp or temps[1]
    temp = temp shl 8
  if to3 > 0:
    temp = temp or temps[0]
    if to3 == 1:
      arr.add temp.toOct(3)
    else:
      arr.add temp.toOct(6)

  reverse arr
  join arr

proc toHex*(bs: BSeq): string =
  ## Returns an hexadecimal representation of `bs` as a string
  for i in bs:
    result &= toHex(int i, 2)

proc `$`*(bs: BSeq): string =
  ## Returns a string representation of `bs`
  var
    limit = 64
    more: string

  if bs.len > limit:
    more = " ... " & $(bs.len - limit) & " more byte"
    if (bs.len - limit) > 1:
      more &= "s"
  else:
    more = ""

  result = "Bytes Sequence: <"
  let ending = (min(limit, bs.len) - 1)
  for i, bt in bs.data:
    result &= bt.toHex
    if i < ending:
      result &= " "
    else:
      if ending < bs.data.len:
         result &= more
      break

  result &= ">"
