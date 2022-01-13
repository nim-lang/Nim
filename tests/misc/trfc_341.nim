# test for https://github.com/nim-lang/RFCs/issues/341
import std/json
import std/jsonutils
import std/macros
import std/options

macro fn1(a: untyped): string = newLit a.lispRepr

doAssert fn1(a.?b.c) == """(DotExpr (Infix (Ident ".?") (Ident "a") (Ident "b")) (Ident "c"))"""
doAssert fn1(a.?b(c)) == """(Infix (Ident ".?()") (Ident "a") (Ident "b") (Ident "c"))"""

template `.?`(a: JsonNode, b: untyped{ident}): JsonNode =
  a[astToStr(b)]

template `.?()`(option: Option, call: untyped, args: varargs[untyped]): untyped =
  if option.isSome:
    some unpackVarargs(option.unsafeGet().call, args)
  else:
    none typeof(unpackVarargs(option.unsafeGet().call, args))

proc identity[T](a: T): T = a
proc timesTwo[T](a: T): T = a * 2
proc times[T](a: T, factors: varargs[T]): T =
  result = a
  for factor in factors:
    result = result * factor

template main =

  let a = (a1: 1, a2: "abc", a3: (a4: 2.5))
  let j = a.toJson
  doAssert j.?a1.getInt == 1
  doAssert j.?a3.?a4.getFloat == 2.5
  doAssert j.?a3.?a4.getFloat.timesTwo == 5.0
  doAssert j.?a3.identity.?a4.getFloat.timesTwo == 5.0
  doAssert j.identity.?a3.identity.?a4.identity.getFloat.timesTwo == 5.0
  doAssert j.identity.?a3.?a4.identity.getFloat.timesTwo == 5.0

  let b = some(21)
  let c = none(int)
  doAssert b.?identity() == some(21)
  doAssert b.?identity().?timesTwo() == some(42)
  doAssert b.?times(2) == some(42)
  doAssert b.?times(2, 3, 4) == some(21 * 2 * 3 * 4)
  doAssert c.?identity().?times(2, 3, 4) == none(int)

static: main()
main()
