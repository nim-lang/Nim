discard """
nimout: '''
newStmtList(
  nnkVarSection.newTree(
    nnkIdentDefs.newTree(
      ident"x",
      newEmptyNode(),
      newCall(
        newDotExpr(
          ident"baz",
          ident"create"
        ),
        newLit(56)
      )
    )
  ),
  nnkProcDef.newTree(
    ident"foo",
    newEmptyNode(),
    newEmptyNode(),
    nnkFormalParams.newTree(
      newEmptyNode()
    ),
    newEmptyNode(),
    newEmptyNode(),
    newStmtList(
      newCommentStmtNode(
        "This is a docstring"
      ),
      nnkCommand.newTree(
        ident"echo",
        newLit("Hello, World!")
      ),
      nnkCommand.newTree(
        ident"echo",
        newLit(
          "something \"quoted\""
        )
      )
    )
  ),
  newCall(
    ident"callNilLit",
    newNimNode(nnkNilLit)
  ),
  newAssignment(
    newDotExpr(
      ident"x",
      ident"y"
    ),
    nnkObjConstr.newTree(
      ident"MyType",
      newColonExpr(
        ident"u1",
        newLit(123'u64)
      ),
      newColonExpr(
        ident"u2",
        newLit(321'u32)
      )
    )
  )
)

var x = baz.create(56)
proc foo() =
  ## This is a docstring
  echo "Hello, World!"
  echo "something \"quoted\""

callNilLit(nil)
x.y = MyType(u1: 123'u64, u2: 321'u32)
'''
"""

import macros

dumpAstGen:
  var x = baz.create(56)
  proc foo() =
    ## This is a docstring
    echo "Hello, World!"
    echo "something \"quoted\""

  callNilLit(nil)
  x.y = MyType(u1: 123'u64, u2: 321'u32)

macro myQuoteAst(arg: untyped): untyped = newLit(arg)


static:
  let myAst = myQuoteAst:
    var x = baz.create(56)
    proc foo() =
      ## This is a docstring
      echo "Hello, World!"
      echo "something \"quoted\""

    callNilLit(nil)
    x.y = MyType(u1: 123'u64, u2: 321'u32)

  echo myAst.repr
