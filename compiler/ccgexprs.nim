#
#
#           The Nim Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# included from cgen.nim

# -------------------------- constant expressions ------------------------

proc int64Literal(i: BiggestInt): PRope =
  if i > low(int64):
    result = rfmt(nil, "IL64($1)", toRope(i))
  else:
    result = ~"(IL64(-9223372036854775807) - IL64(1))"

proc uint64Literal(i: uint64): PRope = toRope($i & "ULL")

proc intLiteral(i: BiggestInt): PRope =
  if i > low(int32) and i <= high(int32):
    result = toRope(i)
  elif i == low(int32):
    # Nim has the same bug for the same reasons :-)
    result = ~"(-2147483647 -1)"
  elif i > low(int64):
    result = rfmt(nil, "IL64($1)", toRope(i))
  else:
    result = ~"(IL64(-9223372036854775807) - IL64(1))"

proc int32Literal(i: int): PRope =
  if i == int(low(int32)):
    result = ~"(-2147483647 -1)"
  else:
    result = toRope(i)

proc genHexLiteral(v: PNode): PRope =
  # hex literals are unsigned in C
  # so we don't generate hex literals any longer.
  if v.kind notin {nkIntLit..nkUInt64Lit}:
    internalError(v.info, "genHexLiteral")
  result = intLiteral(v.intVal)

proc getStrLit(m: BModule, s: string): PRope =
  discard cgsym(m, "TGenericSeq")
  result = con("TMP", toRope(backendId()))
  appf(m.s[cfsData], "STRING_LITERAL($1, $2, $3);$n",
       [result, makeCString(s), toRope(len(s))])

proc genLiteral(p: BProc, n: PNode, ty: PType): PRope =
  if ty == nil: internalError(n.info, "genLiteral: ty is nil")
  case n.kind
  of nkCharLit..nkUInt64Lit:
    case skipTypes(ty, abstractVarRange).kind
    of tyChar, tyNil:
      result = intLiteral(n.intVal)
    of tyBool:
      if n.intVal != 0: result = ~"NIM_TRUE"
      else: result = ~"NIM_FALSE"
    of tyInt64: result = int64Literal(n.intVal)
    of tyUInt64: result = uint64Literal(uint64(n.intVal))
    else:
      result = ropef("(($1) $2)", [getTypeDesc(p.module,
          skipTypes(ty, abstractVarRange)), intLiteral(n.intVal)])
  of nkNilLit:
    let t = skipTypes(ty, abstractVarRange)
    if t.kind == tyProc and t.callConv == ccClosure:
      var id = nodeTableTestOrSet(p.module.dataCache, n, gBackendId)
      result = con("TMP", toRope(id))
      if id == gBackendId:
        # not found in cache:
        inc(gBackendId)
        appf(p.module.s[cfsData],
             "static NIM_CONST $1 $2 = {NIM_NIL,NIM_NIL};$n",
             [getTypeDesc(p.module, t), result])
    else:
      result = toRope("NIM_NIL")
  of nkStrLit..nkTripleStrLit:
    if n.strVal.isNil:
      result = ropecg(p.module, "((#NimStringDesc*) NIM_NIL)", [])
    elif skipTypes(ty, abstractVarRange).kind == tyString:
      var id = nodeTableTestOrSet(p.module.dataCache, n, gBackendId)
      if id == gBackendId:
        # string literal not found in the cache:
        result = ropecg(p.module, "((#NimStringDesc*) &$1)",
                        [getStrLit(p.module, n.strVal)])
      else:
        result = ropecg(p.module, "((#NimStringDesc*) &TMP$1)", [toRope(id)])
    else:
      result = makeCString(n.strVal)
  of nkFloatLit..nkFloat64Lit:
    result = toRope(n.floatVal.toStrMaxPrecision)
  else:
    internalError(n.info, "genLiteral(" & $n.kind & ')')
    result = nil

proc genLiteral(p: BProc, n: PNode): PRope =
  result = genLiteral(p, n, n.typ)

proc bitSetToWord(s: TBitSet, size: int): BiggestInt =
  result = 0
  when true:
    for j in countup(0, size - 1):
      if j < len(s): result = result or `shl`(ze64(s[j]), j * 8)
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
      appf(result, frmt, [toRope(toHex(ze64(cs[i]), 2))])
  else:
    result = intLiteral(bitSetToWord(cs, size))
    #  result := toRope('0x' + ToHex(bitSetToWord(cs, size), size * 2))

proc genSetNode(p: BProc, n: PNode): PRope =
  var cs: TBitSet
  var size = int(getSize(n.typ))
  toBitSet(n, cs)
  if size > 8:
    var id = nodeTableTestOrSet(p.module.dataCache, n, gBackendId)
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
    else: internalError(n.info, "getStorageLoc")
  of nkBracketExpr, nkDotExpr, nkObjDownConv, nkObjUpConv:
    result = getStorageLoc(n.sons[0])
  else: result = OnUnknown

proc genRefAssign(p: BProc, dest, src: TLoc, flags: TAssignmentFlags) =
  if dest.s == OnStack or not usesNativeGC():
    linefmt(p, cpsStmts, "$1 = $2;$n", rdLoc(dest), rdLoc(src))
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
      linefmt(p, cpsStmts, "#asgnRef((void**) $1, $2);$n",
              addrLoc(dest), rdLoc(src))
    else:
      linefmt(p, cpsStmts, "#asgnRefNoCycle((void**) $1, $2);$n",
              addrLoc(dest), rdLoc(src))
  else:
    linefmt(p, cpsStmts, "#unsureAsgnRef((void**) $1, $2);$n",
            addrLoc(dest), rdLoc(src))
    if needToKeepAlive in flags: keepAlive(p, dest)

proc asgnComplexity(n: PNode): int =
  if n != nil:
    case n.kind
    of nkSym: result = 1
    of nkRecCase:
      # 'case objects' are too difficult to inline their assignment operation:
      result = 100
    of nkRecList:
      for t in items(n):
        result += asgnComplexity(t)
    else: discard

proc optAsgnLoc(a: TLoc, t: PType, field: PRope): TLoc =
  assert field != nil
  result.k = locField
  result.s = a.s
  result.t = t
  result.r = rdLoc(a).con(".").con(field)
  result.heapRoot = a.heapRoot

proc genOptAsgnTuple(p: BProc, dest, src: TLoc, flags: TAssignmentFlags) =
  let newflags =
    if src.k == locData:
      flags + {needToCopy}
    elif tfShallow in dest.t.flags:
      flags - {needToCopy}
    else:
      flags
  let t = skipTypes(dest.t, abstractInst).getUniqueType()
  for i in 0 .. <t.len:
    let t = t.sons[i]
    let field = ropef("Field$1", i.toRope)
    genAssignment(p, optAsgnLoc(dest, t, field),
                     optAsgnLoc(src, t, field), newflags)

proc genOptAsgnObject(p: BProc, dest, src: TLoc, flags: TAssignmentFlags,
                      t: PNode) =
  if t == nil: return
  let newflags =
    if src.k == locData:
      flags + {needToCopy}
    elif tfShallow in dest.t.flags:
      flags - {needToCopy}
    else:
      flags
  case t.kind
  of nkSym:
    let field = t.sym
    genAssignment(p, optAsgnLoc(dest, field.typ, field.loc.r),
                     optAsgnLoc(src, field.typ, field.loc.r), newflags)
  of nkRecList:
    for child in items(t): genOptAsgnObject(p, dest, src, newflags, child)
  else: discard

proc genGenericAsgn(p: BProc, dest, src: TLoc, flags: TAssignmentFlags) =
  # Consider:
  # type TMyFastString {.shallow.} = string
  # Due to the implementation of pragmas this would end up to set the
  # tfShallow flag for the built-in string type too! So we check only
  # here for this flag, where it is reasonably safe to do so
  # (for objects, etc.):
  if needToCopy notin flags or
      tfShallow in skipTypes(dest.t, abstractVarRange).flags:
    if dest.s == OnStack or not usesNativeGC():
      useStringh(p.module)
      linefmt(p, cpsStmts,
           "memcpy((void*)$1, (NIM_CONST void*)$2, sizeof($3));$n",
           addrLoc(dest), addrLoc(src), rdLoc(dest))
      if needToKeepAlive in flags: keepAlive(p, dest)
    else:
      linefmt(p, cpsStmts, "#genericShallowAssign((void*)$1, (void*)$2, $3);$n",
              addrLoc(dest), addrLoc(src), genTypeInfo(p.module, dest.t))
  else:
    linefmt(p, cpsStmts, "#genericAssign((void*)$1, (void*)$2, $3);$n",
            addrLoc(dest), addrLoc(src), genTypeInfo(p.module, dest.t))

