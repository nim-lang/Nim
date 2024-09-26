discard """
  nimout: '''
ProcDef
  Sym "foo"
  Empty
  Empty
  FormalParams
    Empty
    IdentDefs
      Sym "x"
      Empty
      Call
        Sym "none"
        Sym "Natural"
  Empty
  Empty
  DiscardStmt
    Empty
ProcDef
  Sym "example"
  Empty
  Empty
  FormalParams
    Empty
    IdentDefs
      Sym "a"
      Empty
      Sym "thing"
  Empty
  Empty
  DiscardStmt
    TupleConstr
      Sym "a"
      Sym "thing"
'''
"""

import options, macros

macro typedTree(n: typed): untyped =
  result = n
  echo treeRepr n

# issue #19118
proc foo(x = none(Natural)) {.typedTree.} = discard

# issue #12942
var thing = 2
proc example(a = thing) {.typedTree.} =
  discard (a, thing)
