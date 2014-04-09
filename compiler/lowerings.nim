#
#
#           The Nimrod Compiler
#        (c) Copyright 2014 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements common simple lowerings.

const
  genPrefix* = ":tmp"         # prefix for generated names

import ast, types, idents, magicsys

proc newTupleAccess*(tup: PNode, i: int): PNode =
  result = newNodeIT(nkBracketExpr, tup.info, tup.typ.skipTypes(
                     abstractInst).sons[i])
  addSon(result, copyTree(tup))
  var lit = newNodeIT(nkIntLit, tup.info, getSysType(tyInt))
  lit.intVal = i
  addSon(result, lit)

proc addVar*(father, v: PNode) = 
  var vpart = newNodeI(nkIdentDefs, v.info, 3)
  vpart.sons[0] = v
  vpart.sons[1] = ast.emptyNode
  vpart.sons[2] = ast.emptyNode
  addSon(father, vpart)

proc newAsgnStmt(le, ri: PNode): PNode =
  result = newNodeI(nkAsgn, le.info, 2)
  result.sons[0] = le
  result.sons[1] = ri

proc lowerTupleUnpacking*(n: PNode; owner: PSym): PNode =
  assert n.kind == nkVarTuple
  let value = n.lastSon
  result = newNodeI(nkStmtList, n.info)

  var temp = newSym(skTemp, getIdent(genPrefix), owner, value.info)
  temp.typ = skipTypes(value.typ, abstractInst)
  incl(temp.flags, sfFromGeneric)

  var v = newNodeI(nkVarSection, value.info)
  v.addVar(newSymNode(temp))
  result.add(v)
  
  result.add newAsgnStmt(newSymNode(temp), value)
  for i in 0 .. n.len-3:
    result.add newAsgnStmt(n.sons[i], newTupleAccess(value, i))
