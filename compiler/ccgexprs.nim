#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# included from cgen.nim

proc lenField: PRope {.inline.} = 
  result = toRope(if gCmd != cmdCompileToCpp: "Sup.len" else: "len")

# -------------------------- constant expressions ------------------------

proc intLiteral(i: biggestInt): PRope =
  if (i > low(int32)) and (i <= high(int32)):
    result = toRope(i)
  elif i == low(int32):
    # Nimrod has the same bug for the same reasons :-)
    result = toRope("(-2147483647 -1)")
  elif i > low(int64):
    result = ropef("IL64($1)", [toRope(i)])
  else:
    result = toRope("(IL64(-9223372036854775807) - IL64(1))")

proc int32Literal(i: Int): PRope =
  if i == int(low(int32)):
    result = toRope("(-2147483647 -1)")
  else:
    result = toRope(i)

proc genHexLiteral(v: PNode): PRope =
  # hex literals are unsigned in C
  # so we don't generate hex literals any longer.
  if not (v.kind in {nkIntLit..nkUInt64Lit}):
    internalError(v.info, "genHexLiteral")
  result = intLiteral(v.intVal)

proc getStrLit(m: BModule, s: string): PRope =
  discard cgsym(m, "TGenericSeq")
  result = con("TMP", toRope(backendId()))
  appf(m.s[cfsData], "STRING_LITERAL($1, $2, $3);$n",
       [result, makeCString(s), ToRope(len(s))])

proc genLiteral(p: BProc, v: PNode, ty: PType): PRope =
  if ty == nil: internalError(v.info, "genLiteral: ty is nil")
  case v.kind
  of nkCharLit..nkUInt64Lit:
    case skipTypes(ty, abstractVarRange).kind
    of tyChar, tyInt64, tyNil:
      result = intLiteral(v.intVal)
    of tyInt:
      if (v.intVal >= low(int32)) and (v.intVal <= high(int32)):
        result = int32Literal(int32(v.intVal))
      else:
        result = intLiteral(v.intVal)
    of tyBool:
      if v.intVal != 0: result = toRope("NIM_TRUE")
      else: result = toRope("NIM_FALSE")
    else:
      result = ropef("(($1) $2)", [getTypeDesc(p.module,
          skipTypes(ty, abstractVarRange)), intLiteral(v.intVal)])
  of nkNilLit:
    result = toRope("NIM_NIL")
  of nkStrLit..nkTripleStrLit:
    if skipTypes(ty, abstractVarRange).kind == tyString:
      var id = NodeTableTestOrSet(p.module.dataCache, v, gBackendId)
      if id == gBackendId:
        # string literal not found in the cache:
        result = ropecg(p.module, "((#NimStringDesc*) &$1)", 
                        [getStrLit(p.module, v.strVal)])
      else:
        result = ropecg(p.module, "((#NimStringDesc*) &TMP$1)", [toRope(id)])
    else:
      result = makeCString(v.strVal)
  of nkFloatLit..nkFloat64Lit:
    result = toRope(v.floatVal.ToStrMaxPrecision)
  else:
    InternalError(v.info, "genLiteral(" & $v.kind & ')')
    result = nil

proc genLiteral(p: BProc, v: PNode): PRope =
  result = genLiteral(p, v, v.typ)

proc bitSetToWord(s: TBitSet, size: int): BiggestInt =
  result = 0
  when true:
    for j in countup(0, size - 1):
      if j < len(s): result = result or `shl`(Ze64(s[j]), j * 8)
  else:
    # not needed, too complex thinking:
    if CPU[platform.hostCPU].endian == CPU[targetCPU].endian:
      for j in countup(0, size - 1):
        if j < len(s): result = result or `shl`(Ze64(s[j]), j * 8)
    else:
      for j in countup(0, size - 1):
        if j < len(s): result = result or `shl`(Ze64(s[j]), (Size - 1 - j) * 8)

proc genRawSetData(cs: TBitSet, size: int): PRope =
  var frmt: TFormatStr
  if size > 8:
    result = ropef("{$n")
    for i in countup(0, size - 1):
      if i < size - 1:
        # not last iteration?
        if (i + 1) mod 8 == 0: frmt = "0x$1,$n"
        else: frmt = "0x$1, "
      else:
        frmt = "0x$1}$n"
      appf(result, frmt, [toRope(toHex(Ze64(cs[i]), 2))])
  else:
    result = intLiteral(bitSetToWord(cs, size))
    #  result := toRope('0x' + ToHex(bitSetToWord(cs, size), size * 2))

proc genSetNode(p: BProc, n: PNode): PRope =
  var cs: TBitSet
  var size = int(getSize(n.typ))
  toBitSet(n, cs)
  if size > 8:
    var id = NodeTableTestOrSet(p.module.dataCache, n, gBackendId)
    result = con("TMP", toRope(id))
    if id == gBackendId:
      # not found in cache:
      inc(gBackendId)
      appf(p.module.s[cfsData], "static NIM_CONST $1 $2 = $3;$n",
           [getTypeDesc(p.module, n.typ), result, genRawSetData(cs, size)])
  else:
    result = genRawSetData(cs, size)

proc getStorageLoc(n: PNode): TStorageLoc =
  case n.kind
  of nkSym:
    case n.sym.kind
    of skParam, skTemp:
      result = OnStack
    of skVar, skForVar, skResult, skLet:
      if sfGlobal in n.sym.flags: result = OnHeap
      else: result = OnStack
    of skConst: 
      if sfGlobal in n.sym.flags: result = OnHeap
      else: result = OnUnknown
    else: result = OnUnknown
  of nkDerefExpr, nkHiddenDeref:
    case n.sons[0].typ.kind
    of tyVar: result = OnUnknown
    of tyPtr: result = OnStack
    of tyRef: result = OnHeap
    else: InternalError(n.info, "getStorageLoc")
  of nkBracketExpr, nkDotExpr, nkObjDownConv, nkObjUpConv:
    result = getStorageLoc(n.sons[0])
  else: result = OnUnknown

proc genRefAssign(p: BProc, dest, src: TLoc, flags: TAssignmentFlags) =
  if dest.s == OnStack or optRefcGC notin gGlobalOptions:
    lineF(p, cpsStmts, "$1 = $2;$n", [rdLoc(dest), rdLoc(src)])
    if needToKeepAlive in flags: keepAlive(p, dest)
  elif dest.s == OnHeap:
    # location is on heap
    # now the writer barrier is inlined for performance:
    #
    #    if afSrcIsNotNil in flags:
    #      UseMagic(p.module, 'nimGCref')
    #      lineF(p, cpsStmts, 'nimGCref($1);$n', [rdLoc(src)])
    #    elif afSrcIsNil notin flags:
    #      UseMagic(p.module, 'nimGCref')
    #      lineF(p, cpsStmts, 'if ($1) nimGCref($1);$n', [rdLoc(src)])
    #    if afDestIsNotNil in flags:
    #      UseMagic(p.module, 'nimGCunref')
    #      lineF(p, cpsStmts, 'nimGCunref($1);$n', [rdLoc(dest)])
    #    elif afDestIsNil notin flags:
    #      UseMagic(p.module, 'nimGCunref')
    #      lineF(p, cpsStmts, 'if ($1) nimGCunref($1);$n', [rdLoc(dest)])
    #    lineF(p, cpsStmts, '$1 = $2;$n', [rdLoc(dest), rdLoc(src)])
    if canFormAcycle(dest.t):
      lineCg(p, cpsStmts, "#asgnRef((void**) $1, $2);$n",
           [addrLoc(dest), rdLoc(src)])
    else:
      lineCg(p, cpsStmts, "#asgnRefNoCycle((void**) $1, $2);$n",
           [addrLoc(dest), rdLoc(src)])
  else:
    lineCg(p, cpsStmts, "#unsureAsgnRef((void**) $1, $2);$n",
         [addrLoc(dest), rdLoc(src)])
    if needToKeepAlive in flags: keepAlive(p, dest)

proc genGenericAsgn(p: BProc, dest, src: TLoc, flags: TAssignmentFlags) =
  # Consider: 
  # type TMyFastString {.shallow.} = string
  # Due to the implementation of pragmas this would end up to set the
  # tfShallow flag for the built-in string type too! So we check only
  # here for this flag, where it is reasonably safe to do so
  # (for objects, etc.):
  if needToCopy notin flags or 
      tfShallow in skipTypes(dest.t, abstractVarRange).flags:
    if dest.s == OnStack or optRefcGC notin gGlobalOptions:
      lineCg(p, cpsStmts,
           "memcpy((void*)$1, (NIM_CONST void*)$2, sizeof($3));$n",
           [addrLoc(dest), addrLoc(src), rdLoc(dest)])
      if needToKeepAlive in flags: keepAlive(p, dest)
    else:
      lineCg(p, cpsStmts, "#genericShallowAssign((void*)$1, (void*)$2, $3);$n",
           [addrLoc(dest), addrLoc(src), genTypeInfo(p.module, dest.t)])
  else:
    lineCg(p, cpsStmts, "#genericAssign((void*)$1, (void*)$2, $3);$n",
         [addrLoc(dest), addrLoc(src), genTypeInfo(p.module, dest.t)])

proc genAssignment(p: BProc, dest, src: TLoc, flags: TAssignmentFlags) =
  # This function replaces all other methods for generating
  # the assignment operation in C.
  if src.t != nil and src.t.kind == tyPtr:
    # little HACK to support the new 'var T' as return type:
    lineCg(p, cpsStmts, "$1 = $2;$n", [rdLoc(dest), rdLoc(src)])
    return
  var ty = skipTypes(dest.t, abstractVarRange)
  case ty.kind
  of tyRef:
    genRefAssign(p, dest, src, flags)
  of tySequence:
    if needToCopy notin flags:
      genRefAssign(p, dest, src, flags)
    else:
      lineCg(p, cpsStmts, "#genericSeqAssign($1, $2, $3);$n",
           [addrLoc(dest), rdLoc(src), genTypeInfo(p.module, dest.t)])
  of tyString:
    if needToCopy notin flags:
      genRefAssign(p, dest, src, flags)
    else:
      if dest.s == OnStack or optRefcGC notin gGlobalOptions:
        lineCg(p, cpsStmts, "$1 = #copyString($2);$n", [dest.rdLoc, src.rdLoc])
        if needToKeepAlive in flags: keepAlive(p, dest)
      elif dest.s == OnHeap:
        # we use a temporary to care for the dreaded self assignment:
        var tmp: TLoc
        getTemp(p, ty, tmp)
        lineCg(p, cpsStmts, "$3 = $1; $1 = #copyStringRC1($2);$n",
             [dest.rdLoc, src.rdLoc, tmp.rdLoc])
        lineCg(p, cpsStmts, "if ($1) #nimGCunrefNoCycle($1);$n", tmp.rdLoc)
      else:
        lineCg(p, cpsStmts, "#unsureAsgnRef((void**) $1, #copyString($2));$n",
             [addrLoc(dest), rdLoc(src)])
        if needToKeepAlive in flags: keepAlive(p, dest)
  of tyTuple, tyObject, tyProc:
    # XXX: check for subtyping?
    if needsComplexAssignment(dest.t):
      genGenericAsgn(p, dest, src, flags)
    else:
      lineCg(p, cpsStmts, "$1 = $2;$n", [rdLoc(dest), rdLoc(src)])
  of tyArray, tyArrayConstr:
    if needsComplexAssignment(dest.t):
      genGenericAsgn(p, dest, src, flags)
    else:
      lineCg(p, cpsStmts,
           "memcpy((void*)$1, (NIM_CONST void*)$2, sizeof($1));$n",
           [rdLoc(dest), rdLoc(src)])
  of tyOpenArray:
    # open arrays are always on the stack - really? What if a sequence is
    # passed to an open array?
    if needsComplexAssignment(dest.t):
      lineCg(p, cpsStmts,     # XXX: is this correct for arrays?
           "#genericAssignOpenArray((void*)$1, (void*)$2, $1Len0, $3);$n",
           [addrLoc(dest), addrLoc(src), genTypeInfo(p.module, dest.t)])
    else:
      lineCg(p, cpsStmts,
           "memcpy((void*)$1, (NIM_CONST void*)$2, sizeof($1[0])*$1Len0);$n",
           [rdLoc(dest), rdLoc(src)])
  of tySet:
    if mapType(ty) == ctArray:
      lineCg(p, cpsStmts, "memcpy((void*)$1, (NIM_CONST void*)$2, $3);$n",
           [rdLoc(dest), rdLoc(src), toRope(getSize(dest.t))])
    else:
      lineCg(p, cpsStmts, "$1 = $2;$n", [rdLoc(dest), rdLoc(src)])
  of tyPtr, tyPointer, tyChar, tyBool, tyEnum, tyCString,
     tyInt..tyUInt64, tyRange:
    lineCg(p, cpsStmts, "$1 = $2;$n", [rdLoc(dest), rdLoc(src)])
  else: InternalError("genAssignment(" & $ty.kind & ')')

