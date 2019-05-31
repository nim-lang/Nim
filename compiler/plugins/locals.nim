#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## The builtin 'system.locals' implemented as a plugin.

import ".." / [pluginsupport, ast, astalgo,
  magicsys, lookups, semdata, lowerings]

proc semLocals*(c: PContext, n: PNode): PNode =
  var counter = 0
  var tupleType = newTypeS(tyTuple, c)
  result = newNodeIT(nkPar, n.info, tupleType)
  tupleType.n = newNodeI(nkRecList, n.info)
  # for now we skip openarrays ...
  for scope in walkScopes(c.currentScope):
    if scope == c.topLevelScope: break
    for it in items(scope.symbols):
      # XXX parameters' owners are wrong for generics; this caused some pain
      # for closures too; we should finally fix it.
      #if it.owner != c.p.owner: return result
      if it.kind in skLocalVars and
          it.typ.skipTypes({tyGenericInst, tyVar}).kind notin
            {tyVarargs, tyOpenArray, tyTypeDesc, tyStatic, tyUntyped, tyTyped, tyEmpty}:

        var field = newSym(skField, it.name, getCurrOwner(c), n.info)
        field.typ = it.typ.skipTypes({tyVar})
        field.position = counter
        inc(counter)

        addSon(tupleType.n, newSymNode(field))
        addSonSkipIntLit(tupleType, field.typ)

        var a = newSymNode(it, result.info)
        if it.typ.skipTypes({tyGenericInst}).kind == tyVar: a = newDeref(a)
        result.add(a)
