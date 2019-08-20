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
  for i in 0 ..< sonsLen(procA):
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
                         "forward declaration at $2") %
                        [getProcHeader(c.config, result, getDeclarationPath = false), c.config$result.info]
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
