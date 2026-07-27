discard """
  output: '''done'''
"""
# Issue #13296: Error: not unused with a macro
# https://github.com/nim-lang/Nim/issues/13296

import macros
macro dType(body: untyped) =
  if body.kind == nnkCall:
    var typ = newNimNode(nnkStmtList)
    typ.add quote do:
      discard
  elif body.kind == nnkTypeSection:
    result = newStmtList(
      body
    )

dType:
  echo "hi"

echo "done"
