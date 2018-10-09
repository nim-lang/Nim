import macros

static:
  let nodeA = newCommentStmtNode("this is a comment")
  doAssert nodeA.repr == "## this is a comment"
  doAssert nodeA.strVal == "this is a comment"
  doAssert $nodeA == "this is a comment"

  let nodeB = newCommentStmtNode("this is a comment")
  doAssert nodeA == nodeB
  nodeB.strVal = "this is a different comment"
  doAssert nodeA != nodeB

macro test(a: typed, b: typed): untyped =
  newLit(a == b)

doAssert test(1, 1) == true
doAssert test(1, 2) == false

type
  Obj = object of RootObj
  Other = object of RootObj

doAssert test(Obj, Obj) == true
doAssert test(Obj, Other) == false

var a, b: int

doAssert test(a, a) == true
doAssert test(a, b) == false

macro test2: untyped =
  newLit(bindSym"Obj" == bindSym"Obj")

macro test3: untyped =
  newLit(bindSym"Obj" == bindSym"Other")

doAssert test2() == true
doAssert test3() == false
