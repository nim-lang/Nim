#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements the searching for procs and iterators.
# This is needed for proper handling of forward declarations.

import 
  ast, astalgo, msgs, semdata, types, trees

proc equalGenericParams(procA, procB: PNode): bool = 
  var a, b: PSym
  result = procA == procB
  if result: return 
  if (procA == nil) or (procB == nil): return 
  if sonsLen(procA) != sonsLen(procB): return 
  for i in countup(0, sonsLen(procA) - 1): 
    if procA.sons[i].kind != nkSym: 
      InternalError(procA.info, "equalGenericParams")
      return
    if procB.sons[i].kind != nkSym: 
      InternalError(procB.info, "equalGenericParams")
      return
    a = procA.sons[i].sym
    b = procB.sons[i].sym
    if (a.name.id != b.name.id) or not sameTypeOrNil(a.typ, b.typ): return 
    if (a.ast != nil) and (b.ast != nil): 
      if not ExprStructuralEquivalent(a.ast, b.ast): return 
  result = true

proc SearchForProc*(c: PContext, fn: PSym, tos: int): PSym = 
  # Searchs for the fn in the symbol table. If the parameter lists are exactly
  # the same the sym in the symbol table is returned, else nil.
  var it: TIdentIter
  result = initIdentIter(it, c.tab.stack[tos], fn.Name)
  while result != nil: 
    if (result.Kind == fn.kind): 
      if equalGenericParams(result.ast.sons[genericParamsPos], 
                            fn.ast.sons[genericParamsPos]): 
        case equalParams(result.typ.n, fn.typ.n)
        of paramsEqual: 
          return 
        of paramsIncompatible: 
          LocalError(fn.info, errNotOverloadable, fn.name.s)
          return 
        of paramsNotEqual: 
          nil
    result = NextIdentIter(it, c.tab.stack[tos])

when false:
  proc paramsFitBorrow(child, parent: PNode): bool = 
    var length = sonsLen(child)
    result = false
    if length == sonsLen(parent): 
      for i in countup(1, length - 1): 
        var m = child.sons[i].sym
        var n = parent.sons[i].sym
        assert((m.kind == skParam) and (n.kind == skParam))
        if not compareTypes(m.typ, n.typ, dcEqOrDistinctOf): return 
      if not compareTypes(child.sons[0].typ, parent.sons[0].typ,
                          dcEqOrDistinctOf): return
      result = true

  proc SearchForBorrowProc*(c: PContext, fn: PSym, tos: int): PSym = 
    # Searchs for the fn in the symbol table. If the parameter lists are suitable
    # for borrowing the sym in the symbol table is returned, else nil.
    var it: TIdentIter
    for scope in countdown(tos, 0): 
      result = initIdentIter(it, c.tab.stack[scope], fn.Name)
      while result != nil: 
        # watchout! result must not be the same as fn!
        if (result.Kind == fn.kind) and (result.id != fn.id): 
          if equalGenericParams(result.ast.sons[genericParamsPos], 
                                fn.ast.sons[genericParamsPos]): 
            if paramsFitBorrow(fn.typ.n, result.typ.n): return 
        result = NextIdentIter(it, c.tab.stack[scope])