proc expr(p: BProc, e: PNode, d: var TLoc)
proc initLocExpr(p: BProc, e: PNode, result: var TLoc) =
  initLoc(result, locNone, e.typ, OnUnknown)
  expr(p, e, result)

proc getDestLoc(p: BProc, d: var TLoc, typ: PType) =
  if d.k == locNone: getTemp(p, typ, d)

proc putLocIntoDest(p: BProc, d: var TLoc, s: TLoc) =
  if d.k != locNone:
    if lfNoDeepCopy in d.flags: genAssignment(p, d, s, {})
    else: genAssignment(p, d, s, {needToCopy})
  else:
    d = s # ``d`` is free, so fill it with ``s``

proc putIntoDest(p: BProc, d: var TLoc, t: PType, r: PRope) =
  var a: TLoc
  if d.k != locNone:
    # need to generate an assignment here
    initLoc(a, locExpr, getUniqueType(t), OnUnknown)
    a.r = r
    if lfNoDeepCopy in d.flags: genAssignment(p, d, a, {})
    else: genAssignment(p, d, a, {needToCopy})
  else:
    # we cannot call initLoc() here as that would overwrite
    # the flags field!
    d.k = locExpr
    d.t = getUniqueType(t)
    d.r = r
    d.a = -1

proc binaryStmt(p: BProc, e: PNode, d: var TLoc, frmt: string) =
  var b: TLoc
  if d.k != locNone: InternalError(e.info, "binaryStmt")
  InitLocExpr(p, e.sons[1], d)
  InitLocExpr(p, e.sons[2], b)
  lineCg(p, cpsStmts, frmt, [rdLoc(d), rdLoc(b)])

proc unaryStmt(p: BProc, e: PNode, d: var TLoc, frmt: string) =
  var a: TLoc
  if (d.k != locNone): InternalError(e.info, "unaryStmt")
  InitLocExpr(p, e.sons[1], a)
  lineCg(p, cpsStmts, frmt, [rdLoc(a)])

proc binaryStmtChar(p: BProc, e: PNode, d: var TLoc, frmt: string) =
  var a, b: TLoc
  if (d.k != locNone): InternalError(e.info, "binaryStmtChar")
  InitLocExpr(p, e.sons[1], a)
  InitLocExpr(p, e.sons[2], b)
  lineCg(p, cpsStmts, frmt, [rdCharLoc(a), rdCharLoc(b)])

proc binaryExpr(p: BProc, e: PNode, d: var TLoc, frmt: string) =
  var a, b: TLoc
  assert(e.sons[1].typ != nil)
  assert(e.sons[2].typ != nil)
  InitLocExpr(p, e.sons[1], a)
  InitLocExpr(p, e.sons[2], b)
  putIntoDest(p, d, e.typ, ropecg(p.module, frmt, [rdLoc(a), rdLoc(b)]))

proc binaryExprChar(p: BProc, e: PNode, d: var TLoc, frmt: string) =
  var a, b: TLoc
  assert(e.sons[1].typ != nil)
  assert(e.sons[2].typ != nil)
  InitLocExpr(p, e.sons[1], a)
  InitLocExpr(p, e.sons[2], b)
  putIntoDest(p, d, e.typ, ropecg(p.module, frmt, [a.rdCharLoc, b.rdCharLoc]))

proc unaryExpr(p: BProc, e: PNode, d: var TLoc, frmt: string) =
  var a: TLoc
  InitLocExpr(p, e.sons[1], a)
  putIntoDest(p, d, e.typ, ropecg(p.module, frmt, [rdLoc(a)]))

proc unaryExprChar(p: BProc, e: PNode, d: var TLoc, frmt: string) =
  var a: TLoc
  InitLocExpr(p, e.sons[1], a)
  putIntoDest(p, d, e.typ, ropecg(p.module, frmt, [rdCharLoc(a)]))

proc binaryArithOverflow(p: BProc, e: PNode, d: var TLoc, m: TMagic) =
  const
    prc: array[mAddi..mModi64, string] = ["addInt", "subInt", "mulInt",
      "divInt", "modInt", "addInt64", "subInt64", "mulInt64", "divInt64",
      "modInt64"]
    opr: array[mAddi..mModi64, string] = ["+", "-", "*", "/", "%", "+", "-",
      "*", "/", "%"]
  var a, b: TLoc
  assert(e.sons[1].typ != nil)
  assert(e.sons[2].typ != nil)
  InitLocExpr(p, e.sons[1], a)
  InitLocExpr(p, e.sons[2], b)
  var t = skipTypes(e.typ, abstractRange)
  if optOverflowCheck notin p.options:
    putIntoDest(p, d, e.typ, ropef("(NI$4)($2 $1 $3)", [toRope(opr[m]),
        rdLoc(a), rdLoc(b), toRope(getSize(t) * 8)]))
  else:
    var storage: PRope
    var size = getSize(t)
    if size < platform.IntSize:
      storage = toRope("NI") 
    else:
      storage = getTypeDesc(p.module, t)
    var tmp = getTempName()
    lineCg(p, cpsLocals, "$1 $2;$n", [storage, tmp])
    lineCg(p, cpsStmts, "$1 = #$2($3, $4);$n", [tmp, toRope(prc[m]), 
                                             rdLoc(a), rdLoc(b)])
    if size < platform.IntSize or t.kind in {tyRange, tyEnum, tySet}:
      lineCg(p, cpsStmts, "if ($1 < $2 || $1 > $3) #raiseOverflow();$n",
           [tmp, intLiteral(firstOrd(t)), intLiteral(lastOrd(t))])
    putIntoDest(p, d, e.typ, ropef("(NI$1)($2)", [toRope(getSize(t)*8), tmp]))

proc unaryArithOverflow(p: BProc, e: PNode, d: var TLoc, m: TMagic) =
  const
    opr: array[mUnaryMinusI..mAbsI64, string] = [
      mUnaryMinusI: "((NI$2)-($1))",
      mUnaryMinusI64: "-($1)",
      mAbsI: "(NI$2)abs($1)",
      mAbsI64: "($1 > 0? ($1) : -($1))"]
  var
    a: TLoc
    t: PType
  assert(e.sons[1].typ != nil)
  InitLocExpr(p, e.sons[1], a)
  t = skipTypes(e.typ, abstractRange)
  if optOverflowCheck in p.options:
    lineCg(p, cpsStmts, "if ($1 == $2) #raiseOverflow();$n",
         [rdLoc(a), intLiteral(firstOrd(t))])
  putIntoDest(p, d, e.typ, ropef(opr[m], [rdLoc(a), toRope(getSize(t) * 8)]))

proc binaryArith(p: BProc, e: PNode, d: var TLoc, op: TMagic) =
  const
    binArithTab: array[mAddF64..mXor, string] = [
      "($1 + $2)",            # AddF64
      "($1 - $2)",            # SubF64
      "($1 * $2)",            # MulF64
      "($1 / $2)",            # DivF64
      "($4)((NU$3)($1) >> (NU$3)($2))", # ShrI
      "($4)((NU$3)($1) << (NU$3)($2))", # ShlI
      "($4)($1 & $2)",      # BitandI
      "($4)($1 | $2)",      # BitorI
      "($4)($1 ^ $2)",      # BitxorI
      "(($1 <= $2) ? $1 : $2)", # MinI
      "(($1 >= $2) ? $1 : $2)", # MaxI
      "($4)((NU64)($1) >> (NU64)($2))", # ShrI64
      "($4)((NU64)($1) << (NU64)($2))", # ShlI64
      "($4)($1 & $2)",            # BitandI64
      "($4)($1 | $2)",            # BitorI64
      "($4)($1 ^ $2)",            # BitxorI64
      "(($1 <= $2) ? $1 : $2)", # MinI64
      "(($1 >= $2) ? $1 : $2)", # MaxI64
      "(($1 <= $2) ? $1 : $2)", # MinF64
      "(($1 >= $2) ? $1 : $2)", # MaxF64
      "($4)((NU$3)($1) + (NU$3)($2))", # AddU
      "($4)((NU$3)($1) - (NU$3)($2))", # SubU
      "($4)((NU$3)($1) * (NU$3)($2))", # MulU
      "($4)((NU$3)($1) / (NU$3)($2))", # DivU
      "($4)((NU$3)($1) % (NU$3)($2))", # ModU
      "($4)((NU64)($1) + (NU64)($2))", # AddU64
      "($4)((NU64)($1) - (NU64)($2))", # SubU64
      "($4)((NU64)($1) * (NU64)($2))", # MulU64
      "($4)((NU64)($1) / (NU64)($2))", # DivU64
      "($4)((NU64)($1) % (NU64)($2))", # ModU64
      "($1 == $2)",           # EqI
      "($1 <= $2)",           # LeI
      "($1 < $2)",            # LtI
      "($1 == $2)",           # EqI64
      "($1 <= $2)",           # LeI64
      "($1 < $2)",            # LtI64
      "($1 == $2)",           # EqF64
      "($1 <= $2)",           # LeF64
      "($1 < $2)",            # LtF64
      "((NU$3)($1) <= (NU$3)($2))", # LeU
      "((NU$3)($1) < (NU$3)($2))", # LtU
      "((NU64)($1) <= (NU64)($2))", # LeU64
      "((NU64)($1) < (NU64)($2))", # LtU64
      "($1 == $2)",           # EqEnum
      "($1 <= $2)",           # LeEnum
      "($1 < $2)",            # LtEnum
      "((NU8)($1) == (NU8)($2))", # EqCh
      "((NU8)($1) <= (NU8)($2))", # LeCh
      "((NU8)($1) < (NU8)($2))", # LtCh
      "($1 == $2)",           # EqB
      "($1 <= $2)",           # LeB
      "($1 < $2)",            # LtB
      "($1 == $2)",           # EqRef
      "($1 == $2)",           # EqProc
      "($1 == $2)",           # EqPtr
      "($1 <= $2)",           # LePtr
      "($1 < $2)",            # LtPtr
      "($1 == $2)",           # EqCString
      "($1 != $2)"]           # Xor
  var
    a, b: TLoc
    s: biggestInt
  assert(e.sons[1].typ != nil)
  assert(e.sons[2].typ != nil)
  InitLocExpr(p, e.sons[1], a)
  InitLocExpr(p, e.sons[2], b)
  # BUGFIX: cannot use result-type here, as it may be a boolean
  s = max(getSize(a.t), getSize(b.t)) * 8
  putIntoDest(p, d, e.typ,
              ropef(binArithTab[op], [rdLoc(a), rdLoc(b), toRope(s),
                                      getSimpleTypeDesc(p.module, e.typ)]))

