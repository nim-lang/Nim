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
  static:
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
  # example that could be used in compiler code
  block: # simplest apporach: val = string
    enumMap:
      type TCallingConvention = enum
        ccDefault = ""   # proc has no explicit calling convention
        ccStdCall  = "stdcall" # procedure is stdcall

    template name(a: TCallingConvention): string = a.val
    doAssert $ccStdCall == "ccStdCall"
    doAssert ccStdCall.val == "stdcall"
    doAssert ccStdCall.name == "stdcall"

  block:
    # more future proof approach: val = tuple[name: string]
    # this allows adding fields without beaking client code
    enumMap:
      type TCallingConvention = enum
        ccDefault = (name: "", doc: "proc has no explicit calling convention")
        ccStdCall  = ("stdcall", "procedure is stdcall")

    template name(a: TCallingConvention): string = a.val.name
    doAssert $ccStdCall == "ccStdCall"
    doAssert ccStdCall.val.name == "stdcall"
    doAssert ccStdCall.name == "stdcall"

block:
  enumMap:
    type MyHoly2 = enum
      k1 = (1.3, 'x', @[10]) # any type is ok
      k2 = (1.0, 'y', @[])

  template fun() =
    doAssert k1.ord == 0
    doAssert k1.val == (1.3, 'x', @[10])
    doAssert k1.val == (1.3, 'x', @[10])
    doAssert $k1 == "k1"

  static: fun()
  fun()

  # checks that we can't mutate values
  doAssert not compiles(k1.val[0] = 5.2)

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
    of kHelp, kHelpAlt: (if false: echo help(); 2)

  doAssert "run".process == 1
  doAssert "h".process == 2
  doAssert "nonexistant".process == 0

when true:
  # example showing we can define an `OrderedEnum` type class for enums
  # with a strict ordering
  proc isOrderedEnum(a: typedesc[enum]): bool =
    mixin val
    when compiles(a.default.val):
      var ret = a.default.val
      var first = true
      for ai in a:
        if first: first = false
        elif ai.val <= ret: return false
        else: ret = ai.val
    return true

  enumMap:
    type MyHoly1 = enum
      k1 = 1
      k2 = 4
      k3 = 4
  enumMap:
    type MyHoly2 = enum
      g1 = 1
      g2 = 4
      g3 = 5
  static:
    doAssert not MyHoly1.isOrderedEnum
    doAssert MyHoly2.isOrderedEnum

  type OrderedEnum = concept a
    isOrderedEnum(a.type)
  proc fun2(a: OrderedEnum) = discard
  doAssert not compiles(fun2(k1))
  doAssert compiles(fun2(g1))
  doAssert MyHoly1 isnot OrderedEnum
  doAssert MyHoly2 is OrderedEnum

  when false:
    # pending https://github.com/nim-lang/Nim/pull/12048
    # we'll be allowed to use:
    proc fun(a: T) {.enableif: isOrderedEnum(T).} = discard
