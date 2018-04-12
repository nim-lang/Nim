discard """
  output: '''(Field0: "string", Field1: "string")'''
"""

# 7528
import macros
import typetraits

macro bar*(n: untyped): typed =
  result = newNimNode(nnkStmtList, n)
  result.add(newCall("write", newIdentNode("stdout"), n))

proc foo0[T](): auto = return (T.name, T.name)
bar foo0[string]()
