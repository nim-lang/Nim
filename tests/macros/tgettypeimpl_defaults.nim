discard """
nimout: '''
ObjectTy
  Empty
  Empty
  RecList
    IdentDefs
      Sym "noDefault"
      Sym "int"
      Empty
    IdentDefs
      Sym "withDefault"
      Sym "string"
      StrLit "Hello World"
ProcTy
  FormalParams
    Sym "bool"
    IdentDefs
      Sym "foo"
      Sym "string"
      StrLit "Proc default"
  Empty
'''
"""

import std/macros

type
  FooBar = object
    noDefault: int
    withDefault = "Hello World"

  SomeProc = proc (foo = "Proc default"): bool

macro dumpBodies() =
  echo bindSym("FooBar").getTypeImpl().treeRepr
  echo bindSym("SomeProc").getTypeImpl().treeRepr

dumpBodies()