proc unaryArith(p: BProc, e: PNode, d: var TLoc, op: TMagic) =
  const
    unArithTab: array[mNot..mToBiggestInt, string] = ["!($1)", # Not
      "$1",                   # UnaryPlusI
      "($3)((NU$2) ~($1))",   # BitnotI
      "$1",                   # UnaryPlusI64
      "($3)((NU$2) ~($1))",   # BitnotI64
      "$1",                   # UnaryPlusF64
      "-($1)",                # UnaryMinusF64
      "($1 > 0? ($1) : -($1))", # AbsF64; BUGFIX: fabs() makes problems
                                # for Tiny C, so we don't use it
      "(($3)(NU)(NU8)($1))",  # mZe8ToI
      "(($3)(NU64)(NU8)($1))", # mZe8ToI64
      "(($3)(NU)(NU16)($1))", # mZe16ToI
      "(($3)(NU64)(NU16)($1))", # mZe16ToI64
      "(($3)(NU64)(NU32)($1))", # mZe32ToI64
      "(($3)(NU64)(NU)($1))", # mZeIToI64
      "(($3)(NU8)(NU)($1))", # ToU8
      "(($3)(NU16)(NU)($1))", # ToU16
      "(($3)(NU32)(NU64)($1))", # ToU32
      "((double) ($1))",      # ToFloat
      "((double) ($1))",      # ToBiggestFloat
      "float64ToInt32($1)",   # ToInt XXX: this is not correct!
      "float64ToInt64($1)"]   # ToBiggestInt
  var
    a: TLoc
    t: PType
  assert(e.sons[1].typ != nil)
  InitLocExpr(p, e.sons[1], a)
  t = skipTypes(e.typ, abstractRange)
  putIntoDest(p, d, e.typ,
              ropef(unArithTab[op], [rdLoc(a), toRope(getSize(t) * 8),
                    getSimpleTypeDesc(p.module, e.typ)]))

proc genDeref(p: BProc, e: PNode, d: var TLoc) =
  var a: TLoc
  if mapType(e.sons[0].typ) == ctArray:
    # XXX the amount of hacks for C's arrays is incredible, maybe we should
    # simply wrap them in a struct? --> Losing auto vectorization then?
    expr(p, e.sons[0], d)
  else:
    initLocExpr(p, e.sons[0], a)
    case skipTypes(a.t, abstractInst).kind
    of tyRef:
      d.s = OnHeap
    of tyVar:
      d.s = OnUnknown
    of tyPtr:
      d.s = OnUnknown         # BUGFIX!
    else: InternalError(e.info, "genDeref " & $a.t.kind)
    putIntoDest(p, d, a.t.sons[0], ropef("(*$1)", [rdLoc(a)]))

proc genAddr(p: BProc, e: PNode, d: var TLoc) =
  var a: TLoc
  if mapType(e.sons[0].typ) == ctArray:
    expr(p, e.sons[0], d)
  else:
    InitLocExpr(p, e.sons[0], a)
    putIntoDest(p, d, e.typ, addrLoc(a))

proc genRecordFieldAux(p: BProc, e: PNode, d, a: var TLoc): PType =
  initLocExpr(p, e.sons[0], a)
  if e.sons[1].kind != nkSym: InternalError(e.info, "genRecordFieldAux")
  if d.k == locNone: d.s = a.s
  discard getTypeDesc(p.module, a.t) # fill the record's fields.loc
  result = a.t

proc genRecordField(p: BProc, e: PNode, d: var TLoc) =
  var a: TLoc
  var ty = genRecordFieldAux(p, e, d, a)
  var r = rdLoc(a)
  var f = e.sons[1].sym
  if ty.kind == tyTuple:
    # we found a unique tuple type which lacks field information
    # so we use Field$i
    appf(r, ".Field$1", [toRope(f.position)])
    putIntoDest(p, d, f.typ, r)
  else:
    var field: PSym = nil
    while ty != nil:
      if ty.kind notin {tyTuple, tyObject}:
        InternalError(e.info, "genRecordField")
      field = lookupInRecord(ty.n, f.name)
      if field != nil: break
      if gCmd != cmdCompileToCpp: app(r, ".Sup")
      ty = GetUniqueType(ty.sons[0])
    if field == nil: InternalError(e.info, "genRecordField 2 ")
    if field.loc.r == nil: InternalError(e.info, "genRecordField 3")
    appf(r, ".$1", [field.loc.r])
    putIntoDest(p, d, field.typ, r)

proc genTupleElem(p: BProc, e: PNode, d: var TLoc) =
  var
    a: TLoc
    i: int
  initLocExpr(p, e.sons[0], a)
  if d.k == locNone: d.s = a.s
  discard getTypeDesc(p.module, a.t) # fill the record's fields.loc
  var ty = a.t
  var r = rdLoc(a)
  case e.sons[1].kind
  of nkIntLit..nkUInt64Lit: i = int(e.sons[1].intVal)
  else: internalError(e.info, "genTupleElem")
  when false:
    if ty.n != nil:
      var field = ty.n.sons[i].sym
      if field == nil: InternalError(e.info, "genTupleElem")
      if field.loc.r == nil: InternalError(e.info, "genTupleElem")
      appf(r, ".$1", [field.loc.r])
  else:
    appf(r, ".Field$1", [toRope(i)])
  putIntoDest(p, d, ty.sons[i], r)

proc genInExprAux(p: BProc, e: PNode, a, b, d: var TLoc)
proc genCheckedRecordField(p: BProc, e: PNode, d: var TLoc) =
  var
    a, u, v, test: TLoc
    f, field, op: PSym
    ty: PType
    r, strLit: PRope
    id: int
    it: PNode
  if optFieldCheck in p.options:
    ty = genRecordFieldAux(p, e.sons[0], d, a)
    r = rdLoc(a)
    f = e.sons[0].sons[1].sym
    field = nil
    while ty != nil:
      assert(ty.kind in {tyTuple, tyObject})
      field = lookupInRecord(ty.n, f.name)
      if field != nil: break
      if gCmd != cmdCompileToCpp: app(r, ".Sup")
      ty = getUniqueType(ty.sons[0])
    if field == nil: InternalError(e.info, "genCheckedRecordField")
    if field.loc.r == nil:
      InternalError(e.info, "genCheckedRecordField") # generate the checks:
    for i in countup(1, sonsLen(e) - 1):
      it = e.sons[i]
      assert(it.kind in nkCallKinds)
      assert(it.sons[0].kind == nkSym)
      op = it.sons[0].sym
      if op.magic == mNot: it = it.sons[1]
      assert(it.sons[2].kind == nkSym)
      initLoc(test, locNone, it.typ, OnStack)
      InitLocExpr(p, it.sons[1], u)
      initLoc(v, locExpr, it.sons[2].typ, OnUnknown)
      v.r = ropef("$1.$2", [r, it.sons[2].sym.loc.r])
      genInExprAux(p, it, u, v, test)
      id = NodeTableTestOrSet(p.module.dataCache,
                              newStrNode(nkStrLit, field.name.s), gBackendId)
      if id == gBackendId: strLit = getStrLit(p.module, field.name.s)
      else: strLit = con("TMP", toRope(id))
      if op.magic == mNot:
        lineCg(p, cpsStmts,
             "if ($1) #raiseFieldError(((#NimStringDesc*) &$2));$n",
             [rdLoc(test), strLit])
      else:
        lineCg(p, cpsStmts,
             "if (!($1)) #raiseFieldError(((#NimStringDesc*) &$2));$n",
             [rdLoc(test), strLit])
    appf(r, ".$1", [field.loc.r])
    putIntoDest(p, d, field.typ, r)
  else:
    genRecordField(p, e.sons[0], d)

proc genArrayElem(p: BProc, e: PNode, d: var TLoc) =
  var a, b: TLoc
  initLocExpr(p, e.sons[0], a)
  initLocExpr(p, e.sons[1], b)
  var ty = skipTypes(skipTypes(a.t, abstractVarRange), abstractPtrs)
  var first = intLiteral(firstOrd(ty))
  # emit range check:
  if (optBoundsCheck in p.options):
    if not isConstExpr(e.sons[1]):
      # semantic pass has already checked for const index expressions
      if firstOrd(ty) == 0:
        if (firstOrd(b.t) < firstOrd(ty)) or (lastOrd(b.t) > lastOrd(ty)):
          lineCg(p, cpsStmts, "if ((NU)($1) > (NU)($2)) #raiseIndexError();$n",
               [rdCharLoc(b), intLiteral(lastOrd(ty))])
      else:
        lineCg(p, cpsStmts, "if ($1 < $2 || $1 > $3) #raiseIndexError();$n",
             [rdCharLoc(b), first, intLiteral(lastOrd(ty))])
  if d.k == locNone: d.s = a.s
  putIntoDest(p, d, elemType(skipTypes(ty, abstractVar)),
              ropef("$1[($2)- $3]", [rdLoc(a), rdCharLoc(b), first]))

proc genCStringElem(p: BProc, e: PNode, d: var TLoc) =
  var a, b: TLoc
  initLocExpr(p, e.sons[0], a)
  initLocExpr(p, e.sons[1], b)
  var ty = skipTypes(a.t, abstractVarRange)
  if d.k == locNone: d.s = a.s
  putIntoDest(p, d, elemType(skipTypes(ty, abstractVar)),
              ropef("$1[$2]", [rdLoc(a), rdCharLoc(b)]))

proc genOpenArrayElem(p: BProc, e: PNode, d: var TLoc) =
  var a, b: TLoc
  initLocExpr(p, e.sons[0], a)
  initLocExpr(p, e.sons[1], b) # emit range check:
  if optBoundsCheck in p.options:
    lineCg(p, cpsStmts, "if ((NU)($1) >= (NU)($2Len0)) #raiseIndexError();$n",
         [rdLoc(b), rdLoc(a)]) # BUGFIX: ``>=`` and not ``>``!
  if d.k == locNone: d.s = a.s
  putIntoDest(p, d, elemType(skipTypes(a.t, abstractVar)),
              ropef("$1[$2]", [rdLoc(a), rdCharLoc(b)]))

