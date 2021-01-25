discard """
  output: '''
x + y = 30
'''
"""

import std/sugar

# `=>`

block:
  let f = () => 42
  doAssert f() == 42

  let g = (x: int) => x + 1
  doAssert g(42) == 43

  let h = (x, y: int) => x + y
  doAssert h(1, 2) == 3

block:
  proc call1(f: () -> int): int = f()
  doAssert call1(() => 12) == 12

  proc call2(f: int -> int): int = f(42)
  doAssert call2(x => x) == 42
  doAssert call2((x) => x) == 42
  doAssert call2((x: int) => x) == 42

  proc call3(f: (int, int) -> int): int = f(1, 2)
  doAssert call3((x, y) => x + y) == 3
  doAssert call3((x, y: int) => x + y) == 3
  doAssert call3((x: int, y: int) => x + y) == 3

# `->`

block:
  doAssert $(() -> int) == "proc (): int{.closure.}"
  doAssert $(float -> int) == "proc (i0: float): int{.closure.}"
  doAssert $((float) -> int) == "proc (i0: float): int{.closure.}"
  doAssert $((float, bool) -> int) == "proc (i0: float, i1: bool): int{.closure.}"

# dump

block:
  let
    x = 10
    y = 20
  dump(x + y) # x + y = 30

# capture

block:
  var closure1: () -> int
  for i in 0 .. 10:
    if i == 5:
      capture i:
        closure1 = () => i
  doAssert closure1() == 5

  var closure2: () -> (int, int)
  for i in 0 .. 10:
    for j in 0 .. 10:
      if i == 5 and j == 3:
        capture i, j:
          closure2 = () => (i, j)
  doAssert closure2() == (5, 3)

# dup

block dup_with_field:
  type
    Foo = object
      col, pos: int
      name: string

  proc inc_col(foo: var Foo) = inc(foo.col)
  proc inc_pos(foo: var Foo) = inc(foo.pos)
  proc name_append(foo: var Foo, s: string) = foo.name &= s

  let a = Foo(col: 1, pos: 2, name: "foo")
  block:
    let b = a.dup(inc_col, inc_pos):
      _.pos = 3
      name_append("bar")
      inc_pos

    doAssert(b == Foo(col: 2, pos: 4, name: "foobar"))

  block:
    let b = a.dup(inc_col, pos = 3, name = "bar"):
      name_append("bar")
      inc_pos

    doAssert(b == Foo(col: 2, pos: 4, name: "barbar"))

import std/algorithm

block:
  var a = @[1, 2, 3, 4, 5, 6, 7, 8, 9]
  doAssert dup(a, sort(_)) == sorted(a)
  doAssert a.dup(sort) == sorted(a)
  # Chaining:
  var aCopy = a
  aCopy.insert(10)
  doAssert a.dup(insert(10)).dup(sort()) == sorted(aCopy)

import std/random

block:
  const b = @[0, 1, 2]
  discard b.dup shuffle()
  doAssert b[0] == 0
  doAssert b[1] == 1

# collect

import std/[sets, tables]

let data = @["bird", "word"] # if this gets stuck in your head, its not my fault

doAssert collect(newSeq, for (i, d) in data.pairs: (if i mod 2 == 0: d)) == @["bird"]
doAssert collect(initTable(2), for (i, d) in data.pairs: {i: d}) == {0: "bird",
      1: "word"}.toTable
doAssert initHashSet.collect(for d in data.items: {d}) == data.toHashSet

block:
  let x = collect(newSeqOfCap(4)):
      for (i, d) in data.pairs:
        if i mod 2 == 0: d
  doAssert x == @["bird"]

block: # bug #12874
  let bug = collect(
      newSeq,
      for (i, d) in data.pairs:(
        block:
          if i mod 2 == 0:
            d
          else:
            d & d
        )
  )
  doAssert bug == @["bird", "wordword"]

import std/strutils

block:
  let y = collect(newSeq):
    for (i, d) in data.pairs:
      try: parseInt(d) except: 0
  doAssert y == @[0, 0]

block:
  let z = collect(newSeq):
    for (i, d) in data.pairs:
      case d
      of "bird": "word"
      else: d
  doAssert z == @["word", "word"]

block:
  proc tforum(): seq[int] =
    collect(newSeq):
      for y in 0..10:
        if y mod 5 == 2:
          for x in 0..y:
            x
  doAssert tforum() == @[0, 1, 2, 0, 1, 2, 3, 4, 5, 6, 7]

block:
  let x = collect:
    for d in data.items:
      when d is int: "word"
      else: d
  doAssert x == @["bird", "word"]

block:
  doAssert collect(for (i, d) in pairs(data): (i, d)) == @[(0, "bird"), (1, "word")]
  doAssert collect(for d in data.items: (try: parseInt(d) except: 0)) == @[0, 0]
  doAssert collect(for (i, d) in pairs(data): {i: d}) == {1: "word",
      0: "bird"}.toTable
  doAssert collect(for d in data.items: {d}) == data.toHashSet

block: # bug #14332
  template foo =
    discard collect(newSeq, for i in 1..3: i)
  foo()