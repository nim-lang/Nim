# test for https://github.com/nim-lang/RFCs/issues/341
import std/json
import std/jsonutils
import std/macros

macro fn1(a: untyped): string = newLit a.lispRepr

doAssert fn1(a.?b.c) == """(DotExpr (Infix (Ident ".?") (Ident "a") (Ident "b")) (Ident "c"))"""

template `.?`(a: JsonNode, b: untyped{ident}): JsonNode =
  a[astToStr(b)]

proc identity[T](a: T): T = a
proc timesTwo[T](a: T): T = a * 2

template main =
  let a = (a1: 1, a2: "abc", a3: (a4: 2.5))
  let j = a.toJson
  doAssert j.?a1.getInt == 1
  doAssert j.?a3.?a4.getFloat == 2.5
  doAssert j.?a3.?a4.getFloat.timesTwo == 5.0
  doAssert j.?a3.identity.?a4.getFloat.timesTwo == 5.0
  doAssert j.identity.?a3.identity.?a4.identity.getFloat.timesTwo == 5.0
  doAssert j.identity.?a3.?a4.identity.getFloat.timesTwo == 5.0

static: main()
main()
