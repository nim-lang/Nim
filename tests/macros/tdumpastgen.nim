discard """
msg: '''nnkStmtList.newTree(
  nnkVarSection.newTree(
    nnkIdentDefs.newTree(
      newIdentNode(!"x"),
      newEmptyNode(),
      nnkCall.newTree(
        nnkDotExpr.newTree(
          newIdentNode(!"foo"),
          newIdentNode(!"create")
        ),
        newLit(56)
      )
    )
  )
)'''
"""

# disabled; can't work as the output is done by the compiler

import macros

dumpAstGen:
  var x = foo.create(56)

