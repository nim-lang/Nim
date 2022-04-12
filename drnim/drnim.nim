#
#
#            Doctor Nim
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

#[

- introduce Phi nodes to complete the SSA representation
- the analysis has to take 'break', 'continue' and 'raises' into account
- We need to map arrays to Z3 and test for something like 'forall(i, (i in 3..4) -> (a[i] > 3))'
- We need teach DrNim what 'inc', 'dec' and 'swap' mean, for example
  'x in n..m; inc x' implies 'x in n+1..m+1'

]#

import std / [
  parseopt, strutils, os, tables, times, intsets, hashes
]

import ".." / compiler / [
  ast, astalgo, types, renderer,
  commands, options, msgs,
  platform, trees, wordrecg, guards,
  idents, lineinfos, cmdlinehelper, modulegraphs, condsyms,
  pathutils, passes, passaux, sem, modules
]

import z3 / z3_api

when not defined(windows):
  # on UNIX we use static linking because UNIX's lib*.so system is broken
  # beyond repair and the neckbeards don't understand software development.
  {.passL: "dist/z3/build/libz3.a".}

const
  HelpMessage = "DrNim Version $1 [$2: $3]\n" &
      "Compiled at $4\n" &
      "Copyright (c) 2006-" & copyrightYear & " by Andreas Rumpf\n"

const
  Usage = """
drnim [options] [projectfile]

Options: Same options that the Nim compiler supports. Plus:

--assumeUnique   Assume unique `ref` pointers. This makes the analysis unsound
                 but more useful for wild Nim code such as the Nim compiler
                 itself.
"""

proc getCommandLineDesc(conf: ConfigRef): string =
  result = (HelpMessage % [system.NimVersion, platform.OS[conf.target.hostOS].name,
                           CPU[conf.target.hostCPU].name, CompileDate]) &
                           Usage

proc helpOnError(conf: ConfigRef) =
  msgWriteln(conf, getCommandLineDesc(conf), {msgStdout})
  msgQuit(0)

type
  CannotMapToZ3Error = object of ValueError
  Z3Exception = object of ValueError
  VersionScope = distinct int
  DrnimContext = ref object
    z3: Z3_context
    graph: ModuleGraph
    idgen: IdGenerator
    facts: seq[(PNode, VersionScope)]
    varVersions: seq[int] # this maps variable IDs to their current version.
    varSyms: seq[PSym] # mirrors 'varVersions'
    o: Operators
    hasUnstructedCf: int
    currOptions: TOptions
    owner: PSym
    mangler: seq[PSym]
    opImplies: PSym

  DrCon = object
    graph: ModuleGraph
    idgen: IdGenerator
    mapping: Table[string, Z3_ast]
    canonParameterNames: bool
    assumeUniqueness: bool
    up: DrnimContext

var
  assumeUniqueness: bool

proc echoFacts(c: DrnimContext) =
  echo "FACTS:"
  for i in 0 ..< c.facts.len:
    let f = c.facts[i]
    echo f[0], " version ", int(f[1])

proc isLoc(m: PNode; assumeUniqueness: bool): bool =
  # We can reason about "locations" and map them to Z3 constants.
  # For code that is full of "ref" (e.g. the Nim compiler itself) that
  # is too limiting
  proc isLet(n: PNode): bool =
    if n.kind == nkSym:
      if n.sym.kind in {skLet, skTemp, skForVar}:
        result = true
      elif n.sym.kind == skParam and skipTypes(n.sym.typ,
                                               abstractInst).kind != tyVar:
        result = true

  var n = m
  while true:
    case n.kind
    of nkDotExpr, nkCheckedFieldExpr, nkObjUpConv, nkObjDownConv, nkHiddenDeref:
      n = n[0]
    of nkDerefExpr:
      n = n[0]
      if not assumeUniqueness: return false
    of nkBracketExpr:
      if isConstExpr(n[1]) or isLet(n[1]) or isConstExpr(n[1].skipConv):
        n = n[0]
      else: return
    of nkHiddenStdConv, nkHiddenSubConv, nkConv:
      n = n[1]
    else:
      break
  if n.kind == nkSym:
    case n.sym.kind
    of skLet, skTemp, skForVar, skParam:
      result = true
    #of skParam:
    #  result = skipTypes(n.sym.typ, abstractInst).kind != tyVar
    of skResult, skVar:
      result = {sfAddrTaken} * n.sym.flags == {}
    else:
      discard

proc currentVarVersion(c: DrnimContext; s: PSym; begin: VersionScope): int =
  # we need to take into account both en- and disabled var bindings here,
  # hence the 'abs' call:
  result = 0
  for i in countdown(int(begin)-1, 0):
    if abs(c.varVersions[i]) == s.id: inc result

proc previousVarVersion(c: DrnimContext; s: PSym; begin: VersionScope): int =
  # we need to ignore currently disabled var bindings here,
  # hence no 'abs' call here.
  result = -1
  for i in countdown(int(begin)-1, 0):
    if c.varVersions[i] == s.id: inc result

proc disamb(c: DrnimContext; s: PSym): int =
  # we group by 's.name.s' to compute the stable name ID.
  result = 0
  for i in 0 ..< c.mangler.len:
    if s == c.mangler[i]: return result
    if s.name.s == c.mangler[i].name.s: inc result
  c.mangler.add s