proc genAssignment(p: BProc, dest, src: TLoc, flags: TAssignmentFlags) =
  # This function replaces all other methods for generating
  # the assignment operation in C.
  if src.t != nil and src.t.kind == tyPtr:
    # little HACK to support the new 'var T' as return type:
    linefmt(p, cpsStmts, "$1 = $2;$n", rdLoc(dest), rdLoc(src))
    return
  var ty = skipTypes(dest.t, abstractRange)
  case ty.kind
  of tyRef:
    genRefAssign(p, dest, src, flags)
  of tySequence:
    if needToCopy notin flags and src.k != locData:
      genRefAssign(p, dest, src, flags)
    else:
      linefmt(p, cpsStmts, "#genericSeqAssign($1, $2, $3);$n",
              addrLoc(dest), rdLoc(src), genTypeInfo(p.module, dest.t))
  of tyString:
    if needToCopy notin flags and src.k != locData:
      genRefAssign(p, dest, src, flags)
    else:
      if dest.s == OnStack or not usesNativeGC():
        linefmt(p, cpsStmts, "$1 = #copyString($2);$n", dest.rdLoc, src.rdLoc)
        if needToKeepAlive in flags: keepAlive(p, dest)
      elif dest.s == OnHeap:
        # we use a temporary to care for the dreaded self assignment:
        var tmp: TLoc
        getTemp(p, ty, tmp)
        linefmt(p, cpsStmts, "$3 = $1; $1 = #copyStringRC1($2);$n",
                dest.rdLoc, src.rdLoc, tmp.rdLoc)
        linefmt(p, cpsStmts, "if ($1) #nimGCunrefNoCycle($1);$n", tmp.rdLoc)
      else:
        linefmt(p, cpsStmts, "#unsureAsgnRef((void**) $1, #copyString($2));$n",
               addrLoc(dest), rdLoc(src))
        if needToKeepAlive in flags: keepAlive(p, dest)
  of tyProc:
    if needsComplexAssignment(dest.t):
      # optimize closure assignment:
      let a = optAsgnLoc(dest, dest.t, "ClEnv".toRope)
      let b = optAsgnLoc(src, dest.t, "ClEnv".toRope)
      genRefAssign(p, a, b, flags)
      linefmt(p, cpsStmts, "$1.ClPrc = $2.ClPrc;$n", rdLoc(dest), rdLoc(src))
    else:
      linefmt(p, cpsStmts, "$1 = $2;$n", rdLoc(dest), rdLoc(src))
  of tyTuple:
    if needsComplexAssignment(dest.t):
      if dest.t.len <= 4: genOptAsgnTuple(p, dest, src, flags)
      else: genGenericAsgn(p, dest, src, flags)
    else:
      linefmt(p, cpsStmts, "$1 = $2;$n", rdLoc(dest), rdLoc(src))
  of tyObject:
    # XXX: check for subtyping?
    if ty.isImportedCppType:
      linefmt(p, cpsStmts, "$1 = $2;$n", rdLoc(dest), rdLoc(src))
    elif not isObjLackingTypeField(ty):
      genGenericAsgn(p, dest, src, flags)
    elif needsComplexAssignment(ty):
      if ty.sons[0].isNil and asgnComplexity(ty.n) <= 4:
        discard getTypeDesc(p.module, ty)
        ty = getUniqueType(ty)
        internalAssert ty.n != nil
        genOptAsgnObject(p, dest, src, flags, ty.n)
      else:
        genGenericAsgn(p, dest, src, flags)
    else:
      linefmt(p, cpsStmts, "$1 = $2;$n", rdLoc(dest), rdLoc(src))
  of tyArray, tyArrayConstr:
    if needsComplexAssignment(dest.t):
      genGenericAsgn(p, dest, src, flags)
    else:
      useStringh(p.module)
      linefmt(p, cpsStmts,
           "memcpy((void*)$1, (NIM_CONST void*)$2, sizeof($1));$n",
           rdLoc(dest), rdLoc(src))
  of tyOpenArray, tyVarargs:
    # open arrays are always on the stack - really? What if a sequence is
    # passed to an open array?
    if needsComplexAssignment(dest.t):
      linefmt(p, cpsStmts,     # XXX: is this correct for arrays?
           "#genericAssignOpenArray((void*)$1, (void*)$2, $1Len0, $3);$n",
           addrLoc(dest), addrLoc(src), genTypeInfo(p.module, dest.t))
    else:
      useStringh(p.module)
      linefmt(p, cpsStmts,
           "memcpy((void*)$1, (NIM_CONST void*)$2, sizeof($1[0])*$1Len0);$n",
           rdLoc(dest), rdLoc(src))
  of tySet:
    if mapType(ty) == ctArray:
      useStringh(p.module)
      linefmt(p, cpsStmts, "memcpy((void*)$1, (NIM_CONST void*)$2, $3);$n",
              rdLoc(dest), rdLoc(src), toRope(getSize(dest.t)))
    else:
      linefmt(p, cpsStmts, "$1 = $2;$n", rdLoc(dest), rdLoc(src))
  of tyPtr, tyPointer, tyChar, tyBool, tyEnum, tyCString,
     tyInt..tyUInt64, tyRange, tyVar:
    linefmt(p, cpsStmts, "$1 = $2;$n", rdLoc(dest), rdLoc(src))
  else: internalError("genAssignment: " & $ty.kind)

proc genDeepCopy(p: BProc; dest, src: TLoc) =
  var ty = skipTypes(dest.t, abstractVarRange)
  case ty.kind
  of tyPtr, tyRef, tyProc, tyTuple, tyObject, tyArray, tyArrayConstr:
    # XXX optimize this
    linefmt(p, cpsStmts, "#genericDeepCopy((void*)$1, (void*)$2, $3);$n",
            addrLoc(dest), addrLoc(src), genTypeInfo(p.module, dest.t))
  of tySequence, tyString:
    linefmt(p, cpsStmts, "#genericSeqDeepCopy($1, $2, $3);$n",
            addrLoc(dest), rdLoc(src), genTypeInfo(p.module, dest.t))
  of tyOpenArray, tyVarargs:
    linefmt(p, cpsStmts,
         "#genericDeepCopyOpenArray((void*)$1, (void*)$2, $1Len0, $3);$n",
         addrLoc(dest), addrLoc(src), genTypeInfo(p.module, dest.t))
  of tySet:
    if mapType(ty) == ctArray:
      useStringh(p.module)
      linefmt(p, cpsStmts, "memcpy((void*)$1, (NIM_CONST void*)$2, $3);$n",
              rdLoc(dest), rdLoc(src), toRope(getSize(dest.t)))
    else:
      linefmt(p, cpsStmts, "$1 = $2;$n", rdLoc(dest), rdLoc(src))
  of tyPointer, tyChar, tyBool, tyEnum, tyCString,
     tyInt..tyUInt64, tyRange, tyVar:
    linefmt(p, cpsStmts, "$1 = $2;$n", rdLoc(dest), rdLoc(src))
  else: internalError("genDeepCopy: " & $ty.kind)

proc getDestLoc(p: BProc, d: var TLoc, typ: PType) =
  if d.k == locNone: getTemp(p, typ, d)

proc putLocIntoDest(p: BProc, d: var TLoc, s: TLoc) =
  if d.k != locNone:
    if lfNoDeepCopy in d.flags: genAssignment(p, d, s, {})
    else: genAssignment(p, d, s, {needToCopy})
  else:
    d = s # ``d`` is free, so fill it with ``s``

proc putDataIntoDest(p: BProc, d: var TLoc, t: PType, r: PRope) =
  var a: TLoc
  if d.k != locNone:
    # need to generate an assignment here
    initLoc(a, locData, t, OnUnknown)
    a.r = r
    if lfNoDeepCopy in d.flags: genAssignment(p, d, a, {})
    else: genAssignment(p, d, a, {needToCopy})
  else:
    # we cannot call initLoc() here as that would overwrite
    # the flags field!
    d.k = locData
    d.t = t
    d.r = r

proc putIntoDest(p: BProc, d: var TLoc, t: PType, r: PRope) =
  var a: TLoc
  if d.k != locNone:
    # need to generate an assignment here
    initLoc(a, locExpr, t, OnUnknown)
    a.r = r
    if lfNoDeepCopy in d.flags: genAssignment(p, d, a, {})
    else: genAssignment(p, d, a, {needToCopy})
  else:
    # we cannot call initLoc() here as that would overwrite
    # the flags field!
    d.k = locExpr
    d.t = t
    d.r = r

proc binaryStmt(p: BProc, e: PNode, d: var TLoc, frmt: string) =
  var a, b: TLoc
  if d.k != locNone: internalError(e.info, "binaryStmt")
  initLocExpr(p, e.sons[1], a)
  initLocExpr(p, e.sons[2], b)
  lineCg(p, cpsStmts, frmt, rdLoc(a), rdLoc(b))

proc unaryStmt(p: BProc, e: PNode, d: var TLoc, frmt: string) =
  var a: TLoc
  if d.k != locNone: internalError(e.info, "unaryStmt")
  initLocExpr(p, e.sons[1], a)
  lineCg(p, cpsStmts, frmt, [rdLoc(a)])

proc binaryStmtChar(p: BProc, e: PNode, d: var TLoc, frmt: string) =
  var a, b: TLoc
  if (d.k != locNone): internalError(e.info, "binaryStmtChar")
  initLocExpr(p, e.sons[1], a)
  initLocExpr(p, e.sons[2], b)
  lineCg(p, cpsStmts, frmt, [rdCharLoc(a), rdCharLoc(b)])

proc binaryExpr(p: BProc, e: PNode, d: var TLoc, frmt: string) =
  var a, b: TLoc
  assert(e.sons[1].typ != nil)
  assert(e.sons[2].typ != nil)
  initLocExpr(p, e.sons[1], a)
  initLocExpr(p, e.sons[2], b)
  putIntoDest(p, d, e.typ, ropecg(p.module, frmt, [rdLoc(a), rdLoc(b)]))

proc binaryExprChar(p: BProc, e: PNode, d: var TLoc, frmt: string) =
  var a, b: TLoc
  assert(e.sons[1].typ != nil)
  assert(e.sons[2].typ != nil)
  initLocExpr(p, e.sons[1], a)
  initLocExpr(p, e.sons[2], b)
  putIntoDest(p, d, e.typ, ropecg(p.module, frmt, [a.rdCharLoc, b.rdCharLoc]))

proc unaryExpr(p: BProc, e: PNode, d: var TLoc, frmt: string) =
  var a: TLoc
  initLocExpr(p, e.sons[1], a)
  putIntoDest(p, d, e.typ, ropecg(p.module, frmt, [rdLoc(a)]))

proc unaryExprChar(p: BProc, e: PNode, d: var TLoc, frmt: string) =
  var a: TLoc
  initLocExpr(p, e.sons[1], a)
  putIntoDest(p, d, e.typ, ropecg(p.module, frmt, [rdCharLoc(a)]))

proc binaryArithOverflowRaw(p: BProc, t: PType, a, b: TLoc;
                            frmt: string): PRope =
  var size = getSize(t)
  let storage = if size < platform.intSize: toRope("NI")
                else: getTypeDesc(p.module, t)
  result = getTempName()
  linefmt(p, cpsLocals, "$1 $2;$n", storage, result)
  lineCg(p, cpsStmts, frmt, result, rdLoc(a), rdLoc(b))
  if size < platform.intSize or t.kind in {tyRange, tyEnum}:
    linefmt(p, cpsStmts, "if ($1 < $2 || $1 > $3) #raiseOverflow();$n",
            result, intLiteral(firstOrd(t)), intLiteral(lastOrd(t)))

