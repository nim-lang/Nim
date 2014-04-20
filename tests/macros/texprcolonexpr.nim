discard """
  msg: '''
Infix
  Ident !"=>"
  Call
    Ident !"name"
    Ident !"a"
    ExprColonExpr
      Ident !"b"
      Ident !"cint"
  NilLit nil
'''
"""
import macros

macro def(x: stmt): stmt {.immediate.} =
  echo treeRepr(x)

def name(a, b:cint) => nil
