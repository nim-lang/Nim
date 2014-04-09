#
#
#           The Nimrod Compiler
#        (c) Copyright 2014 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Implements type sanity checking for ASTs resulting from macros. Lots of
## room for improvement here.

import ast, astalgo, msgs, types

proc ithField(n: PNode, field: int): PSym =
  result = nil
  case n.kind
  of nkRecList:
    for i in countup(0, sonsLen(n) - 1): 
      result = ithField(n.sons[i], field-i)
      if result != nil: return 
  of nkRecCase:
    if n.sons[0].kind != nkSym: internalError(n.info, "ithField")
    result = ithField(n.sons[0], field-1)
    if result != nil: return
    for i in countup(1, sonsLen(n) - 1):
      case n.sons[i].kind
      of nkOfBranch, nkElse:
        result = ithField(lastSon(n.sons[i]), field-1)
        if result != nil: return
      else: internalError(n.info, "ithField(record case branch)")
  of nkSym:
    if field == 0: result = n.sym
  else: discard

proc annotateType*(n: PNode, t: PType) =
  let x = t.skipTypes(abstractInst)
  # Note: x can be unequal to t and we need to be careful to use 't'
  # to not to skip tyGenericInst
  case n.kind
  of nkPar:
    if x.kind == tyObject:
      n.typ = t
      for i in 0 .. <n.len:
        let field = x.n.ithField(i)
        if field.isNil: globalError n.info, "invalid field at index " & $i
        else: annotateType(n.sons[i], field.typ)
    elif x.kind == tyTuple:
      n.typ = t
      for i in 0 .. <n.len:
        if i >= x.len: globalError n.info, "invalid field at index " & $i
        else: annotateType(n.sons[i], x.sons[i])
    elif x.kind == tyProc and x.callConv == ccClosure:
      n.typ = t
    else:
      globalError(n.info, "() must have an object or tuple type")
  of nkBracket:
    if x.kind in {tyArrayConstr, tyArray, tySequence, tyOpenarray}:
      n.typ = t
      for m in n: annotateType(m, x.elemType)
    else:
      globalError(n.info, "[] must have some form of array type")
  of nkCurly:
    if x.kind in {tySet}:
      n.typ = t
      for m in n: annotateType(m, x.elemType)
    else:
      globalError(n.info, "{} must have the set type")
  of nkFloatLit..nkFloat128Lit:
    if x.kind in {tyFloat..tyFloat128}:
      n.typ = t
    else:
      globalError(n.info, "float literal must have some float type")
  of nkCharLit..nkUInt64Lit:
    if x.kind in {tyInt..tyUInt64, tyBool, tyChar, tyEnum}:
      n.typ = t
    else:
      globalError(n.info, "integer literal must have some int type")
  of nkStrLit..nkTripleStrLit:
    if x.kind in {tyString, tyCString}:
      n.typ = t
    else:
      globalError(n.info, "string literal must be of some string type")    
  of nkNilLit:
    if x.kind in NilableTypes:
      n.typ = t
    else:
      globalError(n.info, "nil literal must be of some pointer type")
  else: discard