proc binaryArithOverflow(p: BProc, e: PNode, d: var TLoc, m: TMagic) =
  const
    prc: array[mAddI..mPred, string] = [
      "$# = #addInt($#, $#);$n", "$# = #subInt($#, $#);$n",
      "$# = #mulInt($#, $#);$n", "$# = #divInt($#, $#);$n",
      "$# = #modInt($#, $#);$n",
      "$# = #addInt64($#, $#);$n", "$# = #subInt64($#, $#);$n",
      "$# = #mulInt64($#, $#);$n", "$# = #divInt64($#, $#);$n",
      "$# = #modInt64($#, $#);$n",
      "$# = #addInt($#, $#);$n", "$# = #subInt($#, $#);$n"]
    opr: array[mAddI..mPred, string] = [
      "($#)($# + $#)", "($#)($# - $#)", "($#)($# * $#)",
      "($#)($# / $#)", "($#)($# % $#)",
      "($#)($# + $#)", "($#)($# - $#)", "($#)($# * $#)",
      "($#)($# / $#)", "($#)($# % $#)",
      "($#)($# + $#)", "($#)($# - $#)"]
  var a, b: TLoc
  assert(e.sons[1].typ != nil)
  assert(e.sons[2].typ != nil)
  initLocExpr(p, e.sons[1], a)
  initLocExpr(p, e.sons[2], b)
  # skipping 'range' is correct here as we'll generate a proper range check
  # later via 'chckRange'
  let t = e.typ.skipTypes(abstractRange)
  if optOverflowCheck notin p.options:
    let res = ropef(opr[m], [getTypeDesc(p.module, t), rdLoc(a), rdLoc(b)])
    putIntoDest(p, d, e.typ, res)
  else:
    let res = binaryArithOverflowRaw(p, t, a, b, prc[m])
    putIntoDest(p, d, e.typ, ropef("($#)($#)", [getTypeDesc(p.module, t), res]))

proc unaryArithOverflow(p: BProc, e: PNode, d: var TLoc, m: TMagic) =
  const
    opr: array[mUnaryMinusI..mAbsI64, string] = [
      mUnaryMinusI: "((NI$2)-($1))",
      mUnaryMinusI64: "-($1)",
      mAbsI: "($1 > 0? ($1) : -($1))",
      mAbsI64: "($1 > 0? ($1) : -($1))"]
  var
    a: TLoc
    t: PType
  assert(e.sons[1].typ != nil)
  initLocExpr(p, e.sons[1], a)
  t = skipTypes(e.typ, abstractRange)
  if optOverflowCheck in p.options:
    linefmt(p, cpsStmts, "if ($1 == $2) #raiseOverflow();$n",
            rdLoc(a), intLiteral(firstOrd(t)))
  putIntoDest(p, d, e.typ, ropef(opr[m], [rdLoc(a), toRope(getSize(t) * 8)]))

proc binaryArith(p: BProc, e: PNode, d: var TLoc, op: TMagic) =
  const
    binArithTab: array[mAddF64..mXor, string] = [
      "(($4)($1) + ($4)($2))", # AddF64
      "(($4)($1) - ($4)($2))", # SubF64
      "(($4)($1) * ($4)($2))", # MulF64
      "(($4)($1) / ($4)($2))", # DivF64

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
      "($1 == $2)",           # EqPtr
      "($1 <= $2)",           # LePtr
      "($1 < $2)",            # LtPtr
      "($1 == $2)",           # EqCString
      "($1 != $2)"]           # Xor
  var
    a, b: TLoc
    s: BiggestInt
  assert(e.sons[1].typ != nil)
  assert(e.sons[2].typ != nil)
  initLocExpr(p, e.sons[1], a)
  initLocExpr(p, e.sons[2], b)
  # BUGFIX: cannot use result-type here, as it may be a boolean
  s = max(getSize(a.t), getSize(b.t)) * 8
  putIntoDest(p, d, e.typ,
              ropef(binArithTab[op], [rdLoc(a), rdLoc(b), toRope(s),
                                      getSimpleTypeDesc(p.module, e.typ)]))

proc genEqProc(p: BProc, e: PNode, d: var TLoc) =
  var a, b: TLoc
  assert(e.sons[1].typ != nil)
  assert(e.sons[2].typ != nil)
  initLocExpr(p, e.sons[1], a)
  initLocExpr(p, e.sons[2], b)
  if a.t.callConv == ccClosure:
    putIntoDest(p, d, e.typ,
      ropef("($1.ClPrc == $2.ClPrc && $1.ClEnv == $2.ClEnv)", [
      rdLoc(a), rdLoc(b)]))
  else:
    putIntoDest(p, d, e.typ, ropef("($1 == $2)", [rdLoc(a), rdLoc(b)]))

proc genIsNil(p: BProc, e: PNode, d: var TLoc) =
  let t = skipTypes(e.sons[1].typ, abstractRange)
  if t.kind == tyProc and t.callConv == ccClosure:
    unaryExpr(p, e, d, "$1.ClPrc == 0")
  else:
    unaryExpr(p, e, d, "$1 == 0")

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
      "float64ToInt32($1)",   # ToInt
      "float64ToInt64($1)"]   # ToBiggestInt
  var
    a: TLoc
    t: PType
  assert(e.sons[1].typ != nil)
  initLocExpr(p, e.sons[1], a)
  t = skipTypes(e.typ, abstractRange)
  putIntoDest(p, d, e.typ,
              ropef(unArithTab[op], [rdLoc(a), toRope(getSize(t) * 8),
                    getSimpleTypeDesc(p.module, e.typ)]))

proc isCppRef(p: BProc; typ: PType): bool {.inline.} =
  result = p.module.compileToCpp and
      skipTypes(typ, abstractInst).kind == tyVar and
      tfVarIsPtr notin skipTypes(typ, abstractInst).flags

proc genDeref(p: BProc, e: PNode, d: var TLoc; enforceDeref=false) =
  let mt = mapType(e.sons[0].typ)
  if (mt in {ctArray, ctPtrToArray} and not enforceDeref):
    # XXX the amount of hacks for C's arrays is incredible, maybe we should
    # simply wrap them in a struct? --> Losing auto vectorization then?
    #if e[0].kind != nkBracketExpr:
    #  message(e.info, warnUser, "CAME HERE " & renderTree(e))
    expr(p, e.sons[0], d)
  else:
    var a: TLoc
    initLocExprSingleUse(p, e.sons[0], a)
    let typ = skipTypes(a.t, abstractInst)
    case typ.kind
    of tyRef:
      d.s = OnHeap
    of tyVar:
      d.s = OnUnknown
      if tfVarIsPtr notin typ.flags and p.module.compileToCpp and
          e.kind == nkHiddenDeref:
        putIntoDest(p, d, e.typ, rdLoc(a))
        return
    of tyPtr:
      d.s = OnUnknown         # BUGFIX!
    else: internalError(e.info, "genDeref " & $a.t.kind)
    if enforceDeref and mt == ctPtrToArray:
      # we lie about the type for better C interop: 'ptr array[3,T]' is
      # translated to 'ptr T', but for deref'ing this produces wrong code.
      # See tmissingderef. So we get rid of the deref instead. The codegen
      # ends up using 'memcpy' for the array assignment,
      # so the '&' and '*' cancel out:
      putIntoDest(p, d, a.t.sons[0], rdLoc(a))
    else:
      putIntoDest(p, d, e.typ, ropef("(*$1)", [rdLoc(a)]))

proc genAddr(p: BProc, e: PNode, d: var TLoc) =
  # careful  'addr(myptrToArray)' needs to get the ampersand:
  if e.sons[0].typ.skipTypes(abstractInst).kind in {tyRef, tyPtr}:
    var a: TLoc
    initLocExpr(p, e.sons[0], a)
    putIntoDest(p, d, e.typ, con("&", a.r))
    #Message(e.info, warnUser, "HERE NEW &")
  elif mapType(e.sons[0].typ) == ctArray or isCppRef(p, e.sons[0].typ):
    expr(p, e.sons[0], d)
  else:
    var a: TLoc
    initLocExpr(p, e.sons[0], a)
    putIntoDest(p, d, e.typ, addrLoc(a))

template inheritLocation(d: var TLoc, a: TLoc) =
  if d.k == locNone: d.s = a.s
  if d.heapRoot == nil:
    d.heapRoot = if a.heapRoot != nil: a.heapRoot else: a.r

proc genRecordFieldAux(p: BProc, e: PNode, d, a: var TLoc): PType =
  initLocExpr(p, e.sons[0], a)
  if e.sons[1].kind != nkSym: internalError(e.info, "genRecordFieldAux")
  d.inheritLocation(a)
  discard getTypeDesc(p.module, a.t) # fill the record's fields.loc
  result = a.t.getUniqueType

proc genTupleElem(p: BProc, e: PNode, d: var TLoc) =
  var
    a: TLoc
    i: int
  initLocExpr(p, e.sons[0], a)
  d.inheritLocation(a)
  discard getTypeDesc(p.module, a.t) # fill the record's fields.loc
  var ty = a.t.getUniqueType
  var r = rdLoc(a)
  case e.sons[1].kind
  of nkIntLit..nkUInt64Lit: i = int(e.sons[1].intVal)
  else: internalError(e.info, "genTupleElem")
  appf(r, ".Field$1", [toRope(i)])
  putIntoDest(p, d, ty.sons[i], r)

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
        internalError(e.info, "genRecordField")
      field = lookupInRecord(ty.n, f.name)
      if field != nil: break
      if not p.module.compileToCpp: app(r, ".Sup")
      ty = getUniqueType(ty.sons[0])
    if field == nil: internalError(e.info, "genRecordField 2 ")
    if field.loc.r == nil: internalError(e.info, "genRecordField 3")
    appf(r, ".$1", [field.loc.r])
    putIntoDest(p, d, field.typ, r)
  #d.s = a.s

proc genInExprAux(p: BProc, e: PNode, a, b, d: var TLoc)

