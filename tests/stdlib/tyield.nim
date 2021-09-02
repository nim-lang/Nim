discard """
  targets: "c cpp js"
"""

import std/[sugar, algorithm]

block:
  var x = @[(6.0, 6, '6'),
            (5.0, 5, '5'),
            (4.0, 4, '4'),
            (3.0, 3, '3'),
            (2.0, 2, '2'),
            (1.0, 1, '1')]

  let y = x.reversed

  block:
    let res = collect:
      for (f, i, c) in x:
        (f, i, c)

    doAssert res == x

  iterator popAscending[T](q: var seq[T]): T =
    while q.len > 0: yield q.pop

  block:
    var res = collect:
      for f, i, c in popAscending(x):
        (f, i, c)

    doAssert res == y

    let z = reversed(res)
    let res2 = collect:
      for (f, i, c) in popAscending(res):
        (f, i, c)

    doAssert res2 == z


block:
  var visits = 0
  block:
    proc bar(): (int, int) =
      inc visits
      (visits, visits)

    iterator foo(): (int, int) =
      yield bar()

    for a, b in foo():
      doAssert a == b

    doAssert visits == 1

  block:
    proc iterAux(a: seq[int], i: var int): (int, string) =
      result = (a[i], $a[i])
      inc i

    iterator pairs(a: seq[int]): (int, string) =
      var i = 0
      while i < a.len:
        yield iterAux(a, i)

    var x = newSeq[int](10)
    for i in 0 ..< x.len:
      x[i] = i

    let res = collect:
      for k, v in x:
        (k, v)

    let expected = collect:
      for i in 0 ..< x.len:
        (i, $i)

    doAssert res == expected

  block:
    proc bar(): (int, int, int) =
      inc visits
      (visits, visits, visits)

    iterator foo(): (int, int, int) =
      yield bar()

    for a, b, c in foo():
      doAssert a == b

    doAssert visits == 2


  block:

    proc bar(): int =
      inc visits
      visits

    proc car(): int =
      inc visits
      visits

    iterator foo(): (int, int) =
      yield (bar(), car())
      yield (bar(), car())

    for a, b in foo():
      doAssert b == a + 1

    doAssert visits == 6


  block:
    proc bar(): (int, int) =
      inc visits
      (visits, visits)

    proc t2(): int = 99

    iterator foo(): (int, int) =
      yield (12, t2())
      yield bar()

    let res = collect:
      for (a, b) in foo():
        (a, b)

    doAssert res == @[(12, 99), (7, 7)]
    doAssert visits == 7

  block:
    proc bar(): (int, int) =
      inc visits
      (visits, visits)

    proc t2(): int = 99

    iterator foo(): (int, int) =
      yield ((12, t2()))
      yield (bar())

    let res = collect:
      for (a, b) in foo():
        (a, b)

    doAssert res == @[(12, 99), (8, 8)]
    doAssert visits == 8

  block:
    proc bar(): (int, int) =
      inc visits
      (visits, visits)

    proc t1(): int = 99
    proc t2(): int = 99

    iterator foo(): (int, int) =
      yield (t1(), t2())
      yield bar()

    let res = collect:
      for a, b in foo():
        (a, b)

    doAssert res == @[(99, 99), (9, 9)]
    doAssert visits == 9


  block:
    proc bar(): ((int, int), string) =
      inc visits
      ((visits, visits), $visits)

    proc t2(): int = 99

    iterator foo(): ((int, int), string) =
      yield ((1, 2), $t2())
      yield bar()

    let res = collect:
      for a, b in foo():
        (a, b)

    doAssert res == @[((1, 2), "99"), ((10, 10), "10")]
    doAssert visits == 10


  block:
    proc bar(): (int, int) =
      inc visits
      (visits, visits)

    iterator foo(): (int, int) =
      yield (for i in 0 ..< 10: discard bar(); bar())
      yield (bar())

    let res = collect:
      for (a, b) in foo():
        (a, b)

    doAssert res == @[(21, 21), (22, 22)]

  block:
    proc bar(): (int, int) =
      inc visits
      (visits, visits)

    proc t2(): int = 99

    iterator foo(): (int, int) =
      yield if true: bar() else: (t2(), t2())
      yield (bar())

    let res = collect:
      for a, b in foo():
        (a, b)

    doAssert res == @[(23, 23), (24, 24)]


block:
  iterator foo(): (int, int, int) =
    var time = 777
    yield (1, time, 3)

  let res = collect:
    for a, b, c in foo():
      (a, b, c)

  doAssert res == @[(1, 777, 3)]

block:
  iterator foo(): (int, int, int) =
    var time = 777
    yield (1, time, 3)

  let res = collect:
    for t in foo():
      (t[0], t[1], t[2])

  doAssert res == @[(1, 777, 3)]


block:
  proc bar(): (int, int, int) =
    (1, 2, 3)
  iterator foo(): (int, int, int) =
    yield bar()

  let res = collect:
    for a, b, c in foo():
      (a, b, c)

  doAssert res == @[(1, 2, 3)]