proc stableName(result: var string; c: DrnimContext; n: PNode; version: VersionScope;
                isOld: bool) =
  # we can map full Nim expressions like 'f(a, b, c)' to Z3 variables.
  # We must be careful to select a unique, stable name for these expressions
  # based on structural equality. 'stableName' helps us with this problem.
  # In the future we will also use this string for the caching mechanism.
  case n.kind
  of nkEmpty, nkNilLit, nkType: discard
  of nkIdent:
    result.add n.ident.s
  of nkSym:
    result.add n.sym.name.s
    if n.sym.magic == mNone:
      let d = disamb(c, n.sym)
      if d != 0:
        result.add "`scope="
        result.addInt d
      let v = if isOld: c.previousVarVersion(n.sym, version)
              else: c.currentVarVersion(n.sym, version)
      if v > 0:
        result.add '`'
        result.addInt v
    else:
      result.add "`magic="
      result.addInt ord(n.sym.magic)
  of nkBindStmt:
    # we use 'bind x 3' to use the 3rd version of variable 'x'. This
    # is easier than using 'old' which is position relative.
    assert n.len == 2
    assert n[0].kind == nkSym
    assert n[1].kind == nkIntLit
    let s = n[0].sym
    let v = int(n[1].intVal)
    result.add s.name.s
    let d = disamb(c, s)
    if d != 0:
      result.add "`scope="
      result.addInt d
    if v > 0:
      result.add '`'
      result.addInt v
  of nkCharLit..nkUInt64Lit:
    result.addInt n.intVal
  of nkFloatLit..nkFloat64Lit:
    result.addFloat n.floatVal
  of nkStrLit..nkTripleStrLit:
    result.add strutils.escape n.strVal
  of nkDotExpr:
    stableName(result, c, n[0], version, isOld)
    result.add '.'
    stableName(result, c, n[1], version, isOld)
  of nkBracketExpr:
    stableName(result, c, n[0], version, isOld)
    result.add '['
    stableName(result, c, n[1], version, isOld)
    result.add ']'
  of nkCallKinds:
    if n.len == 2:
      stableName(result, c, n[1], version, isOld)
      result.add '.'
      case getMagic(n)
      of mLengthArray, mLengthOpenArray, mLengthSeq, mLengthStr:
        result.add "len"
      of mHigh:
        result.add "high"
      of mLow:
        result.add "low"
      else:
        stableName(result, c, n[0], version, isOld)
    elif n.kind == nkInfix and n.len == 3:
      result.add '('
      stableName(result, c, n[1], version, isOld)
      result.add ' '
      stableName(result, c, n[0], version, isOld)
      result.add ' '
      stableName(result, c, n[2], version, isOld)
      result.add ')'
    else:
      stableName(result, c, n[0], version, isOld)
      result.add '('
      for i in 1..<n.len:
        if i > 1: result.add ", "
        stableName(result, c, n[i], version, isOld)
      result.add ')'
  else:
    result.add $n.kind
    result.add '('
    for i in 0..<n.len:
      if i > 0: result.add ", "
      stableName(result, c, n[i], version, isOld)
    result.add ')'

proc stableName(c: DrnimContext; n: PNode; version: VersionScope;
                isOld = false): string =
  stableName(result, c, n, version, isOld)

template allScopes(c): untyped = VersionScope(c.varVersions.len)
template currentScope(c): untyped = VersionScope(c.varVersions.len)

proc notImplemented(msg: string) {.noinline.} =
  when defined(debug):
    writeStackTrace()
    echo msg
  raise newException(CannotMapToZ3Error, "; cannot map to Z3: " & msg)

proc notImplemented(n: PNode) {.noinline.} =
  when defined(debug):
    writeStackTrace()
  raise newException(CannotMapToZ3Error, "; cannot map to Z3: " & $n)

proc notImplemented(t: PType) {.noinline.} =
  when defined(debug):
    writeStackTrace()
  raise newException(CannotMapToZ3Error, "; cannot map to Z3: " & typeToString t)

proc translateEnsures(e, x: PNode): PNode =
  if e.kind == nkSym and e.sym.kind == skResult:
    result = x
  else:
    result = shallowCopy(e)
    for i in 0 ..< safeLen(e):
      result[i] = translateEnsures(e[i], x)

proc typeToZ3(c: DrCon; t: PType): Z3_sort =
  template ctx: untyped = c.up.z3
  case t.skipTypes(abstractInst+{tyVar}).kind
  of tyEnum, tyInt..tyInt64:
    result = Z3_mk_int_sort(ctx)
  of tyBool:
    result = Z3_mk_bool_sort(ctx)
  of tyFloat..tyFloat128:
    result = Z3_mk_fpa_sort_double(ctx)
  of tyChar, tyUInt..tyUInt64:
    result = Z3_mk_bv_sort(ctx, 64)
    #cuint(getSize(c.graph.config, t) * 8))
  else:
    notImplemented(t)

template binary(op, a, b): untyped =
  var arr = [a, b]
  op(ctx, cuint(2), addr(arr[0]))

proc nodeToZ3(c: var DrCon; n: PNode; scope: VersionScope; vars: var seq[PNode]): Z3_ast

proc nodeToDomain(c: var DrCon; n, q: PNode; opAnd: PSym): PNode =
  assert n.kind == nkInfix
  let opLe = createMagic(c.graph, c.idgen, "<=", mLeI)
  case $n[0]
  of "..":
    result = buildCall(opAnd, buildCall(opLe, n[1], q), buildCall(opLe, q, n[2]))
  of "..<":
    let opLt = createMagic(c.graph, c.idgen, "<", mLtI)
    result = buildCall(opAnd, buildCall(opLe, n[1], q), buildCall(opLt, q, n[2]))
  else:
    notImplemented(n)

template quantorToZ3(fn) {.dirty.} =
  template ctx: untyped = c.up.z3

  var bound = newSeq[Z3_app](n.len-2)
  let opAnd = createMagic(c.graph, c.idgen, "and", mAnd)
  var known: PNode
  for i in 1..n.len-2:
    let it = n[i]
    doAssert it.kind == nkInfix
    let v = it[1].sym
    let name = Z3_mk_string_symbol(ctx, v.name.s)
    let vz3 = Z3_mk_const(ctx, name, typeToZ3(c, v.typ))
    c.mapping[stableName(c.up, it[1], allScopes(c.up))] = vz3
    bound[i-1] = Z3_to_app(ctx, vz3)
    let domain = nodeToDomain(c, it[2], it[1], opAnd)
    if known == nil:
      known = domain
    else:
      known = buildCall(opAnd, known, domain)

  var dummy: seq[PNode]
  assert known != nil
  let x = nodeToZ3(c, buildCall(createMagic(c.graph, c.idgen, "->", mImplies),
                   known, n[^1]), scope, dummy)
  result = fn(ctx, 0, bound.len.cuint, addr(bound[0]), 0, nil, x)

proc forallToZ3(c: var DrCon; n: PNode; scope: VersionScope): Z3_ast = quantorToZ3(Z3_mk_forall_const)
proc existsToZ3(c: var DrCon; n: PNode; scope: VersionScope): Z3_ast = quantorToZ3(Z3_mk_exists_const)

proc paramName(c: DrnimContext; n: PNode): string =
  case n.sym.kind
  of skParam: result = "arg" & $n.sym.position
  of skResult: result = "result"
  else: result = stableName(c, n, allScopes(c))

