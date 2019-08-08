import std/sugar

proc fun0(a: string, result: var string) {.outparam.} = result.add a

proc fun1(result: var string, b: int=2) {.outparam.} = result.add $b
proc fun2(a1: int, a2 = 1.0, result: var string, a3: int=10, a4 = "") {.outparam.} =
  result.add $(a1, a2, a3, a4)
proc fun3(b: int=2, result: var string) {.outparam.} = result.add $b

proc fun4(b: int=2, result: var float) {.outparam.} = result = float(b)
proc fun4(b: string, result: var string) {.outparam.} = result = b & b

proc fun4b(a: string, result: var int) {.outparam.} = result += a.len
proc fun4b(a: string, result: var float) {.outparam.} = result += a.len.float

proc fun5*(result: var string) {.outparam.} = result.add "asdf"
proc fun6*(a: var string, result: var string) {.outparam.} = result.add a
proc fun7*(a, b: string, result: var string, c, d: int) {.outparam.} = result.add $(a, b, c, d)
proc fun8*(a, b, result, c: var string, d, e = 13) {.outparam.} = result.add $(a, b, c, d, e)

template bar1() =
  proc fun9(result: var int) {.outparam.} = discard
template bar2() =
  proc fun9(result: int) {.outparam.} = discard
template bar3() =
  proc fun9(a: var int) {.outparam.} = discard

proc fun10[T](a: T, result: var string) {.outparam.} = result.add $a
proc fun11[T](a: T, result: var T) {.outparam.} = result = a

proc fun12(a: string, score: var string) {.outparamAs(score).} = score.add a

proc testAll*() =
  doAssert fun0(a="foo") == "foo"
  doAssert fun0(a="foo", result="bar") == "barfoo"

  doAssert fun1(b=13) == "13"
  doAssert fun2(11, 2.0, a3 = 30, a4="asdf") == """(11, 2.0, 30, "asdf")"""
  doAssert fun2(11, a3 = 30, a4="asdf") == """(11, 1.0, 30, "asdf")"""

  block:
    var s = ""
    fun3(b=5, s)
    doAssert s == "5"
  doAssert fun3() == "2"
  doAssert fun3(3) == "3"
  doAssert fun3(b=4) == "4"

  doAssert fun4(13) == 13.0
  doAssert fun4("bac") == "bacbac"

  doAssert fun4b("bac", result = 4) == 4+3
  doAssert fun4b("bacd", result = 5.1) == 5.1+4.0

  doAssert fun5() == "asdf"
  block:
    var a0 = "asdf2"
    doAssert fun6(a0) == "asdf2"
  doAssert fun7("a1", "a2", c=3, d=4) == """("a1", "a2", 3, 4)"""

  block:
    var a = "a1"
    var b = "a2"
    var c = "a3"
    var d = 12
    doAssert fun8(a, b, c=c, d=d) == """("a1", "a2", "a3", 12, 13)"""

  doAssert compiles(bar1())
  doAssert not compiles(bar2())
  doAssert not compiles(bar3())

  doAssert fun10(1.2) == "1.2"
  doAssert fun11(1.3) == 1.3

  doAssert fun12(a = "foo", score = "goo") == "goofoo"


  proc fun13(result: var string, b: int) {.outparam.} = result.add $b
  proc fun14(result: var string, b: int = 2) {.outparam.} = result.add $b

  doAssert fun13(b=13) == "13"
  doAssert fun13(result = "foo", b=14) == "foo14"
  doAssert fun13(b=14, result = "goo") == "goo14"

  doAssert fun14(b=13) == "13"
  doAssert fun14() == "2"
  doAssert fun14(result = "foo", b=14) == "foo14"
  doAssert fun14(b=14, result = "goo") == "goo14"

  doAssert fun14(result = "goo") == "goo2"
proc examples*() =
  ## some examples from https://github.com/nim-lang/RFCs/issues/62
  proc normalizePath2(path: var string) {.outparamAs(path).} = path = "foo:" & path # in osproc.nim
  doAssert "bar".normalizePath2 == "foo:bar"
  proc removeSuffix2(result: var string, suffix: string) {.outparam.} = result.add suffix
  doAssert removeSuffix2(suffix = "ba") == "ba"
  doAssert removeSuffix2("ga", suffix = "ba") == "gaba"

testAll()
examples()
