discard """
cmd: "nim $target --threads:on $options $file"
output: '''
'''
"""

import sharedtables

block:
  var table: SharedTable[int, int]

  init(table)
  table[1] = 10
  doAssert table.mget(1) == 10
  doAssert table.mgetOrPut(3, 7) == 7
  doAssert table.mgetOrPut(3, 99) == 7
  deinitSharedTable(table)

import sequtils, algorithm
proc sortedPairs[T](t: T): auto = toSeq(t.pairs).sorted
template sortedItems(t: untyped): untyped = sorted(toSeq(t))

import tables # refs issue #13504

block: # we use Table as groundtruth, it's well tested elsewhere
  template testDel(t, t0) =
    template put2(i) =
      t[i] = i
      t0[i] = i

    template add2(i, val) =
      t.add(i, val)
      t0.add(i, val)

    template del2(i) =
      t.del(i)
      t0.del(i)

    template checkEquals() =
      doAssert t.len == t0.len
      for k,v in t0:
        doAssert t.mgetOrPut(k, -1) == v # sanity check
        doAssert t.mget(k) == v

    let n = 100
    let n2 = n*2
    let n3 = n*3
    let n4 = n*4
    let n5 = n*5

    for i in 0..<n:
      put2(i)
    for i in 0..<n:
      if i mod 3 == 0:
        del2(i)
    for i in n..<n2:
      put2(i)
    for i in 0..<n2:
      if i mod 7 == 0:
        del2(i)

    checkEquals()

    for i in n2..<n3:
      t0[i] = -2
      doAssert t.mgetOrPut(i, -2) == -2
      doAssert t.mget(i) == -2

    for i in 0..<n4:
      let ok = i in t0
      if not ok: t0[i] = -i
      doAssert t.hasKeyOrPut(i, -i) == ok

    checkEquals()

    for i in n4..<n5:
      add2(i, i*10)
      add2(i, i*11)
      add2(i, i*12)
      del2(i)
      del2(i)

    checkEquals()

  var t: SharedTable[int, int]
  init(t) # ideally should be auto-init
  var t0: Table[int, int]
  testDel(t, t0)
  deinitSharedTable(t)