proc nodeToZ3(c: var DrCon; n: PNode; scope: VersionScope; vars: var seq[PNode]): Z3_ast =
  template ctx: untyped = c.up.z3
  template rec(n): untyped = nodeToZ3(c, n, scope, vars)
  case n.kind
  of nkSym:
    let key = if c.canonParameterNames: paramName(c.up, n) else: stableName(c.up, n, scope)
    result = c.mapping.getOrDefault(key)
    if pointer(result) == nil:
      let name = Z3_mk_string_symbol(ctx, key)
      result = Z3_mk_const(ctx, name, typeToZ3(c, n.sym.typ))
      c.mapping[key] = result
      vars.add n
  of nkCharLit..nkUInt64Lit:
    if n.typ != nil and n.typ.skipTypes(abstractInst).kind in {tyInt..tyInt64}:
      # optimized for the common case
      result = Z3_mk_int64(ctx, clonglong(n.intval), Z3_mk_int_sort(ctx))
    elif n.typ != nil and n.typ.kind == tyBool:
      result = if n.intval != 0: Z3_mk_true(ctx) else: Z3_mk_false(ctx)
    elif n.typ != nil and isUnsigned(n.typ):
      result = Z3_mk_unsigned_int64(ctx, cast[uint64](n.intVal), typeToZ3(c, n.typ))
    else:
      let zt = if n.typ == nil: Z3_mk_int_sort(ctx) else: typeToZ3(c, n.typ)
      result = Z3_mk_numeral(ctx, $getOrdValue(n), zt)
  of nkFloatLit..nkFloat64Lit:
    result = Z3_mk_fpa_numeral_double(ctx, n.floatVal, Z3_mk_fpa_sort_double(ctx))
  of nkCallKinds:
    assert n.len > 0
    let operator = getMagic(n)
    case operator
    of mEqI, mEqF64, mEqEnum, mEqCh, mEqB, mEqRef, mEqProc,
        mEqStr, mEqSet, mEqCString:
      result = Z3_mk_eq(ctx, rec n[1], rec n[2])
    of mLeI, mLeEnum, mLeCh, mLeB, mLePtr, mLeStr:
      result = Z3_mk_le(ctx, rec n[1], rec n[2])
    of mLtI, mLtEnum, mLtCh, mLtB, mLtPtr, mLtStr:
      result = Z3_mk_lt(ctx, rec n[1], rec n[2])
    of mLengthOpenArray, mLengthStr, mLengthArray, mLengthSeq:
      # len(x) needs the same logic as 'x' itself
      if isLoc(n[1], c.assumeUniqueness):
        let key = stableName(c.up, n, scope)
        result = c.mapping.getOrDefault(key)
        if pointer(result) == nil:
          let name = Z3_mk_string_symbol(ctx, key)
          result = Z3_mk_const(ctx, name, Z3_mk_int_sort(ctx))
          c.mapping[key] = result
          vars.add n
      else:
        notImplemented(n)
    of mHigh:
      let addOpr = createMagic(c.graph, c.idgen, "+", mAddI)
      let lenOpr = createMagic(c.graph, c.idgen, "len", mLengthOpenArray)
      let asLenExpr = addOpr.buildCall(lenOpr.buildCall(n[1]), nkIntLit.newIntNode(-1))
      result = rec asLenExpr
    of mLow:
      result = rec lowBound(c.graph.config, n[1])
    of mAddI, mSucc:
      result = binary(Z3_mk_add, rec n[1], rec n[2])
    of mSubI, mPred:
      result = binary(Z3_mk_sub, rec n[1], rec n[2])
    of mMulI:
      result = binary(Z3_mk_mul, rec n[1], rec n[2])
    of mDivI:
      result = Z3_mk_div(ctx, rec n[1], rec n[2])
    of mModI:
      result = Z3_mk_mod(ctx, rec n[1], rec n[2])
    of mMaxI:
      # max(a, b) <=> ite(a < b, b, a)
      result = Z3_mk_ite(ctx, Z3_mk_lt(ctx, rec n[1], rec n[2]),
        rec n[2], rec n[1])
    of mMinI:
      # min(a, b) <=> ite(a < b, a, b)
      result = Z3_mk_ite(ctx, Z3_mk_lt(ctx, rec n[1], rec n[2]),
        rec n[1], rec n[2])
    of mLeU:
      result = Z3_mk_bvule(ctx, rec n[1], rec n[2])
    of mLtU:
      result = Z3_mk_bvult(ctx, rec n[1], rec n[2])
    of mAnd:
      # 'a and b' <=> ite(a, b, false)
      result = Z3_mk_ite(ctx, rec n[1], rec n[2], Z3_mk_false(ctx))
      #result = binary(Z3_mk_and, rec n[1], rec n[2])
    of mOr:
      result = Z3_mk_ite(ctx, rec n[1], Z3_mk_true(ctx), rec n[2])
      #result = binary(Z3_mk_or, rec n[1], rec n[2])
    of mXor:
      result = Z3_mk_xor(ctx, rec n[1], rec n[2])
    of mNot:
      result = Z3_mk_not(ctx, rec n[1])
    of mImplies:
      result = Z3_mk_implies(ctx, rec n[1], rec n[2])
    of mIff:
      result = Z3_mk_iff(ctx, rec n[1], rec n[2])
    of mForall:
      result = forallToZ3(c, n, scope)
    of mExists:
      result = existsToZ3(c, n, scope)
    of mLeF64:
      result = Z3_mk_fpa_leq(ctx, rec n[1], rec n[2])
    of mLtF64:
      result = Z3_mk_fpa_lt(ctx, rec n[1], rec n[2])
    of mAddF64:
      result = Z3_mk_fpa_add(ctx, Z3_mk_fpa_round_nearest_ties_to_even(ctx), rec n[1], rec n[2])
    of mSubF64:
      result = Z3_mk_fpa_sub(ctx, Z3_mk_fpa_round_nearest_ties_to_even(ctx), rec n[1], rec n[2])
    of mMulF64:
      result = Z3_mk_fpa_mul(ctx, Z3_mk_fpa_round_nearest_ties_to_even(ctx), rec n[1], rec n[2])
    of mDivF64:
      result = Z3_mk_fpa_div(ctx, Z3_mk_fpa_round_nearest_ties_to_even(ctx), rec n[1], rec n[2])
    of mShrI:
      # XXX handle conversions from int to uint here somehow
      result = Z3_mk_bvlshr(ctx, rec n[1], rec n[2])
    of mAshrI:
      result = Z3_mk_bvashr(ctx, rec n[1], rec n[2])
    of mShlI:
      result = Z3_mk_bvshl(ctx, rec n[1], rec n[2])
    of mBitandI:
      result = Z3_mk_bvand(ctx, rec n[1], rec n[2])
    of mBitorI:
      result = Z3_mk_bvor(ctx, rec n[1], rec n[2])
    of mBitxorI:
      result = Z3_mk_bvxor(ctx, rec n[1], rec n[2])
    of mOrd, mChr:
      result = rec n[1]
    of mOld:
      let key = if c.canonParameterNames: (paramName(c.up, n[1]) & ".old")
                else: stableName(c.up, n[1], scope, isOld = true)
      result = c.mapping.getOrDefault(key)
      if pointer(result) == nil:
        let name = Z3_mk_string_symbol(ctx, key)
        result = Z3_mk_const(ctx, name, typeToZ3(c, n[1].typ))
        c.mapping[key] = result
        # XXX change the logic in `addRangeInfo` for this
        #vars.add n

    else:
      # sempass2 adds some 'fact' like 'x = f(a, b)' (see addAsgnFact)
      # 'f(a, b)' can have an .ensures annotation and we need to make use
      # of this information.
      # we need to map 'f(a, b)' to a Z3 variable of this name
      let op = n[0].typ
      if op != nil and op.n != nil and op.n.len > 0 and op.n[0].kind == nkEffectList and
          ensuresEffects < op.n[0].len:
        let ensures = op.n[0][ensuresEffects]
        if ensures != nil and ensures.kind != nkEmpty:
          let key = stableName(c.up, n, scope)
          result = c.mapping.getOrDefault(key)
          if pointer(result) == nil:
            let name = Z3_mk_string_symbol(ctx, key)
            result = Z3_mk_const(ctx, name, typeToZ3(c, n.typ))
            c.mapping[key] = result
            vars.add n

      if pointer(result) == nil:
        notImplemented(n)
  of nkStmtListExpr, nkPar:
    var isTrivial = true
    for i in 0..n.len-2:
      isTrivial = isTrivial and n[i].kind in {nkEmpty, nkCommentStmt}
    if isTrivial:
      result = rec n[^1]
    else:
      notImplemented(n)
  of nkHiddenDeref:
    result = rec n[0]
  else:
    if isLoc(n, c.assumeUniqueness):
      let key = stableName(c.up, n, scope)
      result = c.mapping.getOrDefault(key)
      if pointer(result) == nil:
        let name = Z3_mk_string_symbol(ctx, key)
        result = Z3_mk_const(ctx, name, typeToZ3(c, n.typ))
        c.mapping[key] = result
        vars.add n
    else:
      notImplemented(n)

