discard """
nimout: '''nnkStmtList.newTree(
  nnkVarSection.newTree(
    nnkIdentDefs.newTree(
      nnkExportDoc.newTree(
        newIdentNode("x"),
        newEmptyNode(),
        newEmptyNode()
      ),
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
    nnkExportDoc.newTree(
      newIdentNode("foo"),
      newEmptyNode(),
      newEmptyNode()
    ),
    newEmptyNode(),
    newEmptyNode(),
    nnkFormalParams.newTree(
      newEmptyNode()
    ),
    newEmptyNode(),
    newEmptyNode(),
    nnkStmtList.newTree(
      nnkCommentStmt.newTree(
        newLit("This is a docstring")
      ),
      nnkCommand.newTree(
        newIdentNode("echo"),
        newLit("bar")
      )
    )
  )
)'''
"""

import macros

dumpAstGen:
  var x = baz.create(56)

  proc foo() =
    ## This is a docstring
    echo "bar"