proc genSeqElem(p: BPRoc, e: PNode, d: var TLoc) =
  var a, b: TLoc
  initLocExpr(p, e.sons[0], a)
  initLocExpr(p, e.sons[1], b)
  var ty = skipTypes(a.t, abstractVarRange)
  if ty.kind in {tyRef, tyPtr}:
    ty = skipTypes(ty.sons[0], abstractVarRange) # emit range check:
  if optBoundsCheck in p.options:
    if ty.kind == tyString:
      lineCg(p, cpsStmts,
           "if ((NU)($1) > (NU)($2->$3)) #raiseIndexError();$n",
           [rdLoc(b), rdLoc(a), lenField()])
    else:
      lineCg(p, cpsStmts,
           "if ((NU)($1) >= (NU)($2->$3)) #raiseIndexError();$n",
           [rdLoc(b), rdLoc(a), lenField()])
  if d.k == locNone: d.s = OnHeap
  if skipTypes(a.t, abstractVar).kind in {tyRef, tyPtr}:
    a.r = ropef("(*$1)", [a.r])
  putIntoDest(p, d, elemType(skipTypes(a.t, abstractVar)),
              ropef("$1->data[$2]", [rdLoc(a), rdCharLoc(b)]))

proc genAndOr(p: BProc, e: PNode, d: var TLoc, m: TMagic) =
  # how to generate code?
  #  'expr1 and expr2' becomes:
  #     result = expr1
  #     fjmp result, end
  #     result = expr2
  #  end:
  #  ... (result computed)
  # BUGFIX:
  #   a = b or a
  # used to generate:
  # a = b
  # if a: goto end
  # a = a
  # end:
  # now it generates:
  # tmp = b
  # if tmp: goto end
  # tmp = a
  # end:
  # a = tmp
  var
    L: TLabel
    tmp: TLoc
  getTemp(p, e.typ, tmp)      # force it into a temp!
  expr(p, e.sons[1], tmp)
  L = getLabel(p)
  if m == mOr:
    lineF(p, cpsStmts, "if ($1) goto $2;$n", [rdLoc(tmp), L])
  else:
    lineF(p, cpsStmts, "if (!($1)) goto $2;$n", [rdLoc(tmp), L])
  expr(p, e.sons[2], tmp)
  fixLabel(p, L)
  if d.k == locNone:
    d = tmp
  else:
    genAssignment(p, d, tmp, {}) # no need for deep copying

proc genIfExpr(p: BProc, n: PNode, d: var TLoc) =
  #
  #  if (!expr1) goto L1;
  #  thenPart
  #  goto LEnd
  #  L1:
  #  if (!expr2) goto L2;
  #  thenPart2
  #  goto LEnd
  #  L2:
  #  elsePart
  #  Lend:
  #
  var
    it: PNode
    a, tmp: TLoc
    Lend, Lelse: TLabel
  getTemp(p, n.typ, tmp)      # force it into a temp!
  Lend = getLabel(p)
  for i in countup(0, sonsLen(n) - 1):
    it = n.sons[i]
    case it.kind
    of nkElifExpr:
      initLocExpr(p, it.sons[0], a)
      Lelse = getLabel(p)
      lineF(p, cpsStmts, "if (!$1) goto $2;$n", [rdLoc(a), Lelse])
      expr(p, it.sons[1], tmp)
      lineF(p, cpsStmts, "goto $1;$n", [Lend])
      fixLabel(p, Lelse)
    of nkElseExpr:
      expr(p, it.sons[0], tmp)
    else: internalError(n.info, "genIfExpr()")
  fixLabel(p, Lend)
  if d.k == locNone:
    d = tmp
  else:
    genAssignment(p, d, tmp, {}) # no need for deep copying

proc genEcho(p: BProc, n: PNode) =
  # this unusal way of implementing it ensures that e.g. ``echo("hallo", 45)``
  # is threadsafe.
  var args: PRope = nil
  var a: TLoc
  for i in countup(1, n.len-1):
    initLocExpr(p, n.sons[i], a)
    appf(args, ", ($1)->data", [rdLoc(a)])
  lineCg(p, cpsStmts, "printf($1$2);$n", [
    makeCString(repeatStr(n.len-1, "%s") & tnl), args])

include ccgcalls

proc genStrConcat(p: BProc, e: PNode, d: var TLoc) =
  #   <Nimrod code>
  #   s = 'Hello ' & name & ', how do you feel?' & 'z'
  #
  #   <generated C code>
  #  {
  #    string tmp0;
  #    ...
  #    tmp0 = rawNewString(6 + 17 + 1 + s2->len);
  #    // we cannot generate s = rawNewString(...) here, because
  #    // ``s`` may be used on the right side of the expression
  #    appendString(tmp0, strlit_1);
  #    appendString(tmp0, name);
  #    appendString(tmp0, strlit_2);
  #    appendChar(tmp0, 'z');
  #    asgn(s, tmp0);
  #  }
  var a, tmp: TLoc
  getTemp(p, e.typ, tmp)
  var L = 0
  var appends: PRope = nil
  var lens: PRope = nil
  for i in countup(0, sonsLen(e) - 2):
    # compute the length expression:
    initLocExpr(p, e.sons[i + 1], a)
    if skipTypes(e.sons[i + 1].Typ, abstractVarRange).kind == tyChar:
      Inc(L)
      appLineCg(p, appends, "#appendChar($1, $2);$n", [tmp.r, rdLoc(a)])
    else:
      if e.sons[i + 1].kind in {nkStrLit..nkTripleStrLit}:
        Inc(L, len(e.sons[i + 1].strVal))
      else:
        appf(lens, "$1->$2 + ", [rdLoc(a), lenField()])
      appLineCg(p, appends, "#appendString($1, $2);$n", [tmp.r, rdLoc(a)])
  lineCg(p, cpsStmts, "$1 = #rawNewString($2$3);$n", [tmp.r, lens, toRope(L)])
  app(p.s(cpsStmts), appends)
  if d.k == locNone:
    d = tmp
    keepAlive(p, tmp)
  else:
    genAssignment(p, d, tmp, {needToKeepAlive}) # no need for deep copying

proc genStrAppend(p: BProc, e: PNode, d: var TLoc) =
  #  <Nimrod code>
  #  s &= 'Hello ' & name & ', how do you feel?' & 'z'
  #  // BUG: what if s is on the left side too?
  #  <generated C code>
  #  {
  #    s = resizeString(s, 6 + 17 + 1 + name->len);
  #    appendString(s, strlit_1);
  #    appendString(s, name);
  #    appendString(s, strlit_2);
  #    appendChar(s, 'z');
  #  }
  var
    a, dest: TLoc
    appends, lens: PRope
  assert(d.k == locNone)
  var L = 0
  initLocExpr(p, e.sons[1], dest)
  for i in countup(0, sonsLen(e) - 3):
    # compute the length expression:
    initLocExpr(p, e.sons[i + 2], a)
    if skipTypes(e.sons[i + 2].Typ, abstractVarRange).kind == tyChar:
      Inc(L)
      appLineCg(p, appends, "#appendChar($1, $2);$n",
            [rdLoc(dest), rdLoc(a)])
    else:
      if e.sons[i + 2].kind in {nkStrLit..nkTripleStrLit}:
        Inc(L, len(e.sons[i + 2].strVal))
      else:
        appf(lens, "$1->$2 + ", [rdLoc(a), lenField()])
      appLineCg(p, appends, "#appendString($1, $2);$n",
            [rdLoc(dest), rdLoc(a)])
  lineCg(p, cpsStmts, "$1 = #resizeString($1, $2$3);$n",
       [rdLoc(dest), lens, toRope(L)])
  keepAlive(p, dest)
  app(p.s(cpsStmts), appends)

proc genSeqElemAppend(p: BProc, e: PNode, d: var TLoc) =
  # seq &= x  -->
  #    seq = (typeof seq) incrSeq(&seq->Sup, sizeof(x));
  #    seq->data[seq->len-1] = x;
  let seqAppendPattern = if gCmd != cmdCompileToCpp:
      "$1 = ($2) #incrSeq(&($1)->Sup, sizeof($3));$n"
    else:
      "$1 = ($2) #incrSeq($1, sizeof($3));$n"

  var a, b, dest: TLoc
  InitLocExpr(p, e.sons[1], a)
  InitLocExpr(p, e.sons[2], b)
  lineCg(p, cpsStmts, seqAppendPattern, [
      rdLoc(a),
      getTypeDesc(p.module, skipTypes(e.sons[1].typ, abstractVar)),
      getTypeDesc(p.module, skipTypes(e.sons[2].Typ, abstractVar))])
  keepAlive(p, a)
  initLoc(dest, locExpr, b.t, OnHeap)
  dest.r = ropef("$1->data[$1->$2-1]", [rdLoc(a), lenField()])
  genAssignment(p, dest, b, {needToCopy, afDestIsNil})

proc genReset(p: BProc, n: PNode) = 
  var a: TLoc
  InitLocExpr(p, n.sons[1], a)
  lineCg(p, cpsStmts, "#genericReset((void*)$1, $2);$n", 
       [addrLoc(a), genTypeInfo(p.module, skipTypes(a.t, abstractVarRange))])

proc genNew(p: BProc, e: PNode) =
  var
    a, b: TLoc
    reftype, bt: PType
  refType = skipTypes(e.sons[1].typ, abstractVarRange)
  InitLocExpr(p, e.sons[1], a)
  initLoc(b, locExpr, a.t, OnHeap)
  let args = [getTypeDesc(p.module, reftype),
              genTypeInfo(p.module, refType),
              getTypeDesc(p.module, skipTypes(reftype.sons[0], abstractRange))]
  if a.s == OnHeap and optRefcGc in gGlobalOptions:
    # use newObjRC1 as an optimization; and we don't need 'keepAlive' either
    if canFormAcycle(a.t):
      lineCg(p, cpsStmts, "if ($1) #nimGCunref($1);$n", a.rdLoc)
    else:
      lineCg(p, cpsStmts, "if ($1) #nimGCunrefNoCycle($1);$n", a.rdLoc)
    b.r = ropecg(p.module, "($1) #newObjRC1($2, sizeof($3))", args)
    lineCg(p, cpsStmts, "$1 = $2;$n", a.rdLoc, b.rdLoc)
  else:
    b.r = ropecg(p.module, "($1) #newObj($2, sizeof($3))", args)
    genAssignment(p, a, b, {needToKeepAlive})  # set the object type:
  bt = skipTypes(refType.sons[0], abstractRange)
  genObjectInit(p, cpsStmts, bt, a, false)

proc genNewSeqAux(p: BProc, dest: TLoc, length: PRope) =
  let seqtype = skipTypes(dest.t, abstractVarRange)
  let args = [getTypeDesc(p.module, seqtype),
              genTypeInfo(p.module, seqType), length]
  var call: TLoc
  initLoc(call, locExpr, dest.t, OnHeap)
  if dest.s == OnHeap and optRefcGc in gGlobalOptions:
    lineCg(p, cpsStmts, "if ($1) #nimGCunrefNoCycle($1);$n", dest.rdLoc)
    call.r = ropecg(p.module, "($1) #newSeqRC1($2, $3)", args)
    lineCg(p, cpsStmts, "$1 = $2;$n", dest.rdLoc, call.rdLoc)
  else:
    call.r = ropecg(p.module, "($1) #newSeq($2, $3)", args)
    genAssignment(p, dest, call, {needToKeepAlive})
  
proc genNewSeq(p: BProc, e: PNode) =
  var a, b: TLoc
  InitLocExpr(p, e.sons[1], a)
  InitLocExpr(p, e.sons[2], b)
  genNewSeqAux(p, a, b.rdLoc)
  
