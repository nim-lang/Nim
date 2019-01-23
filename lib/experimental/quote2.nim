import macros


#template expectNimNode(arg: NimNode): NimNode = arg

#macro expectNimNode(arg: typed): NimNode =
#  error("expressions needs to be of type NimNode", arg)

proc expectNimNode[T](arg: T): NimNode = arg

proc newTreeWithLineinfo*(kind: NimNodeKind; lineInfo: LineInfo; children: varargs[NimNode]): NimNode {.compileTime.} =
  ## like ``macros.newTree``, just that the first argument is a node to take lineinfo from.
  # TODO lineinfo cannot be forwarded to new node.  I am forced to drop it here.
  result = newNimNode(kind, nil)
  result.add(children)

# TODO restrict unquote to nimnode expressions (error message)

const forwardLineinfo = false

proc newTreeExpr(stmtList, exprNode, unquoteIdent: NimNode): NimNode {.compileTime.} =
  # stmtList is a buffer to generate statements
  if exprNode.kind in nnkLiterals:
    result = newCall(bindSym"newLit", exprNode)
  elif exprNode.kind == nnkIdent:
    result = newCall(bindSym"ident", newLit(exprNode.strVal))
  elif exprNode.kind in nnkCallKinds and exprNode.len == 2 and exprNode[0].eqIdent unquoteIdent:
    result = newCall(bindSym"expectNimNode", exprNode[1])
    echo result.lispRepr
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
      result.add newTreeExpr(stmtList, child, unquoteIdent)

macro quoteAst*(ast: untyped): untyped =
  ## Substitute for ``quote do`` but with ``uq`` for unquoting instead of backticks.
  result = newNimNode(nnkStmtListExpr)
  result.add result.newTreeExpr(ast, ident"uq")

macro quoteAst*(unquoteIdent, ast: untyped): untyped =
  unquoteIdent.expectKind nnkIdent
  result = newStmtList()
  result.add newTreeExpr(result, ast, unquoteIdent)

proc foo(arg1: int, arg2: string): string =
  "xxx"

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

  #result = quoteAst:
  #  echo uq(bindSym"foo")(123, "abc")

  result = newTree(NimNodeKind(115), newTree(NimNodeKind(26), ident("echo"), newTree(
    NimNodeKind(27), expectNimNode(bindSym"foo"), newLit(123), newLit("abc"))))

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

  ## Fails
  result = quote do:
    fails(`b`)

  ## Works
  # result = quote do:
  #   works(`b`)

foo()


# example from #9745  (does not work yet)
# import macros

# var
#   typ {.compiletime.} = newLit("struct ABC")
#   name {.compiletime.} = ident("ABC")

# macro abc(): untyped =
#   result = newNimNode(nnkStmtList)

#   let x = quoteAst:
#     type
#       uq(name) {.importc: uq(typ).} = object

#   echo result.repr

# abc()

# example from #7889

from streams import newStringStream, readData, writeData
import macros

macro bindme*(): untyped =
  quoteAst:
    var tst = "sometext"
    var ss = uq(bindSym"newStringStream")("anothertext")
    uq(bindSym"writeData")(ss, tst[0].addr, 2)
    discard uq(bindSym"readData")(ss, tst[0].addr, 2) # <= comment this out to make compilation successful

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
  result = quoteAst:
    uq(newLit(a.len))

macro fooD(): untyped =
  let a = @[1, 2, 3, 4, 5]
  let len = a.len
  result = quoteAst:
    uq(newLit(len))

macro fooE(): untyped =
  let a = @[1, 2, 3, 4, 5]
  let len = a.len
  result = quoteAst:
    uq(newLit(a[2]))

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
