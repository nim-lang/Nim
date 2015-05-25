discard """
msg: '''StmtList
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

# disabled; can't work as the output is done by the compiler

import macros

#emit("type\N  TFoo = object\N    bar: int")

#var f: TFoo
#f.bar = 5
#echo(f.bar)

dumpTree:
  var x = foo.create(56)

