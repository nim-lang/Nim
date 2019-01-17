import macros

proc newTreeExpr(stmtListExpr, exprNode, unquoteIdent: NimNode): NimNode {.compileTime.} =
  # stmtList is a buffer to generate statements
  if exprNode.kind in nnkLiterals:
    result = newCall(bindSym"newLit", exprNode)
  elif exprNode.kind == nnkIdent:
    result = newCall(bindSym"ident", newLit(exprNode.strVal))
  elif exprNode.kind in nnkCallKinds and exprNode.len == 2 and exprNode[0].eqIdent unquoteIdent:
    result = exprNode[1]
  elif exprNode.kind == nnkSym:
    error("for quoting the ast needs to be untyped", exprNode)
  elif exprNode.kind == nnkEmpty:
    # bug newTree(nnkEmpty) raises exception:
    result = newCall(bindSym"newEmptyNode")
  else:
    result = genSym(nskLet)
    stmtListExpr.add newLetStmt(result, newCall(bindSym"newNimNode", newLit(exprNode.kind))) #, exprNode )
    for child in exprNode:
      stmtListExpr.add newCall(bindSym"add", result, newTreeExpr(stmtListExpr, child, unquoteIdent))

macro quoteAst(ast: untyped): untyped =
  ## Substitute for ``quote do`` but with ``uq`` for unquoting instead of backticks.
  result = newNimNode(nnkStmtListExpr)
  result.add result.newTreeExpr(ast, ident"uq")

macro quoteAst(unquoteIdent, ast: untyped): untyped =
  unquoteIdent.expectKind nnkIdent
  result = newNimNode(nnkStmtListExpr)
  result.add result.newTreeExpr(ast, unquoteIdent)

macro foobar(arg: untyped): untyped =
  # simple generation of source code:
  result = quoteAst:
    echo "Hello world!"

  echo result.treeRepr

  # inject subtrees from local scope, like `` in quote do:
  let world = newLit("world")
  result = quoteAst:
    echo "Hello ", uq(world), "!"

  echo result.treeRepr

  # inject subtree from expression:
  result = quoteAst:
    echo "Hello ", uq(newLit("world")), "!"

  echo result.treeRepr

  # custom name for unquote in case `uq` should collide with anything.
  let x = newLit(123)
  result = quoteAst myUnquote:
    echo "abc ", myUnquote(x), " ", myUnquote(newLit("xyz")), " ", myUnquote(arg)

  echo result.treeRepr

let myVal = "Hallo Welt!"
foobar(myVal)

# example from #10326

template id*(val: int) {.pragma.}
macro m1(): untyped =
   let x = newLit(10)
   let r1 = quote do:
      type T1 {.id(`x`).} = object

   let r2 = quoteAst:
     type T1 {.id(uq(x)).} = object


   echo "from #10326:"
   echo r1[0][0].treeRepr
   echo r2[0][0].treeRepr

m1()

macro lineinfoTest(): untyped =
  # line info is preserved as if the content of ``quoteAst`` is written in a template
  result = quoteAst:
    assert(false)

lineinfoTest()
