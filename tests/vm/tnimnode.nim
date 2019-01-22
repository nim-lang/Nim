import macros

proc assertEq(arg0,arg1: string): void =
  if arg0 != arg1:
    raiseAssert("strings not equal:\n" & arg0 & "\n" & arg1)

# a simple assignment of stmtList to another variable
var node {.compileTime.}: NimNode
# an assignment of stmtList into an array
var nodeArray {.compileTime.}: array[1, NimNode]
# an assignment of stmtList into a seq
var nodeSeq {.compileTime.} = newSeq[NimNode](2)

proc checkNode(arg: NimNode; name: string): void {. compileTime .} =
  echo "checking ", name

  assertEq arg.lispRepr, """(StmtList (DiscardStmt (Empty)))"""

  node = arg
  nodeArray = [arg]
  nodeSeq[0] = arg
  var seqAppend = newSeq[NimNode](0)
  seqAppend.add([arg]) # at the time of this writing this works
  seqAppend.add(arg)   # bit this creates a copy
  arg.add newCall(ident"echo", newLit("Hello World"))

  assertEq arg.lispRepr,          """(StmtList (DiscardStmt (Empty)) (Call (Ident "echo") (StrLit "Hello World")))"""
  assertEq node.lispRepr,         """(StmtList (DiscardStmt (Empty)) (Call (Ident "echo") (StrLit "Hello World")))"""
  assertEq nodeArray[0].lispRepr, """(StmtList (DiscardStmt (Empty)) (Call (Ident "echo") (StrLit "Hello World")))"""
  assertEq nodeSeq[0].lispRepr,   """(StmtList (DiscardStmt (Empty)) (Call (Ident "echo") (StrLit "Hello World")))"""
  assertEq seqAppend[0].lispRepr, """(StmtList (DiscardStmt (Empty)) (Call (Ident "echo") (StrLit "Hello World")))"""
  assertEq seqAppend[1].lispRepr, """(StmtList (DiscardStmt (Empty)) (Call (Ident "echo") (StrLit "Hello World")))"""

  echo "OK"

# the root node that is used to generate the Ast
var stmtList {.compileTime.}: NimNode

static:
  stmtList = newStmtList(nnkDiscardStmt.newTree(newEmptyNode()))

  checkNode(stmtList, "direct construction")


macro foo(stmtList: untyped): untyped =
  checkNode(stmtList, "untyped macro argument")

foo:
  discard


static:
  stmtList = quote do:
    discard

  checkNode(newTree(nnkStmtList, stmtList), "create with quote")


static:
  echo "testing body from loop"
  var loop = quote do:
    for i in 0 ..< 10:
      discard

  let innerBody = loop[2]
  innerBody.add newCall(ident"echo", newLit("Hello World"))

  assertEq loop[2].lispRepr, innerBody.lispRepr

  echo "OK"


static:
  echo "testing creation of comment node"
  var docComment: NimNode = newNimNode(nnkCommentStmt)
  docComment.strVal = "This is a doc comment"

  assertEq repr(docComment), "## This is a doc comment"

  echo "OK"
