discard """
  nimout: '''
Infix
  Ident "from"
  Ident "a"
  Ident "b"
Infix
  Ident "for"
  Infix
    Ident "for"
    Ident "a"
    Infix
      Ident "in"
      Ident "b"
      Ident "c"
  Infix
    Ident "in"
    Ident "d"
    Ident "e"
Infix
  Ident "for"
  Infix
    Ident "for"
    StmtListExpr
      ForStmt
        Ident "a"
        Ident "b"
        Ident "c"
    Infix
      Ident "in"
      Ident "d"
      Ident "e"
  Infix
    Ident "in"
    Ident "f"
    Ident "g"
'''
"""

import macros

dumpTree(a from b)
dumpTree(a for b in c for d in e)
dumpTree((for a in b: c) for d in e for f in g)

proc `from`(a, b: int): int = b - a
doAssert(3 from 4 == 1)

macro `for`(ex: untyped, rang: untyped{nkInfix}): untyped =
  let
    itName = rang[1]
    itExpr = rang[2]
  result = quote do:
    type TItem = typeof(when compiles(for _ in `itExpr`.items: discard): `itExpr`.items else: `itExpr`, typeOfIter)
    type TResult = typeof(block:
      var `itName`: TItem
      `ex`)
    var s: seq[TResult]
    for it in `itExpr`:
      let `itName` = it
      s.add(`ex`)
    s

doAssert((a + 1 for a in [1, 2, 3, 4, 5]) == @[2, 3, 4, 5, 6])
