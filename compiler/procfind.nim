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
  ast, astalgo, msgs, semdata, types, lookups

import std/strutils

proc searchForProcAux(c: PContext, scope: PScope, fn: PSym): PSym =
  const flags = {ExactGenericParams, ExactTypeDescValues,
                 ExactConstraints, IgnoreCC}
  var it: TIdentIter = default(TIdentIter)
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

proc searchForProc*(c: PContext, scope: PScope, fn: PSym): tuple[proto: PSym, comesFromShadowScope: bool] =
  var scope = scope
  result = (searchForProcAux(c, scope, fn), false)
  while result.proto == nil and scope.isShadowScope:
    scope = scope.parent
    result.proto = searchForProcAux(c, scope, fn)
    result.comesFromShadowScope = true
