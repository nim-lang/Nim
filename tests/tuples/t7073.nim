# bug #7073

import std/macros
import stdtest/testutils

macro deb1(a: tuple): string = newLit a.repr
macro deb2(a: tuple): string = newLit a.lispRepr
proc fn(a: int): auto = a*10

const a1* = (field1: fn(1))
const a2* = (field2: 2*10)
let a3* = (field3: fn(3))

assertAll:
  deb1(a1) == "(field1: 10)"
  deb1(a2) == "(field2: 20)"
  deb1(a3) == "a3"

  $a1.type == "tuple[field1: int]"
  $a2.type == "tuple[field2: int]"
  $a3.type == "tuple[field3: int]"

  deb2(a1) == """(TupleConstr (ExprColonExpr (Sym "field1") (IntLit 10)))"""
  deb2(a2) == """(TupleConstr (ExprColonExpr (Sym "field2") (IntLit 20)))"""
  deb2(a3) == """(Sym "a3")"""