proc addRangeInfo(c: var DrCon, n: PNode; scope: VersionScope, res: var seq[Z3_ast]) =
  var cmpOp = mLeI
  if n.typ != nil:
    cmpOp =
      case n.typ.skipTypes(abstractInst).kind
      of tyFloat..tyFloat128: mLeF64
      of tyChar, tyUInt..tyUInt64: mLeU
      else: mLeI

  var lowBound, highBound: PNode
  if n.kind == nkSym:
    let v = n.sym
    let t = v.typ.skipTypes(abstractInst - {tyRange})

    case t.kind
    of tyRange:
      lowBound = t.n[0]
      highBound = t.n[1]
    of tyFloat..tyFloat128:
      # no range information for non-range'd floats
      return
    of tyUInt..tyUInt64, tyChar:
      lowBound = newIntNode(nkUInt64Lit, firstOrd(nil, v.typ))
      lowBound.typ = v.typ
      highBound = newIntNode(nkUInt64Lit, lastOrd(nil, v.typ))
      highBound.typ = v.typ
    of tyInt..tyInt64, tyEnum:
      lowBound = newIntNode(nkInt64Lit, firstOrd(nil, v.typ))
      highBound = newIntNode(nkInt64Lit, lastOrd(nil, v.typ))
    else:
      # no range information available:
      return
  elif n.kind in nkCallKinds and n.len == 2 and n[0].kind == nkSym and
      n[0].sym.magic in {mLengthOpenArray, mLengthStr, mLengthArray, mLengthSeq}:
    # we know it's a 'len(x)' expression and we seek to teach
    # Z3 that the result is >= 0 and <= high(int).
    doAssert n.kind in nkCallKinds
    doAssert n[0].kind == nkSym
    doAssert n.len == 2

    lowBound = newIntNode(nkInt64Lit, 0)
    if n.typ != nil:
      highBound = newIntNode(nkInt64Lit, lastOrd(nil, n.typ))
    else:
      highBound = newIntNode(nkInt64Lit, high(int64))
  else:
    let op = n[0].typ
    if op != nil and op.n != nil and op.n.len > 0 and op.n[0].kind == nkEffectList and
        ensuresEffects < op.n[0].len:
      let ensures = op.n[0][ensuresEffects]
      if ensures != nil and ensures.kind != nkEmpty:
        var dummy: seq[PNode]
        res.add nodeToZ3(c, translateEnsures(ensures, n), scope, dummy)
    return

  let x = newTree(nkInfix, newSymNode createMagic(c.graph, c.idgen, "<=", cmpOp), lowBound, n)
  let y = newTree(nkInfix, newSymNode createMagic(c.graph, c.idgen, "<=", cmpOp), n, highBound)

  var dummy: seq[PNode]
  res.add nodeToZ3(c, x, scope, dummy)
  res.add nodeToZ3(c, y, scope, dummy)

proc on_err(ctx: Z3_context, e: Z3_error_code) {.nimcall.} =
  #writeStackTrace()
  let msg = $Z3_get_error_msg(ctx, e)
  raise newException(Z3Exception, msg)

proc forall(ctx: Z3_context; vars: seq[Z3_ast]; assumption, body: Z3_ast): Z3_ast =
  let x = Z3_mk_implies(ctx, assumption, body)
  if vars.len > 0:
    var bound: seq[Z3_app]
    for v in vars: bound.add Z3_to_app(ctx, v)
    result = Z3_mk_forall_const(ctx, 0, bound.len.cuint, addr(bound[0]), 0, nil, x)
  else:
    result = x