proc genFieldCheck(p: BProc, e: PNode, obj: PRope, field: PSym) =
  var test, u, v: TLoc
  for i in countup(1, sonsLen(e) - 1):
    var it = e.sons[i]
    assert(it.kind in nkCallKinds)
    assert(it.sons[0].kind == nkSym)
    let op = it.sons[0].sym
    if op.magic == mNot: it = it.sons[1]
    let disc = it.sons[2].skipConv
    assert(disc.kind == nkSym)
    initLoc(test, locNone, it.typ, OnStack)
    initLocExpr(p, it.sons[1], u)
    initLoc(v, locExpr, disc.typ, OnUnknown)
    v.r = ropef("$1.$2", [obj, disc.sym.loc.r])
    genInExprAux(p, it, u, v, test)
    let id = nodeTableTestOrSet(p.module.dataCache,
                               newStrNode(nkStrLit, field.name.s), gBackendId)
    let strLit = if id == gBackendId: getStrLit(p.module, field.name.s)
                 else: con("TMP", toRope(id))
    if op.magic == mNot:
      linefmt(p, cpsStmts,
              "if ($1) #raiseFieldError(((#NimStringDesc*) &$2));$n",
              rdLoc(test), strLit)
    else:
      linefmt(p, cpsStmts,
              "if (!($1)) #raiseFieldError(((#NimStringDesc*) &$2));$n",
              rdLoc(test), strLit)

proc genCheckedRecordField(p: BProc, e: PNode, d: var TLoc) =
  if optFieldCheck in p.options:
    var
      a: TLoc
      f, field: PSym
      ty: PType
      r: PRope
    ty = genRecordFieldAux(p, e.sons[0], d, a)
    r = rdLoc(a)
    f = e.sons[0].sons[1].sym
    field = nil
    while ty != nil:
      assert(ty.kind in {tyTuple, tyObject})
      field = lookupInRecord(ty.n, f.name)
      if field != nil: break
      if not p.module.compileToCpp: app(r, ".Sup")
      ty = getUniqueType(ty.sons[0])
    if field == nil: internalError(e.info, "genCheckedRecordField")
    if field.loc.r == nil:
      internalError(e.info, "genCheckedRecordField") # generate the checks:
    genFieldCheck(p, e, r, field)
    app(r, rfmt(nil, ".$1", field.loc.r))
    putIntoDest(p, d, field.typ, r)
  else:
    genRecordField(p, e.sons[0], d)

proc genArrayElem(p: BProc, x, y: PNode, d: var TLoc) =
  var a, b: TLoc
  initLocExpr(p, x, a)
  initLocExpr(p, y, b)
  var ty = skipTypes(skipTypes(a.t, abstractVarRange), abstractPtrs)
  var first = intLiteral(firstOrd(ty))
  # emit range check:
  if optBoundsCheck in p.options and tfUncheckedArray notin ty.flags:
    if not isConstExpr(y):
      # semantic pass has already checked for const index expressions
      if firstOrd(ty) == 0:
        if (firstOrd(b.t) < firstOrd(ty)) or (lastOrd(b.t) > lastOrd(ty)):
          linefmt(p, cpsStmts, "if ((NU)($1) > (NU)($2)) #raiseIndexError();$n",
                  rdCharLoc(b), intLiteral(lastOrd(ty)))
      else:
        linefmt(p, cpsStmts, "if ($1 < $2 || $1 > $3) #raiseIndexError();$n",
                rdCharLoc(b), first, intLiteral(lastOrd(ty)))
    else:
      let idx = getOrdValue(y)
      if idx < firstOrd(ty) or idx > lastOrd(ty):
        localError(x.info, errIndexOutOfBounds)
  d.inheritLocation(a)
  putIntoDest(p, d, elemType(skipTypes(ty, abstractVar)),
              rfmt(nil, "$1[($2)- $3]", rdLoc(a), rdCharLoc(b), first))

proc genCStringElem(p: BProc, x, y: PNode, d: var TLoc) =
  var a, b: TLoc
  initLocExpr(p, x, a)
  initLocExpr(p, y, b)
  var ty = skipTypes(a.t, abstractVarRange)
  if d.k == locNone: d.s = a.s
  putIntoDest(p, d, elemType(skipTypes(ty, abstractVar)),
              rfmt(nil, "$1[$2]", rdLoc(a), rdCharLoc(b)))

proc genOpenArrayElem(p: BProc, x, y: PNode, d: var TLoc) =
  var a, b: TLoc
  initLocExpr(p, x, a)
  initLocExpr(p, y, b) # emit range check:
  if optBoundsCheck in p.options:
    linefmt(p, cpsStmts, "if ((NU)($1) >= (NU)($2Len0)) #raiseIndexError();$n",
            rdLoc(b), rdLoc(a)) # BUGFIX: ``>=`` and not ``>``!
  if d.k == locNone: d.s = a.s
  putIntoDest(p, d, elemType(skipTypes(a.t, abstractVar)),
              rfmt(nil, "$1[$2]", rdLoc(a), rdCharLoc(b)))

proc genSeqElem(p: BProc, x, y: PNode, d: var TLoc) =
  var a, b: TLoc
  initLocExpr(p, x, a)
  initLocExpr(p, y, b)
  var ty = skipTypes(a.t, abstractVarRange)
  if ty.kind in {tyRef, tyPtr}:
    ty = skipTypes(ty.lastSon, abstractVarRange) # emit range check:
  if optBoundsCheck in p.options:
    if ty.kind == tyString:
      linefmt(p, cpsStmts,
           "if ((NU)($1) > (NU)($2->$3)) #raiseIndexError();$n",
           rdLoc(b), rdLoc(a), lenField(p))
    else:
      linefmt(p, cpsStmts,
           "if ((NU)($1) >= (NU)($2->$3)) #raiseIndexError();$n",
           rdLoc(b), rdLoc(a), lenField(p))
  if d.k == locNone: d.s = OnHeap
  d.heapRoot = a.r
  if skipTypes(a.t, abstractVar).kind in {tyRef, tyPtr}:
    a.r = rfmt(nil, "(*$1)", a.r)
  putIntoDest(p, d, elemType(skipTypes(a.t, abstractVar)),
              rfmt(nil, "$1->data[$2]", rdLoc(a), rdCharLoc(b)))

proc genBracketExpr(p: BProc; n: PNode; d: var TLoc) =
  var ty = skipTypes(n.sons[0].typ, abstractVarRange)
  if ty.kind in {tyRef, tyPtr}: ty = skipTypes(ty.lastSon, abstractVarRange)
  case ty.kind
  of tyArray, tyArrayConstr: genArrayElem(p, n.sons[0], n.sons[1], d)
  of tyOpenArray, tyVarargs: genOpenArrayElem(p, n.sons[0], n.sons[1], d)
  of tySequence, tyString: genSeqElem(p, n.sons[0], n.sons[1], d)
  of tyCString: genCStringElem(p, n.sons[0], n.sons[1], d)
  of tyTuple: genTupleElem(p, n, d)
  else: internalError(n.info, "expr(nkBracketExpr, " & $ty.kind & ')')

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
  inc p.splitDecls
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
  dec p.splitDecls

proc genEcho(p: BProc, n: PNode) =
  # this unusal way of implementing it ensures that e.g. ``echo("hallo", 45)``
  # is threadsafe.
  internalAssert n.kind == nkBracket
  discard lists.includeStr(p.module.headerFiles, "<stdio.h>")
  var args: PRope = nil
  var a: TLoc
  for i in countup(0, n.len-1):
    initLocExpr(p, n.sons[i], a)
    appf(args, ", $1? ($1)->data:\"nil\"", [rdLoc(a)])
  linefmt(p, cpsStmts, "printf($1$2);$n",
          makeCString(repeat("%s", n.len) & tnl), args)

proc gcUsage(n: PNode) =
  if gSelectedGC == gcNone: message(n.info, warnGcMem, n.renderTree)

proc genStrConcat(p: BProc, e: PNode, d: var TLoc) =
  #   <Nim code>
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
    if skipTypes(e.sons[i + 1].typ, abstractVarRange).kind == tyChar:
      inc(L)
      app(appends, rfmt(p.module, "#appendChar($1, $2);$n", tmp.r, rdLoc(a)))
    else:
      if e.sons[i + 1].kind in {nkStrLit..nkTripleStrLit}:
        inc(L, len(e.sons[i + 1].strVal))
      else:
        appf(lens, "$1->$2 + ", [rdLoc(a), lenField(p)])
      app(appends, rfmt(p.module, "#appendString($1, $2);$n", tmp.r, rdLoc(a)))
  linefmt(p, cpsStmts, "$1 = #rawNewString($2$3);$n", tmp.r, lens, toRope(L))
  app(p.s(cpsStmts), appends)
  if d.k == locNone:
    d = tmp
    keepAlive(p, tmp)
  else:
    genAssignment(p, d, tmp, {needToKeepAlive}) # no need for deep copying
  gcUsage(e)

proc genStrAppend(p: BProc, e: PNode, d: var TLoc) =
  #  <Nim code>
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
    if skipTypes(e.sons[i + 2].typ, abstractVarRange).kind == tyChar:
      inc(L)
      app(appends, rfmt(p.module, "#appendChar($1, $2);$n",
                        rdLoc(dest), rdLoc(a)))
    else:
      if e.sons[i + 2].kind in {nkStrLit..nkTripleStrLit}:
        inc(L, len(e.sons[i + 2].strVal))
      else:
        appf(lens, "$1->$2 + ", [rdLoc(a), lenField(p)])
      app(appends, rfmt(p.module, "#appendString($1, $2);$n",
                        rdLoc(dest), rdLoc(a)))
  linefmt(p, cpsStmts, "$1 = #resizeString($1, $2$3);$n",
          rdLoc(dest), lens, toRope(L))
  keepAlive(p, dest)
  app(p.s(cpsStmts), appends)
  gcUsage(e)