proc genSeqConstr(p: BProc, t: PNode, d: var TLoc) =
  var arr: TLoc
  if d.k == locNone:
    getTemp(p, t.typ, d)
  # generate call to newSeq before adding the elements per hand:
  genNewSeqAux(p, d, intLiteral(sonsLen(t)))
  for i in countup(0, sonsLen(t) - 1):
    initLoc(arr, locExpr, elemType(skipTypes(t.typ, abstractInst)), OnHeap)
    arr.r = ropef("$1->data[$2]", [rdLoc(d), intLiteral(i)])
    arr.s = OnHeap            # we know that sequences are on the heap
    expr(p, t.sons[i], arr)

proc genArrToSeq(p: BProc, t: PNode, d: var TLoc) =
  var elem, a, arr: TLoc
  if t.kind == nkBracket:
    t.sons[1].typ = t.typ
    genSeqConstr(p, t.sons[1], d)
    return
  if d.k == locNone:
    getTemp(p, t.typ, d)
  # generate call to newSeq before adding the elements per hand:
  var L = int(lengthOrd(t.sons[1].typ))
  
  genNewSeqAux(p, d, intLiteral(L))
  initLocExpr(p, t.sons[1], a)
  for i in countup(0, L - 1):
    initLoc(elem, locExpr, elemType(skipTypes(t.typ, abstractInst)), OnHeap)
    elem.r = ropef("$1->data[$2]", [rdLoc(d), intLiteral(i)])
    elem.s = OnHeap # we know that sequences are on the heap
    initLoc(arr, locExpr, elemType(skipTypes(t.sons[1].typ, abstractInst)), a.s)
    arr.r = ropef("$1[$2]", [rdLoc(a), intLiteral(i)])
    genAssignment(p, elem, arr, {afDestIsNil, needToCopy})
  
proc genNewFinalize(p: BProc, e: PNode) =
  var
    a, b, f: TLoc
    refType, bt: PType
    ti: PRope
    oldModule: BModule
  refType = skipTypes(e.sons[1].typ, abstractVarRange)
  InitLocExpr(p, e.sons[1], a)
  # This is a little hack:
  # XXX this is also a bug, if the finalizer expression produces side-effects
  oldModule = p.module
  p.module = gNimDat
  InitLocExpr(p, e.sons[2], f)
  p.module = oldModule
  initLoc(b, locExpr, a.t, OnHeap)
  ti = genTypeInfo(p.module, refType)
  appf(gNimDat.s[cfsTypeInit3], "$1->finalizer = (void*)$2;$n", [ti, rdLoc(f)])
  b.r = ropecg(p.module, "($1) #newObj($2, sizeof($3))", [
      getTypeDesc(p.module, refType),
      ti, getTypeDesc(p.module, skipTypes(reftype.sons[0], abstractRange))])
  genAssignment(p, a, b, {needToKeepAlive})  # set the object type:
  bt = skipTypes(refType.sons[0], abstractRange)
  genObjectInit(p, cpsStmts, bt, a, false)

proc genOf(p: BProc, x: PNode, typ: PType, d: var TLoc) =
  var a: TLoc
  initLocExpr(p, x, a)
  var dest = skipTypes(typ, abstractPtrs)
  var r = rdLoc(a)
  var nilCheck: PRope = nil
  var t = skipTypes(a.t, abstractInst)
  while t.kind in {tyVar, tyPtr, tyRef}:
    if t.kind != tyVar: nilCheck = r
    r = ropef("(*$1)", [r])
    t = skipTypes(t.sons[0], abstractInst)
  if gCmd != cmdCompileToCpp:
    while (t.kind == tyObject) and (t.sons[0] != nil):
      app(r, ".Sup")
      t = skipTypes(t.sons[0], abstractInst)
  if nilCheck != nil:
    r = ropecg(p.module, "(($1) && #isObj($2.m_type, $3))",
              [nilCheck, r, genTypeInfo(p.module, dest)])
  else:
    r = ropecg(p.module, "#isObj($1.m_type, $2)", 
              [r, genTypeInfo(p.module, dest)])
  putIntoDest(p, d, getSysType(tyBool), r)

proc genOf(p: BProc, n: PNode, d: var TLoc) =
  genOf(p, n.sons[1], n.sons[2].typ, d)

proc genRepr(p: BProc, e: PNode, d: var TLoc) =
  # XXX we don't generate keep alive info for now here
  var a: TLoc
  InitLocExpr(p, e.sons[1], a)
  var t = skipTypes(e.sons[1].typ, abstractVarRange)
  case t.kind
  of tyInt..tyInt64, tyUInt..tyUInt64:
    putIntoDest(p, d, e.typ, 
                ropecg(p.module, "#reprInt((NI64)$1)", [rdLoc(a)]))
  of tyFloat..tyFloat128:
    putIntoDest(p, d, e.typ, ropecg(p.module, "#reprFloat($1)", [rdLoc(a)]))
  of tyBool:
    putIntoDest(p, d, e.typ, ropecg(p.module, "#reprBool($1)", [rdLoc(a)]))
  of tyChar:
    putIntoDest(p, d, e.typ, ropecg(p.module, "#reprChar($1)", [rdLoc(a)]))
  of tyEnum, tyOrdinal:
    putIntoDest(p, d, e.typ,
                ropecg(p.module, "#reprEnum($1, $2)", [
                rdLoc(a), genTypeInfo(p.module, t)]))
  of tyString:
    putIntoDest(p, d, e.typ, ropecg(p.module, "#reprStr($1)", [rdLoc(a)]))
  of tySet:
    putIntoDest(p, d, e.typ, ropecg(p.module, "#reprSet($1, $2)", [
                addrLoc(a), genTypeInfo(p.module, t)]))
  of tyOpenArray:
    var b: TLoc
    case a.t.kind
    of tyOpenArray:
      putIntoDest(p, b, e.typ, ropef("$1, $1Len0", [rdLoc(a)]))
    of tyString, tySequence:
      putIntoDest(p, b, e.typ, 
                  ropef("$1->data, $1->$2", [rdLoc(a), lenField()]))
    of tyArray, tyArrayConstr:
      putIntoDest(p, b, e.typ,
                  ropef("$1, $2", [rdLoc(a), toRope(lengthOrd(a.t))]))
    else: InternalError(e.sons[0].info, "genRepr()")
    putIntoDest(p, d, e.typ, 
        ropecg(p.module, "#reprOpenArray($1, $2)", [rdLoc(b),
        genTypeInfo(p.module, elemType(t))]))
  of tyCString, tyArray, tyArrayConstr, tyRef, tyPtr, tyPointer, tyNil,
     tySequence:
    putIntoDest(p, d, e.typ,
                ropecg(p.module, "#reprAny($1, $2)", [
                rdLoc(a), genTypeInfo(p.module, t)]))
  else:
    putIntoDest(p, d, e.typ, ropecg(p.module, "#reprAny($1, $2)",
                                   [addrLoc(a), genTypeInfo(p.module, t)]))

proc genGetTypeInfo(p: BProc, e: PNode, d: var TLoc) =
  var t = skipTypes(e.sons[1].typ, abstractVarRange)
  putIntoDest(p, d, e.typ, genTypeInfo(p.module, t))

proc genDollar(p: BProc, n: PNode, d: var TLoc, frmt: string) =
  var a: TLoc
  InitLocExpr(p, n.sons[1], a)
  a.r = ropecg(p.module, frmt, [rdLoc(a)])
  if d.k == locNone: getTemp(p, n.typ, d)
  genAssignment(p, d, a, {needToKeepAlive})

proc genArrayLen(p: BProc, e: PNode, d: var TLoc, op: TMagic) =
  var a = e.sons[1]
  if a.kind == nkHiddenAddr: a = a.sons[0]
  var typ = skipTypes(a.Typ, abstractVar)
  case typ.kind
  of tyOpenArray:
    if op == mHigh: unaryExpr(p, e, d, "($1Len0-1)")
    else: unaryExpr(p, e, d, "$1Len0")
  of tyCstring:
    if op == mHigh: unaryExpr(p, e, d, "(strlen($1)-1)")
    else: unaryExpr(p, e, d, "strlen($1)")
  of tyString, tySequence:
    if gCmd != cmdCompileToCpp:
      if op == mHigh: unaryExpr(p, e, d, "($1->Sup.len-1)")
      else: unaryExpr(p, e, d, "$1->Sup.len")
    else:
      if op == mHigh: unaryExpr(p, e, d, "($1->len-1)")
      else: unaryExpr(p, e, d, "$1->len")
  of tyArray, tyArrayConstr:
    # YYY: length(sideeffect) is optimized away incorrectly?
    if op == mHigh: putIntoDest(p, d, e.typ, toRope(lastOrd(Typ)))
    else: putIntoDest(p, d, e.typ, toRope(lengthOrd(typ)))
  else: InternalError(e.info, "genArrayLen()")

proc genSetLengthSeq(p: BProc, e: PNode, d: var TLoc) =
  var a, b: TLoc
  assert(d.k == locNone)
  InitLocExpr(p, e.sons[1], a)
  InitLocExpr(p, e.sons[2], b)
  var t = skipTypes(e.sons[1].typ, abstractVar)
  let setLenPattern = if gCmd != cmdCompileToCpp:
      "$1 = ($3) #setLengthSeq(&($1)->Sup, sizeof($4), $2);$n"
    else:
      "$1 = ($3) #setLengthSeq($1, sizeof($4), $2);$n"

  lineCg(p, cpsStmts, setLenPattern, [
      rdLoc(a), rdLoc(b), getTypeDesc(p.module, t),
      getTypeDesc(p.module, t.sons[0])])
  keepAlive(p, a)

proc genSetLengthStr(p: BProc, e: PNode, d: var TLoc) =
  binaryStmt(p, e, d, "$1 = #setLengthStr($1, $2);$n")
  keepAlive(P, d)

proc genSwap(p: BProc, e: PNode, d: var TLoc) =
  # swap(a, b) -->
  # temp = a
  # a = b
  # b = temp
  var a, b, tmp: TLoc
  getTemp(p, skipTypes(e.sons[1].typ, abstractVar), tmp)
  InitLocExpr(p, e.sons[1], a) # eval a
  InitLocExpr(p, e.sons[2], b) # eval b
  genAssignment(p, tmp, a, {})
  genAssignment(p, a, b, {})
  genAssignment(p, b, tmp, {})

proc rdSetElemLoc(a: TLoc, setType: PType): PRope =
  # read a location of an set element; it may need a substraction operation
  # before the set operation
  result = rdCharLoc(a)
  assert(setType.kind == tySet)
  if firstOrd(setType) != 0:
    result = ropef("($1- $2)", [result, toRope(firstOrd(setType))])

proc fewCmps(s: PNode): bool =
  # this function estimates whether it is better to emit code
  # for constructing the set or generating a bunch of comparisons directly
  if s.kind != nkCurly: InternalError(s.info, "fewCmps")
  if (getSize(s.typ) <= platform.intSize) and (nfAllConst in s.flags):
    result = false            # it is better to emit the set generation code
  elif elemType(s.typ).Kind in {tyInt, tyInt16..tyInt64}:
    result = true             # better not emit the set if int is basetype!
  else:
    result = sonsLen(s) <= 8  # 8 seems to be a good value

