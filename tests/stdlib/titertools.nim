discard """
  action: "run"
"""

import std/[itertools, assertions, options, tables, sets]
from std/strutils import isUpperAscii, isLowerAscii, toUpperAscii, split

const
  ints = [-2, -1, 1, 3, -4, 5]
  chars = ['a', '.', 'b', 'C', 'z', 'd']
  strs = ["foo", "BAR", "Niklaus", "deadbeef"]
  text = "Epicurus sought tranquility through simplicity and pleasure."

block test_map:
  doAssert ints.items.map(abs).collect() == @[2, 1, 1, 3, 4, 5]
  doAssert chars.items.map(toUpperAscii).collect() == @['A', '.', 'B', 'C', 'Z', 'D']
  doAssert strs.items.map(toUpperAscii).collect() == @["FOO", "BAR", "NIKLAUS", "DEADBEEF"]

  doAssert ints.items.mapIt(abs(it)).collect() == @[2, 1, 1, 3, 4, 5]
  doAssert chars.items.mapIt(char(it.ord + 1)).collect() == @['b', '/', 'c', 'D', '{', 'e']
  doAssert strs.items.mapIt((var s = it; s.setLen(1); s)).collect() == @["f", "B", "N", "d"]

block test_filter:
  doAssert ints.items.filter(proc(x: int): bool = x > 0).collect() == @[1, 3, 5]
  doAssert chars.items.filter(proc(x: char): bool = x in {'a'..'z'}).collect() == @['a', 'b', 'z', 'd']
  doAssert strs.items.filter(proc(x: string): bool = x.len == 3).collect() == @["foo", "BAR"]

  doAssert ints.items.filterIt(it mod 2 == 0).collect() == @[-2, -4]
  doAssert chars.items.filterIt(it notin {'a'..'d'}).collect() == @['.', 'C', 'z']
  doAssert strs.items.filterIt(it.len > 7).collect() == @["deadbeef"]

block test_group:
  doAssert ints.items.group(2).collect() == @[(-2, -1), (1, 3), (-4, 5)]
  doAssert ints.items.group(4).collect() == @[(-2, -1, 1, 3)]
  doAssert chars.items.group(6).collect() == @[('a', '.', 'b', 'C', 'z', 'd')]

block test_skip:
  doAssert ints.items.skip(3).collect() == @[3, -4, 5]
  doAssert chars.items.skip(6).collect() == newSeq[char](0)
  doAssert strs.items.skip(0).collect() == @strs

block test_skipWhile:
  doAssert ints.items.skipWhile(proc(x: int): bool = x < 0).collect() == @[1, 3, -4, 5]
  doAssert ints.items.skipWhileIt(it < 0).collect() == @[1, 3, -4, 5]

block test_take:
  doAssert ints.items.take(3).collect() == @[-2, -1, 1]
  doAssert chars.items.take(6).collect() == @chars
  doAssert strs.items.take(0).collect() == newSeq[string](0)

block test_takeWhile:
  doAssert ints.items.takeWhile(proc(x: int): bool = x < 0).collect() == @[-2, -1]
  doAssert ints.items.takeWhileIt(it < 0).collect() == @[-2, -1]

block test_stepBy:
  doAssert ints.items.stepBy(2).collect() == @[-2, 1, -4]
  doAssert text.items.stepBy(5).foldIt("", (acc.add(it); acc)) == "Ero qtr ly s"
  doAssert chars.items.stepBy(9000).collect() == @['a']

block test_enumerate:
  doAssert ints.items.enumerate.collect() == @[(0, -2), (1, -1), (2, 1), (3, 3), (4, -4), (5, 5)]

block test_flatten:
  let wordEndBytes = text.split.mapIt(it[^2..^1]).flatten().mapIt(ord(it).byte).collect(set[byte])
  doAssert wordEndBytes == {46.byte, 100, 101, 103, 104, 110, 115, 116, 117, 121}