proc genSeqElemAppend(p: BProc, e: PNode, d: var TLoc) =
  # seq &= x  -->
  #    seq = (typeof seq) incrSeq(&seq->Sup, sizeof(x));
  #    seq->data[seq->len-1] = x;
  let seqAppendPattern = if not p.module.compileToCpp:
                           "$1 = ($2) #incrSeq(&($1)->Sup, sizeof($3));$n"
                         else:
                           "$1 = ($2) #incrSeq($1, sizeof($3));$n"
  var a, b, dest: TLoc
  initLocExpr(p, e.sons[1], a)
  initLocExpr(p, e.sons[2], b)
  lineCg(p, cpsStmts, seqAppendPattern, [
      rdLoc(a),
      getTypeDesc(p.module, skipTypes(e.sons[1].typ, abstractVar)),
      getTypeDesc(p.module, skipTypes(e.sons[2].typ, abstractVar))])
  keepAlive(p, a)
  initLoc(dest, locExpr, b.t, OnHeap)
  dest.r = rfmt(nil, "$1->data[$1->$2-1]", rdLoc(a), lenField(p))
  genAssignment(p, dest, b, {needToCopy, afDestIsNil})
  gcUsage(e)

proc genReset(p: BProc, n: PNode) =
  var a: TLoc
  initLocExpr(p, n.sons[1], a)
  linefmt(p, cpsStmts, "#genericReset((void*)$1, $2);$n",
          addrLoc(a), genTypeInfo(p.module, skipTypes(a.t, abstractVarRange)))

proc rawGenNew(p: BProc, a: TLoc, sizeExpr: PRope) =
  var sizeExpr = sizeExpr
  let refType = skipTypes(a.t, abstractVarRange)
  var b: TLoc
  initLoc(b, locExpr, a.t, OnHeap)
  if sizeExpr.isNil:
    sizeExpr = ropef("sizeof($1)",
        getTypeDesc(p.module, skipTypes(refType.sons[0], abstractRange)))
  let args = [getTypeDesc(p.module, refType),
              genTypeInfo(p.module, refType),
              sizeExpr]
  if a.s == OnHeap and usesNativeGC():
    # use newObjRC1 as an optimization; and we don't need 'keepAlive' either
    if canFormAcycle(a.t):
      linefmt(p, cpsStmts, "if ($1) #nimGCunref($1);$n", a.rdLoc)
    else:
      linefmt(p, cpsStmts, "if ($1) #nimGCunrefNoCycle($1);$n", a.rdLoc)
    b.r = ropecg(p.module, "($1) #newObjRC1($2, $3)", args)
    linefmt(p, cpsStmts, "$1 = $2;$n", a.rdLoc, b.rdLoc)
  else:
    b.r = ropecg(p.module, "($1) #newObj($2, $3)", args)
    genAssignment(p, a, b, {needToKeepAlive})  # set the object type:
  let bt = skipTypes(refType.sons[0], abstractRange)
  genObjectInit(p, cpsStmts, bt, a, false)

proc genNew(p: BProc, e: PNode) =
  var a: TLoc
  initLocExpr(p, e.sons[1], a)
  # 'genNew' also handles 'unsafeNew':
  if e.len == 3:
    var se: TLoc
    initLocExpr(p, e.sons[2], se)
    rawGenNew(p, a, se.rdLoc)
  else:
    rawGenNew(p, a, nil)
  gcUsage(e)

proc genNewSeqAux(p: BProc, dest: TLoc, length: PRope) =
  let seqtype = skipTypes(dest.t, abstractVarRange)
  let args = [getTypeDesc(p.module, seqtype),
              genTypeInfo(p.module, seqtype), length]
  var call: TLoc
  initLoc(call, locExpr, dest.t, OnHeap)
  if dest.s == OnHeap and usesNativeGC():
    if canFormAcycle(dest.t):
      linefmt(p, cpsStmts, "if ($1) #nimGCunref($1);$n", dest.rdLoc)
    else:
      linefmt(p, cpsStmts, "if ($1) #nimGCunrefNoCycle($1);$n", dest.rdLoc)
    call.r = ropecg(p.module, "($1) #newSeqRC1($2, $3)", args)
    linefmt(p, cpsStmts, "$1 = $2;$n", dest.rdLoc, call.rdLoc)
  else:
    call.r = ropecg(p.module, "($1) #newSeq($2, $3)", args)
    genAssignment(p, dest, call, {needToKeepAlive})

proc genNewSeq(p: BProc, e: PNode) =
  var a, b: TLoc
  initLocExpr(p, e.sons[1], a)
  initLocExpr(p, e.sons[2], b)
  genNewSeqAux(p, a, b.rdLoc)
  gcUsage(e)

proc genObjConstr(p: BProc, e: PNode, d: var TLoc) =
  var tmp: TLoc
  var t = e.typ.skipTypes(abstractInst)
  getTemp(p, t, tmp)
  let isRef = t.kind == tyRef
  var r = rdLoc(tmp)
  if isRef:
    rawGenNew(p, tmp, nil)
    t = t.lastSon.skipTypes(abstractInst)
    r = ropef("(*$1)", r)
    gcUsage(e)
  else:
    constructLoc(p, tmp)
  discard getTypeDesc(p.module, t)
  for i in 1 .. <e.len:
    let it = e.sons[i]
    var tmp2: TLoc
    tmp2.r = r
    var field: PSym = nil
    var ty = getUniqueType(t)
    while ty != nil:
      field = lookupInRecord(ty.n, it.sons[0].sym.name)
      if field != nil: break
      if not p.module.compileToCpp: app(tmp2.r, ".Sup")
      ty = getUniqueType(ty.sons[0])
    if field == nil or field.loc.r == nil: internalError(e.info, "genObjConstr")
    if it.len == 3 and optFieldCheck in p.options:
      genFieldCheck(p, it.sons[2], tmp2.r, field)
    app(tmp2.r, ".")
    app(tmp2.r, field.loc.r)
    tmp2.k = locTemp
    tmp2.t = field.loc.t
    tmp2.s = if isRef: OnHeap else: OnStack
    tmp2.heapRoot = tmp.r
    expr(p, it.sons[1], tmp2)

  if d.k == locNone:
    d = tmp
  else:
    genAssignment(p, d, tmp, {})

proc genSeqConstr(p: BProc, t: PNode, d: var TLoc) =
  var arr: TLoc
  if d.k == locNone:
    getTemp(p, t.typ, d)
  # generate call to newSeq before adding the elements per hand:
  genNewSeqAux(p, d, intLiteral(sonsLen(t)))
  for i in countup(0, sonsLen(t) - 1):
    initLoc(arr, locExpr, elemType(skipTypes(t.typ, typedescInst)), OnHeap)
    arr.r = rfmt(nil, "$1->data[$2]", rdLoc(d), intLiteral(i))
    arr.s = OnHeap            # we know that sequences are on the heap
    expr(p, t.sons[i], arr)
  gcUsage(t)

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
    elem.r = rfmt(nil, "$1->data[$2]", rdLoc(d), intLiteral(i))
    elem.s = OnHeap # we know that sequences are on the heap
    initLoc(arr, locExpr, elemType(skipTypes(t.sons[1].typ, abstractInst)), a.s)
    arr.r = rfmt(nil, "$1[$2]", rdLoc(a), intLiteral(i))
    genAssignment(p, elem, arr, {afDestIsNil, needToCopy})

proc genNewFinalize(p: BProc, e: PNode) =
  var
    a, b, f: TLoc
    refType, bt: PType
    ti: PRope
    oldModule: BModule
  refType = skipTypes(e.sons[1].typ, abstractVarRange)
  initLocExpr(p, e.sons[1], a)
  initLocExpr(p, e.sons[2], f)
  initLoc(b, locExpr, a.t, OnHeap)
  ti = genTypeInfo(p.module, refType)
  appf(p.module.s[cfsTypeInit3], "$1->finalizer = (void*)$2;$n", [ti, rdLoc(f)])
  b.r = ropecg(p.module, "($1) #newObj($2, sizeof($3))", [
      getTypeDesc(p.module, refType),
      ti, getTypeDesc(p.module, skipTypes(refType.lastSon, abstractRange))])
  genAssignment(p, a, b, {needToKeepAlive})  # set the object type:
  bt = skipTypes(refType.lastSon, abstractRange)
  genObjectInit(p, cpsStmts, bt, a, false)
  gcUsage(e)

proc genOfHelper(p: BProc; dest: PType; a: PRope): PRope =
  # unfortunately 'genTypeInfo' sets tfObjHasKids as a side effect, so we
  # have to call it here first:
  let ti = genTypeInfo(p.module, dest)
  if tfFinal in dest.flags or (p.module.objHasKidsValid and
                               tfObjHasKids notin dest.flags):
    result = ropef("$1.m_type == $2", a, ti)
  else:
    discard cgsym(p.module, "TNimType")
    inc p.module.labels
    let cache = con("Nim_OfCheck_CACHE", p.module.labels.toRope)
    appf(p.module.s[cfsVars], "static TNimType* $#[2];$n", cache)
    result = rfmt(p.module, "#isObjWithCache($#.m_type, $#, $#)", a, ti, cache)
  when false:
    # former version:
    result = rfmt(p.module, "#isObj($1.m_type, $2)",
                  a, genTypeInfo(p.module, dest))

proc genOf(p: BProc, x: PNode, typ: PType, d: var TLoc) =
  var a: TLoc
  initLocExpr(p, x, a)
  var dest = skipTypes(typ, typedescPtrs)
  var r = rdLoc(a)
  var nilCheck: PRope = nil
  var t = skipTypes(a.t, abstractInst)
  while t.kind in {tyVar, tyPtr, tyRef}:
    if t.kind != tyVar: nilCheck = r
    if t.kind != tyVar or not p.module.compileToCpp:
      r = rfmt(nil, "(*$1)", r)
    t = skipTypes(t.lastSon, typedescInst)
  if not p.module.compileToCpp:
    while t.kind == tyObject and t.sons[0] != nil:
      app(r, ~".Sup")
      t = skipTypes(t.sons[0], typedescInst)
  if isObjLackingTypeField(t):
    globalError(x.info, errGenerated,
      "no 'of' operator available for pure objects")
  if nilCheck != nil:
    r = rfmt(p.module, "(($1) && ($2))", nilCheck, genOfHelper(p, dest, r))
  else:
    r = rfmt(p.module, "($1)", genOfHelper(p, dest, r))
  putIntoDest(p, d, getSysType(tyBool), r)

