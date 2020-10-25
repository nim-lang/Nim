# bug #4462
import macros
import os

block:
  proc foo(t: typedesc) {.compileTime.} =
    assert sameType(getType(t), getType(int))

  static:
    foo(int)

# #4412
block:
  proc default[T](t: typedesc[T]): T {.inline.} = discard

  static:
    var x = default(type(0))

# #6379
import algorithm

static:
  var numArray = [1, 2, 3, 4, -1]
  numArray.sort(cmp)
  assert numArray == [-1, 1, 2, 3, 4]

  var str = "cba"
  str.sort(cmp)
  assert str == "abc"

# #6086
import math, sequtils, sugar

block:
  proc f: int =
    toSeq(10..<10_000).filter(
      a => a == ($a).map(
        d => (d.ord-'0'.ord).int^4
      ).sum
    ).sum

  var a = f()
  const b = f()

  assert a == b

block:
  proc f(): seq[char] =
    result = "hello".map(proc(x: char): char = x)

  var runTime = f()
  const compTime = f()
  assert runTime == compTime

# #6083
block:
  proc abc(): seq[int] =
    result = @[0]
    result.setLen(2)
    var tmp: int

    for i in 0 ..< 2:
      inc tmp
      result[i] = tmp

  const fact1000 = abc()
  assert fact1000 == @[1, 2]

# Tests for VM ops
block:
  static:
    # for joint test, the project path is different, so I disabled it:
    when false:
      assert "vm" in getProjectPath()

    let b = getEnv("UNSETENVVAR")
    assert b == ""
    assert existsEnv("UNSERENVVAR") == false
    putEnv("UNSETENVVAR", "VALUE")
    assert getEnv("UNSETENVVAR") == "VALUE"
    assert existsEnv("UNSETENVVAR") == true

    assert fileExists("MISSINGFILE") == false
    assert dirExists("MISSINGDIR") == false

# #7210
block:
  static:
    proc f(size: int): int =
      var some = newStringOfCap(size)
      result = size
    doAssert f(4) == 4

# #6689
block:
  static:
    proc foo(): int = 0
    var f: proc(): int
    doAssert f.isNil
    f = foo
    doAssert(not f.isNil)

block:
  static:
    var x: ref ref int
    new(x)
    doAssert(not x.isNil)

# #7871
static:
  type Obj = object
    field: int
  var s = newSeq[Obj](1)
  var o = Obj()
  s[0] = o
  o.field = 2
  doAssert s[0].field == 0

# #8125
static:
   let def_iter_var = ident("it")

# #8142
static:
  type Obj = object
    names: string

  proc pushName(o: var Obj) =
    var s = ""
    s.add("FOOBAR")
    o.names.add(s)

  var o = Obj()
  o.names = ""
  o.pushName()
  o.pushName()
  doAssert o.names == "FOOBARFOOBAR"

# #8154
import parseutils

static:
  type Obj = object
    i: int

  proc foo(): Obj =
    discard parseInt("1", result.i, 0)

  static:
    doAssert foo().i == 1

# #10333
block:
  const
    encoding: auto = [
      ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"],
      ["", "X", "XX", "XXX", "XL", "L", "LX", "LXX", "LXXX", "XC"],
      ["", "C", "CC", "CCC", "CD", "D", "DC", "DCC", "DCCC", "CM"],
      ["", "M", "MM", "MMM", "--", "-", "--", "---", "----", "--"],
    ]
  doAssert encoding.len == 4

# #10886

proc tor(): bool =
  result = true
  result = false or result

proc tand(): bool =
  result = false
  result = true and result

const
  ctor = tor()
  ctand = not tand()

static:
  doAssert ctor
  doAssert ctand

block: # bug #13081
  type Kind = enum
    k0, k1, k2, k3

  type Foo = object
    x0: float
    case kind: Kind
    of k0: discard
    of k1: x1: int
    of k2: x2: string
    of k3: x3: string

  const j1 = Foo(x0: 1.2, kind: k1, x1: 12)
  const j2 = Foo(x0: 1.3, kind: k2, x2: "abc")
  const j3 = Foo(x0: 1.3, kind: k3, x3: "abc2")
  static:
    doAssert $j1 == "(x0: 1.2, kind: k1, x1: 12)"
    doAssert $j2 == """(x0: 1.3, kind: k2, x2: "abc")"""
    doAssert $j3 == """(x0: 1.3, kind: k3, x3: "abc2")"""
  doAssert $j1 == "(x0: 1.2, kind: k1, x1: 12)"
  doAssert $j2 == """(x0: 1.3, kind: k2, x2: "abc")"""
  doAssert $j3 == """(x0: 1.3, kind: k3, x3: "abc2")"""

  doAssert j1.x1 == 12
  static:
    doAssert j1.x1 == 12

# bug #15363
import sequtils

block:
  func identity(a: bool): bool = a

  var a: seq[bool] = static:
      newSeq[bool](0).mapIt(it) # segfaults
  var b: seq[bool] = static:
      newSeq[bool](0).filterIt(it) # does not segfault
  var c: seq[bool] = static:
      newSeq[bool](0).map(identity) # does not segfault
  var d: seq[bool] = static:
      newSeq[bool](0).map(proc (a: bool): bool = false) # segfaults
  var e: seq[bool] = static:
      newSeq[bool](0).filter(identity) # does not segfault
  var f: seq[bool] = static:
      newSeq[bool](0).filter(proc (a: bool): bool = false) # segfaults

  doAssert a == @[]
  doAssert b == @[]
  doAssert c == @[]
  doAssert d == @[]
  doAssert e == @[]
  doAssert f == @[]

import tables

block: # bug #8007
  type
    CostKind = enum
      Fixed,
      Dynamic

    Cost = object
      case kind*: CostKind
      of Fixed:
        cost*: int
      of Dynamic:
        handler*: proc(value: int): int {.nimcall.}

  proc foo(value: int): int {.nimcall.} =
    sizeof(value)

  const a: array[2, Cost] =[
    Cost(kind: Fixed, cost: 999),
    Cost(kind: Dynamic, handler: foo)
  ]

  # OK with arrays & object variants
  doAssert $a == "[(kind: Fixed, cost: 999), (kind: Dynamic, handler: ...)]"

  const b: Table[int, Cost] = {
    0: Cost(kind: Fixed, cost: 999),
    1: Cost(kind: Dynamic, handler: foo)
  }.toTable

  # KO with Tables & object variants
  # echo b # {0: (kind: Fixed, cost: 0), 1: (kind: Dynamic, handler: ...)} # <----- wrong behaviour
  doAssert $b == "{0: (kind: Fixed, cost: 999), 1: (kind: Dynamic, handler: ...)}"

  const c: Table[int, int] = {
    0: 100,
    1: 999
  }.toTable

  # OK with Tables and primitive int
  doAssert $c == "{0: 100, 1: 999}"

  # For some reason the following gives
  #    Error: invalid type for const: Cost
  const d0 = Cost(kind: Fixed, cost: 999)

  # OK with seq & object variants
  const d = @[Cost(kind: Fixed, cost: 999), Cost(kind: Dynamic, handler: foo)]
  doAssert $d == "@[(kind: Fixed, cost: 999), (kind: Dynamic, handler: ...)]"
