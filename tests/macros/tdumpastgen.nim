discard """
nimout: '''
nnkStmtList.newTree(
  nnkVarSection.newTree(
    nnkIdentDefs.newTree(
      newIdentNode("x"),
      newEmptyNode(),
      nnkCall.newTree(
        nnkDotExpr.newTree(
          newIdentNode("baz"),
          newIdentNode("create")
        ),
        newLit(56)
      )
    )
  ),
  nnkProcDef.newTree(
    newIdentNode("foo"),
    newEmptyNode(),
    newEmptyNode(),
    nnkFormalParams.newTree(
      newEmptyNode()
    ),
    newEmptyNode(),
    newEmptyNode(),
    nnkStmtList.newTree(
      newCommentStmtNode("This is a docstring"),
      nnkCommand.newTree(
        newIdentNode("echo"),
        newLit("Hello, World!")
      ),
      nnkCommand.newTree(
        newIdentNode("echo"),
        newLit("something \"quoted\"")
      )
    )
  ),
  nnkCall.newTree(
    newIdentNode("callNilLit"),
    newNilLit()
  ),
  nnkAsgn.newTree(
    nnkDotExpr.newTree(
      newIdentNode("x"),
      newIdentNode("y")
    ),
    nnkObjConstr.newTree(
      newIdentNode("MyType"),
      nnkExprColonExpr.newTree(
        newIdentNode("u1"),
        nnkUInt64Lit.newTree(
        )
      ),
      nnkExprColonExpr.newTree(
        newIdentNode("u2"),
        nnkUInt32Lit.newTree(
        )
      )
    )
  )
)
'''
"""

import macros
import stdtest/unittest_light

dumpAstGen:
  var x = baz.create(56)
  proc foo() =
    ## This is a docstring
    echo "Hello, World!"
    echo "something \"quoted\""

  callNilLit(nil)
  x.y = MyType(u1: 123'u64, u2: 321'u32)

macro myQuoteAst(arg: untyped): untyped = astGen(arg)

static:
  let myAst = myQuoteAst:
    var x = baz.create(56)
    proc foo() =
      ## This is a docstring
      echo "Hello, World!"
      echo "something \"quoted\""

    callNilLit(nil)
    x.y = MyType(u1: 123'u64, u2: 321'u32)
  assertEquals myAst.repr, """

var x = baz.create(56)
proc foo() =
  ## This is a docstring
  echo "Hello, World!"
  echo "something \"quoted\""

callNilLit(nil)
x.y = MyType(u1: 123'u64, u2: 321'u32)"""