proc genOf(p: BProc, n: PNode, d: var TLoc) =
  genOf(p, n.sons[1], n.sons[2].typ, d)

proc genRepr(p: BProc, e: PNode, d: var TLoc) =
  var a: TLoc
  initLocExpr(p, e.sons[1], a)
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
  of tyOpenArray, tyVarargs:
    var b: TLoc
    case a.t.kind
    of tyOpenArray, tyVarargs:
      putIntoDest(p, b, e.typ, ropef("$1, $1Len0", [rdLoc(a)]))
    of tyString, tySequence:
      putIntoDest(p, b, e.typ,
                  ropef("$1->data, $1->$2", [rdLoc(a), lenField(p)]))
    of tyArray, tyArrayConstr:
      putIntoDest(p, b, e.typ,
                  ropef("$1, $2", [rdLoc(a), toRope(lengthOrd(a.t))]))
    else: internalError(e.sons[0].info, "genRepr()")
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
  gcUsage(e)

proc genGetTypeInfo(p: BProc, e: PNode, d: var TLoc) =
  var t = skipTypes(e.sons[1].typ, abstractVarRange)
  putIntoDest(p, d, e.typ, genTypeInfo(p.module, t))

proc genDollar(p: BProc, n: PNode, d: var TLoc, frmt: string) =
  var a: TLoc
  initLocExpr(p, n.sons[1], a)
  a.r = ropecg(p.module, frmt, [rdLoc(a)])
  if d.k == locNone: getTemp(p, n.typ, d)
  genAssignment(p, d, a, {needToKeepAlive})
  gcUsage(n)

proc genArrayLen(p: BProc, e: PNode, d: var TLoc, op: TMagic) =
  var a = e.sons[1]
  if a.kind == nkHiddenAddr: a = a.sons[0]
  var typ = skipTypes(a.typ, abstractVar)
  case typ.kind
  of tyOpenArray, tyVarargs:
    if op == mHigh: unaryExpr(p, e, d, "($1Len0-1)")
    else: unaryExpr(p, e, d, "$1Len0")
  of tyCString:
    useStringh(p.module)
    if op == mHigh: unaryExpr(p, e, d, "(strlen($1)-1)")
    else: unaryExpr(p, e, d, "strlen($1)")
  of tyString, tySequence:
    if not p.module.compileToCpp:
      if op == mHigh: unaryExpr(p, e, d, "($1->Sup.len-1)")
      else: unaryExpr(p, e, d, "$1->Sup.len")
    else:
      if op == mHigh: unaryExpr(p, e, d, "($1->len-1)")
      else: unaryExpr(p, e, d, "$1->len")
  of tyArray, tyArrayConstr:
    # YYY: length(sideeffect) is optimized away incorrectly?
    if op == mHigh: putIntoDest(p, d, e.typ, toRope(lastOrd(typ)))
    else: putIntoDest(p, d, e.typ, toRope(lengthOrd(typ)))
  else: internalError(e.info, "genArrayLen()")

proc genSetLengthSeq(p: BProc, e: PNode, d: var TLoc) =
  var a, b: TLoc
  assert(d.k == locNone)
  initLocExpr(p, e.sons[1], a)
  initLocExpr(p, e.sons[2], b)
  var t = skipTypes(e.sons[1].typ, abstractVar)
  let setLenPattern = if not p.module.compileToCpp:
      "$1 = ($3) #setLengthSeq(&($1)->Sup, sizeof($4), $2);$n"
    else:
      "$1 = ($3) #setLengthSeq($1, sizeof($4), $2);$n"

  lineCg(p, cpsStmts, setLenPattern, [
      rdLoc(a), rdLoc(b), getTypeDesc(p.module, t),
      getTypeDesc(p.module, t.sons[0])])
  keepAlive(p, a)
  gcUsage(e)

proc genSetLengthStr(p: BProc, e: PNode, d: var TLoc) =
  binaryStmt(p, e, d, "$1 = #setLengthStr($1, $2);$n")
  keepAlive(p, d)
  gcUsage(e)

proc genSwap(p: BProc, e: PNode, d: var TLoc) =
  # swap(a, b) -->
  # temp = a
  # a = b
  # b = temp
  var a, b, tmp: TLoc
  getTemp(p, skipTypes(e.sons[1].typ, abstractVar), tmp)
  initLocExpr(p, e.sons[1], a) # eval a
  initLocExpr(p, e.sons[2], b) # eval b
  genAssignment(p, tmp, a, {})
  genAssignment(p, a, b, {})
  genAssignment(p, b, tmp, {})

proc rdSetElemLoc(a: TLoc, setType: PType): PRope =
  # read a location of an set element; it may need a subtraction operation
  # before the set operation
  result = rdCharLoc(a)
  assert(setType.kind == tySet)
  if firstOrd(setType) != 0:
    result = ropef("($1- $2)", [result, toRope(firstOrd(setType))])

proc fewCmps(s: PNode): bool =
  # this function estimates whether it is better to emit code
  # for constructing the set or generating a bunch of comparisons directly
  if s.kind != nkCurly: internalError(s.info, "fewCmps")
  if (getSize(s.typ) <= platform.intSize) and (nfAllConst in s.flags):
    result = false            # it is better to emit the set generation code
  elif elemType(s.typ).kind in {tyInt, tyInt16..tyInt64}:
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
  initLocExpr(p, e.sons[1], a)
  initLocExpr(p, e.sons[2], b)
  lineF(p, cpsStmts, frmt, [rdLoc(a), rdSetElemLoc(b, a.t)])