block test_fold:
  func appended(acc: sink seq[string]; it: int): seq[string] =
    result = acc
    result.add($it)

  proc grow(acc: var seq[string]; it: int) =
    acc.add($it)

  doAssert ints.items.fold(@["acc"], appended) == @["acc", "-2", "-1", "1", "3", "-4", "5"]
  doAssert ints.items.fold(@["acc"], grow) == @["acc", "-2", "-1", "1", "3", "-4", "5"]
  doAssert chars.items.foldIt({'@'}, (acc.incl(it); acc)) == {'.', '@', 'C', 'a', 'b', 'd', 'z'}
  let t = chars.items.enumerate.foldIt(initTable[char, int](), (acc[it[1]] = it[0]; acc))
  doAssert t['d'] == 5

block test_collectToSeq:
  doAssert ints.items.collect() == @ints
  doAssert chars.items.collect() == @chars
  doAssert strs.items.collect() == @strs

block test_collectToSpecificContainers:
  doAssert text.items.collect(set[char]) == {' ', '.', 'E', 'a', 'c', 'd', 'e', 'g', 'h', 'i', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'y'}
  doAssert ints.items.collect(seq[int]) == @[-2, -1, 1, 3, -4, 5]
  doAssert strs.items.collect(HashSet[string]) == toHashSet(strs)
  doAssert chars.items.collect(string) == "a.bCzd"
  type Foo[int] = object
    v*: seq[int]
  proc push(f: var Foo; val: int) {.used.} =
    f.v.add val
  let foo = ints.items.filterIt(it > 0).collect(Foo[int])
  doAssert foo.v == @[1, 3, 5]

block test_collectToAssociativeContainer:
  const kvs = [(3, "c"), (1, "a"), (2, "b")]
  let t = kvs.items.collect(OrderedTable[int, string])
  doAssert t.keys.collect(3) == @[3, 1, 2]

  type Foo[char, int] = object
    v: array[char, int]
  proc `[]=`(c: var Foo[char, int]; k: char; v: int) {.used.} =
    c.v[k] = v
  let f = kvs.items.mapIt((it[1][0], it[0])).collect(toType = Foo[char, int])
  doAssert f.v['\0'] == 0 and f.v['a'] == 1 and f.v['b'] == 2 and f.v['c'] == 3

block test_minMax:
  doAssert ints.items.min() == -4
  doAssert chars.items.min() == '.'
  doAssert strs.items.min() == "BAR"

  doAssert ints.items.max() == 5
  doAssert chars.items.max() == 'z'
  doAssert strs.items.max() == "foo"

block test_count:
  doAssert ints.items.count() == 6
  doAssert chars.items.count() == 6
  doAssert strs.items.count() == 4

block test_sum:
  doAssert ints.items.sum() == 2

block test_product:
  doAssert ints.items.product() == -120

block test_anyAll:
  doAssert ints.items.anyIt(it > 1)
  doAssert chars.items.anyIt(it.isUpperAscii)
  doAssert chars.items.any(isLowerAscii)
  doAssert chars.items.allIt(it in {'.', 'C', 'a'..'z'})
  doAssert chars.items.all(isLowerAscii) == false
  doAssert "".items.allIt(it == '!')

block test_find:
  doAssert ints.items.find(proc(x: int): bool = x > 1) == some(3)
  doAssert ints.items.findIt(it < -2) == some(-4)
  doAssert strs.items.find(proc(x: string): bool = x.items.all(isUpperAscii)) == some("BAR")
  doAssert strs.items.findIt(it == "Dijkstra").isNone()
  doAssert chars.items.find(proc(x: char): bool = x.ord > 'y'.ord) == some('z')

block test_position:
  doAssert ints.items.position(proc(x: int): bool = x > -1) == some(2)
  doAssert ints.items.positionIt(it == 1) == some(2)
  doAssert strs.items.position(proc(x: string): bool = x.items.all(isUpperAscii)) == some(1)
  doAssert strs.items.positionIt(it == "Dijkstra").isNone()
  doAssert chars.items.position(proc(x: char): bool = x.ord > 'y'.ord) == some(4)

block test_nth:
  doAssert ints.items.nth(0) == some(-2)
  doAssert chars.items.nth(6) == none(char)
  doAssert strs.items.nth(1) == some("BAR")
  doAssert text.items.enumerate.filterIt(it[1] in {'x'..'z'}).nth(0) == some((26, 'y'))

static:
  discard (0..9).items.mapIt(it).foldIt(0, acc + it)
  discard (0..9).items.mapIt(it).sum()
