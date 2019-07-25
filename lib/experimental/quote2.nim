import macros
export macros

template expectNimNode(arg: untyped): NimNode = arg

proc newTreeWithLineinfo*(kind: NimNodeKind; lineinfo: LineInfo; children: varargs[NimNode]): NimNode {.compileTime.} =
  ## like ``macros.newTree``, just that the first argument is a node to take lineinfo from.
  # TODO lineinfo cannot be forwarded to new node.  I am forced to drop it here.
  result = newNimNode(kind, nil)
  result.lineinfoObj = lineinfo
  result.add(children)

# TODO restrict unquote to nimnode expressions (error message)

const forwardLineinfo = true


proc lookupSymbol(symbolTable, name: NimNode): NimNode =
  # Expects `symbolTable` to be a list of ExprEqExpr, to use it like a `Table`.
  for x in symbolTable:
    if eqIdent(x[0], name):
      return x[1]

proc newTreeExpr(exprNode, symbolTable: NimNode): NimNode {.compileTime.} =
  # stmtList is a buffer to generate statements
  if exprNode.kind in nnkLiterals:
    result = newCall(bindSym"newLit", exprNode)
  elif exprNode.kind == nnkIdent:
    result = lookupSymbol(symbolTable, exprNode) or newCall(bindSym"ident", newLit(exprNode.strVal))
  elif exprNode.kind == nnkSym:
    error("for quoting the ast needs to be untyped", exprNode)
  elif exprNode.kind == nnkCommentStmt:
    result = newCall(bindSym"newCommentStmtNode", newLit(exprNode.strVal))
  elif exprNode.kind == nnkEmpty:
    # bug newTree(nnkEmpty) raises exception:
    result = newCall(bindSym"newEmptyNode")
  else:
    if forwardLineInfo:
      result = newCall(bindSym"newTreeWithLineinfo", newLit(exprNode.kind), newLit(exprNode.lineinfoObj))
    else:
      result = newCall(bindSym"newTree", newLit(exprNode.kind))
    for child in exprNode:
      result.add newTreeExpr(child, symbolTable)


# macro quoteAst*(ast: untyped): untyped =
#   ## Substitute for ``quote do`` but with ``uq`` for unquoting instead of backticks.
#   result = newNimNode(nnkStmtListExpr)
#   result.add result.newTreeExpr(ast, ident"uq")
#   echo "quoteAst:"
#   echo result.repr

let pushPragmaExpr {.compileTime.} =  nnkPragma.newTree(
  newIdentNode("push"),
  nnkExprColonExpr.newTree(
    nnkBracketExpr.newTree(
      newIdentNode("hint"),
      newIdentNode("ConvFromXtoItselfNotNeeded")
    ),
    newIdentNode("off")
  )
)
let popPragmaExpr {.compileTime.} = nnkPragma.newTree(
  newIdentNode("pop")
)

dumpAstGen:
  let x = 123

macro quoteAst*(args: varargs[untyped]): untyped =
  let symbolTable = newStmtList()

  for i in 0 ..< args.len-1:
    expectKind(args[i], {nnkIdent, nnkExprEqExpr})
    var a,b: NimNode
    if args[i].kind == nnkExprEqExpr:
      a = args[i][0]
      b = args[i][1]
    else:
      a = args[i]
      b = args[i]

    b = newCall(bindSym"expectNimnode", b)
    if a.kind == nnkAccQuoted:
      a = a[0]

    symbolTable.add nnkExprEqExpr.newTree(a, b)


  result = newTreeExpr(args[^1], symbolTable)

  # echo result.repr
