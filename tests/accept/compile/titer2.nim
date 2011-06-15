discard """
  output: '''true'''
  cmd: "nimrod cc --gc:none --hints:on $# $#"
"""

import hashes

type
  TSlotEnum = enum seEmpty, seFilled, seDeleted
  TKeyValuePair[A, B] = tuple[slot: TSlotEnum, key: A, val: B]
  TKeyValuePairSeq[A, B] = seq[TKeyValuePair[A, B]]
  TTable* {.final.}[A, B] = object
    data: TKeyValuePairSeq[A, B]
    counter: int

proc len*[A, B](t: TTable[A, B]): int = 
  result = t.counter

iterator pairs*[A, B](t: TTable[A, B]): tuple[key: A, val: B] =
  ## iterates over any (key, value) pair in the table `t`.
  for h in 0..high(t.data):
    if t.data[h].slot == seFilled: yield (t.data[h].key, t.data[h].val)

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
  for k, v in t.pairs: nil
  for k, v in t.pairs: nil

echo "true"

