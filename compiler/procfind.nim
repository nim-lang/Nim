#
#
#           The Nim Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements the searching for procs and iterators.
# This is needed for proper handling of forward declarations.

import
  ast, astalgo, msgs, semdata, types, trees, strutils

proc equalGenericParams(procA, procB: PNode): bool =
  if sonsLen(procA) != sonsLen(procB): return false
  for i in countup(0, sonsLen(procA) - 1):
    if procA.sons[i].kind != nkSym:
      return false
    if procB.sons[i].kind != nkSym:
      return false
    let a = procA.sons[i].sym
    let b = procB.sons[i].sym
    if a.name.id != b.name.id or
        not sameTypeOrNil(a.typ, b.typ, {ExactTypeDescValues}): return
    if a.ast != nil and b.ast != nil:
      if not exprStructuralEquivalent(a.ast, b.ast): return
  result = true

proc searchForProcOld*(c: PContext, scope: PScope, fn: PSym): PSym =
  # Searchs for a forward declaration or a "twin" symbol of fn
  # in the symbol table. If the parameter lists are exactly
  # the same the sym in the symbol table is returned, else nil.
  var it: TIdentIter
  result = initIdentIter(it, scope.symbols, fn.name)
  if isGenericRoutine(fn):
    # we simply check the AST; this is imprecise but nearly the best what
    # can be done; this doesn't work either though as type constraints are
    # not kept in the AST ..
    while result != nil:
      if result.kind == fn.kind and isGenericRoutine(result):
        let genR = result.ast.sons[genericParamsPos]
        let genF = fn.ast.sons[genericParamsPos]
        if exprStructuralEquivalent(genR, genF) and
           exprStructuralEquivalent(result.ast.sons[paramsPos],
                                    fn.ast.sons[paramsPos]) and
           equalGenericParams(genR, genF):
            return
      result = nextIdentIter(it, scope.symbols)
  else:
    while result != nil:
      if result.kind == fn.kind and not isGenericRoutine(result):
        case equalParams(result.typ.n, fn.typ.n)
        of paramsEqual:
          return
        of paramsIncompatible:
          localError(c.config, fn.info, "overloaded '$1' leads to ambiguous calls" % fn.name.s)
          return
        of paramsNotEqual:
          discard
      result = nextIdentIter(it, scope.symbols)

proc searchForProcNew(c: PContext, scope: PScope, fn: PSym): PSym =
  const flags = {ExactGenericParams, ExactTypeDescValues,
                 ExactConstraints, IgnoreCC}
  var it: TIdentIter
  result = initIdentIter(it, scope.symbols, fn.name)
  while result != nil:
    if result.kind == fn.kind: #and sameType(result.typ, fn.typ, flags):
      case equalParams(result.typ.n, fn.typ.n)
      of paramsEqual:
        if (sfExported notin result.flags) and (sfExported in fn.flags):
          let message = ("public implementation '$1' has non-public " &
                         "forward declaration in $2") %
                        [getProcHeader(c.config, result), c.config$result.info]
          localError(c.config, fn.info, message)
        return
      of paramsIncompatible:
        localError(c.config, fn.info, "overloaded '$1' leads to ambiguous calls" % fn.name.s)
        return
      of paramsNotEqual:
        discard
    result = nextIdentIter(it, scope.symbols)

proc searchForProc*(c: PContext, scope: PScope, fn: PSym): PSym =
  result = searchForProcNew(c, scope, fn)
  when false:
    let old = searchForProcOld(c, scope, fn)
    if old != result:
      echo "Mismatch in searchForProc: ", fn.info
      debug fn.typ
      debug if result != nil: result.typ else: nil
      debug if old != nil: old.typ else: nil

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

  proc searchForBorrowProc*(c: PContext, startScope: PScope, fn: PSym): PSym =
    # Searchs for the fn in the symbol table. If the parameter lists are suitable
    # for borrowing the sym in the symbol table is returned, else nil.
    var it: TIdentIter
    for scope in walkScopes(startScope):
      result = initIdentIter(it, scope.symbols, fn.Name)
      while result != nil:
        # watchout! result must not be the same as fn!
        if (result.Kind == fn.kind) and (result.id != fn.id):
          if equalGenericParams(result.ast.sons[genericParamsPos],
                                fn.ast.sons[genericParamsPos]):
            if paramsFitBorrow(fn.typ.n, result.typ.n): return
        result = NextIdentIter(it, scope.symbols)
