discard """
nimout: '''
StmtList
  VarSection
    IdentDefs
      Ident "x"
      Empty
      Call
        DotExpr
          Ident "foo"
          Ident "create"
        IntLit 56'''
"""

# disabled; can't work as the output is done by the compiler

import macros

#emit("type\n  TFoo = object\n    bar: int")

#var f: TFoo
#f.bar = 5
#echo(f.bar)

dumpTree:
  var x = foo.create(56)

