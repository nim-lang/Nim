discard """
output: '''StmtList
  VarSection
    IdentDefs
      Ident !"x"
      nil
      Call
        DotExpr
          Ident !"foo"
          Ident !"create"
        IntLit 56'''
"""

import macros

#emit("type\n  TFoo = object\n    bar: int")

#var f: TFoo
#f.bar = 5
#echo(f.bar)

dumpTree:
  var x = foo.create(56)

