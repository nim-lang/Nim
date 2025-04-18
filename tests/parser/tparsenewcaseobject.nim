discard """
  nimout: '''
StmtList
  TypeSection
    TypeDef
      Ident "Node"
      Empty
      RefTy
        ObjectTy
          Empty
          Empty
          RecList
            RecCase
              IdentDefs
                Empty
                Empty
                Empty
              OfBranch
                Ident "AddOpr"
                Ident "SubOpr"
                Ident "MulOpr"
                Ident "DivOpr"
                RecList
                  IdentDefs
                    Ident "a"
                    Ident "b"
                    Ident "Node"
                    Empty
              OfBranch
                Ident "Value"
                RecList
                  NilLit
            IdentDefs
              Ident "info"
              Ident "LineInfo"
              Empty
            RecCase
              IdentDefs
                PragmaExpr
                  Empty
                  Pragma
                    ExprColonExpr
                      Ident "size"
                      IntLit 1
                Empty
                Empty
              OfBranch
                Ident "Foo"
                NilLit

type
  Node = ref object
    case
    of AddOpr, SubOpr, MulOpr, DivOpr:
      a, b: Node
    of Value:
      nil
    info: LineInfo
    case {.size: 1.}
    of Foo:
      nil
'''
"""

import std/macros

macro foo(x: untyped) =
  echo x.treeRepr
  echo x.repr

foo:
  type
    Node = ref object
      case
      of AddOpr, SubOpr, MulOpr, DivOpr:
        a, b: Node
      of Value:
        discard
      info: LineInfo
      case {.size: 1.}
      of Foo: discard
