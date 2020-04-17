import std/enummaps
from sequtils import toSeq

template isDefault[T](a: T): bool = a == default(type(a))

when false:
  # the current design of macro pragmas makes the following hard or impossible
  # but the following syntax will be possible pending https://github.com/nim-lang/Nim/issues/13830
  type MyHoly {.enumMap.} = enum
    k1 = 1
    k2 = 4

block:
  enumMap:
    type MyHoly = enum
      k1 = 1
      k2 = 4 ## some comment
      k3 = 1 # repeated and out of order is ok

  doAssert k1.ord == 0
  doAssert k1.val == 1
  doAssert k2.ord == 1
  doAssert k2.val == 4
  doAssert k2 == MyHoly.k2
  for ai in MyHoly: discard
  doAssert toSeq(MyHoly) == @[k1, k2, k3]

  block: # https://github.com/nim-lang/Nim/issues/13980
    proc fun(e: MyHoly): int =
      case e
      of k1: 1
      of k2: 2
      of k3: 3
    doAssert k2.fun == 2

  doAssert MyHoly.default.val.type is int

  doAssert MyHoly.byVal(4) == k2
  doAssert MyHoly.byVal(1) == k1 # finds 1st occurrence
  doAssert MyHoly.vals == [1,4,1]

block:
  enumMap:
    type MyHoly2 = enum
      k1 = (1.3, 'x', @[10]) # any type is ok
      k2 = (1.0, 'y', @[])
  doAssert k1.ord == 0
  doAssert k1.val == (1.3, 'x', @[10])
  doAssert $k1 == "k1"

import menummaps

block:
  # test import
  doAssert Foo.f1 == f1
  doAssert f2.val == "foo2"

  # test lookup
  doAssert Foo.byVal("foo3") == f3
  doAssert Foo.byVal("nonexistant").isDefault
  doAssert Foo.byVal("nonexistant2").isDefault

block:
  # example: cmdline application; this minimizes boilerplate and eliminates
  # code duplication of cmd names, and allows help messages to access command
  # names + doc strings
  enumMap:
    type Cmd = enum
      kDefault = (name: "", doc: "")
      kRun = ("run", "perform a run")
      kJump = ("jump", "this will do a jump")
      kHelp = ("help", "print cmdline usage")
      kHelpAlt = ("h", "ditto")

  proc help(): string =
    ## no code duplication: the strings (and doc msgs) appear only once
    result = "cmdline usage:\n"
    for ai in Cmd:
      if ai == Cmd.default: continue
      result.add "  " & ai.val[0] & ": " & ai.val[1] & "\n"

  proc process(cmd: string): int =
    let key = Cmd.findByIt(it.val.name == cmd)
    case key
    of kDefault: 0
    of kRun: 1
    of kJump: 2
    of kHelp, kHelpAlt: (echo help(); 2)

  doAssert "run".process == 1
  doAssert "h".process == 2
  doAssert "nonexistant".process == 0
