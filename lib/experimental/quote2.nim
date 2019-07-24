import macros

# template expectNimNode(arg: NimNode): NimNode = arg
# macro expectNimNode(arg: typed): NimNode =
#   error("expressions needs to be of type NimNode", arg)

proc expectNimNode[T](arg: T): NimNode = arg

proc newTreeWithLineinfo*(kind: NimNodeKind; lineinfo: LineInfo; children: varargs[NimNode]): NimNode {.compileTime.} =
  ## like ``macros.newTree``, just that the first argument is a node to take lineinfo from.
  # TODO lineinfo cannot be forwarded to new node.  I am forced to drop it here.
  result = newNimNode(kind, nil)
  result.lineinfoObj = lineinfo
  result.add(children)

# TODO restrict unquote to nimnode expressions (error message)

const forwardLineinfo = false


proc lookupSymbol(symbolTable, name: NimNode): NimNode =
  # Expects `symbolTable` to be a list of ExprEqExpr, to use it like a `Table`.
  for x in symbolTable:
    if eqIdent(x[0], name):
      return x[1]

proc newTreeExpr(stmtList, exprNode, symbolTable: NimNode): NimNode {.compileTime.} =
  # stmtList is a buffer to generate statements
  if exprNode.kind in nnkLiterals:
    result = newCall(bindSym"newLit", exprNode)
  elif exprNode.kind == nnkIdent:
    result = lookupSymbol(symbolTable, exprNode) or newCall(bindSym"ident", newLit(exprNode.strVal))
  #elif exprNode.kind in nnkCallKinds and exprNode.len == 2 and exprNode[0].eqIdent unquoteIdent:
  #  result = newCall(bindSym"expectNimNode", exprNode[1])
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
      result.add newTreeExpr(stmtList, child, symbolTable)

# macro quoteAst*(ast: untyped): untyped =
#   ## Substitute for ``quote do`` but with ``uq`` for unquoting instead of backticks.
#   result = newNimNode(nnkStmtListExpr)
#   result.add result.newTreeExpr(ast, ident"uq")

#   echo "quoteAst:"
#   echo result.repr

macro quoteAst*(args: varargs[untyped]): untyped =

  let symbolTable = newStmtList()

  for i in 0 ..< args.len-1:
    expectKind(args[i], {nnkIdent, nnkExprEqExpr})
    if args[i].kind == nnkExprEqExpr:
      symbolTable.add args[i]
    else:
      symbolTable.add nnkExprEqExpr.newTree(args[i], args[i])

  result = newStmtList()
  result.add newTreeExpr(result, args[^1], symbolTable)

  #echo "quoteAst:"
  #echo "input: ", args[^1].treeRepr
  #echo result.repr

proc foo(arg1: int, arg2: string): string =
  "xxx"

macro foobar(arg: untyped): untyped =
  # simple generation of source code:

  #echo "foobar: ", arg.lispRepr

  result = quoteAst:
    echo "Hello world!"

  echo result.treeRepr

  # inject subtrees from local scope, like `` in quote do:
  let world = newLit("world")
  result = quoteAst(world):
    echo "Hello ", world, "!"

  echo result.treeRepr

  # inject subtree from expression:
  result = quoteAst(world = newLit("world")):
    echo "Hello ", world, "!"

  echo result.treeRepr

  # custom name for unquote in case `uq` should collide with anything.
  let x = newLit(123)
  result = quoteAst(x, xyz = newLit("xyz"), arg):
    echo "abc ", x, " ", xyz, " ", arg

  result = quoteAst(foo = bindSym"foo"):
    echo foo(123, "abc")

  echo result.treeRepr

  # result = quoteAst:
  #   var tmp = 1
  #   for x in 0 ..< 100:
  #     tmp *= 3

  echo "result: ", result.lispRepr

let myVal = "Hallo Welt!"
foobar(myVal)

# example from #10326


proc skipNodes(arg: NimNode, kinds: set[NimNodeKind]): NimNode =
  result = arg
  while result.kind in kinds:
    result = result[0]

template id*(val: int) {.pragma.}
macro m1(): untyped =
   let x = newLit(10)
   let r1 = quote do:
     type T1 {.id(`x`).} = object

   let r2 = quoteAst(x):
     type T1 {.id(x).} = object

   echo "from #10326:"
   let n1 = r1.skipNodes({nnkStmtList, nnkTypeSection, nnkTypeDef})[1][0][1]
   let n2 = r2.skipNodes({nnkStmtList, nnkTypeSection, nnkTypeDef})[1][0][1]
   doAssert n1.lispRepr == n2.lispRepr

m1()

macro lineinfoTest(): untyped =
  # line info is preserved as if the content of ``quoteAst`` is written in a template
  result = quoteAst:
    assert(false)

#lineinfoTest()

# example from #7375

macro fails(b: static[bool]): untyped =
  echo b
  result = newStmtList()

macro works(b: static[int]): untyped =
  echo b
  result = newStmtList()

macro foo(): untyped =
  var b = newLit(false)
  result = newStmtList()

  ## Fails
  let tmp1 = quoteAst(b):
    fails(b)
  result.add tmp1

  ## Works
  let tmp2 = quoteAst(b = newLit(123)):
    works(b)
  result.add tmp2

  echo "foo 7375 "
  echo result.treeRepr

foo()


# example from #9745
# import macros

var
  typ {.compiletime.} = newLit("struct ABC")
  name {.compiletime.} = ident("ABC")

macro abc(): untyped =
  result = quoteAst(name,typ):
    type
      name {.importc: typ.} = object

abc()

# example from #7889

# test.nim

# from binder import bindme
# bindme()

# example from #8220

macro fooA(): untyped =
  result = quoteAst:
    let bar = "Hello, World"
    echo &"Let's interpolate {bar} in the string"

foo()


# example from #7589

macro fooB(x: untyped): untyped =
  result = quoteAst:
    echo uq(bindSym"==")(3,4) # echo ["false"]' has no type (or is ambiguous)
  echo result.treerepr

# example from #7726

import macros

macro fooC(): untyped =
  let a = @[1, 2, 3, 4, 5]
  result = quoteAst(len = newLit(a.len)):
    len

macro fooD(): untyped =
  let a = @[1, 2, 3, 4, 5]
  let len = a.len
  result = quoteAst(len = newLit(len)):
    len

macro fooE(): untyped =
  let a = @[1, 2, 3, 4, 5]
  let len = a.len
  result = quoteAst(x = newLit(a[2])):
    x

echo fooC() # Outputs 5
echo fooD() # Outputs 5
echo fooE() # Outputs 3


# example from #10430

import macros

macro commentTest(arg: untyped): untyped =
  let tmp = quoteAst:
    ## comment 1
    echo "abc"
    ## comment 2
    ## still comment 2

  doAssert tmp.treeRepr == arg.treeRepr

commentTest:
  ## comment 1
  echo "abc"
  ## comment 2
  ## still comment 2
