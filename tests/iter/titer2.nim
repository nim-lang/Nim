discard """
  output: '''true
3
4
5
0
1
2
3
4'''
  cmd: "nim $target --gc:none --hints:on --warnings:off $options $file"
"""

import hashes

type
  TSlotEnum = enum seEmpty, seFilled, seDeleted
  TKeyValuePair[A, B] = tuple[slot: TSlotEnum, key: A, val: B]
  TKeyValuePairSeq[A, B] = seq[TKeyValuePair[A, B]]
  TTable* {.final.}[A, B] = object
    data: TKeyValuePairSeq[A, B]
    counter: int

iterator mycountup(a, b: int): int =
  var res = a
  while res <= b:
    yield res
    inc(res)

when true:
  iterator pairs*[A, B](t: TTable[A, B]): tuple[key: A, val: B] =
    ## iterates over any (key, value) pair in the table `t`.
    for h in mycountup(0, high(t.data)):
      var k = t.data[h].key
      if t.data[h].slot == seFilled: yield (k, t.data[h].val)
else:
  iterator pairs*(t: TTable[int, string]): tuple[key: int, val: string] =
    ## iterates over any (key, value) pair in the table `t`.
    for h in mycountup(0, high(t.data)):
      var k = t.data[h].key
      if t.data[h].slot == seFilled: yield (k, t.data[h].val)

proc initTable*[A, B](initialSize=64): TTable[A, B] =
  ## creates a new hash table that is empty. `initialSize` needs to be
  ## a power of two.
  result.counter = 0
  newSeq(result.data, initialSize)

block Test1:
  # generic cache does not instantiate the same iterator[types] twice. This
  # means we have only one instantiation of 'h'. However, this is the same for
  # a non-generic iterator!

  var t = initTable[int, string]()
  for k, v in t.pairs: discard
  for k, v in t.pairs: discard

echo "true"

# bug #1560
for i in @[3, 4, 5]:
  echo($i)

# bug #6992
for i in 0 ..< 5u32:
  echo i
