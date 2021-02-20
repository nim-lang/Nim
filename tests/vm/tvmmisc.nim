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
  doAssert numArray == [-1, 1, 2, 3, 4]

  var str = "cba"
  str.sort(cmp)
  doAssert str == "abc"

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

  doAssert a == b

block:
  proc f(): seq[char] =
    result = "hello".map(proc(x: char): char = x)

  var runTime = f()
  const compTime = f()
  doAssert runTime == compTime

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
  doAssert fact1000 == @[1, 2]

# Tests for VM ops
block:
  static:
    # for joint test, the project path is different, so I disabled it:
    when false:
      doAssert "vm" in getProjectPath()

    let b = getEnv("UNSETENVVAR")
    doAssert b == ""
    doAssert existsEnv("UNSERENVVAR") == false
    putEnv("UNSETENVVAR", "VALUE")
    doAssert getEnv("UNSETENVVAR") == "VALUE"
    doAssert existsEnv("UNSETENVVAR") == true

    doAssert fileExists("MISSINGFILE") == false
    doAssert dirExists("MISSINGDIR") == false

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

block: # bug #15595
  proc fn0()=echo 0
  proc fn1()=discard
  proc main=
    var local = 0
    proc fn2()=echo local
    var a0 = fn0
    var a1 = fn1
    var a2 = fn2
    var a3: proc()
    var a4: proc()
    doAssert a0 == fn0 # bugfix
    doAssert a1 == fn1 # ditto
    doAssert a2 == fn2 # ditto

    doAssert fn0 != fn1

    doAssert a2 != nil
    doAssert a3 == nil # bugfix

    doAssert a3 == a4 # bugfix
  static: main()
  main()

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

block: # bug #14340
  block:
    proc opl3EnvelopeCalcSin0() = discard
    type EnvelopeSinfunc = proc()
    # const EnvelopeCalcSin0 = opl3EnvelopeCalcSin0 # ok
    const EnvelopeCalcSin0: EnvelopeSinfunc = opl3EnvelopeCalcSin0 # was bug
    const envelopeSin = [EnvelopeCalcSin0]
    var a = 0
    envelopeSin[a]()

  block:
    type Mutator = proc() {.noSideEffect, gcsafe, locks: 0.}
    proc mutator0() = discard
    const mTable = [Mutator(mutator0)]
    var i=0
    mTable[i]()

block: # VM wrong register free causes errors in unrelated code
  block: # bug #15597
    #[
    Error: unhandled exception: 'sym' is not accessible using discriminant 'kind' of type 'TNode' [FieldDefect]
    in /Users/timothee/git_clone/nim/Nim_prs/compiler/vm.nim(1176) rawExecute
    in opcIndCall
    in let prc = if not isClosure: bb.sym else: bb[0].sym
    ]#
    proc bar2(head: string): string = "asdf"
    proc gook(u1: int) = discard

    type PathEntry = object
      kind: int
      path: string

    iterator globOpt(): int =
      var u1: int

      gook(u1)
      gook(u1)
      gook(u1)
      gook(u1)
      gook(u1)
      gook(u1)
      gook(u1)
      gook(u1)
      gook(u1)
      gook(u1)
      gook(u1)
      gook(u1)
      gook(u1)
      gook(u1)

      var entry = PathEntry()
      entry.path = bar2("")
      if false:
        echo "here2"

    proc processAux(a: float) = discard

    template bar(iter: untyped): untyped =
      var ret: float
      for x in iter: break
      ret

    proc main() =
      processAux(bar(globOpt()))
    static: main()

  block: # ditto
    # D20201024T133245
    type Deque = object
    proc initDeque2(initialSize: int = 4): Deque = Deque()
    proc len2(a: Deque): int = 2
    proc baz(dir: string): bool = true
    proc bar2(head: string): string = "asdf"
    proc bar3(path: var string) = path = path

    type PathEntry = object
      kind: int
      path: string

    proc initGlobOpt(dir: string, a1=false,a2=false,a3=false,a4=false): string = dir

    iterator globOpt(dir: string): int =
      var stack = initDeque2()
      doAssert baz("")
      let z = stack.len2
      if stack.len2 >= 0:
        var entry = PathEntry()
        let current = if true: stack.len2 else: stack.len2
        entry.path = bar2("")
        bar3(entry.path)
      if false:
        echo "here2" # comment here => you get same error as https://github.com/nim-lang/Nim/issues/15704

    proc processAux(a: float) = discard

    template bar(iter: untyped): untyped =
      var ret: float
      for x in iter: break
      ret
    proc main() =
      processAux(bar(globOpt(initGlobOpt("."))))
    static: main()

  block: # bug #15704
    #[
    Error: attempt to access a nil address kind: rkFloat
    ]#
    type Deque = object
    proc initDeque2(initialSize: int = 4): Deque = Deque()
    proc len2(a: Deque): int = 2

    proc baz(dir: string): bool = true
    proc bar2(head: string): string = "asdf"
    proc bar3(path: var string) = path = path

    type PathEntry = object
      kind: int
      path: string
      depth: int

    proc initGlobOpt(dir: string, a1=false,a2=false,a3=false,a4=false): string =
      dir

    iterator globOpt(dir: string): int =
      var stack = initDeque2()
      doAssert baz("")
      let z = stack.len2
      var a5: int
      if stack.len2 >= 0:
        var entry = PathEntry()
        if false:
          echo "here"
        let current = if true: stack.len2 else: stack.len2
        entry.depth = 1
        entry.path = bar2("")
        bar3(entry.path)
    proc processAux(a: float) = discard
    template bar(iter: untyped): untyped =
      var ret: float
      for x in iter:
        break
      ret
    const dir = "."
    proc main() =
      processAux(bar(globOpt(initGlobOpt(dir))))
    static: main()

block: # bug #8015
  block:
    type Foo = object
      case b: bool
      of false: v1: int
      of true: v2: int
    const t = [Foo(b: false, v1: 1), Foo(b: true, v2: 2)]
    doAssert $t == "[(b: false, v1: 1), (b: true, v2: 2)]"
    doAssert $t[0] == "(b: false, v1: 1)" # was failing

  block:
    type
      CostKind = enum
        Fixed,
        Dynamic

      Cost = object
        case kind*: CostKind
        of Fixed:
          cost*: int
        of Dynamic:
          handler*: proc(): int {.nimcall.}

    proc foo1(): int {.nimcall.} =
      100

    proc foo2(): int {.nimcall.} =
      200

    # Change to `let` and it doesn't crash
    const costTable = [
      0: Cost(kind: Fixed, cost: 999),
      1: Cost(kind: Dynamic, handler: foo1),
      2: Cost(kind: Dynamic, handler: foo2)
    ]

    doAssert $costTable[0] == "(kind: Fixed, cost: 999)"
    doAssert costTable[1].handler() == 100
    doAssert costTable[2].handler() == 200

    # Now trying to carry the table as an object field
    type
      Wrapper = object
        table: array[3, Cost]

    proc procNewWrapper(): Wrapper =
      result.table = costTable

    # Alternatively, change to `const` and it doesn't crash
    let viaProc = procNewWrapper()

    doAssert viaProc.table[1].handler != nil
    doAssert viaProc.table[2].handler != nil
    doAssert $viaProc.table[0] == "(kind: Fixed, cost: 999)"
    doAssert viaProc.table[1].handler() == 100
    doAssert viaProc.table[2].handler() == 200
