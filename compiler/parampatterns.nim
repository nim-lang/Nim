#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the pattern matching features for term rewriting
## macro support.

import strutils, ast, astalgo, types, msgs, idents, renderer, wordrecg, trees

# we precompile the pattern here for efficiency into some internal
# stack based VM :-) Why? Because it's fun; I did no benchmarks to see if that
# actually improves performance.
type
  TAliasRequest* = enum # first byte of the bytecode determines alias checking
    aqNone = 1,         # no alias analysis requested
    aqShouldAlias,      # with some other param
    aqNoAlias           # request noalias
  TOpcode = enum
    ppEof = 1, # end of compiled pattern
    ppOr,      # we could short-cut the evaluation for 'and' and 'or',
    ppAnd,     # but currently we don't
    ppNot,
    ppSym,
    ppAtom,
    ppLit,
    ppIdent,
    ppCall,
    ppSymKind,
    ppNodeKind,
    ppLValue,
    ppLocal,
    ppSideEffect,
    ppNoSideEffect
  TPatternCode = string

const
  MaxStackSize* = 64 ## max required stack size by the VM

proc patternError(n: PNode) =
  localError(n.info, errIllFormedAstX, renderTree(n, {renderNoComments}))

proc add(code: var TPatternCode, op: TOpcode) {.inline.} =
  add(code, chr(ord(op)))

proc whichAlias*(p: PSym): TAliasRequest =
  if p.constraint != nil:
    result = TAliasRequest(p.constraint.strVal[0].ord)
  else:
    result = aqNone

proc compileConstraints(p: PNode, result: var TPatternCode) =
  case p.kind
  of nkCallKinds:
    if p.sons[0].kind != nkIdent:
      patternError(p.sons[0])
      return
    let op = p.sons[0].ident
    if p.len == 3:
      if op.s == "|" or op.id == ord(wOr):
        compileConstraints(p.sons[1], result)
        compileConstraints(p.sons[2], result)
        result.add(ppOr)
      elif op.s == "&" or op.id == ord(wAnd):
        compileConstraints(p.sons[1], result)
        compileConstraints(p.sons[2], result)
        result.add(ppAnd)
      else:
        patternError(p)
    elif p.len == 2 and (op.s == "~" or op.id == ord(wNot)):
      compileConstraints(p.sons[1], result)
      result.add(ppNot)
    else:
      patternError(p)
  of nkAccQuoted, nkPar:
    if p.len == 1:
      compileConstraints(p.sons[0], result)
    else:
      patternError(p)
  of nkIdent:
    let spec = p.ident.s.normalize
    case spec
    of "atom":  result.add(ppAtom)
    of "lit":   result.add(ppLit)
    of "sym":   result.add(ppSym)
    of "ident": result.add(ppIdent)
    of "call":  result.add(ppCall)
    of "alias": result[0] = chr(aqShouldAlias.ord)
    of "noalias": result[0] = chr(aqNoAlias.ord)
    of "lvalue": result.add(ppLValue)
    of "local": result.add(ppLocal)
    of "sideeffect": result.add(ppSideEffect)
    of "nosideeffect": result.add(ppNoSideEffect)
    else:
      # check all symkinds:
      internalAssert int(high(TSymKind)) < 255
      for i in low(TSymKind)..high(TSymKind):
        if cmpIgnoreStyle(($i).substr(2), spec) == 0:
          result.add(ppSymKind)
          result.add(chr(i.ord))
          return
      # check all nodekinds:
      internalAssert int(high(TNodeKind)) < 255
      for i in low(TNodeKind)..high(TNodeKind):
        if cmpIgnoreStyle($i, spec) == 0:
          result.add(ppNodeKind)
          result.add(chr(i.ord))
          return
      patternError(p)
  else:
    patternError(p)

proc semNodeKindConstraints*(p: PNode): PNode =
  ## does semantic checking for a node kind pattern and compiles it into an
  ## efficient internal format.
  assert p.kind == nkCurlyExpr
  result = newNodeI(nkStrLit, p.info)
  result.strVal = newStringOfCap(10)
  result.strVal.add(chr(aqNone.ord))
  if p.len >= 2:
    for i in 1.. <p.len:
      compileConstraints(p.sons[i], result.strVal)
    if result.strVal.len > MaxStackSize-1:
      internalError(p.info, "parameter pattern too complex")
  else:
    patternError(p)
  result.strVal.add(ppEof)

type
  TSideEffectAnalysis = enum
    seUnknown, seSideEffect, seNoSideEffect

