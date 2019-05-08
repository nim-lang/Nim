#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Implements type sanity checking for ASTs resulting from macros. Lots of
## room for improvement here.

import ast, astalgo, msgs, types, options

proc ithField(n: PNode, field: var int): PSym =
  result = nil
  case n.kind
  of nkRecList:
    for i in 0 ..< sonsLen(n):
      result = ithField(n.sons[i], field)
      if result != nil: return
  of nkRecCase:
    if n.sons[0].kind != nkSym: return
    result = ithField(n.sons[0], field)
    if result != nil: return
    for i in 1 ..< sonsLen(n):
      case n.sons[i].kind
      of nkOfBranch, nkElse:
        result = ithField(lastSon(n.sons[i]), field)
        if result != nil: return
      else: discard
  of nkSym:
    if field == 0: result = n.sym
    else: dec(field)
  else: discard

proc annotateType*(n: PNode, t: PType; conf: ConfigRef) =
  let x = t.skipTypes(abstractInst+{tyRange})
  # Note: x can be unequal to t and we need to be careful to use 't'
  # to not to skip tyGenericInst
  case n.kind
  of nkObjConstr:
    let x = t.skipTypes(abstractPtrs)
    n.typ = t
    for i in 1 ..< n.len:
      var j = i-1
      let field = x.n.ithField(j)
      if field.isNil:
        globalError conf, n.info, "invalid field at index " & $i
      else:
        internalAssert(conf, n.sons[i].kind == nkExprColonExpr)
        annotateType(n.sons[i].sons[1], field.typ, conf)
  of nkPar, nkTupleConstr:
    if x.kind == tyTuple:
      n.typ = t
      for i in 0 ..< n.len:
        if i >= x.len: globalError conf, n.info, "invalid field at index " & $i
        else: annotateType(n.sons[i], x.sons[i], conf)
    elif x.kind == tyProc and x.callConv == ccClosure:
      n.typ = t
    else:
      globalError(conf, n.info, "() must have a tuple type")
  of nkBracket:
    if x.kind in {tyArray, tySequence, tyOpenArray}:
      n.typ = t
      for m in n: annotateType(m, x.elemType, conf)
    else:
      globalError(conf, n.info, "[] must have some form of array type")
  of nkCurly:
    if x.kind in {tySet}:
      n.typ = t
      for m in n: annotateType(m, x.elemType, conf)
    else:
      globalError(conf, n.info, "{} must have the set type")
  of nkFloatLit..nkFloat128Lit:
    if x.kind in {tyFloat..tyFloat128}:
      n.typ = t
    else:
      globalError(conf, n.info, "float literal must have some float type")
  of nkCharLit..nkUInt64Lit:
    if x.kind in {tyInt..tyUInt64, tyBool, tyChar, tyEnum}:
      n.typ = t
    else:
      globalError(conf, n.info, "integer literal must have some int type")
  of nkStrLit..nkTripleStrLit:
    if x.kind in {tyString, tyCString}:
      n.typ = t
    else:
      globalError(conf, n.info, "string literal must be of some string type")
  of nkNilLit:
    if x.kind in NilableTypes+{tyString, tySequence}:
      n.typ = t
    else:
      globalError(conf, n.info, "nil literal must be of some pointer type")
  else: discard