proc conj(ctx: Z3_context; conds: seq[Z3_ast]): Z3_ast =
  if conds.len > 0:
    result = Z3_mk_and(ctx, cuint(conds.len), unsafeAddr conds[0])
  else:
    result = Z3_mk_true(ctx)

proc setupZ3(): Z3_context =
  let cfg = Z3_mk_config()
  when false:
    Z3_set_param_value(cfg, "timeout", "1000")
  Z3_set_param_value(cfg, "model", "true")
  result = Z3_mk_context(cfg)
  Z3_del_config(cfg)
  Z3_set_error_handler(result, on_err)

proc proofEngineAux(c: var DrCon; assumptions: seq[(PNode, VersionScope)];
                    toProve: (PNode, VersionScope)): (bool, string) =
  c.mapping = initTable[string, Z3_ast]()
  try:

    #[
    For example, let's have these facts:

      i < 10
      i > 0

    Question:

      i + 3 < 13

    What we need to produce:

    forall(i, (i < 10) & (i > 0) -> (i + 3 < 13))

    ]#

    var collectedVars: seq[PNode]

    template ctx(): untyped = c.up.z3

    let solver = Z3_mk_solver(ctx)
    var lhs: seq[Z3_ast]
    for assumption in items(assumptions):
      try:
        let za = nodeToZ3(c, assumption[0], assumption[1], collectedVars)
        #Z3_solver_assert ctx, solver, za
        lhs.add za
      except CannotMapToZ3Error:
        discard "ignore a fact we cannot map to Z3"

    let z3toProve = nodeToZ3(c, toProve[0], toProve[1], collectedVars)
    for v in collectedVars:
      addRangeInfo(c, v, toProve[1], lhs)

    # to make Z3 produce nice counterexamples, we try to prove the
    # negation of our conjecture and see if it's Z3_L_FALSE
    let fa = Z3_mk_not(ctx, Z3_mk_implies(ctx, conj(ctx, lhs), z3toProve))

    #Z3_mk_not(ctx, forall(ctx, collectedVars, conj(ctx, lhs), z3toProve))

    when defined(dz3):
      echo "toProve: ", Z3_ast_to_string(ctx, fa), " ", c.graph.config $ toProve[0].info, " ", int(toProve[1])
    Z3_solver_assert ctx, solver, fa

    let z3res = Z3_solver_check(ctx, solver)
    result[0] = z3res == Z3_L_FALSE
    result[1] = ""
    if not result[0]:
      let counterex = strip($Z3_model_to_string(ctx, Z3_solver_get_model(ctx, solver)))
      if counterex.len > 0:
        result[1].add "; counter example: " & counterex
  except ValueError:
    result[0] = false
    result[1] = getCurrentExceptionMsg()

proc proofEngine(ctx: DrnimContext; assumptions: seq[(PNode, VersionScope)];
                 toProve: (PNode, VersionScope)): (bool, string) =
  var c: DrCon
  c.graph = ctx.graph
  c.idgen = ctx.idgen
  c.assumeUniqueness = assumeUniqueness
  c.up = ctx
  result = proofEngineAux(c, assumptions, toProve)

proc skipAddr(n: PNode): PNode {.inline.} =
  (if n.kind == nkHiddenAddr: n[0] else: n)

proc translateReq(r, call: PNode): PNode =
  if r.kind == nkSym and r.sym.kind == skParam:
    if r.sym.position+1 < call.len:
      result = call[r.sym.position+1].skipAddr
    else:
      notImplemented("no argument given for formal parameter: " & r.sym.name.s)
  else:
    result = shallowCopy(r)
    for i in 0 ..< safeLen(r):
      result[i] = translateReq(r[i], call)

proc requirementsCheck(ctx: DrnimContext; assumptions: seq[(PNode, VersionScope)];
                      call, requirement: PNode): (bool, string) =
  try:
    let r = translateReq(requirement, call)
    result = proofEngine(ctx, assumptions, (r, ctx.currentScope))
  except ValueError:
    result[0] = false
    result[1] = getCurrentExceptionMsg()

proc compatibleProps(graph: ModuleGraph; formal, actual: PType): bool {.nimcall.} =
  #[
  Thoughts on subtyping rules for 'proc' types:

    proc a(y: int) {.requires: y > 0.}  # a is 'weaker' than F
    # 'requires' must be weaker (or equal)
    # 'ensures'  must be stronger (or equal)

    # a 'is weaker than' b iff  b -> a
    # a 'is stronger than' b iff a -> b
    # --> We can use Z3 to compute whether 'var x: T = q' is valid

    type
      F = proc (y: int) {.requires: y > 5.}

    var
      x: F = a # valid?
  ]#
  proc isEmpty(n: PNode): bool {.inline.} = n == nil or n.safeLen == 0

  result = true
  if formal.n != nil and formal.n.len > 0 and formal.n[0].kind == nkEffectList and
      ensuresEffects < formal.n[0].len:

    let frequires = formal.n[0][requiresEffects]
    let fensures = formal.n[0][ensuresEffects]

    if actual.n != nil and actual.n.len > 0 and actual.n[0].kind == nkEffectList and
        ensuresEffects < actual.n[0].len:
      let arequires = actual.n[0][requiresEffects]
      let aensures = actual.n[0][ensuresEffects]

      var c: DrCon
      c.graph = graph
      c.idgen = graph.idgen
      c.canonParameterNames = true
      try:
        c.up = DrnimContext(z3: setupZ3(), o: initOperators(graph), graph: graph, owner: nil,
          opImplies: createMagic(graph, c.idgen, "->", mImplies))
        template zero: untyped = VersionScope(0)
        if not frequires.isEmpty:
          result = not arequires.isEmpty and proofEngineAux(c, @[(frequires, zero)], (arequires, zero))[0]

        if result:
          if not fensures.isEmpty:
            result = not aensures.isEmpty and proofEngineAux(c, @[(aensures, zero)], (fensures, zero))[0]
      finally:
        Z3_del_context(c.up.z3)
    else:
      # formal has requirements but 'actual' has none, so make it
      # incompatible. XXX What if the requirement only mentions that
      # we already know from the type system?
      result = frequires.isEmpty and fensures.isEmpty

template config(c: typed): untyped = c.graph.config

proc addFact(c: DrnimContext; n: PNode) =
  let v = c.currentScope
  if n.kind in nkCallKinds and n[0].kind == nkSym and n[0].sym.magic in {mOr, mAnd}:
    c.addFact(n[1])
  c.facts.add((n, v))