proc checkForSideEffects(n: PNode): TSideEffectAnalysis =
  # XXX is 'raise' a side effect?
  case n.kind
  of nkCallKinds:
    # only calls can produce side effects:
    let op = n.sons[0]
    if op.kind == nkSym and isRoutine(op.sym):
      let s = op.sym
      if sfSideEffect in s.flags:
        return seSideEffect
      # assume no side effect:
      result = seNoSideEffect
    elif tfNoSideEffect in op.typ.flags:
      # indirect call without side effects:
      result = seNoSideEffect
    else:
      # indirect call: assume side effect:
      return seSideEffect
    # we need to check n[0] too: (FwithSideEffectButReturnsProcWithout)(args)
    for i in 0 .. <n.len:
      let ret = checkForSideEffects(n.sons[i])
      if ret == seSideEffect: return ret
      elif ret == seUnknown and result == seNoSideEffect:
        result = seUnknown
  of nkNone..nkNilLit:
    # an atom cannot produce a side effect:
    result = seNoSideEffect
  else:
    for i in 0 .. <n.len:
      let ret = checkForSideEffects(n.sons[i])
      if ret == seSideEffect: return ret
      elif ret == seUnknown and result == seNoSideEffect:
        result = seUnknown

type
  TAssignableResult* = enum
    arNone,                   # no l-value and no discriminant
    arLValue,                 # is an l-value
    arLocalLValue,            # is an l-value, but local var; must not escape
                              # its stack frame!
    arDiscriminant,           # is a discriminant
    arStrange                 # it is a strange beast like 'typedesc[var T]'

proc isAssignable*(owner: PSym, n: PNode): TAssignableResult =
  ## 'owner' can be nil!
  result = arNone
  case n.kind
  of nkSym:
    # don't list 'skLet' here:
    if n.sym.kind in {skVar, skResult, skTemp}:
      if owner != nil and owner.id == n.sym.owner.id and
          sfGlobal notin n.sym.flags:
        result = arLocalLValue
      else:
        result = arLValue
    elif n.sym.kind == skType:
      let t = n.sym.typ.skipTypes({tyTypeDesc})
      if t.kind == tyVar: result = arStrange
  of nkDotExpr:
    if skipTypes(n.sons[0].typ, abstractInst-{tyTypeDesc}).kind in
        {tyVar, tyPtr, tyRef}:
      result = arLValue
    else:
      result = isAssignable(owner, n.sons[0])
    if result != arNone and sfDiscriminant in n.sons[1].sym.flags:
      result = arDiscriminant
  of nkBracketExpr:
    if skipTypes(n.sons[0].typ, abstractInst-{tyTypeDesc}).kind in
        {tyVar, tyPtr, tyRef}:
      result = arLValue
    else:
      result = isAssignable(owner, n.sons[0])
  of nkHiddenStdConv, nkHiddenSubConv, nkConv:
    # Object and tuple conversions are still addressable, so we skip them
    # XXX why is 'tyOpenArray' allowed here?
    if skipTypes(n.typ, abstractPtrs-{tyTypeDesc}).kind in
        {tyOpenArray, tyTuple, tyObject}:
      result = isAssignable(owner, n.sons[1])
    elif compareTypes(n.typ, n.sons[1].typ, dcEqIgnoreDistinct):
      # types that are equal modulo distinction preserve l-value:
      result = isAssignable(owner, n.sons[1])
  of nkHiddenDeref, nkDerefExpr, nkHiddenAddr:
    result = arLValue
  of nkObjUpConv, nkObjDownConv, nkCheckedFieldExpr:
    result = isAssignable(owner, n.sons[0])
  of nkCallKinds:
    # builtin slice keeps lvalue-ness:
    if getMagic(n) == mSlice: result = isAssignable(owner, n.sons[1])
  else:
    discard

proc isLValue*(n: PNode): bool =
  isAssignable(nil, n) in {arLValue, arLocalLValue, arStrange}

proc matchNodeKinds*(p, n: PNode): bool =
  # matches the parameter constraint 'p' against the concrete AST 'n'.
  # Efficiency matters here.
  var stack {.noinit.}: array[0..MaxStackSize, bool]
  # empty patterns are true:
  stack[0] = true
  var sp = 1

  template push(x: bool) =
    stack[sp] = x
    inc sp

  let code = p.strVal
  var pc = 1
  while true:
    case TOpcode(code[pc])
    of ppEof: break
    of ppOr:
      stack[sp-2] = stack[sp-1] or stack[sp-2]
      dec sp
    of ppAnd:
      stack[sp-2] = stack[sp-1] and stack[sp-2]
      dec sp
    of ppNot: stack[sp-1] = not stack[sp-1]
    of ppSym: push n.kind == nkSym
    of ppAtom: push isAtom(n)
    of ppLit: push n.kind in {nkCharLit..nkNilLit}
    of ppIdent: push n.kind == nkIdent
    of ppCall: push n.kind in nkCallKinds
    of ppSymKind:
      let kind = TSymKind(code[pc+1])
      push n.kind == nkSym and n.sym.kind == kind
      inc pc
    of ppNodeKind:
      let kind = TNodeKind(code[pc+1])
      push n.kind == kind
      inc pc
    of ppLValue: push isAssignable(nil, n) in {arLValue, arLocalLValue}
    of ppLocal: push isAssignable(nil, n) == arLocalLValue
    of ppSideEffect: push checkForSideEffects(n) == seSideEffect
    of ppNoSideEffect: push checkForSideEffects(n) != seSideEffect
    inc pc
  result = stack[sp-1]

