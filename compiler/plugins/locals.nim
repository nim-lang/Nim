#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## The builtin 'system.locals' implemented as a plugin.

import ".." / [ast, astalgo,
  magicsys, lookups, semdata, lowerings]

proc semLocals*(c: PContext, n: PNode): PNode =
  var counter = 0
  var tupleType = newTypeS(tyTuple, c)
  result = newNodeIT(nkTupleConstr, n.info, tupleType)
  tupleType.n = newNodeI(nkRecList, n.info)
  let owner = getCurrOwner(c)
  # for now we skip openarrays ...
  for scope in localScopesFrom(c, c.currentScope):
    for it in items(scope.symbols):
      if it.kind in skLocalVars and
          it.typ.skipTypes({tyGenericInst, tyVar}).kind notin
            {tyVarargs, tyOpenArray, tyTypeDesc, tyStatic, tyUntyped, tyTyped, tyEmpty}:

        if it.owner == owner:
          var field = newSym(skField, it.name, nextSymId c.idgen, owner, n.info)
          field.typ = it.typ.skipTypes({tyVar})
          field.position = counter
          inc(counter)

          tupleType.n.add newSymNode(field)
          addSonSkipIntLit(tupleType, field.typ, c.idgen)

          var a = newSymNode(it, result.info)
          if it.typ.skipTypes({tyGenericInst}).kind == tyVar: a = newDeref(a)
          result.add(a)