proc neg(c: DrnimContext; n: PNode): PNode =
  result = newNodeI(nkCall, n.info, 2)
  result[0] = newSymNode(c.o.opNot)
  result[1] = n

proc addFactNeg(c: DrnimContext; n: PNode) =
  addFact(c, neg(c, n))

proc combineFacts(c: DrnimContext; a, b: PNode): PNode =
  if a == nil:
    result = b
  else:
    result = buildCall(c.o.opAnd, a, b)

proc prove(c: DrnimContext; prop: PNode): bool =
  let (success, m) = proofEngine(c, c.facts, (prop, c.currentScope))
  if not success:
    message(c.config, prop.info, warnStaticIndexCheck, "cannot prove: " & $prop & m)
  result = success

proc traversePragmaStmt(c: DrnimContext, n: PNode) =
  for it in n:
    if it.kind == nkExprColonExpr:
      let pragma = whichPragma(it)
      if pragma == wAssume:
        addFact(c, it[1])
      elif pragma == wInvariant or pragma == wAssert:
        if prove(c, it[1]):
          addFact(c, it[1])
        else:
          echoFacts(c)

proc requiresCheck(c: DrnimContext, call: PNode; op: PType) =
  assert op.n[0].kind == nkEffectList
  if requiresEffects < op.n[0].len:
    let requires = op.n[0][requiresEffects]
    if requires != nil and requires.kind != nkEmpty:
      # we need to map the call arguments to the formal parameters used inside
      # 'requires':
      let (success, m) = requirementsCheck(c, c.facts, call, requires)
      if not success:
        message(c.config, call.info, warnStaticIndexCheck, "cannot prove: " & $requires & m)

proc freshVersion(c: DrnimContext; arg: PNode) =
  let v = getRoot(arg)
  if v != nil:
    c.varVersions.add v.id
    c.varSyms.add v

proc translateEnsuresFromCall(c: DrnimContext, e, call: PNode): PNode =
  if e.kind in nkCallKinds and e[0].kind == nkSym and e[0].sym.magic == mOld:
    assert e[1].kind == nkSym and e[1].sym.kind == skParam
    let param = e[1].sym
    let arg = call[param.position+1].skipAddr
    result = buildCall(e[0].sym, arg)
  elif e.kind == nkSym and e.sym.kind == skParam:
    let param = e.sym
    let arg = call[param.position+1].skipAddr
    result = arg
  else:
    result = shallowCopy(e)
    for i in 0 ..< safeLen(e): result[i] = translateEnsuresFromCall(c, e[i], call)

proc collectEnsuredFacts(c: DrnimContext, call: PNode; op: PType) =
  assert op.n[0].kind == nkEffectList
  for i in 1 ..< min(call.len, op.len):
    if op[i].kind == tyVar:
      freshVersion(c, call[i].skipAddr)

  if ensuresEffects < op.n[0].len:
    let ensures = op.n[0][ensuresEffects]
    if ensures != nil and ensures.kind != nkEmpty:
      addFact(c, translateEnsuresFromCall(c, ensures, call))

proc checkLe(c: DrnimContext, a, b: PNode) =
  var cmpOp = mLeI
  if a.typ != nil:
    case a.typ.skipTypes(abstractInst).kind
    of tyFloat..tyFloat128: cmpOp = mLeF64
    of tyChar, tyUInt..tyUInt64: cmpOp = mLeU
    else: discard

  let cmp = newTree(nkInfix, newSymNode createMagic(c.graph, c.idgen, "<=", cmpOp), a, b)
  cmp.info = a.info
  discard prove(c, cmp)

proc checkBounds(c: DrnimContext; arr, idx: PNode) =
  checkLe(c, lowBound(c.config, arr), idx)
  checkLe(c, idx, highBound(c.config, arr, c.o))

proc checkRange(c: DrnimContext; value: PNode; typ: PType) =
  let t = typ.skipTypes(abstractInst - {tyRange})
  if t.kind == tyRange:
    let lowBound = copyTree(t.n[0])
    lowBound.info = value.info
    let highBound = copyTree(t.n[1])
    highBound.info = value.info
    checkLe(c, lowBound, value)
    checkLe(c, value, highBound)

proc addAsgnFact*(c: DrnimContext, key, value: PNode) =
  var fact = newNodeI(nkCall, key.info, 3)
  fact[0] = newSymNode(c.o.opEq)
  fact[1] = key
  fact[2] = value
  c.facts.add((fact, c.currentScope))

proc traverse(c: DrnimContext; n: PNode)

proc traverseTryStmt(c: DrnimContext; n: PNode) =
  traverse(c, n[0])
  let oldFacts = c.facts.len
  for i in 1 ..< n.len:
    traverse(c, n[i].lastSon)
  setLen(c.facts, oldFacts)

proc traverseCase(c: DrnimContext; n: PNode) =
  traverse(c, n[0])
  let oldFacts = c.facts.len
  for i in 1 ..< n.len:
    traverse(c, n[i].lastSon)
  # XXX make this as smart as 'if elif'
  setLen(c.facts, oldFacts)

proc disableVarVersions(c: DrnimContext; until: int) =
  for i in until..<c.varVersions.len:
    c.varVersions[i] = - abs(c.varVersions[i])

proc varOfVersion(c: DrnimContext; x: PSym; scope: int): PNode =
  let version = currentVarVersion(c, x, VersionScope(scope))
  result = newTree(nkBindStmt, newSymNode(x), newIntNode(nkIntLit, version))

