#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Plugin to transform an inline iterator into a data structure.

import ".." / [pluginsupport, ast, astalgo,
  magicsys, lookups, semdata,
  lambdalifting, rodread, msgs]

proc iterToProcImpl(c: PContext, n: PNode): PNode =
  result = newNodeI(nkStmtList, n.info)
  let iter = n[1]
  if iter.kind != nkSym or iter.sym.kind != skIterator:
    localError(iter.info, "first argument needs to be an iterator")
    return
  if n[2].typ.isNil:
    localError(n[2].info, "second argument needs to be a type")
    return
  if n[3].kind != nkIdent:
    localError(n[3].info, "third argument needs to be an identifier")
    return

  let t = n[2].typ.skipTypes({tyTypeDesc, tyGenericInst})
  if t.kind notin {tyRef, tyPtr} or t.lastSon.kind != tyObject:
    localError(n[2].info,
        "type must be a non-generic ref|ptr to object with state field")
    return
  let body = liftIterToProc(iter.sym, iter.sym.getBody, t)

  let prc = newSym(skProc, n[3].ident, iter.sym.owner, iter.sym.info)
  prc.typ = copyType(iter.sym.typ, prc, false)
  excl prc.typ.flags, tfCapturesEnv
  prc.typ.n.add newSymNode(getEnvParam(iter.sym))
  prc.typ.rawAddSon t
  let orig = iter.sym.ast
  prc.ast = newProcNode(nkProcDef, n.info,
                        name = newSymNode(prc),
                        params = orig[paramsPos],
                        pragmas = orig[pragmasPos],
                        body = body)
  prc.ast.add iter.sym.ast.sons[resultPos]
  addInterfaceDecl(c, prc)

registerPlugin("stdlib", "system", "iterToProc", iterToProcImpl)
