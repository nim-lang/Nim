discard """
  output: '''done'''
"""
# Issue #10902: cannot instantiate T when generating AST from macro
# https://github.com/nim-lang/Nim/issues/10902

import macros

type
  Base[T] = ref object

macro genCloneProc(typeWithGenArg: untyped): untyped =
  result = newProc(
    ident "clone", [
      typeWithGenArg,
      newIdentDefs(
        ident "self",
        typeWithGenArg,
      )
    ],
    newStmtList(
      newNimNode(nnkDiscardStmt).add(newEmptyNode())
    )
  )
  let genericParamIdent = typeWithGenArg[1]
  result[2] = newNimNode(nnkGenericParams)
  result[2].add(newIdentDefs(genericParamIdent, newEmptyNode()))

genCloneProc(Base[T])

echo "done"
