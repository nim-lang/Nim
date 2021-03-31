# Dump the contents of a NimNode

import macros

template plus(a, b: untyped): untyped {.dirty} =
  a + b

macro call(e: untyped): untyped =
  result = newCall("foo", newStrLitNode("bar"))

macro dumpAST(n: untyped): untyped =
  # dump AST as a side-effect and return the inner node
  let n = callsite()
  echo n.lispRepr
  echo n.treeRepr

  var plusAst = getAst(plus(1, 2))
  echo plusAst.lispRepr

  var callAst = getAst(call(4))
  echo callAst.lispRepr

  var e = parseExpr("foo(bar + baz)")
  echo e.lispRepr

  result = n[1]

dumpAST:
  proc add(x, y: int): int =
    return x + y

  proc sub(x, y: int): int = return x - y

macro fun() =
  let n = quote do:
    1+1 == 2
  doAssert n.repr == "1 + 1 == 2", n.repr
fun()

macro fun2(): untyped =
  let n = quote do:
    1 + 2 * 3 == 1 + 6
  doAssert n.repr == "1 + 2 * 3 == 1 + 6", n.repr
fun2()

macro fun3(): untyped =
  let n = quote do:
    int | float | array | seq | object | ptr | pointer | float32
  doAssert n.repr == "int | float | array | seq | object | ptr | pointer | float32", n.repr
fun3()

macro fun4() =
  let n = quote do:
    (a: 1)
  doAssert n.repr == "(a: 1)", n.repr
fun4()

# nkTupleConstr vs nkPar tests:
block: # lispRepr
  macro lispRepr2(a: untyped): string = newLit a.lispRepr

  doAssert lispRepr2(()) == """(TupleConstr)"""
  doAssert lispRepr2((a: 1)) == """(TupleConstr (ExprColonExpr (Ident "a") (IntLit 1)))"""
  doAssert lispRepr2((a: 1, b: 2)) == """(TupleConstr (ExprColonExpr (Ident "a") (IntLit 1)) (ExprColonExpr (Ident "b") (IntLit 2)))"""
  doAssert lispRepr2((1,)) == """(TupleConstr (IntLit 1))"""
  doAssert lispRepr2((1, 2)) == """(TupleConstr (IntLit 1) (IntLit 2))"""
  doAssert lispRepr2((1, 2, 3.0)) == """(TupleConstr (IntLit 1) (IntLit 2) (FloatLit 3.0))"""
  doAssert lispRepr2((1)) == """(Par (IntLit 1))"""
  doAssert lispRepr2((1+2)) == """(Par (Infix (Ident "+") (IntLit 1) (IntLit 2)))"""

block: # repr
  macro repr2(a: untyped): string = newLit a.repr

  doAssert repr2(()) == "()"
  doAssert repr2((a: 1)) == "(a: 1)"
  doAssert repr2((a: 1, b: 2)) == "(a: 1, b: 2)"
  doAssert repr2((1,)) == "(1,)"
  doAssert repr2((1, 2)) == "(1, 2)"
  doAssert repr2((1, 2, 3.0)) == "(1, 2, 3.0)"
  doAssert repr2((1)) == "(1)"
  doAssert repr2((1+2)) == "(1 + 2)"