proc traverseIf(c: DrnimContext; n: PNode) =
  #[ Consider this example::

    var x = y   # x'0
    if a:
      inc x     # x'1 == x'0 + 1
    elif b:
      inc x, 2  # x'2 == x'0 + 2

  afterwards we know this is fact::

    x'3 = Phi(x'0, x'1, x'2)

  So a Phi node from SSA representation is an 'or' formula like::

    x'3 == x'1 or x'3 == x'2 or x'3 == x'0

  However, this loses some information. The formula that doesn't
  lose information is::

    (a -> (x'3 == x'1)) and
    ((not a and b) -> (x'3 == x'2)) and
    ((not a and not b) -> (x'3 == x'0))

  (Where ``->`` is the logical implication.)

  In addition to the Phi information we also know the 'facts'
  computed by the branches, for example::

    if a:
      factA
    elif b:
      factB
    else:
      factC

    (a -> factA) and
    ((not a and b) -> factB) and
    ((not a and not b) -> factC)

  We can combine these two aspects by producing the following facts
  after each branch::

    var x = y   # x'0
    if a:
      inc x     # x'1 == x'0 + 1
      # also:     x'1 == x'final
    elif b:
      inc x, 2  # x'2 == x'0 + 2
      # also:     x'2 == x'final
    else:
      # also:     x'0 == x'final

  ]#
  let oldFacts = c.facts.len
  let oldVars = c.varVersions.len
  var newFacts: seq[PNode]
  var branches = newSeq[(PNode, int)](n.len) # (cond, newVars) pairs
  template condVersion(): untyped = VersionScope(oldVars)

  for i in 0..<n.len:
    let branch = n[i]
    setLen(c.facts, oldFacts)

    var cond = PNode(nil)
    for j in 0..i-1:
      addFactNeg(c, n[j][0])
      cond = combineFacts(c, cond, neg(c, n[j][0]))
    if branch.len > 1:
      addFact(c, branch[0])
      cond = combineFacts(c, cond, branch[0])

    for i in 0..<branch.len:
      traverse(c, branch[i])

    assert cond != nil
    branches[i] = (cond, c.varVersions.len)

    var newInfo = PNode(nil)
    for f in oldFacts..<c.facts.len:
      newInfo = combineFacts(c, newInfo, c.facts[f][0])
    if newInfo != nil:
      newFacts.add buildCall(c.opImplies, cond, newInfo)

    disableVarVersions(c, oldVars)

  setLen(c.facts, oldFacts)
  for f in newFacts: c.facts.add((f, condVersion))
  # build the 'Phi' information:
  let varsWithoutFinals = c.varVersions.len
  var mutatedVars = initIntSet()
  for i in oldVars ..< varsWithoutFinals:
    let vv = c.varVersions[i]
    if not mutatedVars.containsOrIncl(vv):
      c.varVersions.add vv
      c.varSyms.add c.varSyms[i]

  var prevIdx = oldVars
  for i in 0 ..< branches.len:
    for v in prevIdx .. branches[i][1] - 1:
      c.facts.add((buildCall(c.opImplies, branches[i][0],
        buildCall(c.o.opEq, varOfVersion(c, c.varSyms[v], branches[i][1]), newSymNode(c.varSyms[v]))),
        condVersion))
    prevIdx = branches[i][1]

proc traverseBlock(c: DrnimContext; n: PNode) =
  traverse(c, n)

proc addFactLe(c: DrnimContext; a, b: PNode) =
  c.addFact c.o.opLe.buildCall(a, b)

proc addFactLt(c: DrnimContext; a, b: PNode) =
  c.addFact c.o.opLt.buildCall(a, b)

proc ensuresCheck(c: DrnimContext; owner: PSym) =
  if owner.typ != nil and owner.typ.kind == tyProc and owner.typ.n != nil:
    let n = owner.typ.n
    if n.len > 0 and n[0].kind == nkEffectList and ensuresEffects < n[0].len:
      let ensures = n[0][ensuresEffects]
      if ensures != nil and ensures.kind != nkEmpty:
        discard prove(c, ensures)

proc traverseAsgn(c: DrnimContext; n: PNode) =
  traverse(c, n[0])
  traverse(c, n[1])

  proc replaceByOldParams(fact, le: PNode): PNode =
    if guards.sameTree(fact, le):
      result = newNodeIT(nkCall, fact.info, fact.typ)
      result.add newSymNode createMagic(c.graph, c.idgen, "old", mOld)
      result.add fact
    else:
      result = shallowCopy(fact)
      for i in 0 ..< safeLen(fact):
        result[i] = replaceByOldParams(fact[i], le)

  freshVersion(c, n[0])
  addAsgnFact(c, n[0], replaceByOldParams(n[1], n[0]))
  when defined(debug):
    echoFacts(c)

