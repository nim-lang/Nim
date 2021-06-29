# Dump the contents of a NimNode

import macros

block:
  template plus(a, b: untyped): untyped {.dirty} =
    a + b

  macro call(e: untyped): untyped =
    result = newCall("foo", newStrLitNode("bar"))

  macro dumpAST(n: untyped): string =
    var msg = ""
    msg.add "lispRepr:\n" & n.lispRepr & "\n"
    msg.add "treeRepr:\n" & n.treeRepr & "\n"

    var plusAst = getAst(plus(1, 2))
    msg.add "lispRepr:\n" & n.lispRepr & "\n"

    var callAst = getAst(call(4))
    msg.add "callAst.lispRepr:\n" & callAst.lispRepr & "\n"

    var e = parseExpr("foo(bar + baz)")
    msg.add "e.lispRepr:\n" & e.lispRepr & "\n"
    result = msg.newLit

  let a = dumpAST:
    proc add(x, y: int): int =
      return x + y
    const foo = 3

  doAssert a == """
lispRepr:
(StmtList (ProcDef (Ident "add") (Empty) (Empty) (FormalParams (Ident "int") (IdentDefs (Ident "x") (Ident "y") (Ident "int") (Empty))) (Empty) (Empty) (StmtList (ReturnStmt (Infix (Ident "+") (Ident "x") (Ident "y"))))) (ConstSection (ConstDef (Ident "foo") (Empty) (IntLit 3))))
treeRepr:
StmtList
  ProcDef
    Ident "add"
    Empty
    Empty
    FormalParams
      Ident "int"
      IdentDefs
        Ident "x"
        Ident "y"
        Ident "int"
        Empty
    Empty
    Empty
    StmtList
      ReturnStmt
        Infix
          Ident "+"
          Ident "x"
          Ident "y"
  ConstSection
    ConstDef
      Ident "foo"
      Empty
      IntLit 3
lispRepr:
(StmtList (ProcDef (Ident "add") (Empty) (Empty) (FormalParams (Ident "int") (IdentDefs (Ident "x") (Ident "y") (Ident "int") (Empty))) (Empty) (Empty) (StmtList (ReturnStmt (Infix (Ident "+") (Ident "x") (Ident "y"))))) (ConstSection (ConstDef (Ident "foo") (Empty) (IntLit 3))))
callAst.lispRepr:
(Call (Ident "foo") (StrLit "bar"))
e.lispRepr:
(Call (Ident "foo") (Infix (Ident "+") (Ident "bar") (Ident "baz")))
"""

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

block: # treeRepr
  macro treeRepr2(a: untyped): string = newLit a.treeRepr
  macro treeRepr3(a: typed): string = newLit a.treeRepr

  doAssert treeRepr2(1+1 == 2) == """
Infix
  Ident "=="
  Infix
    Ident "+"
    IntLit 1
    IntLit 1
  IntLit 2"""

  proc baz() = discard
  proc baz(a: int) = discard
  proc baz(a: float) = discard

  doAssert treeRepr3(baz()) == """
Call
  Sym "baz""""

  let a = treeRepr3(block:
    proc bar(a: auto) = baz())
  doAssert a == """
BlockStmt
  Empty
  ProcDef
    Sym "bar"
    Empty
    GenericParams
      Sym "a:type"
    FormalParams
      Empty
      IdentDefs
        Sym "a"
        Sym "auto"
        Empty
    Empty
    Bracket
      Empty
      Empty
    StmtList
      Call
        OpenSymChoice 3 "baz""""
