discard """
nimout: '''nnkStmtList.newTree(
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
        newLit("bar")
      )
    )
  )
)'''
"""

# disabled; can't work as the output is done by the compiler

import macros

dumpAstGen:
  var x = baz.create(56)

  proc foo() =
    ## This is a docstring
    echo "bar"
