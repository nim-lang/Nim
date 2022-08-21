discard """
  targets: "c cpp js"
"""

# targets include `cpp` because in the past, there were several cpp-specific bugs with tuples.

import std/tables

template main() =
  block: # bug #4479
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

    var bar = MyTuple (
      num: 7,
      strings: @[],
      ints: @[],
    )

    var fooUnnamed = MyTuple((7, @[], @[]))
    var n = 7
    var fooSym = MyTuple((num: n, strings: @[], ints: @[]))

  block: # bug #1910
    var p = newOrderedTable[tuple[a:int], int]()
    var q = newOrderedTable[tuple[x:int], int]()
    for key in p.keys:
      echo key.a
    for key in q.keys:
      echo key.x

  block: # bug #2121
    type
      Item[K,V] = tuple
        key: K
        value: V

    var q = newseq[Item[int,int]](1)
    let (x,y) = q[0]

  block: # bug #2369
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

  block: # bug #1986
    proc test(): int64 =
      return 0xdeadbeef.int64

    const items = [
      (var1: test(), var2: 100'u32),
      (var1: test(), var2: 192'u32)
    ]

  block: # bug #14911
    doAssert $(a: 1) == "(a: 1)" # works
    doAssert $(`a`: 1) == "(a: 1)"  # works
    doAssert $(`a`: 1, `b`: 2) == "(a: 1, b: 2)" # was: Error: named expression expected

  block: # bug #16822
    var scores: seq[(set[char], int)] = @{{'/'} : 10}

    var x1: set[char]
    for item in items(scores):
      x1 = item[0]

    doAssert x1 == {'/'}

    var x2: set[char]
    for (chars, value) in items(scores):
      x2 = chars

    doAssert x2 == {'/'}

  block: # bug #14574
    proc fn(): auto =
      let a = @[("foo", (12, 13))]
      for (k,v) in a:
        return (k,v)
    doAssert fn() == ("foo", (12, 13))

  block: # bug #14574
    iterator fn[T](a:T): lent T = yield a
    let a = (10, (11,))
    proc bar(): auto =
      for (x,y) in fn(a):
        return (x,y)
    doAssert bar() == (10, (11,))

proc mainProc() =
  # other tests should be in `main`
  block:
    type A = tuple[x: int, y: int]
    doAssert (x: 1, y: 2).A == A (x: 1, y: 2) # MCS => can't use a template

static:
  main()
  mainProc()

main()
mainProc()