proc traverse(c: DrnimContext; n: PNode) =
  case n.kind
  of nkEmpty..nkNilLit:
    discard "nothing to do"
  of nkRaiseStmt, nkBreakStmt, nkContinueStmt:
    inc c.hasUnstructedCf
    for i in 0..<n.safeLen:
      traverse(c, n[i])
  of nkReturnStmt:
    for i in 0 ..< n.safeLen:
      traverse(c, n[i])
    ensuresCheck(c, c.owner)
  of nkCallKinds:
    # p's effects are ours too:
    var a = n[0]
    let op = a.typ
    if op != nil and op.kind == tyProc and op.n[0].kind == nkEffectList:
      requiresCheck(c, n, op)
      collectEnsuredFacts(c, n, op)
    if a.kind == nkSym:
      case a.sym.magic
      of mNew, mNewFinalize, mNewSeq:
        # may not look like an assignment, but it is:
        let arg = n[1]
        freshVersion(c, arg)
        traverse(c, arg)
        let x = newNodeIT(nkObjConstr, arg.info, arg.typ)
        x.add arg
        addAsgnFact(c, arg, x)
      of mArrGet, mArrPut:
        #if optStaticBoundsCheck in c.currOptions: checkBounds(c, n[1], n[2])
        discard
      else:
        discard

    for i in 0..<n.safeLen:
      traverse(c, n[i])
  of nkDotExpr:
    #guardDotAccess(c, n)
    for i in 0..<n.len: traverse(c, n[i])
  of nkCheckedFieldExpr:
    traverse(c, n[0])
    #checkFieldAccess(c.facts, n, c.config)
  of nkTryStmt: traverseTryStmt(c, n)
  of nkPragma: traversePragmaStmt(c, n)
  of nkAsgn, nkFastAsgn: traverseAsgn(c, n)
  of nkVarSection, nkLetSection:
    for child in n:
      let last = lastSon(child)
      if last.kind != nkEmpty: traverse(c, last)
      if child.kind == nkIdentDefs and last.kind != nkEmpty:
        for i in 0..<child.len-2:
          addAsgnFact(c, child[i], last)
      elif child.kind == nkVarTuple and last.kind != nkEmpty:
        for i in 0..<child.len-1:
          if child[i].kind == nkEmpty or
              child[i].kind == nkSym and child[i].sym.name.s == "_":
            discard "anon variable"
          elif last.kind in {nkPar, nkTupleConstr}:
            addAsgnFact(c, child[i], last[i])
  of nkConstSection:
    for child in n:
      let last = lastSon(child)
      traverse(c, last)
  of nkCaseStmt: traverseCase(c, n)
  of nkWhen, nkIfStmt, nkIfExpr: traverseIf(c, n)
  of nkBlockStmt, nkBlockExpr: traverseBlock(c, n[1])
  of nkWhileStmt:
    # 'while true' loop?
    if isTrue(n[0]):
      traverseBlock(c, n[1])
    else:
      let oldFacts = c.facts.len
      addFact(c, n[0])
      traverse(c, n[0])
      traverse(c, n[1])
      setLen(c.facts, oldFacts)
  of nkForStmt, nkParForStmt:
    # we are very conservative here and assume the loop is never executed:
    let oldFacts = c.facts.len
    let iterCall = n[n.len-2]
    if optStaticBoundsCheck in c.currOptions and iterCall.kind in nkCallKinds:
      let op = iterCall[0]
      if op.kind == nkSym and fromSystem(op.sym):
        let iterVar = n[0]
        case op.sym.name.s
        of "..", "countup", "countdown":
          let lower = iterCall[1]
          let upper = iterCall[2]
          # for i in 0..n   means  0 <= i and i <= n. Countdown is
          # the same since only the iteration direction changes.
          addFactLe(c, lower, iterVar)
          addFactLe(c, iterVar, upper)
        of "..<":
          let lower = iterCall[1]
          let upper = iterCall[2]
          addFactLe(c, lower, iterVar)
          addFactLt(c, iterVar, upper)
        else: discard

    for i in 0..<n.len-2:
      let it = n[i]
      traverse(c, it)
    let loopBody = n[^1]
    traverse(c, iterCall)
    traverse(c, loopBody)
    setLen(c.facts, oldFacts)
  of nkTypeSection, nkProcDef, nkConverterDef, nkMethodDef, nkIteratorDef,
      nkMacroDef, nkTemplateDef, nkLambda, nkDo, nkFuncDef:
    discard
  of nkCast:
    if n.len == 2:
      traverse(c, n[1])
  of nkHiddenStdConv, nkHiddenSubConv, nkConv:
    if n.len == 2:
      traverse(c, n[1])
      if optStaticBoundsCheck in c.currOptions:
        checkRange(c, n[1], n.typ)
  of nkObjUpConv, nkObjDownConv, nkChckRange, nkChckRangeF, nkChckRange64:
    if n.len == 1:
      traverse(c, n[0])
      if optStaticBoundsCheck in c.currOptions:
        checkRange(c, n[0], n.typ)
  of nkBracketExpr:
    if optStaticBoundsCheck in c.currOptions and n.len == 2:
      if n[0].typ != nil and skipTypes(n[0].typ, abstractVar).kind != tyTuple:
        checkBounds(c, n[0], n[1])
    for i in 0 ..< n.len: traverse(c, n[i])
  else:
    for i in 0 ..< n.len: traverse(c, n[i])

proc strongSemCheck(graph: ModuleGraph; owner: PSym; n: PNode) =
  var c = DrnimContext()
  c.currOptions = graph.config.options + owner.options
  if optStaticBoundsCheck in c.currOptions:
    c.z3 = setupZ3()
    c.o = initOperators(graph)
    c.graph = graph
    c.idgen = graph.idgen
    c.owner = owner
    c.opImplies = createMagic(c.graph, c.idgen, "->", mImplies)
    try:
      traverse(c, n)
      ensuresCheck(c, owner)
    finally:
      Z3_del_context(c.z3)


proc mainCommand(graph: ModuleGraph) =
  let conf = graph.config
  conf.lastCmdTime = epochTime()

  graph.strongSemCheck = strongSemCheck
  graph.compatibleProps = compatibleProps

  graph.config.setErrorMaxHighMaybe
  defineSymbol(graph.config.symbols, "nimcheck")
  defineSymbol(graph.config.symbols, "nimDrNim")

  registerPass graph, verbosePass
  registerPass graph, semPass
  compileProject(graph)
  if conf.errorCounter == 0:
    genSuccessX(graph.config)

proc processCmdLine(pass: TCmdLinePass, cmd: string; config: ConfigRef) =
  var p = parseopt.initOptParser(cmd)
  var argsCount = 1

  config.commandLine.setLen 0
  config.setCmd cmdCheck
  while true:
    parseopt.next(p)
    case p.kind
    of cmdEnd: break
    of cmdLongOption, cmdShortOption:
      config.commandLine.add " "
      config.commandLine.addCmdPrefix p.kind
      config.commandLine.add p.key.quoteShell # quoteShell to be future proof
      if p.val.len > 0:
        config.commandLine.add ':'
        config.commandLine.add p.val.quoteShell

      if p.key == " ":
        p.key = "-"
        if processArgument(pass, p, argsCount, config): break
      else:
        case p.key.normalize
        of "assumeunique":
          assumeUniqueness = true
        else:
          processSwitch(pass, p, config)
    of cmdArgument:
      config.commandLine.add " "
      config.commandLine.add p.key.quoteShell
      if processArgument(pass, p, argsCount, config): break
  if pass == passCmd2:
    if {optRun, optWasNimscript} * config.globalOptions == {} and
        config.arguments.len > 0 and config.cmd notin {cmdTcc, cmdNimscript}:
      rawMessage(config, errGenerated, errArgsNeedRunOption)

proc handleCmdLine(cache: IdentCache; conf: ConfigRef) =
  incl conf.options, optStaticBoundsCheck
  let self = NimProg(
    supportsStdinFile: true,
    processCmdLine: processCmdLine
  )
  self.initDefinesProg(conf, "drnim")
  if paramCount() == 0:
    helpOnError(conf)
    return

  self.processCmdLineAndProjectPath(conf)
  var graph = newModuleGraph(cache, conf)
  if not self.loadConfigsAndProcessCmdLine(cache, conf, graph): return
  mainCommand(graph)
  if conf.hasHint(hintGCStats): echo(GC_getStatistics())

when compileOption("gc", "refc"):
  # the new correct mark&sweep collector is too slow :-/
  GC_disableMarkAndSweep()

when not defined(selftest):
  let conf = newConfigRef()
  handleCmdLine(newIdentCache(), conf)
  when declared(GC_setMaxPause):
    echo GC_getStatistics()
  msgQuit(int8(conf.errorCounter > 0))