proc binaryExprIn(p: BProc, e: PNode, a, b, d: var TLoc, frmt: string) =
  putIntoDest(p, d, e.typ, ropef(frmt, [rdLoc(a), rdSetElemLoc(b, a.t)]))

proc genInExprAux(p: BProc, e: PNode, a, b, d: var TLoc) =
  case int(getSize(skipTypes(e.sons[1].typ, abstractVar)))
  of 1: binaryExprIn(p, e, a, b, d, "(($1 &(1<<(($2)&7)))!=0)")
  of 2: binaryExprIn(p, e, a, b, d, "(($1 &(1<<(($2)&15)))!=0)")
  of 4: binaryExprIn(p, e, a, b, d, "(($1 &(1<<(($2)&31)))!=0)")
  of 8: binaryExprIn(p, e, a, b, d, "(($1 &(IL64(1)<<(($2)&IL64(63))))!=0)")
  else: binaryExprIn(p, e, a, b, d, "(($1[$2/8] &(1<<($2%8)))!=0)")

proc binaryStmtInExcl(p: BProc, e: PNode, d: var TLoc, frmt: string) =
  var a, b: TLoc
  assert(d.k == locNone)
  InitLocExpr(p, e.sons[1], a)
  InitLocExpr(p, e.sons[2], b)
  lineF(p, cpsStmts, frmt, [rdLoc(a), rdSetElemLoc(b, a.t)])

proc genInOp(p: BProc, e: PNode, d: var TLoc) =
  var a, b, x, y: TLoc
  if (e.sons[1].Kind == nkCurly) and fewCmps(e.sons[1]):
    # a set constructor but not a constant set:
    # do not emit the set, but generate a bunch of comparisons
    initLocExpr(p, e.sons[2], a)
    initLoc(b, locExpr, e.typ, OnUnknown)
    b.r = toRope("(")
    var length = sonsLen(e.sons[1])
    for i in countup(0, length - 1):
      if e.sons[1].sons[i].Kind == nkRange:
        InitLocExpr(p, e.sons[1].sons[i].sons[0], x)
        InitLocExpr(p, e.sons[1].sons[i].sons[1], y)
        appf(b.r, "$1 >= $2 && $1 <= $3",
             [rdCharLoc(a), rdCharLoc(x), rdCharLoc(y)])
      else:
        InitLocExpr(p, e.sons[1].sons[i], x)
        appf(b.r, "$1 == $2", [rdCharLoc(a), rdCharLoc(x)])
      if i < length - 1: app(b.r, " || ")
    app(b.r, ")")
    putIntoDest(p, d, e.typ, b.r)
  else:
    assert(e.sons[1].typ != nil)
    assert(e.sons[2].typ != nil)
    InitLocExpr(p, e.sons[1], a)
    InitLocExpr(p, e.sons[2], b)
    genInExprAux(p, e, a, b, d)

proc genSetOp(p: BProc, e: PNode, d: var TLoc, op: TMagic) =
  const
    lookupOpr: array[mLeSet..mSymDiffSet, string] = [
      "for ($1 = 0; $1 < $2; $1++) { $n" &
        "  $3 = (($4[$1] & ~ $5[$1]) == 0);$n" &
        "  if (!$3) break;}$n", "for ($1 = 0; $1 < $2; $1++) { $n" &
        "  $3 = (($4[$1] & ~ $5[$1]) == 0);$n" & "  if (!$3) break;}$n" &
        "if ($3) $3 = (memcmp($4, $5, $2) != 0);$n",
      "&", "|", "& ~", "^"]
  var a, b, i: TLoc
  var setType = skipTypes(e.sons[1].Typ, abstractVar)
  var size = int(getSize(setType))
  case size
  of 1, 2, 4, 8:
    case op
    of mIncl:
      var ts = "NI" & $(size * 8)
      binaryStmtInExcl(p, e, d,
          "$1 |=(1<<((" & ts & ")($2)%(sizeof(" & ts & ")*8)));$n")
    of mExcl:
      var ts = "NI" & $(size * 8)
      binaryStmtInExcl(p, e, d, "$1 &= ~(1 << ((" & ts & ")($2) % (sizeof(" &
          ts & ")*8)));$n")
    of mCard:
      if size <= 4: unaryExprChar(p, e, d, "#countBits32($1)")
      else: unaryExprChar(p, e, d, "#countBits64($1)")
    of mLtSet: binaryExprChar(p, e, d, "(($1 & ~ $2 ==0)&&($1 != $2))")
    of mLeSet: binaryExprChar(p, e, d, "(($1 & ~ $2)==0)")
    of mEqSet: binaryExpr(p, e, d, "($1 == $2)")
    of mMulSet: binaryExpr(p, e, d, "($1 & $2)")
    of mPlusSet: binaryExpr(p, e, d, "($1 | $2)")
    of mMinusSet: binaryExpr(p, e, d, "($1 & ~ $2)")
    of mSymDiffSet: binaryExpr(p, e, d, "($1 ^ $2)")
    of mInSet:
      genInOp(p, e, d)
    else: internalError(e.info, "genSetOp()")
  else:
    case op
    of mIncl: binaryStmtInExcl(p, e, d, "$1[$2/8] |=(1<<($2%8));$n")
    of mExcl: binaryStmtInExcl(p, e, d, "$1[$2/8] &= ~(1<<($2%8));$n")
    of mCard: unaryExprChar(p, e, d, "#cardSet($1, " & $size & ')')
    of mLtSet, mLeSet:
      getTemp(p, getSysType(tyInt), i) # our counter
      initLocExpr(p, e.sons[1], a)
      initLocExpr(p, e.sons[2], b)
      if d.k == locNone: getTemp(p, a.t, d)
      lineF(p, cpsStmts, lookupOpr[op],
           [rdLoc(i), toRope(size), rdLoc(d), rdLoc(a), rdLoc(b)])
    of mEqSet:
      binaryExprChar(p, e, d, "(memcmp($1, $2, " & $(size) & ")==0)")
    of mMulSet, mPlusSet, mMinusSet, mSymDiffSet:
      # we inline the simple for loop for better code generation:
      getTemp(p, getSysType(tyInt), i) # our counter
      initLocExpr(p, e.sons[1], a)
      initLocExpr(p, e.sons[2], b)
      if d.k == locNone: getTemp(p, a.t, d)
      lineF(p, cpsStmts,
           "for ($1 = 0; $1 < $2; $1++) $n" & 
           "  $3[$1] = $4[$1] $6 $5[$1];$n", [
          rdLoc(i), toRope(size), rdLoc(d), rdLoc(a), rdLoc(b),
          toRope(lookupOpr[op])])
    of mInSet: genInOp(p, e, d)
    else: internalError(e.info, "genSetOp")

proc genOrd(p: BProc, e: PNode, d: var TLoc) =
  unaryExprChar(p, e, d, "$1")

proc genCast(p: BProc, e: PNode, d: var TLoc) =
  const
    ValueTypes = {tyTuple, tyObject, tyArray, tyOpenArray, tyArrayConstr}
  # we use whatever C gives us. Except if we have a value-type, we need to go
  # through its address:
  var a: TLoc
  InitLocExpr(p, e.sons[1], a)
  let etyp = skipTypes(e.typ, abstractRange)
  if etyp.kind in ValueTypes and lfIndirect notin a.flags:
    putIntoDest(p, d, e.typ, ropef("(*($1*) ($2))",
        [getTypeDesc(p.module, e.typ), addrLoc(a)]))
  elif etyp.kind == tyProc and etyp.callConv == ccClosure:
    putIntoDest(p, d, e.typ, ropef("(($1) ($2))",
        [getClosureType(p.module, etyp, clHalfWithEnv), rdCharLoc(a)]))
  else:
    putIntoDest(p, d, e.typ, ropef("(($1) ($2))",
        [getTypeDesc(p.module, e.typ), rdCharLoc(a)]))

proc genRangeChck(p: BProc, n: PNode, d: var TLoc, magic: string) =
  var a: TLoc
  var dest = skipTypes(n.typ, abstractVar)
  if optRangeCheck notin p.options:
    InitLocExpr(p, n.sons[0], a)
    putIntoDest(p, d, n.typ, ropef("(($1) ($2))",
        [getTypeDesc(p.module, dest), rdCharLoc(a)]))
  else:
    InitLocExpr(p, n.sons[0], a)
    putIntoDest(p, d, dest, ropecg(p.module, "(($1)#$5($2, $3, $4))", [
        getTypeDesc(p.module, dest), rdCharLoc(a),
        genLiteral(p, n.sons[1], dest), genLiteral(p, n.sons[2], dest),
        toRope(magic)]))

proc genConv(p: BProc, e: PNode, d: var TLoc) =
  if compareTypes(e.typ, e.sons[1].typ, dcEqIgnoreDistinct):
    expr(p, e.sons[1], d)
  else:
    genCast(p, e, d)

proc convStrToCStr(p: BProc, n: PNode, d: var TLoc) =
  var a: TLoc
  initLocExpr(p, n.sons[0], a)
  putIntoDest(p, d, skipTypes(n.typ, abstractVar), ropef("$1->data",
      [rdLoc(a)]))

proc convCStrToStr(p: BProc, n: PNode, d: var TLoc) =
  var a: TLoc
  initLocExpr(p, n.sons[0], a)
  putIntoDest(p, d, skipTypes(n.typ, abstractVar),
              ropecg(p.module, "#cstrToNimstr($1)", [rdLoc(a)]))

proc genStrEquals(p: BProc, e: PNode, d: var TLoc) =
  var x: TLoc
  var a = e.sons[1]
  var b = e.sons[2]
  if (a.kind == nkNilLit) or (b.kind == nkNilLit):
    binaryExpr(p, e, d, "($1 == $2)")
  elif (a.kind in {nkStrLit..nkTripleStrLit}) and (a.strVal == ""):
    initLocExpr(p, e.sons[2], x)
    putIntoDest(p, d, e.typ, 
      ropef("(($1) && ($1)->$2 == 0)", [rdLoc(x), lenField()]))
  elif (b.kind in {nkStrLit..nkTripleStrLit}) and (b.strVal == ""):
    initLocExpr(p, e.sons[1], x)
    putIntoDest(p, d, e.typ, 
      ropef("(($1) && ($1)->$2 == 0)", [rdLoc(x), lenField()]))
  else:
    binaryExpr(p, e, d, "#eqStrings($1, $2)")

proc binaryFloatArith(p: BProc, e: PNode, d: var TLoc, m: TMagic) =
  if {optNanCheck, optInfCheck} * p.options != {}:
    const opr: array[mAddF64..mDivF64, string] = ["+", "-", "*", "/"]
    var a, b: TLoc
    assert(e.sons[1].typ != nil)
    assert(e.sons[2].typ != nil)
    InitLocExpr(p, e.sons[1], a)
    InitLocExpr(p, e.sons[2], b)
    putIntoDest(p, d, e.typ, ropef("($2 $1 $3)", [
                toRope(opr[m]), rdLoc(a), rdLoc(b)]))
    if optNanCheck in p.options:
      lineCg(p, cpsStmts, "#nanCheck($1);$n", [rdLoc(d)])
    if optInfCheck in p.options:
      lineCg(p, cpsStmts, "#infCheck($1);$n", [rdLoc(d)])
  else:
    binaryArith(p, e, d, m)