proc genInOp(p: BProc, e: PNode, d: var TLoc) =
  var a, b, x, y: TLoc
  if (e.sons[1].kind == nkCurly) and fewCmps(e.sons[1]):
    # a set constructor but not a constant set:
    # do not emit the set, but generate a bunch of comparisons; and if we do
    # so, we skip the unnecessary range check: This is a semantical extension
    # that code now relies on. :-/ XXX
    let ea = if e.sons[2].kind in {nkChckRange, nkChckRange64}:
               e.sons[2].sons[0]
             else:
               e.sons[2]
    initLocExpr(p, ea, a)
    initLoc(b, locExpr, e.typ, OnUnknown)
    b.r = toRope("(")
    var length = sonsLen(e.sons[1])
    for i in countup(0, length - 1):
      if e.sons[1].sons[i].kind == nkRange:
        initLocExpr(p, e.sons[1].sons[i].sons[0], x)
        initLocExpr(p, e.sons[1].sons[i].sons[1], y)
        appf(b.r, "$1 >= $2 && $1 <= $3",
             [rdCharLoc(a), rdCharLoc(x), rdCharLoc(y)])
      else:
        initLocExpr(p, e.sons[1].sons[i], x)
        appf(b.r, "$1 == $2", [rdCharLoc(a), rdCharLoc(x)])
      if i < length - 1: app(b.r, " || ")
    app(b.r, ")")
    putIntoDest(p, d, e.typ, b.r)
  else:
    assert(e.sons[1].typ != nil)
    assert(e.sons[2].typ != nil)
    initLocExpr(p, e.sons[1], a)
    initLocExpr(p, e.sons[2], b)
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
  var setType = skipTypes(e.sons[1].typ, abstractVar)
  var size = int(getSize(setType))
  case size
  of 1, 2, 4, 8:
    case op
    of mIncl:
      var ts = "NI" & $(size * 8)
      binaryStmtInExcl(p, e, d,
          "$1 |= ((" & ts & ")1)<<(($2)%(sizeof(" & ts & ")*8));$n")
    of mExcl:
      var ts = "NI" & $(size * 8)
      binaryStmtInExcl(p, e, d, "$1 &= ~(((" & ts & ")1) << (($2) % (sizeof(" &
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
      if d.k == locNone: getTemp(p, getSysType(tyBool), d)
      lineF(p, cpsStmts, lookupOpr[op],
           [rdLoc(i), toRope(size), rdLoc(d), rdLoc(a), rdLoc(b)])
    of mEqSet:
      useStringh(p.module)
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

proc genSomeCast(p: BProc, e: PNode, d: var TLoc) =
  const
    ValueTypes = {tyTuple, tyObject, tyArray, tyOpenArray, tyVarargs,
                  tyArrayConstr}
  # we use whatever C gives us. Except if we have a value-type, we need to go
  # through its address:
  var a: TLoc
  initLocExpr(p, e.sons[1], a)
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

proc genCast(p: BProc, e: PNode, d: var TLoc) =
  const floatTypes = {tyFloat..tyFloat128}
  let
    destt = skipTypes(e.typ, abstractRange)
    srct = skipTypes(e.sons[1].typ, abstractRange)
  if destt.kind in floatTypes or srct.kind in floatTypes:
    # 'cast' and some float type involved? --> use a union.
    inc(p.labels)
    var lbl = p.labels.toRope
    var tmp: TLoc
    tmp.r = ropef("LOC$1.source", lbl)
    linefmt(p, cpsLocals, "union { $1 source; $2 dest; } LOC$3;$n",
      getTypeDesc(p.module, srct), getTypeDesc(p.module, destt), lbl)
    tmp.k = locExpr
    tmp.t = srct
    tmp.s = OnStack
    tmp.flags = {}
    expr(p, e.sons[1], tmp)
    putIntoDest(p, d, e.typ, ropef("LOC$#.dest", lbl))
  else:
    # I prefer the shorter cast version for pointer types -> generate less
    # C code; plus it's the right thing to do for closures:
    genSomeCast(p, e, d)

proc genRangeChck(p: BProc, n: PNode, d: var TLoc, magic: string) =
  var a: TLoc
  var dest = skipTypes(n.typ, abstractVar)
  # range checks for unsigned turned out to be buggy and annoying:
  if optRangeCheck notin p.options or dest.kind in {tyUInt..tyUInt64}:
    initLocExpr(p, n.sons[0], a)
    putIntoDest(p, d, n.typ, ropef("(($1) ($2))",
        [getTypeDesc(p.module, dest), rdCharLoc(a)]))
  else:
    initLocExpr(p, n.sons[0], a)
    if leValue(n.sons[2], n.sons[1]):
      internalError(n.info, "range check will always fail; empty range")
    putIntoDest(p, d, dest, ropecg(p.module, "(($1)#$5($2, $3, $4))", [
        getTypeDesc(p.module, dest), rdCharLoc(a),
        genLiteral(p, n.sons[1], dest), genLiteral(p, n.sons[2], dest),
        toRope(magic)]))

proc genConv(p: BProc, e: PNode, d: var TLoc) =
  let destType = e.typ.skipTypes({tyVar, tyGenericInst})
  if compareTypes(destType, e.sons[1].typ, dcEqIgnoreDistinct):
    expr(p, e.sons[1], d)
  else:
    genSomeCast(p, e, d)

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
  gcUsage(n)

proc genStrEquals(p: BProc, e: PNode, d: var TLoc) =
  var x: TLoc
  var a = e.sons[1]
  var b = e.sons[2]
  if (a.kind == nkNilLit) or (b.kind == nkNilLit):
    binaryExpr(p, e, d, "($1 == $2)")
  elif (a.kind in {nkStrLit..nkTripleStrLit}) and (a.strVal == ""):
    initLocExpr(p, e.sons[2], x)
    putIntoDest(p, d, e.typ,
      rfmt(nil, "(($1) && ($1)->$2 == 0)", rdLoc(x), lenField(p)))
  elif (b.kind in {nkStrLit..nkTripleStrLit}) and (b.strVal == ""):
    initLocExpr(p, e.sons[1], x)
    putIntoDest(p, d, e.typ,
      rfmt(nil, "(($1) && ($1)->$2 == 0)", rdLoc(x), lenField(p)))
  else:
    binaryExpr(p, e, d, "#eqStrings($1, $2)")

proc binaryFloatArith(p: BProc, e: PNode, d: var TLoc, m: TMagic) =
  if {optNaNCheck, optInfCheck} * p.options != {}:
    const opr: array[mAddF64..mDivF64, string] = ["+", "-", "*", "/"]
    var a, b: TLoc
    assert(e.sons[1].typ != nil)
    assert(e.sons[2].typ != nil)
    initLocExpr(p, e.sons[1], a)
    initLocExpr(p, e.sons[2], b)
    putIntoDest(p, d, e.typ, rfmt(nil, "(($4)($2) $1 ($4)($3))",
                                  toRope(opr[m]), rdLoc(a), rdLoc(b),
                                  getSimpleTypeDesc(p.module, e[1].typ)))
    if optNaNCheck in p.options:
      linefmt(p, cpsStmts, "#nanCheck($1);$n", rdLoc(d))
    if optInfCheck in p.options:
      linefmt(p, cpsStmts, "#infCheck($1);$n", rdLoc(d))
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
  of mEqProc: genEqProc(p, e, d)
  of mAddI..mPred: binaryArithOverflow(p, e, d, op)
  of mRepr: genRepr(p, e, d)
  of mGetTypeInfo: genGetTypeInfo(p, e, d)
  of mSwap: genSwap(p, e, d)
  of mUnaryLt:
    if optOverflowCheck notin p.options: unaryExpr(p, e, d, "($1 - 1)")
    else: unaryExpr(p, e, d, "#subInt($1, 1)")
  of mInc, mDec:
    const opr: array [mInc..mDec, string] = ["$1 += $2;$n", "$1 -= $2;$n"]
    const fun64: array [mInc..mDec, string] = ["$# = #addInt64($#, $#);$n",
                                               "$# = #subInt64($#, $#);$n"]
    const fun: array [mInc..mDec, string] = ["$# = #addInt($#, $#);$n",
                                             "$# = #subInt($#, $#);$n"]
    if optOverflowCheck notin p.options:
      binaryStmt(p, e, d, opr[op])
    else:
      var a, b: TLoc
      assert(e.sons[1].typ != nil)
      assert(e.sons[2].typ != nil)
      initLocExpr(p, e.sons[1], a)
      initLocExpr(p, e.sons[2], b)

      let underlying = skipTypes(e.sons[1].typ, {tyGenericInst, tyVar, tyRange})
      let ranged = skipTypes(e.sons[1].typ, {tyGenericInst, tyVar})
      let res = binaryArithOverflowRaw(p, ranged, a, b,
        if underlying.kind == tyInt64: fun64[op] else: fun[op])
      putIntoDest(p, a, ranged, ropef("($#)($#)", [
        getTypeDesc(p.module, ranged), res]))

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
  of mIsNil: genIsNil(p, e, d)
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
    let t = e.sons[1].typ.skipTypes({tyTypeDesc})
    putIntoDest(p, d, e.typ, ropef("((NI)sizeof($1))",
                                   [getTypeDesc(p.module, t)]))
  of mChr: genSomeCast(p, e, d)
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
  of mNewString, mNewStringOfCap, mCopyStr, mCopyStrLast, mExit,
      mParseBiggestFloat:
    var opr = e.sons[0].sym
    if lfNoDecl notin opr.loc.flags:
      discard cgsym(p.module, opr.loc.r.ropeToStr)
    genCall(p, e, d)
  of mReset: genReset(p, e)
  of mEcho: genEcho(p, e[1].skipConv)
  of mArrToSeq: genArrToSeq(p, e, d)
  of mNLen..mNError:
    localError(e.info, errCannotGenerateCodeForX, e.sons[0].sym.name.s)
  of mSlurp..mQuoteAst:
    localError(e.info, errXMustBeCompileTime, e.sons[0].sym.name.s)
  of mSpawn:
    let n = lowerings.wrapProcForSpawn(p.module.module, e, e.typ, nil, nil)
    expr(p, n, d)
  of mParallel:
    let n = semparallel.liftParallel(p.module.module, e)
    expr(p, n, d)
  of mDeepCopy:
    var a, b: TLoc
    let x = if e[1].kind in {nkAddr, nkHiddenAddr}: e[1][0] else: e[1]
    initLocExpr(p, x, a)
    initLocExpr(p, e.sons[2], b)
    genDeepCopy(p, a, b)
  else: internalError(e.info, "genMagicExpr: " & $op)

proc genConstExpr(p: BProc, n: PNode): PRope
proc handleConstExpr(p: BProc, n: PNode, d: var TLoc): bool =
  if nfAllConst in n.flags and d.k == locNone and n.len > 0 and n.isDeepConstExpr:
    var t = getUniqueType(n.typ)
    discard getTypeDesc(p.module, t) # so that any fields are initialized
    var id = nodeTableTestOrSet(p.module.dataCache, n, gBackendId)
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
      useStringh(p.module)
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

proc isConstClosure(n: PNode): bool {.inline.} =
  result = n.sons[0].kind == nkSym and isRoutine(n.sons[0].sym) and
      n.sons[1].kind == nkNilLit

proc genClosure(p: BProc, n: PNode, d: var TLoc) =
  assert n.kind == nkClosure

  if isConstClosure(n):
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
    linefmt(p, cpsStmts, "$1.ClPrc = $2; $1.ClEnv = $3;$n",
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
  if optObjCheck in p.options and not isObjLackingTypeField(dest):
    var r = rdLoc(a)
    var nilCheck: PRope = nil
    var t = skipTypes(a.t, abstractInst)
    while t.kind in {tyVar, tyPtr, tyRef}:
      if t.kind != tyVar: nilCheck = r
      if t.kind != tyVar or not p.module.compileToCpp:
        r = ropef("(*$1)", [r])
      t = skipTypes(t.lastSon, abstractInst)
    if not p.module.compileToCpp:
      while t.kind == tyObject and t.sons[0] != nil:
        app(r, ".Sup")
        t = skipTypes(t.sons[0], abstractInst)
    if nilCheck != nil:
      linefmt(p, cpsStmts, "if ($1) #chckObj($2.m_type, $3);$n",
              nilCheck, r, genTypeInfo(p.module, dest))
    else:
      linefmt(p, cpsStmts, "#chckObj($1.m_type, $2);$n",
              r, genTypeInfo(p.module, dest))
  if n.sons[0].typ.kind != tyObject:
    putIntoDest(p, d, n.typ,
                ropef("(($1) ($2))", [getTypeDesc(p.module, n.typ), rdLoc(a)]))
  else:
    putIntoDest(p, d, n.typ, ropef("(*($1*) ($2))",
                                   [getTypeDesc(p.module, dest), addrLoc(a)]))

proc downConv(p: BProc, n: PNode, d: var TLoc) =
  if p.module.compileToCpp:
    expr(p, n.sons[0], d)     # downcast does C++ for us
  else:
    var dest = skipTypes(n.typ, abstractPtrs)

    var arg = n.sons[0]
    while arg.kind == nkObjDownConv: arg = arg.sons[0]

    var src = skipTypes(arg.typ, abstractPtrs)
    var a: TLoc
    initLocExpr(p, arg, a)
    var r = rdLoc(a)
    let isRef = skipTypes(arg.typ, abstractInst).kind in {tyRef, tyPtr, tyVar}
    if isRef:
      app(r, "->Sup")
    else:
      app(r, ".Sup")
    for i in countup(2, abs(inheritanceDiff(dest, src))): app(r, ".Sup")
    if isRef:
      # it can happen that we end up generating '&&x->Sup' here, so we pack
      # the '&x->Sup' into a temporary and then those address is taken
      # (see bug #837). However sometimes using a temporary is not correct:
      # init(TFigure(my)) # where it is passed to a 'var TFigure'. We test
      # this by ensuring the destination is also a pointer:
      if d.k == locNone and skipTypes(n.typ, abstractInst).kind in {tyRef, tyPtr, tyVar}:
        getTemp(p, n.typ, d)
        linefmt(p, cpsStmts, "$1 = &$2;$n", rdLoc(d), r)
      else:
        r = con("&", r)
        putIntoDest(p, d, n.typ, r)
    else:
      putIntoDest(p, d, n.typ, r)

proc exprComplexConst(p: BProc, n: PNode, d: var TLoc) =
  var t = getUniqueType(n.typ)
  discard getTypeDesc(p.module, t) # so that any fields are initialized
  var id = nodeTableTestOrSet(p.module.dataCache, n, gBackendId)
  var tmp = con("TMP", toRope(id))

  if id == gBackendId:
    # expression not found in the cache:
    inc(gBackendId)
    appf(p.module.s[cfsData], "NIM_CONST $1 $2 = $3;$n",
         [getTypeDesc(p.module, t), tmp, genConstExpr(p, n)])

  if d.k == locNone:
    fillLoc(d, locData, t, tmp, OnHeap)
  else:
    putDataIntoDest(p, d, t, tmp)

proc expr(p: BProc, n: PNode, d: var TLoc) =
  case n.kind
  of nkSym:
    var sym = n.sym
    case sym.kind
    of skMethod:
      if {sfDispatcher, sfForward} * sym.flags != {}:
        # we cannot produce code for the dispatcher yet:
        fillProcLoc(sym)
        genProcPrototype(p.module, sym)
      else:
        genProc(p.module, sym)
      putLocIntoDest(p, d, sym.loc)
    of skProc, skConverter, skIterators:
      genProc(p.module, sym)
      if sym.loc.r == nil or sym.loc.t == nil:
        internalError(n.info, "expr: proc not init " & sym.name.s)
      putLocIntoDest(p, d, sym.loc)
    of skConst:
      if sfFakeConst in sym.flags:
        if sfGlobal in sym.flags: genVarPrototype(p.module, sym)
        putLocIntoDest(p, d, sym.loc)
      elif isSimpleConst(sym.typ):
        putIntoDest(p, d, n.typ, genLiteral(p, sym.ast, sym.typ))
      else:
        genComplexConst(p, sym, d)
    of skEnumField:
      putIntoDest(p, d, n.typ, toRope(sym.position))
    of skVar, skForVar, skResult, skLet:
      if sfGlobal in sym.flags: genVarPrototype(p.module, sym)
      if sym.loc.r == nil or sym.loc.t == nil:
        #echo "FAILED FOR PRCO ", p.prc.name.s
        internalError n.info, "expr: var not init " & sym.name.s & "_" & $sym.id
      if sfThread in sym.flags:
        accessThreadLocalVar(p, sym)
        if emulatedThreadVars():
          putIntoDest(p, d, sym.loc.t, con("NimTV->", sym.loc.r))
        else:
          putLocIntoDest(p, d, sym.loc)
      else:
        putLocIntoDest(p, d, sym.loc)
    of skTemp:
      if sym.loc.r == nil or sym.loc.t == nil:
        #echo "FAILED FOR PRCO ", p.prc.name.s
        #echo renderTree(p.prc.ast, {renderIds})
        internalError(n.info, "expr: temp not init " & sym.name.s & "_" & $sym.id)
      putLocIntoDest(p, d, sym.loc)
    of skParam:
      if sym.loc.r == nil or sym.loc.t == nil:
        #echo "FAILED FOR PRCO ", p.prc.name.s
        #debug p.prc.typ.n
        #echo renderTree(p.prc.ast, {renderIds})
        internalError(n.info, "expr: param not init " & sym.name.s & "_" & $sym.id)
      putLocIntoDest(p, d, sym.loc)
    else: internalError(n.info, "expr(" & $sym.kind & "); unknown symbol")
  of nkNilLit:
    if not isEmptyType(n.typ):
      putIntoDest(p, d, n.typ, genLiteral(p, n))
  of nkStrLit..nkTripleStrLit:
    putDataIntoDest(p, d, n.typ, genLiteral(p, n))
  of nkIntLit..nkUInt64Lit,
     nkFloatLit..nkFloat128Lit, nkCharLit:
    putIntoDest(p, d, n.typ, genLiteral(p, n))
  of nkCall, nkHiddenCallConv, nkInfix, nkPrefix, nkPostfix, nkCommand,
     nkCallStrLit:
    genLineDir(p, n)
    let op = n.sons[0]
    if n.typ.isNil:
      # discard the value:
      var a: TLoc
      if op.kind == nkSym and op.sym.magic != mNone:
        genMagicExpr(p, n, a, op.sym.magic)
      else:
        genCall(p, n, a)
    else:
      # load it into 'd':
      if op.kind == nkSym and op.sym.magic != mNone:
        genMagicExpr(p, n, d, op.sym.magic)
      else:
        genCall(p, n, d)
  of nkCurly:
    if isDeepConstExpr(n) and n.len != 0:
      putIntoDest(p, d, n.typ, genSetNode(p, n))
    else:
      genSetConstr(p, n, d)
  of nkBracket:
    if isDeepConstExpr(n) and n.len != 0:
      exprComplexConst(p, n, d)
    elif skipTypes(n.typ, abstractVarRange).kind == tySequence:
      genSeqConstr(p, n, d)
    else:
      genArrayConstr(p, n, d)
  of nkPar:
    if isDeepConstExpr(n) and n.len != 0:
      exprComplexConst(p, n, d)
    else:
      genTupleConstr(p, n, d)
  of nkObjConstr: genObjConstr(p, n, d)
  of nkCast: genCast(p, n, d)
  of nkHiddenStdConv, nkHiddenSubConv, nkConv: genConv(p, n, d)
  of nkHiddenAddr, nkAddr: genAddr(p, n, d)
  of nkBracketExpr: genBracketExpr(p, n, d)
  of nkDerefExpr, nkHiddenDeref: genDeref(p, n, d)
  of nkDotExpr: genRecordField(p, n, d)
  of nkCheckedFieldExpr: genCheckedRecordField(p, n, d)
  of nkBlockExpr, nkBlockStmt: genBlock(p, n, d)
  of nkStmtListExpr: genStmtListExpr(p, n, d)
  of nkStmtList:
    for i in countup(0, sonsLen(n) - 1): genStmts(p, n.sons[i])
  of nkIfExpr, nkIfStmt: genIf(p, n, d)
  of nkObjDownConv: downConv(p, n, d)
  of nkObjUpConv: upConv(p, n, d)
  of nkChckRangeF: genRangeChck(p, n, d, "chckRangeF")
  of nkChckRange64: genRangeChck(p, n, d, "chckRange64")
  of nkChckRange: genRangeChck(p, n, d, "chckRange")
  of nkStringToCString: convStrToCStr(p, n, d)
  of nkCStringToString: convCStrToStr(p, n, d)
  of nkLambdaKinds:
    var sym = n.sons[namePos].sym
    genProc(p.module, sym)
    if sym.loc.r == nil or sym.loc.t == nil:
      internalError(n.info, "expr: proc not init " & sym.name.s)
    putLocIntoDest(p, d, sym.loc)
  of nkClosure: genClosure(p, n, d)

  of nkEmpty: discard
  of nkWhileStmt: genWhileStmt(p, n)
  of nkVarSection, nkLetSection: genVarStmt(p, n)
  of nkConstSection: genConstStmt(p, n)
  of nkForStmt: internalError(n.info, "for statement not eliminated")
  of nkCaseStmt: genCase(p, n, d)
  of nkReturnStmt: genReturnStmt(p, n)
  of nkBreakStmt: genBreakStmt(p, n)
  of nkAsgn: genAsgn(p, n, fastAsgn=false)
  of nkFastAsgn:
    # transf is overly aggressive with 'nkFastAsgn', so we work around here.
    # See tests/run/tcnstseq3 for an example that would fail otherwise.
    genAsgn(p, n, fastAsgn=p.prc != nil)
  of nkDiscardStmt:
    if n.sons[0].kind != nkEmpty:
      genLineDir(p, n)
      var a: TLoc
      initLocExpr(p, n.sons[0], a)
  of nkAsmStmt: genAsmStmt(p, n)
  of nkTryStmt:
    if p.module.compileToCpp: genTryCpp(p, n, d)
    else: genTry(p, n, d)
  of nkRaiseStmt: genRaiseStmt(p, n)
  of nkTypeSection:
    # we have to emit the type information for object types here to support
    # separate compilation:
    genTypeSection(p.module, n)
  of nkCommentStmt, nkIteratorDef, nkIncludeStmt,
     nkImportStmt, nkImportExceptStmt, nkExportStmt, nkExportExceptStmt,
     nkFromStmt, nkTemplateDef, nkMacroDef:
    discard
  of nkPragma: genPragma(p, n)
  of nkPragmaBlock: expr(p, n.lastSon, d)
  of nkProcDef, nkMethodDef, nkConverterDef:
    if n.sons[genericParamsPos].kind == nkEmpty:
      var prc = n.sons[namePos].sym
      # due to a bug/limitation in the lambda lifting, unused inner procs
      # are not transformed correctly. We work around this issue (#411) here
      # by ensuring it's no inner proc (owner is a module):
      if prc.skipGenericOwner.kind == skModule:
        if (optDeadCodeElim notin gGlobalOptions and
            sfDeadCodeElim notin getModule(prc).flags) or
            ({sfExportc, sfCompilerProc} * prc.flags == {sfExportc}) or
            (sfExportc in prc.flags and lfExportLib in prc.loc.flags) or
            (prc.kind == skMethod):
          # we have not only the header:
          if prc.getBody.kind != nkEmpty or lfDynamicLib in prc.loc.flags:
            genProc(p.module, prc)
  of nkParForStmt: genParForStmt(p, n)
  of nkState: genState(p, n)
  of nkGotoState: genGotoState(p, n)
  of nkBreakState: genBreakState(p, n)
  else: internalError(n.info, "expr(" & $n.kind & "); unknown node kind")

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
  case n.kind
  of nkHiddenStdConv, nkHiddenSubConv:
    result = genConstExpr(p, n.sons[1])
  of nkCurly:
    var cs: TBitSet
    toBitSet(n, cs)
    result = genRawSetData(cs, int(getSize(n.typ)))
  of nkBracket, nkPar, nkClosure, nkObjConstr:
    var t = skipTypes(n.typ, abstractInst)
    if t.kind == tySequence:
      result = genConstSeq(p, n, t)
    else:
      result = genConstSimpleList(p, n)
  else:
    var d: TLoc
    initLocExpr(p, n, d)
    result = rdLoc(d)
