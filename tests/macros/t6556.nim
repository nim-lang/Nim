discard """
  output: '''
1
1
'''
"""

# bug #6556: injecting the same symbol into several blocks
import std/macros

macro injectSymbolInBlocks(varname: untyped, procBody: untyped): untyped =
  result = newStmtList()
  for i in [1, 2]:
    let body = newStmtList()
    body.add(newLetStmt(varname, newIntLitNode(1)))
    body.add(procBody)
    result.add(newBlockStmt(body))

proc macroVersion() =
  injectSymbolInBlocks(a):
    echo a

macroVersion()