proc genMagicExpr(p: BProc, e: PNode, d: var TLoc, op: TMagic) =
  var line, filen: PRope
  case op
  of mOr, mAnd: genAndOr(p, e, d, op)
  of mNot..mToBiggestInt: unaryArith(p, e, d, op)
  of mUnaryMinusI..mAbsI64: unaryArithOverflow(p, e, d, op)
  of mAddF64..mDivF64: binaryFloatArith(p, e, d, op)
  of mShrI..mXor: binaryArith(p, e, d, op)
  of mAddi..mModi64: binaryArithOverflow(p, e, d, op)
  of mRepr: genRepr(p, e, d)
  of mGetTypeInfo: genGetTypeInfo(p, e, d)
  of mSwap: genSwap(p, e, d)
  of mUnaryLt: 
    if not (optOverflowCheck in p.Options): unaryExpr(p, e, d, "$1 - 1")
    else: unaryExpr(p, e, d, "#subInt($1, 1)")
  of mPred:
    # XXX: range checking?
    if not (optOverflowCheck in p.Options): binaryExpr(p, e, d, "$1 - $2")
    else: binaryExpr(p, e, d, "#subInt($1, $2)")
  of mSucc:
    # XXX: range checking?
    if not (optOverflowCheck in p.Options): binaryExpr(p, e, d, "$1 + $2")
    else: binaryExpr(p, e, d, "#addInt($1, $2)")
  of mInc:
    if not (optOverflowCheck in p.Options):
      binaryStmt(p, e, d, "$1 += $2;$n")
    elif skipTypes(e.sons[1].typ, abstractVar).kind == tyInt64:
      binaryStmt(p, e, d, "$1 = #addInt64($1, $2);$n")
    else:
      binaryStmt(p, e, d, "$1 = #addInt($1, $2);$n")
  of ast.mDec:
    if not (optOverflowCheck in p.Options):
      binaryStmt(p, e, d, "$1 -= $2;$n")
    elif skipTypes(e.sons[1].typ, abstractVar).kind == tyInt64:
      binaryStmt(p, e, d, "$1 = #subInt64($1, $2);$n")
    else:
      binaryStmt(p, e, d, "$1 = #subInt($1, $2);$n")
  of mConStrStr: genStrConcat(p, e, d)
  of mAppendStrCh:
    binaryStmt(p, e, d, "$1 = #addChar($1, $2);$n")
    # strictly speaking we need to generate "keepAlive" here too, but this
    # very likely not needed and would slow down the code too much I fear
  of mAppendStrStr: genStrAppend(p, e, d)
  of mAppendSeqElem: genSeqElemAppend(p, e, d)
  of mEqStr: genStrEquals(p, e, d)
  of mLeStr: binaryExpr(p, e, d, "(#cmpStrings($1, $2) <= 0)")
  of mLtStr: binaryExpr(p, e, d, "(#cmpStrings($1, $2) < 0)")
  of mIsNil: unaryExpr(p, e, d, "$1 == 0")
  of mIntToStr: genDollar(p, e, d, "#nimIntToStr($1)")
  of mInt64ToStr: genDollar(p, e, d, "#nimInt64ToStr($1)")
  of mBoolToStr: genDollar(p, e, d, "#nimBoolToStr($1)")
  of mCharToStr: genDollar(p, e, d, "#nimCharToStr($1)")
  of mFloatToStr: genDollar(p, e, d, "#nimFloatToStr($1)")
  of mCStrToStr: genDollar(p, e, d, "#cstrToNimstr($1)")
  of mStrToStr: expr(p, e.sons[1], d)
  of mEnumToStr: genRepr(p, e, d)
  of mOf: genOf(p, e, d)
  of mNew: genNew(p, e)
  of mNewFinalize: genNewFinalize(p, e)
  of mNewSeq: genNewSeq(p, e)
  of mSizeOf:
    putIntoDest(p, d, e.typ, ropef("((NI)sizeof($1))",
                                   [getTypeDesc(p.module, e.sons[1].typ)]))
  of mChr: genCast(p, e, d)
  of mOrd: genOrd(p, e, d)
  of mLengthArray, mHigh, mLengthStr, mLengthSeq, mLengthOpenArray:
    genArrayLen(p, e, d, op)
  of mGCref: unaryStmt(p, e, d, "#nimGCref($1);$n")
  of mGCunref: unaryStmt(p, e, d, "#nimGCunref($1);$n")
  of mSetLengthStr: genSetLengthStr(p, e, d)
  of mSetLengthSeq: genSetLengthSeq(p, e, d)
  of mIncl, mExcl, mCard, mLtSet, mLeSet, mEqSet, mMulSet, mPlusSet, mMinusSet,
     mInSet:
    genSetOp(p, e, d, op)
  of mNewString, mNewStringOfCap, mCopyStr, mCopyStrLast, mExit, mRand:
    var opr = e.sons[0].sym
    if lfNoDecl notin opr.loc.flags:
      discard cgsym(p.module, opr.loc.r.ropeToStr)
    genCall(p, e, d)
  of mReset: genReset(p, e)
  of mEcho: genEcho(p, e)
  of mArrToSeq: genArrToSeq(p, e, d)
  of mNLen..mNError:
    localError(e.info, errCannotGenerateCodeForX, e.sons[0].sym.name.s)
  of mSlurp, mStaticExec:
    localError(e.info, errXMustBeCompileTime, e.sons[0].sym.name.s)
  else: internalError(e.info, "genMagicExpr: " & $op)

proc genConstExpr(p: BProc, n: PNode): PRope
proc handleConstExpr(p: BProc, n: PNode, d: var TLoc): bool =
  if (nfAllConst in n.flags) and (d.k == locNone) and (sonsLen(n) > 0):
    var t = getUniqueType(n.typ)
    discard getTypeDesc(p.module, t) # so that any fields are initialized
    var id = NodeTableTestOrSet(p.module.dataCache, n, gBackendId)
    fillLoc(d, locData, t, con("TMP", toRope(id)), OnHeap)
    if id == gBackendId:
      # expression not found in the cache:
      inc(gBackendId)
      appf(p.module.s[cfsData], "NIM_CONST $1 $2 = $3;$n",
           [getTypeDesc(p.module, t), d.r, genConstExpr(p, n)])
    result = true
  else:
    result = false

proc genSetConstr(p: BProc, e: PNode, d: var TLoc) =
  # example: { a..b, c, d, e, f..g }
  # we have to emit an expression of the form:
  # memset(tmp, 0, sizeof(tmp)); inclRange(tmp, a, b); incl(tmp, c);
  # incl(tmp, d); incl(tmp, e); inclRange(tmp, f, g);
  var
    a, b, idx: TLoc
  if nfAllConst in e.flags:
    putIntoDest(p, d, e.typ, genSetNode(p, e))
  else:
    if d.k == locNone: getTemp(p, e.typ, d)
    if getSize(e.typ) > 8:
      # big set:
      lineF(p, cpsStmts, "memset($1, 0, sizeof($1));$n", [rdLoc(d)])
      for i in countup(0, sonsLen(e) - 1):
        if e.sons[i].kind == nkRange:
          getTemp(p, getSysType(tyInt), idx) # our counter
          initLocExpr(p, e.sons[i].sons[0], a)
          initLocExpr(p, e.sons[i].sons[1], b)
          lineF(p, cpsStmts, "for ($1 = $3; $1 <= $4; $1++) $n" &
              "$2[$1/8] |=(1<<($1%8));$n", [rdLoc(idx), rdLoc(d),
              rdSetElemLoc(a, e.typ), rdSetElemLoc(b, e.typ)])
        else:
          initLocExpr(p, e.sons[i], a)
          lineF(p, cpsStmts, "$1[$2/8] |=(1<<($2%8));$n",
               [rdLoc(d), rdSetElemLoc(a, e.typ)])
    else:
      # small set
      var ts = "NI" & $(getSize(e.typ) * 8)
      lineF(p, cpsStmts, "$1 = 0;$n", [rdLoc(d)])
      for i in countup(0, sonsLen(e) - 1):
        if e.sons[i].kind == nkRange:
          getTemp(p, getSysType(tyInt), idx) # our counter
          initLocExpr(p, e.sons[i].sons[0], a)
          initLocExpr(p, e.sons[i].sons[1], b)
          lineF(p, cpsStmts, "for ($1 = $3; $1 <= $4; $1++) $n" &
              "$2 |=(1<<((" & ts & ")($1)%(sizeof(" & ts & ")*8)));$n", [
              rdLoc(idx), rdLoc(d), rdSetElemLoc(a, e.typ),
              rdSetElemLoc(b, e.typ)])
        else:
          initLocExpr(p, e.sons[i], a)
          lineF(p, cpsStmts,
               "$1 |=(1<<((" & ts & ")($2)%(sizeof(" & ts & ")*8)));$n",
               [rdLoc(d), rdSetElemLoc(a, e.typ)])

proc genTupleConstr(p: BProc, n: PNode, d: var TLoc) =
  var rec: TLoc
  if not handleConstExpr(p, n, d):
    var t = getUniqueType(n.typ)
    discard getTypeDesc(p.module, t) # so that any fields are initialized
    if d.k == locNone: getTemp(p, t, d)
    for i in countup(0, sonsLen(n) - 1):
      var it = n.sons[i]
      if it.kind == nkExprColonExpr: it = it.sons[1]
      initLoc(rec, locExpr, it.typ, d.s)
      rec.r = ropef("$1.Field$2", [rdLoc(d), toRope(i)])
      expr(p, it, rec)
      when false:
        initLoc(rec, locExpr, it.typ, d.s)
        if (t.n.sons[i].kind != nkSym): InternalError(n.info, "genTupleConstr")
        rec.r = ropef("$1.$2",
                      [rdLoc(d), mangleRecFieldName(t.n.sons[i].sym, t)])
        expr(p, it, rec)

proc IsConstClosure(n: PNode): bool {.inline.} =
  result = n.sons[0].kind == nkSym and isRoutine(n.sons[0].sym) and
      n.sons[1].kind == nkNilLit
      
proc genClosure(p: BProc, n: PNode, d: var TLoc) =
  assert n.kind == nkClosure
  
  if IsConstClosure(n):
    inc(p.labels)
    var tmp = con("LOC", toRope(p.labels))
    appf(p.module.s[cfsData], "NIM_CONST $1 $2 = $3;$n",
        [getTypeDesc(p.module, n.typ), tmp, genConstExpr(p, n)])
    putIntoDest(p, d, n.typ, tmp)
  else:
    var tmp, a, b: TLoc
    initLocExpr(p, n.sons[0], a)
    initLocExpr(p, n.sons[1], b)
    getTemp(p, n.typ, tmp)
    lineCg(p, cpsStmts, "$1.ClPrc = $2; $1.ClEnv = $3;$n",
          tmp.rdLoc, a.rdLoc, b.rdLoc)
    putLocIntoDest(p, d, tmp)

proc genArrayConstr(p: BProc, n: PNode, d: var TLoc) =
  var arr: TLoc
  if not handleConstExpr(p, n, d):
    if d.k == locNone: getTemp(p, n.typ, d)
    for i in countup(0, sonsLen(n) - 1):
      initLoc(arr, locExpr, elemType(skipTypes(n.typ, abstractInst)), d.s)
      arr.r = ropef("$1[$2]", [rdLoc(d), intLiteral(i)])
      expr(p, n.sons[i], arr)

