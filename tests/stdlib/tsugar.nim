import std/sugar

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

import algorithm

var a = @[1, 2, 3, 4, 5, 6, 7, 8, 9]
doAssert dup(a, sort(_)) == sorted(a)
doAssert a.dup(sort) == sorted(a)
#Chaining:
var aCopy = a
aCopy.insert(10)
doAssert a.dup(insert(10)).dup(sort()) == sorted(aCopy)

import random

const b = @[0, 1, 2]
let c = b.dup shuffle()
doAssert c[0] == 1
doAssert c[1] == 0

#test collect
import sets, tables

let data = @["bird", "word"] # if this gets stuck in your head, its not my fault
assert collect(newSeq, for (i, d) in data.pairs: (if i mod 2 == 0: d)) == @["bird"]
assert collect(initTable(2), for (i, d) in data.pairs: {i: d}) == {0: "bird",
      1: "word"}.toTable
assert initHashSet.collect(for d in data.items: {d}) == data.toHashSet

let x = collect(newSeqOfCap(4)):
    for (i, d) in data.pairs:
      if i mod 2 == 0: d
assert x == @["bird"]

# bug #12874

let bug1 = collect(
    newSeq,
    for (i, d) in data.pairs:(
      block:
        if i mod 2 == 0:
          d
        else:
          d & d
      )
)
assert bug1 == @["bird", "wordword"]

import strutils
let y = collect(newSeq):
  for (i, d) in data.pairs:
    try: parseInt(d) except: 0
assert y == @[0, 0]

let z = collect(newSeq):
  for (i, d) in data.pairs:
    case d
    of "bird": "word"
    else: d
assert z == @["word", "word"]

proc tforum =
  let ans = collect(newSeq):
    for y in 0..10:
      if y mod 5 == 2:
        for x in 0..y:
          x

tforum()

block:
  let x = collect:
    for d in data.items:
      when d is int: "word"
      else: d
  assert x == @["bird", "word"]
assert collect(for (i, d) in pairs(data): (i, d)) == @[(0, "bird"), (1, "word")]
assert collect(for d in data.items: (try: parseInt(d) except: 0)) == @[0, 0]
assert collect(for (i, d) in pairs(data): {i: d}) == {1: "word",
    0: "bird"}.toTable
assert collect(for d in data.items: {d}) == data.toHashSet
