discard """
  output: '''
3
4
'''
"""

# A macro that uses a node of its input twice must produce two trees, sem
# transforms them in place (macroutils: a body shared by a proc and a
# template). The old VM copied such nodes.

import std/macros

macro gen(body: untyped): untyped =
  result = newStmtList()
  result.add newProc(ident"tmpl", [ident"untyped", newIdentDefs(ident"x", ident"untyped")],
                     body, nnkTemplateDef)
  result.add newProc(ident"prc", [ident"int", newIdentDefs(ident"x", ident"int")], body)

gen:
  x + 1

echo prc(2)
echo tmpl(3)