proc genComplexConst(p: BProc, sym: PSym, d: var TLoc) =
  requestConstImpl(p, sym)
  assert((sym.loc.r != nil) and (sym.loc.t != nil))
  putLocIntoDest(p, d, sym.loc)

proc genStmtListExpr(p: BProc, n: PNode, d: var TLoc) =
  var length = sonsLen(n)
  for i in countup(0, length - 2): genStmts(p, n.sons[i])
  if length > 0: expr(p, n.sons[length - 1], d)

proc upConv(p: BProc, n: PNode, d: var TLoc) =
  var a: TLoc
  initLocExpr(p, n.sons[0], a)
  var dest = skipTypes(n.typ, abstractPtrs)
  if optObjCheck in p.options and not isPureObject(dest):
    var r = rdLoc(a)
    var nilCheck: PRope = nil
    var t = skipTypes(a.t, abstractInst)
    while t.kind in {tyVar, tyPtr, tyRef}:
      if t.kind != tyVar: nilCheck = r
      r = ropef("(*$1)", [r])
      t = skipTypes(t.sons[0], abstractInst)
    if gCmd != cmdCompileToCpp:
      while t.kind == tyObject and t.sons[0] != nil:
        app(r, ".Sup")
        t = skipTypes(t.sons[0], abstractInst)
    if nilCheck != nil:
      lineCg(p, cpsStmts, "if ($1) #chckObj($2.m_type, $3);$n",
           [nilCheck, r, genTypeInfo(p.module, dest)])
    else:
      lineCg(p, cpsStmts, "#chckObj($1.m_type, $2);$n",
           [r, genTypeInfo(p.module, dest)])
  if n.sons[0].typ.kind != tyObject:
    putIntoDest(p, d, n.typ,
                ropef("(($1) ($2))", [getTypeDesc(p.module, n.typ), rdLoc(a)]))
  else:
    putIntoDest(p, d, n.typ, ropef("(*($1*) ($2))",
                                   [getTypeDesc(p.module, dest), addrLoc(a)]))

proc downConv(p: BProc, n: PNode, d: var TLoc) =
  if gCmd == cmdCompileToCpp:
    expr(p, n.sons[0], d)     # downcast does C++ for us
  else:
    var dest = skipTypes(n.typ, abstractPtrs)
    var src = skipTypes(n.sons[0].typ, abstractPtrs)
    var a: TLoc
    initLocExpr(p, n.sons[0], a)
    var r = rdLoc(a)
    if skipTypes(n.sons[0].typ, abstractInst).kind in {tyRef, tyPtr, tyVar}:
      app(r, "->Sup")
      for i in countup(2, abs(inheritanceDiff(dest, src))): app(r, ".Sup")
      r = con("&", r)
    else:
      for i in countup(1, abs(inheritanceDiff(dest, src))): app(r, ".Sup")
    putIntoDest(p, d, n.typ, r)

proc exprComplexConst(p: BProc, n: PNode, d: var TLoc) =
  var t = getUniqueType(n.typ)
  discard getTypeDesc(p.module, t) # so that any fields are initialized
  var id = NodeTableTestOrSet(p.module.dataCache, n, gBackendId)
  var tmp = con("TMP", toRope(id))
  
  if id == gBackendId:
    # expression not found in the cache:
    inc(gBackendId)
    appf(p.module.s[cfsData], "NIM_CONST $1 $2 = $3;$n",
         [getTypeDesc(p.module, t), tmp, genConstExpr(p, n)])
  
  if d.k == locNone:
    fillLoc(d, locData, t, tmp, OnHeap)
  else:
    putIntoDest(p, d, t, tmp)

proc genBlock(p: BProc, t: PNode, d: var TLoc)
proc expr(p: BProc, e: PNode, d: var TLoc) =
  case e.kind
  of nkSym:
    var sym = e.sym
    case sym.Kind
    of skMethod:
      if sym.getBody.kind == nkEmpty:
        # we cannot produce code for the dispatcher yet:
        fillProcLoc(sym)
        genProcPrototype(p.module, sym)
      else:
        genProc(p.module, sym)
      putLocIntoDest(p, d, sym.loc)
    of skProc, skConverter:
      genProc(p.module, sym)
      if sym.loc.r == nil or sym.loc.t == nil:
        InternalError(e.info, "expr: proc not init " & sym.name.s)
      putLocIntoDest(p, d, sym.loc)
    of skConst:
      if sfFakeConst in sym.flags:
        if sfGlobal in sym.flags: genVarPrototype(p.module, sym)
        putLocIntoDest(p, d, sym.loc)
      elif isSimpleConst(sym.typ):
        putIntoDest(p, d, e.typ, genLiteral(p, sym.ast, sym.typ))
      else:
        genComplexConst(p, sym, d)
    of skEnumField:
      putIntoDest(p, d, e.typ, toRope(sym.position))
    of skVar, skForVar, skResult, skLet:
      if sfGlobal in sym.flags: genVarPrototype(p.module, sym)
      if sym.loc.r == nil or sym.loc.t == nil:
        InternalError(e.info, "expr: var not init " & sym.name.s)
      if sfThread in sym.flags:
        AccessThreadLocalVar(p, sym)
        if emulatedThreadVars(): 
          putIntoDest(p, d, sym.loc.t, con("NimTV->", sym.loc.r))
        else:
          putLocIntoDest(p, d, sym.loc)
      else:
        putLocIntoDest(p, d, sym.loc)
    of skTemp:
      if sym.loc.r == nil or sym.loc.t == nil:
        InternalError(e.info, "expr: temp not init " & sym.name.s)
      putLocIntoDest(p, d, sym.loc)
    of skParam:
      if sym.loc.r == nil or sym.loc.t == nil:
        InternalError(e.info, "expr: param not init " & sym.name.s)
      putLocIntoDest(p, d, sym.loc)
    else: InternalError(e.info, "expr(" & $sym.kind & "); unknown symbol")
  of nkStrLit..nkTripleStrLit, nkIntLit..nkUInt64Lit,
     nkFloatLit..nkFloat128Lit, nkNilLit, nkCharLit:
    putIntoDest(p, d, e.typ, genLiteral(p, e))
  of nkCall, nkHiddenCallConv, nkInfix, nkPrefix, nkPostfix, nkCommand,
     nkCallStrLit:
    if e.sons[0].kind == nkSym and e.sons[0].sym.magic != mNone:
      genMagicExpr(p, e, d, e.sons[0].sym.magic)
    else:
      genCall(p, e, d)
  of nkCurly:
    if isDeepConstExpr(e) and e.len != 0:
      putIntoDest(p, d, e.typ, genSetNode(p, e))
    else:
      genSetConstr(p, e, d)
  of nkBracket:
    if isDeepConstExpr(e) and e.len != 0:
      exprComplexConst(p, e, d)
    elif skipTypes(e.typ, abstractVarRange).kind == tySequence:
      genSeqConstr(p, e, d)
    else:
      genArrayConstr(p, e, d)
  of nkPar:
    if isDeepConstExpr(e) and e.len != 0:
      exprComplexConst(p, e, d)
    else:
      genTupleConstr(p, e, d)
  of nkCast: genCast(p, e, d)
  of nkHiddenStdConv, nkHiddenSubConv, nkConv: genConv(p, e, d)
  of nkHiddenAddr, nkAddr: genAddr(p, e, d)
  of nkBracketExpr:
    var ty = skipTypes(e.sons[0].typ, abstractVarRange)
    if ty.kind in {tyRef, tyPtr}: ty = skipTypes(ty.sons[0], abstractVarRange)
    case ty.kind
    of tyArray, tyArrayConstr: genArrayElem(p, e, d)
    of tyOpenArray: genOpenArrayElem(p, e, d)
    of tySequence, tyString: genSeqElem(p, e, d)
    of tyCString: genCStringElem(p, e, d)
    of tyTuple: genTupleElem(p, e, d)
    else: InternalError(e.info, "expr(nkBracketExpr, " & $ty.kind & ')')
  of nkDerefExpr, nkHiddenDeref: genDeref(p, e, d)
  of nkDotExpr: genRecordField(p, e, d)
  of nkCheckedFieldExpr: genCheckedRecordField(p, e, d)
  of nkBlockExpr: genBlock(p, e, d)
  of nkStmtListExpr: genStmtListExpr(p, e, d)
  of nkIfExpr: genIfExpr(p, e, d)
  of nkObjDownConv: downConv(p, e, d)
  of nkObjUpConv: upConv(p, e, d)
  of nkChckRangeF: genRangeChck(p, e, d, "chckRangeF")
  of nkChckRange64: genRangeChck(p, e, d, "chckRange64")
  of nkChckRange: genRangeChck(p, e, d, "chckRange")
  of nkStringToCString: convStrToCStr(p, e, d)
  of nkCStringToString: convCStrToStr(p, e, d)
  of nkLambdaKinds:
    var sym = e.sons[namePos].sym
    genProc(p.module, sym)
    if sym.loc.r == nil or sym.loc.t == nil:
      InternalError(e.info, "expr: proc not init " & sym.name.s)
    putLocIntoDest(p, d, sym.loc)
  of nkClosure: genClosure(p, e, d)
  of nkMetaNode: expr(p, e.sons[0], d)
  else: InternalError(e.info, "expr(" & $e.kind & "); unknown node kind")

proc genNamedConstExpr(p: BProc, n: PNode): PRope =
  if n.kind == nkExprColonExpr: result = genConstExpr(p, n.sons[1])
  else: result = genConstExpr(p, n)

proc genConstSimpleList(p: BProc, n: PNode): PRope =
  var length = sonsLen(n)
  result = toRope("{")
  for i in countup(0, length - 2):
    appf(result, "$1,$n", [genNamedConstExpr(p, n.sons[i])])
  if length > 0: app(result, genNamedConstExpr(p, n.sons[length - 1]))
  appf(result, "}$n")

proc genConstSeq(p: BProc, n: PNode, t: PType): PRope =
  var data = ropef("{{$1, $1}", n.len.toRope)
  if n.len > 0: 
    # array part needs extra curlies:
    data.app(", {")
    for i in countup(0, n.len - 1):
      if i > 0: data.appf(",$n")
      data.app genConstExpr(p, n.sons[i])
    data.app("}")
  data.app("}")
  
  inc(gBackendId)
  result = con("CNSTSEQ", gBackendId.toRope)
  
  appcg(p.module, cfsData,
        "NIM_CONST struct {$n" & 
        "  #TGenericSeq Sup;$n" &
        "  $1 data[$2];$n" & 
        "} $3 = $4;$n", [
        getTypeDesc(p.module, t.sons[0]), n.len.toRope, result, data])

  result = ropef("(($1)&$2)", [getTypeDesc(p.module, t), result])

proc genConstExpr(p: BProc, n: PNode): PRope =
  case n.Kind
  of nkHiddenStdConv, nkHiddenSubConv:
    result = genConstExpr(p, n.sons[1])
  of nkCurly:
    var cs: TBitSet
    toBitSet(n, cs)
    result = genRawSetData(cs, int(getSize(n.typ)))
  of nkBracket, nkPar, nkClosure:
    var t = skipTypes(n.typ, abstractInst)
    if t.kind == tySequence:
      result = genConstSeq(p, n, t)
    else:
      result = genConstSimpleList(p, n)
  else:
    var d: TLoc
    initLocExpr(p, n, d)
    result = rdLoc(d)
