discard """
  nimout: '''
StmtList
  ReturnStmt
    StmtListExpr
      Call
        DotExpr
          Ident "x"
          Ident "add"
        StrLit "123"
      Call
        DotExpr
          Ident "x"
          Ident "add"
        StrLit "123"
      Ident "x"
'''
"""

import std/macros

dumpTree:
  return (x.add("123"); x.add("123"); x)
