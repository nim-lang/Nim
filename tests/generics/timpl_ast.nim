discard """
  action: compile
"""

import std/macros
import std/assertions

block: # issue #16639
  type Foo[T] = object
    when true:
      x: float

  type Bar = object
    when true:
      x: float

  macro test() =
    let a = getImpl(bindSym"Foo")[^1]
    let b = getImpl(bindSym"Bar")[^1]
    doAssert treeRepr(a) == treeRepr(b)

  test()

import strutils

block: # issues #9899, ##14708
  macro implRepr(a: typed): string =
    result = newLit(repr(a.getImpl))

  type
    Option[T] = object
      when false: discard # issue #14708
      when false: x: int
      when T is (ref | ptr):
        val: T
      else:
        val: T
        has: bool

  static: # check information is retained
    let r = implRepr(Option)
    doAssert "when T is" in r
    doAssert r.count("val: T") == 2
    doAssert "has: bool" in r

  block: # try to compile the output
    macro parse(s: static string) =
      result = parseStmt(s)
    parse("type " & implRepr(Option))
