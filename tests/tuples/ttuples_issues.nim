discard """
output: '''(a: 1)
(a: 1)
(a: 1, b: 2)
'''
"""


import tables


block t4479:
  type
    MyTuple = tuple
      num: int
      strings: seq[string]
      ints: seq[int]

  var foo = MyTuple((
    num: 7,
    strings: @[],
    ints: @[],
  ))

  var bar = (
    num: 7,
    strings: @[],
    ints: @[],
  ).MyTuple

  var fooUnnamed = MyTuple((7, @[], @[]))
  var n = 7
  var fooSym = MyTuple((num: n, strings: @[], ints: @[]))


block t1910:
  var p = newOrderedTable[tuple[a:int], int]()
  var q = newOrderedTable[tuple[x:int], int]()
  for key in p.keys:
    echo key.a
  for key in q.keys:
    echo key.x


block t2121:
  type
    Item[K,V] = tuple
      key: K
      value: V

  var q = newseq[Item[int,int]](1)
  let (x,y) = q[0]


block t2369:
  type HashedElem[T] = tuple[num: int, storedVal: ref T]

  proc append[T](tab: var seq[HashedElem[T]], n: int, val: ref T) =
      #tab.add((num: n, storedVal: val))
      var he: HashedElem[T] = (num: n, storedVal: val)
      #tab.add(he)

  var g: seq[HashedElem[int]] = @[]

  proc foo() =
      var x: ref int
      new(x)
      x[] = 77
      g.append(44, x)


block t1986:
  proc test(): int64 =
    return 0xdeadbeef.int64

  const items = [
    (var1: test(), var2: 100'u32),
    (var1: test(), var2: 192'u32)
  ]

# bug #14911
echo (a: 1)  # works
echo (`a`: 1)  # works
echo (`a`: 1, `b`: 2)  # Error: named expression expected
