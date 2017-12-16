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

proc int64Literal(i: BiggestInt): Rope =
  if i > low(int64):
    result = rfmt(nil, "IL64($1)", rope(i))
  else:
    result = ~"(IL64(-9223372036854775807) - IL64(1))"

proc uint64Literal(i: uint64): Rope = rope($i & "ULL")

proc intLiteral(i: BiggestInt): Rope =
  if i > low(int32) and i <= high(int32):
    result = rope(i)
  elif i == low(int32):
    # Nim has the same bug for the same reasons :-)
    result = ~"(-2147483647 -1)"
  elif i > low(int64):
    result = rfmt(nil, "IL64($1)", rope(i))
  else:
    result = ~"(IL64(-9223372036854775807) - IL64(1))"

proc getStrLit(m: BModule, s: string): Rope =
  discard cgsym(m, "TGenericSeq")
  result = getTempName(m)
  addf(m.s[cfsData], "STRING_LITERAL($1, $2, $3);$n",
       [result, makeCString(s), rope(len(s))])

proc genLiteral(p: BProc, n: PNode, ty: PType): Rope =
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
      result = "(($1) $2)" % [getTypeDesc(p.module,
          ty), intLiteral(n.intVal)]
  of nkNilLit:
    let t = skipTypes(ty, abstractVarRange)
    if t.kind == tyProc and t.callConv == ccClosure:
      let id = nodeTableTestOrSet(p.module.dataCache, n, p.module.labels)
      result = p.module.tmpBase & rope(id)
      if id == p.module.labels:
        # not found in cache:
        inc(p.module.labels)
        addf(p.module.s[cfsData],
             "static NIM_CONST $1 $2 = {NIM_NIL,NIM_NIL};$n",
             [getTypeDesc(p.module, ty), result])
    else:
      result = rope("NIM_NIL")
  of nkStrLit..nkTripleStrLit:
    if n.strVal.isNil:
      result = ropecg(p.module, "((#NimStringDesc*) NIM_NIL)", [])
    elif skipTypes(ty, abstractVarRange).kind == tyString:
      let id = nodeTableTestOrSet(p.module.dataCache, n, p.module.labels)
      if id == p.module.labels:
        # string literal not found in the cache:
        result = ropecg(p.module, "((#NimStringDesc*) &$1)",
                        [getStrLit(p.module, n.strVal)])
      else:
        result = ropecg(p.module, "((#NimStringDesc*) &$1$2)",
                        [p.module.tmpBase, rope(id)])
    else:
      result = makeCString(n.strVal)
  of nkFloatLit, nkFloat64Lit:
    result = rope(n.floatVal.toStrMaxPrecision)
  of nkFloat32Lit:
    result = rope(n.floatVal.toStrMaxPrecision("f"))
  else:
    internalError(n.info, "genLiteral(" & $n.kind & ')')
    result = nil

proc genLiteral(p: BProc, n: PNode): Rope =
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

proc genRawSetData(cs: TBitSet, size: int): Rope =
  var frmt: FormatStr
  if size > 8:
    result = "{$n" % []
    for i in countup(0, size - 1):
      if i < size - 1:
        # not last iteration?
        if (i + 1) mod 8 == 0: frmt = "0x$1,$n"
        else: frmt = "0x$1, "
      else:
        frmt = "0x$1}$n"
      addf(result, frmt, [rope(toHex(ze64(cs[i]), 2))])
  else:
    result = intLiteral(bitSetToWord(cs, size))
    #  result := rope('0x' + ToHex(bitSetToWord(cs, size), size * 2))

proc genSetNode(p: BProc, n: PNode): Rope =
  var cs: TBitSet
  var size = int(getSize(n.typ))
  toBitSet(n, cs)
  if size > 8:
    let id = nodeTableTestOrSet(p.module.dataCache, n, p.module.labels)
    result = p.module.tmpBase & rope(id)
    if id == p.module.labels:
      # not found in cache:
      inc(p.module.labels)
      addf(p.module.s[cfsData], "static NIM_CONST $1 $2 = $3;$n",
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

proc canMove(n: PNode): bool =
  # for now we're conservative here:
  if n.kind == nkBracket:
    # This needs to be kept consistent with 'const' seq code
    # generation!
    if not isDeepConstExpr(n) or n.len == 0:
      if skipTypes(n.typ, abstractVarRange).kind == tySequence:
        return true
  result = n.kind in nkCallKinds
  #if result:
  #  echo n.info, " optimized ", n
  #  result = false

proc genRefAssign(p: BProc, dest, src: TLoc, flags: TAssignmentFlags) =
  if dest.storage == OnStack or not usesNativeGC():
    linefmt(p, cpsStmts, "$1 = $2;$n", rdLoc(dest), rdLoc(src))
  elif dest.storage == OnHeap:
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

proc optAsgnLoc(a: TLoc, t: PType, field: Rope): TLoc =
  assert field != nil
  result.k = locField
  result.storage = a.storage
  result.lode = lodeTyp t
  result.r = rdLoc(a) & "." & field

proc genOptAsgnTuple(p: BProc, dest, src: TLoc, flags: TAssignmentFlags) =
  let newflags =
    if src.storage == OnStatic:
      flags + {needToCopy}
    elif tfShallow in dest.t.flags:
      flags - {needToCopy}
    else:
      flags
  let t = skipTypes(dest.t, abstractInst).getUniqueType()
  for i in 0 ..< t.len:
    let t = t.sons[i]
    let field = "Field$1" % [i.rope]
    genAssignment(p, optAsgnLoc(dest, t, field),
                     optAsgnLoc(src, t, field), newflags)

proc genOptAsgnObject(p: BProc, dest, src: TLoc, flags: TAssignmentFlags,
                      t: PNode, typ: PType) =
  if t == nil: return
  let newflags =
    if src.storage == OnStatic:
      flags + {needToCopy}
    elif tfShallow in dest.t.flags:
      flags - {needToCopy}
    else:
      flags
  case t.kind
  of nkSym:
    let field = t.sym
    if field.loc.r == nil: fillObjectFields(p.module, typ)
    genAssignment(p, optAsgnLoc(dest, field.typ, field.loc.r),
                     optAsgnLoc(src, field.typ, field.loc.r), newflags)
  of nkRecList:
    for child in items(t): genOptAsgnObject(p, dest, src, newflags, child, typ)
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
    if dest.storage == OnStack or not usesNativeGC():
      useStringh(p.module)
      linefmt(p, cpsStmts,
           "memcpy((void*)$1, (NIM_CONST void*)$2, sizeof($3));$n",
           addrLoc(dest), addrLoc(src), rdLoc(dest))
    else:
      linefmt(p, cpsStmts, "#genericShallowAssign((void*)$1, (void*)$2, $3);$n",
              addrLoc(dest), addrLoc(src), genTypeInfo(p.module, dest.t, dest.lode.info))
  else:
    linefmt(p, cpsStmts, "#genericAssign((void*)$1, (void*)$2, $3);$n",
            addrLoc(dest), addrLoc(src), genTypeInfo(p.module, dest.t, dest.lode.info))

proc genAssignment(p: BProc, dest, src: TLoc, flags: TAssignmentFlags) =
  # This function replaces all other methods for generating
  # the assignment operation in C.
  if src.t != nil and src.t.kind == tyPtr:
    # little HACK to support the new 'var T' as return type:
    linefmt(p, cpsStmts, "$1 = $2;$n", rdLoc(dest), rdLoc(src))
    return
  let ty = skipTypes(dest.t, abstractRange + tyUserTypeClasses)
  case ty.kind
  of tyRef:
    genRefAssign(p, dest, src, flags)
  of tySequence:
    if (needToCopy notin flags and src.storage != OnStatic) or canMove(src.lode):
      genRefAssign(p, dest, src, flags)
    else:
      linefmt(p, cpsStmts, "#genericSeqAssign($1, $2, $3);$n",
              addrLoc(dest), rdLoc(src),
              genTypeInfo(p.module, dest.t, dest.lode.info))
  of tyString:
    if (needToCopy notin flags and src.storage != OnStatic) or canMove(src.lode):
      genRefAssign(p, dest, src, flags)
    else:
      if dest.storage == OnStack or not usesNativeGC():
        linefmt(p, cpsStmts, "$1 = #copyString($2);$n", dest.rdLoc, src.rdLoc)
      elif dest.storage == OnHeap:
        # we use a temporary to care for the dreaded self assignment:
        var tmp: TLoc
        getTemp(p, ty, tmp)
        linefmt(p, cpsStmts, "$3 = $1; $1 = #copyStringRC1($2);$n",
                dest.rdLoc, src.rdLoc, tmp.rdLoc)
        linefmt(p, cpsStmts, "if ($1) #nimGCunrefNoCycle($1);$n", tmp.rdLoc)
      else:
        linefmt(p, cpsStmts, "#unsureAsgnRef((void**) $1, #copyString($2));$n",
               addrLoc(dest), rdLoc(src))
  of tyProc:
    if needsComplexAssignment(dest.t):
      # optimize closure assignment:
      let a = optAsgnLoc(dest, dest.t, "ClE_0".rope)
      let b = optAsgnLoc(src, dest.t, "ClE_0".rope)
      genRefAssign(p, a, b, flags)
      linefmt(p, cpsStmts, "$1.ClP_0 = $2.ClP_0;$n", rdLoc(dest), rdLoc(src))
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
        internalAssert ty.n != nil
        genOptAsgnObject(p, dest, src, flags, ty.n, ty)
      else:
        genGenericAsgn(p, dest, src, flags)
    else:
      linefmt(p, cpsStmts, "$1 = $2;$n", rdLoc(dest), rdLoc(src))
  of tyArray:
    if needsComplexAssignment(dest.t):
      genGenericAsgn(p, dest, src, flags)
    else:
      useStringh(p.module)
      linefmt(p, cpsStmts,
           "memcpy((void*)$1, (NIM_CONST void*)$2, sizeof($3));$n",
           rdLoc(dest), rdLoc(src), getTypeDesc(p.module, dest.t))
  of tyOpenArray, tyVarargs:
    # open arrays are always on the stack - really? What if a sequence is
    # passed to an open array?
    if needsComplexAssignment(dest.t):
      linefmt(p, cpsStmts,     # XXX: is this correct for arrays?
           "#genericAssignOpenArray((void*)$1, (void*)$2, $1Len_0, $3);$n",
           addrLoc(dest), addrLoc(src),
           genTypeInfo(p.module, dest.t, dest.lode.info))
    else:
      useStringh(p.module)
      linefmt(p, cpsStmts,
           "memcpy((void*)$1, (NIM_CONST void*)$2, sizeof($1[0])*$1Len_0);$n",
           rdLoc(dest), rdLoc(src))
  of tySet:
    if mapType(ty) == ctArray:
      useStringh(p.module)
      linefmt(p, cpsStmts, "memcpy((void*)$1, (NIM_CONST void*)$2, $3);$n",
              rdLoc(dest), rdLoc(src), rope(getSize(dest.t)))
    else:
      linefmt(p, cpsStmts, "$1 = $2;$n", rdLoc(dest), rdLoc(src))
  of tyPtr, tyPointer, tyChar, tyBool, tyEnum, tyCString,
     tyInt..tyUInt64, tyRange, tyVar:
    linefmt(p, cpsStmts, "$1 = $2;$n", rdLoc(dest), rdLoc(src))
  else: internalError("genAssignment: " & $ty.kind)

  if optMemTracker in p.options and dest.storage in {OnHeap, OnUnknown}:
    #writeStackTrace()
    #echo p.currLineInfo, " requesting"
    linefmt(p, cpsStmts, "#memTrackerWrite((void*)$1, $2, $3, $4);$n",
            addrLoc(dest), rope getSize(dest.t),
            makeCString(p.currLineInfo.toFullPath),
            rope p.currLineInfo.safeLineNm)

proc genDeepCopy(p: BProc; dest, src: TLoc) =
  template addrLocOrTemp(a: TLoc): Rope =
    if a.k == locExpr:
      var tmp: TLoc
      getTemp(p, a.t, tmp)
      genAssignment(p, tmp, a, {})
      addrLoc(tmp)
    else:
      addrLoc(a)

  var ty = skipTypes(dest.t, abstractVarRange)
  case ty.kind
  of tyPtr, tyRef, tyProc, tyTuple, tyObject, tyArray:
    # XXX optimize this
    linefmt(p, cpsStmts, "#genericDeepCopy((void*)$1, (void*)$2, $3);$n",
            addrLoc(dest), addrLocOrTemp(src),
            genTypeInfo(p.module, dest.t, dest.lode.info))
  of tySequence, tyString:
    linefmt(p, cpsStmts, "#genericSeqDeepCopy($1, $2, $3);$n",
            addrLoc(dest), rdLoc(src),
            genTypeInfo(p.module, dest.t, dest.lode.info))
  of tyOpenArray, tyVarargs:
    linefmt(p, cpsStmts,
         "#genericDeepCopyOpenArray((void*)$1, (void*)$2, $1Len_0, $3);$n",
         addrLoc(dest), addrLocOrTemp(src),
         genTypeInfo(p.module, dest.t, dest.lode.info))
  of tySet:
    if mapType(ty) == ctArray:
      useStringh(p.module)
      linefmt(p, cpsStmts, "memcpy((void*)$1, (NIM_CONST void*)$2, $3);$n",
              rdLoc(dest), rdLoc(src), rope(getSize(dest.t)))
    else:
      linefmt(p, cpsStmts, "$1 = $2;$n", rdLoc(dest), rdLoc(src))
  of tyPointer, tyChar, tyBool, tyEnum, tyCString,
     tyInt..tyUInt64, tyRange, tyVar:
    linefmt(p, cpsStmts, "$1 = $2;$n", rdLoc(dest), rdLoc(src))
  else: internalError("genDeepCopy: " & $ty.kind)

proc putLocIntoDest(p: BProc, d: var TLoc, s: TLoc) =
  if d.k != locNone:
    if lfNoDeepCopy in d.flags: genAssignment(p, d, s, {})
    else: genAssignment(p, d, s, {needToCopy})
  else:
    d = s # ``d`` is free, so fill it with ``s``

proc putDataIntoDest(p: BProc, d: var TLoc, n: PNode, r: Rope) =
  var a: TLoc
  if d.k != locNone:
    # need to generate an assignment here
    initLoc(a, locData, n, OnStatic)
    a.r = r
    if lfNoDeepCopy in d.flags: genAssignment(p, d, a, {})
    else: genAssignment(p, d, a, {needToCopy})
  else:
    # we cannot call initLoc() here as that would overwrite
    # the flags field!
    d.k = locData
    d.lode = n
    d.r = r

proc putIntoDest(p: BProc, d: var TLoc, n: PNode, r: Rope; s=OnUnknown) =
  var a: TLoc
  if d.k != locNone:
    # need to generate an assignment here
    initLoc(a, locExpr, n, s)
    a.r = r
    if lfNoDeepCopy in d.flags: genAssignment(p, d, a, {})
    else: genAssignment(p, d, a, {needToCopy})
  else:
    # we cannot call initLoc() here as that would overwrite
    # the flags field!
    d.k = locExpr
    d.lode = n
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

proc binaryExpr(p: BProc, e: PNode, d: var TLoc, frmt: string) =
  var a, b: TLoc
  assert(e.sons[1].typ != nil)
  assert(e.sons[2].typ != nil)
  initLocExpr(p, e.sons[1], a)
  initLocExpr(p, e.sons[2], b)
  putIntoDest(p, d, e, ropecg(p.module, frmt, [rdLoc(a), rdLoc(b)]))

proc binaryExprChar(p: BProc, e: PNode, d: var TLoc, frmt: string) =
  var a, b: TLoc
  assert(e.sons[1].typ != nil)
  assert(e.sons[2].typ != nil)
  initLocExpr(p, e.sons[1], a)
  initLocExpr(p, e.sons[2], b)
  putIntoDest(p, d, e, ropecg(p.module, frmt, [a.rdCharLoc, b.rdCharLoc]))

proc unaryExpr(p: BProc, e: PNode, d: var TLoc, frmt: string) =
  var a: TLoc
  initLocExpr(p, e.sons[1], a)
  putIntoDest(p, d, e, ropecg(p.module, frmt, [rdLoc(a)]))

proc unaryExprChar(p: BProc, e: PNode, d: var TLoc, frmt: string) =
  var a: TLoc
  initLocExpr(p, e.sons[1], a)
  putIntoDest(p, d, e, ropecg(p.module, frmt, [rdCharLoc(a)]))

proc binaryArithOverflowRaw(p: BProc, t: PType, a, b: TLoc;
                            frmt: string): Rope =
  var size = getSize(t)
  let storage = if size < platform.intSize: rope("NI")
                else: getTypeDesc(p.module, t)
  result = getTempName(p.module)
  linefmt(p, cpsLocals, "$1 $2;$n", storage, result)
  lineCg(p, cpsStmts, frmt, result, rdCharLoc(a), rdCharLoc(b))
  if size < platform.intSize or t.kind in {tyRange, tyEnum}:
    linefmt(p, cpsStmts, "if ($1 < $2 || $1 > $3) #raiseOverflow();$n",
            result, intLiteral(firstOrd(t)), intLiteral(lastOrd(t)))

proc binaryArithOverflow(p: BProc, e: PNode, d: var TLoc, m: TMagic) =
  const
    prc: array[mAddI..mPred, string] = [
      "$# = #addInt($#, $#);$n", "$# = #subInt($#, $#);$n",
      "$# = #mulInt($#, $#);$n", "$# = #divInt($#, $#);$n",
      "$# = #modInt($#, $#);$n",
      "$# = #addInt($#, $#);$n", "$# = #subInt($#, $#);$n"]
    prc64: array[mAddI..mPred, string] = [
      "$# = #addInt64($#, $#);$n", "$# = #subInt64($#, $#);$n",
      "$# = #mulInt64($#, $#);$n", "$# = #divInt64($#, $#);$n",
      "$# = #modInt64($#, $#);$n",
      "$# = #addInt64($#, $#);$n", "$# = #subInt64($#, $#);$n"]
    opr: array[mAddI..mPred, string] = [
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
    let res = opr[m] % [getTypeDesc(p.module, e.typ), rdLoc(a), rdLoc(b)]
    putIntoDest(p, d, e, res)
  else:
    let res = binaryArithOverflowRaw(p, t, a, b,
                                   if t.kind == tyInt64: prc64[m] else: prc[m])
    putIntoDest(p, d, e, "($#)($#)" % [getTypeDesc(p.module, e.typ), res])

proc unaryArithOverflow(p: BProc, e: PNode, d: var TLoc, m: TMagic) =
  const
    opr: array[mUnaryMinusI..mAbsI, string] = [
      mUnaryMinusI: "((NI$2)-($1))",
      mUnaryMinusI64: "-($1)",
      mAbsI: "($1 > 0? ($1) : -($1))"]
  var
    a: TLoc
    t: PType
  assert(e.sons[1].typ != nil)
  initLocExpr(p, e.sons[1], a)
  t = skipTypes(e.typ, abstractRange)
  if optOverflowCheck in p.options:
    linefmt(p, cpsStmts, "if ($1 == $2) #raiseOverflow();$n",
            rdLoc(a), intLiteral(firstOrd(t)))
  putIntoDest(p, d, e, opr[m] % [rdLoc(a), rope(getSize(t) * 8)])

proc binaryArith(p: BProc, e: PNode, d: var TLoc, op: TMagic) =
  const
    binArithTab: array[mAddF64..mXor, string] = [
      "(($4)($1) + ($4)($2))", # AddF64
      "(($4)($1) - ($4)($2))", # SubF64
      "(($4)($1) * ($4)($2))", # MulF64
      "(($4)($1) / ($4)($2))", # DivF64

      "($4)((NU$5)($1) >> (NU$3)($2))", # ShrI
      "($4)((NU$3)($1) << (NU$3)($2))", # ShlI
      "($4)($1 & $2)",      # BitandI
      "($4)($1 | $2)",      # BitorI
      "($4)($1 ^ $2)",      # BitxorI
      "(($1 <= $2) ? $1 : $2)", # MinI
      "(($1 >= $2) ? $1 : $2)", # MaxI
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
      "($1 != $2)"]           # Xor
  var
    a, b: TLoc
    s, k: BiggestInt
  assert(e.sons[1].typ != nil)
  assert(e.sons[2].typ != nil)
  initLocExpr(p, e.sons[1], a)
  initLocExpr(p, e.sons[2], b)
  # BUGFIX: cannot use result-type here, as it may be a boolean
  s = max(getSize(a.t), getSize(b.t)) * 8
  k = getSize(a.t) * 8
  putIntoDest(p, d, e,
              binArithTab[op] % [rdLoc(a), rdLoc(b), rope(s),
                                      getSimpleTypeDesc(p.module, e.typ), rope(k)])

proc genEqProc(p: BProc, e: PNode, d: var TLoc) =
  var a, b: TLoc
  assert(e.sons[1].typ != nil)
  assert(e.sons[2].typ != nil)
  initLocExpr(p, e.sons[1], a)
  initLocExpr(p, e.sons[2], b)
  if a.t.skipTypes(abstractInst).callConv == ccClosure:
    putIntoDest(p, d, e,
      "($1.ClP_0 == $2.ClP_0 && $1.ClE_0 == $2.ClE_0)" % [rdLoc(a), rdLoc(b)])
  else:
    putIntoDest(p, d, e, "($1 == $2)" % [rdLoc(a), rdLoc(b)])

proc genIsNil(p: BProc, e: PNode, d: var TLoc) =
  let t = skipTypes(e.sons[1].typ, abstractRange)
  if t.kind == tyProc and t.callConv == ccClosure:
    unaryExpr(p, e, d, "($1.ClP_0 == 0)")
  else:
    unaryExpr(p, e, d, "($1 == 0)")

proc unaryArith(p: BProc, e: PNode, d: var TLoc, op: TMagic) =
  const
    unArithTab: array[mNot..mToBiggestInt, string] = ["!($1)", # Not
      "$1",                   # UnaryPlusI
      "($3)((NU$2) ~($1))",   # BitnotI
      "$1",                   # UnaryPlusF64
      "-($1)",                # UnaryMinusF64
      "($1 < 0? -($1) : ($1))", # AbsF64; BUGFIX: fabs() makes problems
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
  putIntoDest(p, d, e,
              unArithTab[op] % [rdLoc(a), rope(getSize(t) * 8),
                getSimpleTypeDesc(p.module, e.typ)])

proc isCppRef(p: BProc; typ: PType): bool {.inline.} =
  result = p.module.compileToCpp and
      skipTypes(typ, abstractInst).kind == tyVar and
      tfVarIsPtr notin skipTypes(typ, abstractInst).flags

proc genDeref(p: BProc, e: PNode, d: var TLoc; enforceDeref=false) =
  let mt = mapType(e.sons[0].typ)
  if mt in {ctArray, ctPtrToArray} and not enforceDeref:
    # XXX the amount of hacks for C's arrays is incredible, maybe we should
    # simply wrap them in a struct? --> Losing auto vectorization then?
    #if e[0].kind != nkBracketExpr:
    #  message(e.info, warnUser, "CAME HERE " & renderTree(e))
    expr(p, e.sons[0], d)
    if e.sons[0].typ.skipTypes(abstractInst).kind == tyRef:
      d.storage = OnHeap
  else:
    var a: TLoc
    var typ = skipTypes(e.sons[0].typ, abstractInst)
    if typ.kind in {tyUserTypeClass, tyUserTypeClassInst} and typ.isResolvedUserTypeClass:
      typ = typ.lastSon
    if typ.kind == tyVar and tfVarIsPtr notin typ.flags and p.module.compileToCpp and e.sons[0].kind == nkHiddenAddr:
      initLocExprSingleUse(p, e[0][0], d)
      return
    else:
      initLocExprSingleUse(p, e.sons[0], a)
    if d.k == locNone:
      # dest = *a;  <-- We do not know that 'dest' is on the heap!
      # It is completely wrong to set 'd.storage' here, unless it's not yet
      # been assigned to.
      case typ.kind
      of tyRef:
        d.storage = OnHeap
      of tyVar:
        d.storage = OnUnknown
        if tfVarIsPtr notin typ.flags and p.module.compileToCpp and
            e.kind == nkHiddenDeref:
          putIntoDest(p, d, e, rdLoc(a), a.storage)
          return
      of tyPtr:
        d.storage = OnUnknown         # BUGFIX!
      else:
        internalError(e.info, "genDeref " & $typ.kind)
    elif p.module.compileToCpp:
      if typ.kind == tyVar and tfVarIsPtr notin typ.flags and
           e.kind == nkHiddenDeref:
        putIntoDest(p, d, e, rdLoc(a), a.storage)
        return
    if enforceDeref and mt == ctPtrToArray:
      # we lie about the type for better C interop: 'ptr array[3,T]' is
      # translated to 'ptr T', but for deref'ing this produces wrong code.
      # See tmissingderef. So we get rid of the deref instead. The codegen
      # ends up using 'memcpy' for the array assignment,
      # so the '&' and '*' cancel out:
      putIntoDest(p, d, lodeTyp(a.t.sons[0]), rdLoc(a), a.storage)
    else:
      putIntoDest(p, d, e, "(*$1)" % [rdLoc(a)], a.storage)

proc genAddr(p: BProc, e: PNode, d: var TLoc) =
  # careful  'addr(myptrToArray)' needs to get the ampersand:
  if e.sons[0].typ.skipTypes(abstractInst).kind in {tyRef, tyPtr}:
    var a: TLoc
    initLocExpr(p, e.sons[0], a)
    putIntoDest(p, d, e, "&" & a.r, a.storage)
    #Message(e.info, warnUser, "HERE NEW &")
  elif mapType(e.sons[0].typ) == ctArray or isCppRef(p, e.sons[0].typ):
    expr(p, e.sons[0], d)
  else:
    var a: TLoc
    initLocExpr(p, e.sons[0], a)
    putIntoDest(p, d, e, addrLoc(a), a.storage)

template inheritLocation(d: var TLoc, a: TLoc) =
  if d.k == locNone: d.storage = a.storage

proc genRecordFieldAux(p: BProc, e: PNode, d, a: var TLoc) =
  initLocExpr(p, e.sons[0], a)
  if e.sons[1].kind != nkSym: internalError(e.info, "genRecordFieldAux")
  d.inheritLocation(a)
  discard getTypeDesc(p.module, a.t) # fill the record's fields.loc

proc genTupleElem(p: BProc, e: PNode, d: var TLoc) =
  var
    a: TLoc
    i: int
  initLocExpr(p, e.sons[0], a)
  let tupType = a.t.skipTypes(abstractInst)
  assert tupType.kind == tyTuple
  d.inheritLocation(a)
  discard getTypeDesc(p.module, a.t) # fill the record's fields.loc
  var r = rdLoc(a)
  case e.sons[1].kind
  of nkIntLit..nkUInt64Lit: i = int(e.sons[1].intVal)
  else: internalError(e.info, "genTupleElem")
  addf(r, ".Field$1", [rope(i)])
  putIntoDest(p, d, e, r, a.storage)

proc lookupFieldAgain(p: BProc, ty: PType; field: PSym; r: var Rope;
                      resTyp: ptr PType = nil): PSym =
  var ty = ty
  assert r != nil
  while ty != nil:
    ty = ty.skipTypes(skipPtrs)
    assert(ty.kind in {tyTuple, tyObject})
    result = lookupInRecord(ty.n, field.name)
    if result != nil:
      if resTyp != nil: resTyp[] = ty
      break
    if not p.module.compileToCpp: add(r, ".Sup")
    ty = ty.sons[0]
  if result == nil: internalError(field.info, "genCheckedRecordField")

proc genRecordField(p: BProc, e: PNode, d: var TLoc) =
  var a: TLoc
  genRecordFieldAux(p, e, d, a)
  var r = rdLoc(a)
  var f = e.sons[1].sym
  let ty = skipTypes(a.t, abstractInst + tyUserTypeClasses)
  if ty.kind == tyTuple:
    # we found a unique tuple type which lacks field information
    # so we use Field$i
    addf(r, ".Field$1", [rope(f.position)])
    putIntoDest(p, d, e, r, a.storage)
  else:
    var rtyp: PType
    let field = lookupFieldAgain(p, ty, f, r, addr rtyp)
    if field.loc.r == nil and rtyp != nil: fillObjectFields(p.module, rtyp)
    if field.loc.r == nil: internalError(e.info, "genRecordField 3 " & typeToString(ty))
    addf(r, ".$1", [field.loc.r])
    putIntoDest(p, d, e, r, a.storage)

proc genInExprAux(p: BProc, e: PNode, a, b, d: var TLoc)

proc genFieldCheck(p: BProc, e: PNode, obj: Rope, field: PSym) =
  var test, u, v: TLoc
  for i in countup(1, sonsLen(e) - 1):
    var it = e.sons[i]
    assert(it.kind in nkCallKinds)
    assert(it.sons[0].kind == nkSym)
    let op = it.sons[0].sym
    if op.magic == mNot: it = it.sons[1]
    let disc = it.sons[2].skipConv
    assert(disc.kind == nkSym)
    initLoc(test, locNone, it, OnStack)
    initLocExpr(p, it.sons[1], u)
    initLoc(v, locExpr, disc, OnUnknown)
    v.r = obj
    v.r.add(".")
    v.r.add(disc.sym.loc.r)
    genInExprAux(p, it, u, v, test)
    let id = nodeTableTestOrSet(p.module.dataCache,
                               newStrNode(nkStrLit, field.name.s), p.module.labels)
    let strLit = if id == p.module.labels: getStrLit(p.module, field.name.s)
                 else: p.module.tmpBase & rope(id)
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
    var a: TLoc
    genRecordFieldAux(p, e.sons[0], d, a)
    let ty = skipTypes(a.t, abstractInst)
    var r = rdLoc(a)
    let f = e.sons[0].sons[1].sym
    let field = lookupFieldAgain(p, ty, f, r)
    if field.loc.r == nil: fillObjectFields(p.module, ty)
    if field.loc.r == nil:
      internalError(e.info, "genCheckedRecordField") # generate the checks:
    genFieldCheck(p, e, r, field)
    add(r, rfmt(nil, ".$1", field.loc.r))
    putIntoDest(p, d, e.sons[0], r, a.storage)
  else:
    genRecordField(p, e.sons[0], d)

proc genArrayElem(p: BProc, n, x, y: PNode, d: var TLoc) =
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
  putIntoDest(p, d, n,
              rfmt(nil, "$1[($2)- $3]", rdLoc(a), rdCharLoc(b), first), a.storage)

proc genCStringElem(p: BProc, n, x, y: PNode, d: var TLoc) =
  var a, b: TLoc
  initLocExpr(p, x, a)
  initLocExpr(p, y, b)
  var ty = skipTypes(a.t, abstractVarRange)
  inheritLocation(d, a)
  putIntoDest(p, d, n,
              rfmt(nil, "$1[$2]", rdLoc(a), rdCharLoc(b)), a.storage)

proc genOpenArrayElem(p: BProc, n, x, y: PNode, d: var TLoc) =
  var a, b: TLoc
  initLocExpr(p, x, a)
  initLocExpr(p, y, b) # emit range check:
  if optBoundsCheck in p.options:
    linefmt(p, cpsStmts, "if ((NU)($1) >= (NU)($2Len_0)) #raiseIndexError();$n",
            rdLoc(b), rdLoc(a)) # BUGFIX: ``>=`` and not ``>``!
  inheritLocation(d, a)
  putIntoDest(p, d, n,
              rfmt(nil, "$1[$2]", rdLoc(a), rdCharLoc(b)), a.storage)

proc genSeqElem(p: BProc, n, x, y: PNode, d: var TLoc) =
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
  if d.k == locNone: d.storage = OnHeap
  if skipTypes(a.t, abstractVar).kind in {tyRef, tyPtr}:
    a.r = rfmt(nil, "(*$1)", a.r)
  putIntoDest(p, d, n,
              rfmt(nil, "$1->data[$2]", rdLoc(a), rdCharLoc(b)), a.storage)

proc genBracketExpr(p: BProc; n: PNode; d: var TLoc) =
  var ty = skipTypes(n.sons[0].typ, abstractVarRange + tyUserTypeClasses)
  if ty.kind in {tyRef, tyPtr}: ty = skipTypes(ty.lastSon, abstractVarRange)
  case ty.kind
  of tyArray: genArrayElem(p, n, n.sons[0], n.sons[1], d)
  of tyOpenArray, tyVarargs: genOpenArrayElem(p, n, n.sons[0], n.sons[1], d)
  of tySequence, tyString: genSeqElem(p, n, n.sons[0], n.sons[1], d)
  of tyCString: genCStringElem(p, n, n.sons[0], n.sons[1], d)
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
  if platform.targetOS == osGenode:
    # bypass libc and print directly to the Genode LOG session
    var args: Rope = nil
    var a: TLoc
    for i in countup(0, n.len-1):
      if n.sons[i].skipConv.kind == nkNilLit:
        add(args, ", \"nil\"")
      else:
        initLocExpr(p, n.sons[i], a)
        addf(args, ", $1? ($1)->data:\"nil\"", [rdLoc(a)])
    p.module.includeHeader("<base/log.h>")
    linefmt(p, cpsStmts, """Genode::log(""$1);$n""", args)
  else:
    if n.len == 0:
      linefmt(p, cpsStmts, "#echoBinSafe(NIM_NIL, $1);$n", n.len.rope)
    else:
      var a: TLoc
      initLocExpr(p, n, a)
      linefmt(p, cpsStmts, "#echoBinSafe($1, $2);$n", a.rdLoc, n.len.rope)
    when false:
      p.module.includeHeader("<stdio.h>")
      linefmt(p, cpsStmts, "printf($1$2);$n",
              makeCString(repeat("%s", n.len) & tnl), args)
      linefmt(p, cpsStmts, "fflush(stdout);$n")

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
  var appends: Rope = nil
  var lens: Rope = nil
  for i in countup(0, sonsLen(e) - 2):
    # compute the length expression:
    initLocExpr(p, e.sons[i + 1], a)
    if skipTypes(e.sons[i + 1].typ, abstractVarRange).kind == tyChar:
      inc(L)
      add(appends, rfmt(p.module, "#appendChar($1, $2);$n", tmp.r, rdLoc(a)))
    else:
      if e.sons[i + 1].kind in {nkStrLit..nkTripleStrLit}:
        inc(L, len(e.sons[i + 1].strVal))
      else:
        addf(lens, "$1->$2 + ", [rdLoc(a), lenField(p)])
      add(appends, rfmt(p.module, "#appendString($1, $2);$n", tmp.r, rdLoc(a)))
  linefmt(p, cpsStmts, "$1 = #rawNewString($2$3);$n", tmp.r, lens, rope(L))
  add(p.s(cpsStmts), appends)
  if d.k == locNone:
    d = tmp
  else:
    genAssignment(p, d, tmp, {}) # no need for deep copying
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
    appends, lens: Rope
  assert(d.k == locNone)
  var L = 0
  initLocExpr(p, e.sons[1], dest)
  for i in countup(0, sonsLen(e) - 3):
    # compute the length expression:
    initLocExpr(p, e.sons[i + 2], a)
    if skipTypes(e.sons[i + 2].typ, abstractVarRange).kind == tyChar:
      inc(L)
      add(appends, rfmt(p.module, "#appendChar($1, $2);$n",
                        rdLoc(dest), rdLoc(a)))
    else:
      if e.sons[i + 2].kind in {nkStrLit..nkTripleStrLit}:
        inc(L, len(e.sons[i + 2].strVal))
      else:
        addf(lens, "$1->$2 + ", [rdLoc(a), lenField(p)])
      add(appends, rfmt(p.module, "#appendString($1, $2);$n",
                        rdLoc(dest), rdLoc(a)))
  linefmt(p, cpsStmts, "$1 = #resizeString($1, $2$3);$n",
          rdLoc(dest), lens, rope(L))
  add(p.s(cpsStmts), appends)
  gcUsage(e)

proc genSeqElemAppend(p: BProc, e: PNode, d: var TLoc) =
  # seq &= x  -->
  #    seq = (typeof seq) incrSeq(&seq->Sup, sizeof(x));
  #    seq->data[seq->len-1] = x;
  let seqAppendPattern = if not p.module.compileToCpp:
                           "$1 = ($2) #incrSeqV2(&($1)->Sup, sizeof($3));$n"
                         else:
                           "$1 = ($2) #incrSeqV2($1, sizeof($3));$n"
  var a, b, dest, tmpL: TLoc
  initLocExpr(p, e.sons[1], a)
  initLocExpr(p, e.sons[2], b)
  let bt = skipTypes(e.sons[2].typ, {tyVar})
  lineCg(p, cpsStmts, seqAppendPattern, [
      rdLoc(a),
      getTypeDesc(p.module, e.sons[1].typ),
      getTypeDesc(p.module, bt)])
  #if bt != b.t:
  #  echo "YES ", e.info, " new: ", typeToString(bt), " old: ", typeToString(b.t)
  initLoc(dest, locExpr, e.sons[2], OnHeap)
  getIntTemp(p, tmpL)
  lineCg(p, cpsStmts, "$1 = $2->$3++;$n", tmpL.r, rdLoc(a), lenField(p))
  dest.r = rfmt(nil, "$1->data[$2]", rdLoc(a), tmpL.r)
  genAssignment(p, dest, b, {needToCopy, afDestIsNil})
  gcUsage(e)

proc genReset(p: BProc, n: PNode) =
  var a: TLoc
  initLocExpr(p, n.sons[1], a)
  linefmt(p, cpsStmts, "#genericReset((void*)$1, $2);$n",
          addrLoc(a),
          genTypeInfo(p.module, skipTypes(a.t, {tyVar}), n.info))

proc rawGenNew(p: BProc, a: TLoc, sizeExpr: Rope) =
  var sizeExpr = sizeExpr
  let typ = a.t
  var b: TLoc
  initLoc(b, locExpr, a.lode, OnHeap)
  let refType = typ.skipTypes(abstractInst)
  assert refType.kind == tyRef
  let bt = refType.lastSon
  if sizeExpr.isNil:
    sizeExpr = "sizeof($1)" %
        [getTypeDesc(p.module, bt)]
  let args = [getTypeDesc(p.module, typ),
              genTypeInfo(p.module, typ, a.lode.info),
              sizeExpr]
  if a.storage == OnHeap and usesNativeGC():
    # use newObjRC1 as an optimization
    if canFormAcycle(a.t):
      linefmt(p, cpsStmts, "if ($1) { #nimGCunrefRC1($1); $1 = NIM_NIL; }$n", a.rdLoc)
    else:
      linefmt(p, cpsStmts, "if ($1) { #nimGCunrefNoCycle($1); $1 = NIM_NIL; }$n", a.rdLoc)
    b.r = ropecg(p.module, "($1) #newObjRC1($2, $3)", args)
    linefmt(p, cpsStmts, "$1 = $2;$n", a.rdLoc, b.rdLoc)
  else:
    b.r = ropecg(p.module, "($1) #newObj($2, $3)", args)
    genAssignment(p, a, b, {})  # set the object type:
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

proc genNewSeqAux(p: BProc, dest: TLoc, length: Rope) =
  let seqtype = skipTypes(dest.t, abstractVarRange)
  let args = [getTypeDesc(p.module, seqtype),
              genTypeInfo(p.module, seqtype, dest.lode.info), length]
  var call: TLoc
  initLoc(call, locExpr, dest.lode, OnHeap)
  if dest.storage == OnHeap and usesNativeGC():
    if canFormAcycle(dest.t):
      linefmt(p, cpsStmts, "if ($1) { #nimGCunrefRC1($1); $1 = NIM_NIL; }$n", dest.rdLoc)
    else:
      linefmt(p, cpsStmts, "if ($1) { #nimGCunrefNoCycle($1); $1 = NIM_NIL; }$n", dest.rdLoc)
    call.r = ropecg(p.module, "($1) #newSeqRC1($2, $3)", args)
    linefmt(p, cpsStmts, "$1 = $2;$n", dest.rdLoc, call.rdLoc)
  else:
    call.r = ropecg(p.module, "($1) #newSeq($2, $3)", args)
    genAssignment(p, dest, call, {})

proc genNewSeq(p: BProc, e: PNode) =
  var a, b: TLoc
  initLocExpr(p, e.sons[1], a)
  initLocExpr(p, e.sons[2], b)
  genNewSeqAux(p, a, b.rdLoc)
  gcUsage(e)

proc genNewSeqOfCap(p: BProc; e: PNode; d: var TLoc) =
  let seqtype = skipTypes(e.typ, abstractVarRange)
  var a: TLoc
  initLocExpr(p, e.sons[1], a)
  putIntoDest(p, d, e, ropecg(p.module,
              "($1)#nimNewSeqOfCap($2, $3)", [
              getTypeDesc(p.module, seqtype),
              genTypeInfo(p.module, seqtype, e.info), a.rdLoc]))
  gcUsage(e)

proc genConstExpr(p: BProc, n: PNode): Rope
proc handleConstExpr(p: BProc, n: PNode, d: var TLoc): bool =
  if d.k == locNone and n.len > ord(n.kind == nkObjConstr) and n.isDeepConstExpr:
    let t = n.typ
    discard getTypeDesc(p.module, t) # so that any fields are initialized
    let id = nodeTableTestOrSet(p.module.dataCache, n, p.module.labels)
    fillLoc(d, locData, n, p.module.tmpBase & rope(id), OnStatic)
    if id == p.module.labels:
      # expression not found in the cache:
      inc(p.module.labels)
      addf(p.module.s[cfsData], "NIM_CONST $1 $2 = $3;$n",
           [getTypeDesc(p.module, t), d.r, genConstExpr(p, n)])
    result = true
  else:
    result = false

proc genObjConstr(p: BProc, e: PNode, d: var TLoc) =
  #echo rendertree e, " ", e.isDeepConstExpr
  # inheritance in C++ does not allow struct initialization so
  # we skip this step here:
  if not p.module.compileToCpp:
    if handleConstExpr(p, e, d): return
  var tmp: TLoc
  var t = e.typ.skipTypes(abstractInst)
  getTemp(p, t, tmp)
  let isRef = t.kind == tyRef
  var r = rdLoc(tmp)
  if isRef:
    rawGenNew(p, tmp, nil)
    t = t.lastSon.skipTypes(abstractInst)
    r = "(*$1)" % [r]
    gcUsage(e)
  else:
    constructLoc(p, tmp)
  discard getTypeDesc(p.module, t)
  let ty = getUniqueType(t)
  for i in 1 ..< e.len:
    let it = e.sons[i]
    var tmp2: TLoc
    tmp2.r = r
    let field = lookupFieldAgain(p, ty, it.sons[0].sym, tmp2.r)
    if field.loc.r == nil: fillObjectFields(p.module, ty)
    if field.loc.r == nil: internalError(e.info, "genObjConstr")
    if it.len == 3 and optFieldCheck in p.options:
      genFieldCheck(p, it.sons[2], r, field)
    add(tmp2.r, ".")
    add(tmp2.r, field.loc.r)
    tmp2.k = locTemp
    tmp2.lode = it.sons[1]
    tmp2.storage = if isRef: OnHeap else: OnStack
    expr(p, it.sons[1], tmp2)

  if d.k == locNone:
    d = tmp
  else:
    genAssignment(p, d, tmp, {})

proc lhsDoesAlias(a, b: PNode): bool =
  for y in b:
    if isPartOf(a, y) != arNo: return true

proc genSeqConstr(p: BProc, n: PNode, d: var TLoc) =
  var arr, tmp: TLoc
  # bug #668
  let doesAlias = lhsDoesAlias(d.lode, n)
  let dest = if doesAlias: addr(tmp) else: addr(d)
  if doesAlias:
    getTemp(p, n.typ, tmp)
  elif d.k == locNone:
    getTemp(p, n.typ, d)
  # generate call to newSeq before adding the elements per hand:
  genNewSeqAux(p, dest[], intLiteral(sonsLen(n)))
  for i in countup(0, sonsLen(n) - 1):
    initLoc(arr, locExpr, n[i], OnHeap)
    arr.r = rfmt(nil, "$1->data[$2]", rdLoc(dest[]), intLiteral(i))
    arr.storage = OnHeap            # we know that sequences are on the heap
    expr(p, n[i], arr)
  gcUsage(n)
  if doesAlias:
    if d.k == locNone:
      d = tmp
    else:
      genAssignment(p, d, tmp, {})

proc genArrToSeq(p: BProc, n: PNode, d: var TLoc) =
  var elem, a, arr: TLoc
  if n.sons[1].kind == nkBracket:
    n.sons[1].typ = n.typ
    genSeqConstr(p, n.sons[1], d)
    return
  if d.k == locNone:
    getTemp(p, n.typ, d)
  # generate call to newSeq before adding the elements per hand:
  let L = int(lengthOrd(n.sons[1].typ))
  genNewSeqAux(p, d, intLiteral(L))
  initLocExpr(p, n.sons[1], a)
  # bug #5007; do not produce excessive C source code:
  if L < 10:
    for i in countup(0, L - 1):
      initLoc(elem, locExpr, lodeTyp elemType(skipTypes(n.typ, abstractInst)), OnHeap)
      elem.r = rfmt(nil, "$1->data[$2]", rdLoc(d), intLiteral(i))
      elem.storage = OnHeap # we know that sequences are on the heap
      initLoc(arr, locExpr, lodeTyp elemType(skipTypes(n.sons[1].typ, abstractInst)), a.storage)
      arr.r = rfmt(nil, "$1[$2]", rdLoc(a), intLiteral(i))
      genAssignment(p, elem, arr, {afDestIsNil, needToCopy})
  else:
    var i: TLoc
    getTemp(p, getSysType(tyInt), i)
    let oldCode = p.s(cpsStmts)
    linefmt(p, cpsStmts, "for ($1 = 0; $1 < $2; $1++) {$n",  i.r, L.rope)
    initLoc(elem, locExpr, lodeTyp elemType(skipTypes(n.typ, abstractInst)), OnHeap)
    elem.r = rfmt(nil, "$1->data[$2]", rdLoc(d), rdLoc(i))
    elem.storage = OnHeap # we know that sequences are on the heap
    initLoc(arr, locExpr, lodeTyp elemType(skipTypes(n.sons[1].typ, abstractInst)), a.storage)
    arr.r = rfmt(nil, "$1[$2]", rdLoc(a), rdLoc(i))
    genAssignment(p, elem, arr, {afDestIsNil, needToCopy})
    lineF(p, cpsStmts, "}$n", [])


proc genNewFinalize(p: BProc, e: PNode) =
  var
    a, b, f: TLoc
    refType, bt: PType
    ti: Rope
  refType = skipTypes(e.sons[1].typ, abstractVarRange)
  initLocExpr(p, e.sons[1], a)
  initLocExpr(p, e.sons[2], f)
  initLoc(b, locExpr, a.lode, OnHeap)
  ti = genTypeInfo(p.module, refType, e.info)
  addf(p.module.s[cfsTypeInit3], "$1->finalizer = (void*)$2;$n", [ti, rdLoc(f)])
  b.r = ropecg(p.module, "($1) #newObj($2, sizeof($3))", [
      getTypeDesc(p.module, refType),
      ti, getTypeDesc(p.module, skipTypes(refType.lastSon, abstractRange))])
  genAssignment(p, a, b, {})  # set the object type:
  bt = skipTypes(refType.lastSon, abstractRange)
  genObjectInit(p, cpsStmts, bt, a, false)
  gcUsage(e)

proc genOfHelper(p: BProc; dest: PType; a: Rope; info: TLineInfo): Rope =
  # unfortunately 'genTypeInfo' sets tfObjHasKids as a side effect, so we
  # have to call it here first:
  let ti = genTypeInfo(p.module, dest, info)
  if tfFinal in dest.flags or (objHasKidsValid in p.module.flags and
                               tfObjHasKids notin dest.flags):
    result = "$1.m_type == $2" % [a, ti]
  else:
    discard cgsym(p.module, "TNimType")
    inc p.module.labels
    let cache = "Nim_OfCheck_CACHE" & p.module.labels.rope
    addf(p.module.s[cfsVars], "static TNimType* $#[2];$n", [cache])
    result = rfmt(p.module, "#isObjWithCache($#.m_type, $#, $#)", a, ti, cache)
  when false:
    # former version:
    result = rfmt(p.module, "#isObj($1.m_type, $2)",
                  a, genTypeInfo(p.module, dest, info))

proc genOf(p: BProc, x: PNode, typ: PType, d: var TLoc) =
  var a: TLoc
  initLocExpr(p, x, a)
  var dest = skipTypes(typ, typedescPtrs)
  var r = rdLoc(a)
  var nilCheck: Rope = nil
  var t = skipTypes(a.t, abstractInst)
  while t.kind in {tyVar, tyPtr, tyRef}:
    if t.kind != tyVar: nilCheck = r
    if t.kind != tyVar or not p.module.compileToCpp:
      r = rfmt(nil, "(*$1)", r)
    t = skipTypes(t.lastSon, typedescInst)
  if not p.module.compileToCpp:
    while t.kind == tyObject and t.sons[0] != nil:
      add(r, ~".Sup")
      t = skipTypes(t.sons[0], skipPtrs)
  if isObjLackingTypeField(t):
    globalError(x.info, errGenerated,
      "no 'of' operator available for pure objects")
  if nilCheck != nil:
    r = rfmt(p.module, "(($1) && ($2))", nilCheck, genOfHelper(p, dest, r, x.info))
  else:
    r = rfmt(p.module, "($1)", genOfHelper(p, dest, r, x.info))
  putIntoDest(p, d, x, r, a.storage)

proc genOf(p: BProc, n: PNode, d: var TLoc) =
  genOf(p, n.sons[1], n.sons[2].typ, d)

proc genRepr(p: BProc, e: PNode, d: var TLoc) =
  var a: TLoc
  initLocExpr(p, e.sons[1], a)
  var t = skipTypes(e.sons[1].typ, abstractVarRange)
  case t.kind
  of tyInt..tyInt64, tyUInt..tyUInt64:
    putIntoDest(p, d, e,
                ropecg(p.module, "#reprInt((NI64)$1)", [rdLoc(a)]), a.storage)
  of tyFloat..tyFloat128:
    putIntoDest(p, d, e, ropecg(p.module, "#reprFloat($1)", [rdLoc(a)]), a.storage)
  of tyBool:
    putIntoDest(p, d, e, ropecg(p.module, "#reprBool($1)", [rdLoc(a)]), a.storage)
  of tyChar:
    putIntoDest(p, d, e, ropecg(p.module, "#reprChar($1)", [rdLoc(a)]), a.storage)
  of tyEnum, tyOrdinal:
    putIntoDest(p, d, e,
                ropecg(p.module, "#reprEnum((NI)$1, $2)", [
                rdLoc(a), genTypeInfo(p.module, t, e.info)]), a.storage)
  of tyString:
    putIntoDest(p, d, e, ropecg(p.module, "#reprStr($1)", [rdLoc(a)]), a.storage)
  of tySet:
    putIntoDest(p, d, e, ropecg(p.module, "#reprSet($1, $2)", [
                addrLoc(a), genTypeInfo(p.module, t, e.info)]), a.storage)
  of tyOpenArray, tyVarargs:
    var b: TLoc
    case a.t.kind
    of tyOpenArray, tyVarargs:
      putIntoDest(p, b, e, "$1, $1Len_0" % [rdLoc(a)], a.storage)
    of tyString, tySequence:
      putIntoDest(p, b, e,
                  "$1->data, $1->$2" % [rdLoc(a), lenField(p)], a.storage)
    of tyArray:
      putIntoDest(p, b, e,
                  "$1, $2" % [rdLoc(a), rope(lengthOrd(a.t))], a.storage)
    else: internalError(e.sons[0].info, "genRepr()")
    putIntoDest(p, d, e,
        ropecg(p.module, "#reprOpenArray($1, $2)", [rdLoc(b),
        genTypeInfo(p.module, elemType(t), e.info)]), a.storage)
  of tyCString, tyArray, tyRef, tyPtr, tyPointer, tyNil, tySequence:
    putIntoDest(p, d, e,
                ropecg(p.module, "#reprAny($1, $2)", [
                rdLoc(a), genTypeInfo(p.module, t, e.info)]), a.storage)
  of tyEmpty, tyVoid:
    localError(e.info, "'repr' doesn't support 'void' type")
  else:
    putIntoDest(p, d, e, ropecg(p.module, "#reprAny($1, $2)",
                              [addrLoc(a), genTypeInfo(p.module, t, e.info)]),
                               a.storage)
  gcUsage(e)

proc genGetTypeInfo(p: BProc, e: PNode, d: var TLoc) =
  let t = e.sons[1].typ
  putIntoDest(p, d, e, genTypeInfo(p.module, t, e.info))

proc genDollar(p: BProc, n: PNode, d: var TLoc, frmt: string) =
  var a: TLoc
  initLocExpr(p, n.sons[1], a)
  a.r = ropecg(p.module, frmt, [rdLoc(a)])
  if d.k == locNone: getTemp(p, n.typ, d)
  genAssignment(p, d, a, {})
  gcUsage(n)

proc genArrayLen(p: BProc, e: PNode, d: var TLoc, op: TMagic) =
  var a = e.sons[1]
  if a.kind == nkHiddenAddr: a = a.sons[0]
  var typ = skipTypes(a.typ, abstractVar + tyUserTypeClasses)
  case typ.kind
  of tyOpenArray, tyVarargs:
    if op == mHigh: unaryExpr(p, e, d, "($1Len_0-1)")
    else: unaryExpr(p, e, d, "$1Len_0")
  of tyCString:
    useStringh(p.module)
    if op == mHigh: unaryExpr(p, e, d, "($1 ? (strlen($1)-1) : -1)")
    else: unaryExpr(p, e, d, "($1 ? strlen($1) : 0)")
  of tyString:
    if not p.module.compileToCpp:
      if op == mHigh: unaryExpr(p, e, d, "($1 ? ($1->Sup.len-1) : -1)")
      else: unaryExpr(p, e, d, "($1 ? $1->Sup.len : 0)")
    else:
      if op == mHigh: unaryExpr(p, e, d, "($1 ? ($1->len-1) : -1)")
      else: unaryExpr(p, e, d, "($1 ? $1->len : 0)")
  of tySequence:
    var a, tmp: TLoc
    initLocExpr(p, e[1], a)
    getIntTemp(p, tmp)
    var frmt: FormatStr
    if not p.module.compileToCpp:
      if op == mHigh:
        frmt = "$1 = ($2 ? ($2->Sup.len-1) : -1);$n"
      else:
        frmt = "$1 = ($2 ? $2->Sup.len : 0);$n"
    else:
      if op == mHigh:
        frmt = "$1 = ($2 ? ($2->len-1) : -1);$n"
      else:
        frmt = "$1 = ($2 ? $2->len : 0);$n"
    lineCg(p, cpsStmts, frmt, tmp.r, rdLoc(a))
    putIntoDest(p, d, e, tmp.r)
  of tyArray:
    # YYY: length(sideeffect) is optimized away incorrectly?
    if op == mHigh: putIntoDest(p, d, e, rope(lastOrd(typ)))
    else: putIntoDest(p, d, e, rope(lengthOrd(typ)))
  else: internalError(e.info, "genArrayLen()")

proc genSetLengthSeq(p: BProc, e: PNode, d: var TLoc) =
  var a, b: TLoc
  assert(d.k == locNone)
  var x = e.sons[1]
  if x.kind in {nkAddr, nkHiddenAddr}: x = x[0]
  initLocExpr(p, x, a)
  initLocExpr(p, e.sons[2], b)
  let t = skipTypes(e.sons[1].typ, {tyVar})
  let setLenPattern = if not p.module.compileToCpp:
      "$1 = ($3) #setLengthSeq(&($1)->Sup, sizeof($4), $2);$n"
    else:
      "$1 = ($3) #setLengthSeq($1, sizeof($4), $2);$n"

  lineCg(p, cpsStmts, setLenPattern, [
      rdLoc(a), rdLoc(b), getTypeDesc(p.module, t),
      getTypeDesc(p.module, t.skipTypes(abstractInst).sons[0])])
  gcUsage(e)

proc genSetLengthStr(p: BProc, e: PNode, d: var TLoc) =
  binaryStmt(p, e, d, "$1 = #setLengthStr($1, $2);$n")
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

proc rdSetElemLoc(a: TLoc, setType: PType): Rope =
  # read a location of an set element; it may need a subtraction operation
  # before the set operation
  result = rdCharLoc(a)
  assert(setType.kind == tySet)
  if firstOrd(setType) != 0:
    result = "($1- $2)" % [result, rope(firstOrd(setType))]

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
  putIntoDest(p, d, e, frmt % [rdLoc(a), rdSetElemLoc(b, a.t)])

proc genInExprAux(p: BProc, e: PNode, a, b, d: var TLoc) =
  case int(getSize(skipTypes(e.sons[1].typ, abstractVar)))
  of 1: binaryExprIn(p, e, a, b, d, "(($1 &(1U<<((NU)($2)&7U)))!=0)")
  of 2: binaryExprIn(p, e, a, b, d, "(($1 &(1U<<((NU)($2)&15U)))!=0)")
  of 4: binaryExprIn(p, e, a, b, d, "(($1 &(1U<<((NU)($2)&31U)))!=0)")
  of 8: binaryExprIn(p, e, a, b, d, "(($1 &((NU64)1<<((NU)($2)&63U)))!=0)")
  else: binaryExprIn(p, e, a, b, d, "(($1[(NU)($2)>>3] &(1U<<((NU)($2)&7U)))!=0)")

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
    initLoc(b, locExpr, e, OnUnknown)
    b.r = rope("(")
    var length = sonsLen(e.sons[1])
    for i in countup(0, length - 1):
      if e.sons[1].sons[i].kind == nkRange:
        initLocExpr(p, e.sons[1].sons[i].sons[0], x)
        initLocExpr(p, e.sons[1].sons[i].sons[1], y)
        addf(b.r, "$1 >= $2 && $1 <= $3",
             [rdCharLoc(a), rdCharLoc(x), rdCharLoc(y)])
      else:
        initLocExpr(p, e.sons[1].sons[i], x)
        addf(b.r, "$1 == $2", [rdCharLoc(a), rdCharLoc(x)])
      if i < length - 1: add(b.r, " || ")
    add(b.r, ")")
    putIntoDest(p, d, e, b.r)
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
      var ts = "NU" & $(size * 8)
      binaryStmtInExcl(p, e, d,
          "$1 |= ((" & ts & ")1)<<(($2)%(sizeof(" & ts & ")*8));$n")
    of mExcl:
      var ts = "NU" & $(size * 8)
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
    of mIncl: binaryStmtInExcl(p, e, d, "$1[(NU)($2)>>3] |=(1U<<($2&7U));$n")
    of mExcl: binaryStmtInExcl(p, e, d, "$1[(NU)($2)>>3] &= ~(1U<<($2&7U));$n")
    of mCard: unaryExprChar(p, e, d, "#cardSet($1, " & $size & ')')
    of mLtSet, mLeSet:
      getTemp(p, getSysType(tyInt), i) # our counter
      initLocExpr(p, e.sons[1], a)
      initLocExpr(p, e.sons[2], b)
      if d.k == locNone: getTemp(p, getSysType(tyBool), d)
      lineF(p, cpsStmts, lookupOpr[op],
           [rdLoc(i), rope(size), rdLoc(d), rdLoc(a), rdLoc(b)])
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
          rdLoc(i), rope(size), rdLoc(d), rdLoc(a), rdLoc(b),
          rope(lookupOpr[op])])
    of mInSet: genInOp(p, e, d)
    else: internalError(e.info, "genSetOp")

proc genOrd(p: BProc, e: PNode, d: var TLoc) =
  unaryExprChar(p, e, d, "$1")

proc genSomeCast(p: BProc, e: PNode, d: var TLoc) =
  const
    ValueTypes = {tyTuple, tyObject, tyArray, tyOpenArray, tyVarargs}
  # we use whatever C gives us. Except if we have a value-type, we need to go
  # through its address:
  var a: TLoc
  initLocExpr(p, e.sons[1], a)
  let etyp = skipTypes(e.typ, abstractRange)
  if etyp.kind in ValueTypes and lfIndirect notin a.flags:
    putIntoDest(p, d, e, "(*($1*) ($2))" %
        [getTypeDesc(p.module, e.typ), addrLoc(a)], a.storage)
  elif etyp.kind == tyProc and etyp.callConv == ccClosure:
    putIntoDest(p, d, e, "(($1) ($2))" %
        [getClosureType(p.module, etyp, clHalfWithEnv), rdCharLoc(a)], a.storage)
  else:
    let srcTyp = skipTypes(e.sons[1].typ, abstractRange)
    # C++ does not like direct casts from pointer to shorter integral types
    if srcTyp.kind in {tyPtr, tyPointer} and etyp.kind in IntegralTypes:
      putIntoDest(p, d, e, "(($1) (ptrdiff_t) ($2))" %
          [getTypeDesc(p.module, e.typ), rdCharLoc(a)], a.storage)
    else:
      putIntoDest(p, d, e, "(($1) ($2))" %
          [getTypeDesc(p.module, e.typ), rdCharLoc(a)], a.storage)

proc genCast(p: BProc, e: PNode, d: var TLoc) =
  const ValueTypes = {tyFloat..tyFloat128, tyTuple, tyObject, tyArray}
  let
    destt = skipTypes(e.typ, abstractRange)
    srct = skipTypes(e.sons[1].typ, abstractRange)
  if destt.kind in ValueTypes or srct.kind in ValueTypes:
    # 'cast' and some float type involved? --> use a union.
    inc(p.labels)
    var lbl = p.labels.rope
    var tmp: TLoc
    tmp.r = "LOC$1.source" % [lbl]
    linefmt(p, cpsLocals, "union { $1 source; $2 dest; } LOC$3;$n",
      getTypeDesc(p.module, e.sons[1].typ), getTypeDesc(p.module, e.typ), lbl)
    tmp.k = locExpr
    tmp.lode = lodeTyp srct
    tmp.storage = OnStack
    tmp.flags = {}
    expr(p, e.sons[1], tmp)
    putIntoDest(p, d, e, "LOC$#.dest" % [lbl], tmp.storage)
  else:
    # I prefer the shorter cast version for pointer types -> generate less
    # C code; plus it's the right thing to do for closures:
    genSomeCast(p, e, d)

proc genRangeChck(p: BProc, n: PNode, d: var TLoc, magic: string) =
  var a: TLoc
  var dest = skipTypes(n.typ, abstractVar)
  # range checks for unsigned turned out to be buggy and annoying:
  if optRangeCheck notin p.options or dest.skipTypes({tyRange}).kind in
                                             {tyUInt..tyUInt64}:
    initLocExpr(p, n.sons[0], a)
    putIntoDest(p, d, n, "(($1) ($2))" %
        [getTypeDesc(p.module, dest), rdCharLoc(a)], a.storage)
  else:
    initLocExpr(p, n.sons[0], a)
    putIntoDest(p, d, lodeTyp dest, ropecg(p.module, "(($1)#$5($2, $3, $4))", [
        getTypeDesc(p.module, dest), rdCharLoc(a),
        genLiteral(p, n.sons[1], dest), genLiteral(p, n.sons[2], dest),
        rope(magic)]), a.storage)

proc genConv(p: BProc, e: PNode, d: var TLoc) =
  let destType = e.typ.skipTypes({tyVar, tyGenericInst, tyAlias})
  if sameBackendType(destType, e.sons[1].typ):
    expr(p, e.sons[1], d)
  else:
    genSomeCast(p, e, d)

proc convStrToCStr(p: BProc, n: PNode, d: var TLoc) =
  var a: TLoc
  initLocExpr(p, n.sons[0], a)
  putIntoDest(p, d, n, "$1->data" % [rdLoc(a)],
              a.storage)

proc convCStrToStr(p: BProc, n: PNode, d: var TLoc) =
  var a: TLoc
  initLocExpr(p, n.sons[0], a)
  putIntoDest(p, d, n,
              ropecg(p.module, "#cstrToNimstr($1)", [rdLoc(a)]),
              a.storage)
  gcUsage(n)

proc genStrEquals(p: BProc, e: PNode, d: var TLoc) =
  var x: TLoc
  var a = e.sons[1]
  var b = e.sons[2]
  if (a.kind == nkNilLit) or (b.kind == nkNilLit):
    binaryExpr(p, e, d, "($1 == $2)")
  elif (a.kind in {nkStrLit..nkTripleStrLit}) and (a.strVal == ""):
    initLocExpr(p, e.sons[2], x)
    putIntoDest(p, d, e,
      rfmt(nil, "(($1) && ($1)->$2 == 0)", rdLoc(x), lenField(p)))
  elif (b.kind in {nkStrLit..nkTripleStrLit}) and (b.strVal == ""):
    initLocExpr(p, e.sons[1], x)
    putIntoDest(p, d, e,
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
    putIntoDest(p, d, e, rfmt(nil, "(($4)($2) $1 ($4)($3))",
                              rope(opr[m]), rdLoc(a), rdLoc(b),
                              getSimpleTypeDesc(p.module, e[1].typ)))
    if optNaNCheck in p.options:
      linefmt(p, cpsStmts, "#nanCheck($1);$n", rdLoc(d))
    if optInfCheck in p.options:
      linefmt(p, cpsStmts, "#infCheck($1);$n", rdLoc(d))
  else:
    binaryArith(p, e, d, m)

proc genMagicExpr(p: BProc, e: PNode, d: var TLoc, op: TMagic) =
  case op
  of mOr, mAnd: genAndOr(p, e, d, op)
  of mNot..mToBiggestInt: unaryArith(p, e, d, op)
  of mUnaryMinusI..mAbsI: unaryArithOverflow(p, e, d, op)
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
    const opr: array[mInc..mDec, string] = ["$1 += $2;$n", "$1 -= $2;$n"]
    const fun64: array[mInc..mDec, string] = ["$# = #addInt64($#, $#);$n",
                                               "$# = #subInt64($#, $#);$n"]
    const fun: array[mInc..mDec, string] = ["$# = #addInt($#, $#);$n",
                                             "$# = #subInt($#, $#);$n"]
    let underlying = skipTypes(e.sons[1].typ, {tyGenericInst, tyAlias, tyVar, tyRange})
    if optOverflowCheck notin p.options or underlying.kind in {tyUInt..tyUInt64}:
      binaryStmt(p, e, d, opr[op])
    else:
      var a, b: TLoc
      assert(e.sons[1].typ != nil)
      assert(e.sons[2].typ != nil)
      initLocExpr(p, e.sons[1], a)
      initLocExpr(p, e.sons[2], b)

      let ranged = skipTypes(e.sons[1].typ, {tyGenericInst, tyAlias, tyVar})
      let res = binaryArithOverflowRaw(p, ranged, a, b,
        if underlying.kind == tyInt64: fun64[op] else: fun[op])
      putIntoDest(p, a, e.sons[1], "($#)($#)" % [
        getTypeDesc(p.module, ranged), res])

  of mConStrStr: genStrConcat(p, e, d)
  of mAppendStrCh: binaryStmt(p, e, d, "$1 = #addChar($1, $2);$n")
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
  of mNewSeqOfCap: genNewSeqOfCap(p, e, d)
  of mSizeOf:
    let t = e.sons[1].typ.skipTypes({tyTypeDesc})
    putIntoDest(p, d, e, "((NI)sizeof($1))" % [getTypeDesc(p.module, t)])
  of mChr: genSomeCast(p, e, d)
  of mOrd: genOrd(p, e, d)
  of mLengthArray, mHigh, mLengthStr, mLengthSeq, mLengthOpenArray:
    genArrayLen(p, e, d, op)
  of mXLenStr:
    if not p.module.compileToCpp:
      unaryExpr(p, e, d, "($1->Sup.len)")
    else:
      unaryExpr(p, e, d, "$1->len")
  of mXLenSeq:
    # see 'taddhigh.nim' for why we need to use a temporary here:
    var a, tmp: TLoc
    initLocExpr(p, e[1], a)
    getIntTemp(p, tmp)
    var frmt: FormatStr
    if not p.module.compileToCpp:
      frmt = "$1 = $2->Sup.len;$n"
    else:
      frmt = "$1 = $2->len;$n"
    lineCg(p, cpsStmts, frmt, tmp.r, rdLoc(a))
    putIntoDest(p, d, e, tmp.r)
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
      discard cgsym(p.module, $opr.loc.r)
    genCall(p, e, d)
  of mReset: genReset(p, e)
  of mEcho: genEcho(p, e[1].skipConv)
  of mArrToSeq: genArrToSeq(p, e, d)
  of mNLen..mNError, mSlurp..mQuoteAst:
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
  of mDotDot, mEqCString: genCall(p, e, d)
  else:
    when defined(debugMagics):
      echo p.prc.name.s, " ", p.prc.id, " ", p.prc.flags, " ", p.prc.ast[genericParamsPos].kind
    internalError(e.info, "genMagicExpr: " & $op)

proc genSetConstr(p: BProc, e: PNode, d: var TLoc) =
  # example: { a..b, c, d, e, f..g }
  # we have to emit an expression of the form:
  # memset(tmp, 0, sizeof(tmp)); inclRange(tmp, a, b); incl(tmp, c);
  # incl(tmp, d); incl(tmp, e); inclRange(tmp, f, g);
  var
    a, b, idx: TLoc
  if nfAllConst in e.flags:
    putIntoDest(p, d, e, genSetNode(p, e))
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
              "$2[(NU)($1)>>3] |=(1U<<((NU)($1)&7U));$n", [rdLoc(idx), rdLoc(d),
              rdSetElemLoc(a, e.typ), rdSetElemLoc(b, e.typ)])
        else:
          initLocExpr(p, e.sons[i], a)
          lineF(p, cpsStmts, "$1[(NU)($2)>>3] |=(1U<<((NU)($2)&7U));$n",
               [rdLoc(d), rdSetElemLoc(a, e.typ)])
    else:
      # small set
      var ts = "NU" & $(getSize(e.typ) * 8)
      lineF(p, cpsStmts, "$1 = 0;$n", [rdLoc(d)])
      for i in countup(0, sonsLen(e) - 1):
        if e.sons[i].kind == nkRange:
          getTemp(p, getSysType(tyInt), idx) # our counter
          initLocExpr(p, e.sons[i].sons[0], a)
          initLocExpr(p, e.sons[i].sons[1], b)
          lineF(p, cpsStmts, "for ($1 = $3; $1 <= $4; $1++) $n" &
              "$2 |=((" & ts & ")(1)<<(($1)%(sizeof(" & ts & ")*8)));$n", [
              rdLoc(idx), rdLoc(d), rdSetElemLoc(a, e.typ),
              rdSetElemLoc(b, e.typ)])
        else:
          initLocExpr(p, e.sons[i], a)
          lineF(p, cpsStmts,
               "$1 |=((" & ts & ")(1)<<(($2)%(sizeof(" & ts & ")*8)));$n",
               [rdLoc(d), rdSetElemLoc(a, e.typ)])

proc genTupleConstr(p: BProc, n: PNode, d: var TLoc) =
  var rec: TLoc
  if not handleConstExpr(p, n, d):
    let t = n.typ
    discard getTypeDesc(p.module, t) # so that any fields are initialized
    if d.k == locNone: getTemp(p, t, d)
    for i in countup(0, sonsLen(n) - 1):
      var it = n.sons[i]
      if it.kind == nkExprColonExpr: it = it.sons[1]
      initLoc(rec, locExpr, it, d.storage)
      rec.r = "$1.Field$2" % [rdLoc(d), rope(i)]
      expr(p, it, rec)

proc isConstClosure(n: PNode): bool {.inline.} =
  result = n.sons[0].kind == nkSym and isRoutine(n.sons[0].sym) and
      n.sons[1].kind == nkNilLit

proc genClosure(p: BProc, n: PNode, d: var TLoc) =
  assert n.kind == nkClosure

  if isConstClosure(n):
    inc(p.module.labels)
    var tmp = "CNSTCLOSURE" & rope(p.module.labels)
    addf(p.module.s[cfsData], "static NIM_CONST $1 $2 = $3;$n",
        [getTypeDesc(p.module, n.typ), tmp, genConstExpr(p, n)])
    putIntoDest(p, d, n, tmp, OnStatic)
  else:
    var tmp, a, b: TLoc
    initLocExpr(p, n.sons[0], a)
    initLocExpr(p, n.sons[1], b)
    if n.sons[0].skipConv.kind == nkClosure:
      internalError(n.info, "closure to closure created")
    # tasyncawait.nim breaks with this optimization:
    when false:
      if d.k != locNone:
        linefmt(p, cpsStmts, "$1.ClP_0 = $2; $1.ClE_0 = $3;$n",
                d.rdLoc, a.rdLoc, b.rdLoc)
    else:
      getTemp(p, n.typ, tmp)
      linefmt(p, cpsStmts, "$1.ClP_0 = $2; $1.ClE_0 = $3;$n",
              tmp.rdLoc, a.rdLoc, b.rdLoc)
      putLocIntoDest(p, d, tmp)

proc genArrayConstr(p: BProc, n: PNode, d: var TLoc) =
  var arr: TLoc
  if not handleConstExpr(p, n, d):
    if d.k == locNone: getTemp(p, n.typ, d)
    for i in countup(0, sonsLen(n) - 1):
      initLoc(arr, locExpr, lodeTyp elemType(skipTypes(n.typ, abstractInst)), d.storage)
      arr.r = "$1[$2]" % [rdLoc(d), intLiteral(i)]
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
  let dest = skipTypes(n.typ, abstractPtrs)
  if optObjCheck in p.options and not isObjLackingTypeField(dest):
    var r = rdLoc(a)
    var nilCheck: Rope = nil
    var t = skipTypes(a.t, abstractInst)
    while t.kind in {tyVar, tyPtr, tyRef}:
      if t.kind != tyVar: nilCheck = r
      if t.kind != tyVar or not p.module.compileToCpp:
        r = "(*$1)" % [r]
      t = skipTypes(t.lastSon, abstractInst)
    if not p.module.compileToCpp:
      while t.kind == tyObject and t.sons[0] != nil:
        add(r, ".Sup")
        t = skipTypes(t.sons[0], skipPtrs)
    if nilCheck != nil:
      linefmt(p, cpsStmts, "if ($1) #chckObj($2.m_type, $3);$n",
              nilCheck, r, genTypeInfo(p.module, dest, n.info))
    else:
      linefmt(p, cpsStmts, "#chckObj($1.m_type, $2);$n",
              r, genTypeInfo(p.module, dest, n.info))
  if n.sons[0].typ.kind != tyObject:
    putIntoDest(p, d, n,
                "(($1) ($2))" % [getTypeDesc(p.module, n.typ), rdLoc(a)], a.storage)
  else:
    putIntoDest(p, d, n, "(*($1*) ($2))" %
                        [getTypeDesc(p.module, dest), addrLoc(a)], a.storage)

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
      add(r, "->Sup")
    else:
      add(r, ".Sup")
    for i in countup(2, abs(inheritanceDiff(dest, src))): add(r, ".Sup")
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
        r = "&" & r
        putIntoDest(p, d, n, r, a.storage)
    else:
      putIntoDest(p, d, n, r, a.storage)

proc exprComplexConst(p: BProc, n: PNode, d: var TLoc) =
  let t = n.typ
  discard getTypeDesc(p.module, t) # so that any fields are initialized
  let id = nodeTableTestOrSet(p.module.dataCache, n, p.module.labels)
  let tmp = p.module.tmpBase & rope(id)

  if id == p.module.labels:
    # expression not found in the cache:
    inc(p.module.labels)
    addf(p.module.s[cfsData], "NIM_CONST $1 $2 = $3;$n",
         [getTypeDesc(p.module, t), tmp, genConstExpr(p, n)])

  if d.k == locNone:
    fillLoc(d, locData, n, tmp, OnStatic)
  else:
    putDataIntoDest(p, d, n, tmp)
    # This fixes bug #4551, but we really need better dataflow
    # analysis to make this 100% safe.
    if t.kind notin {tySequence, tyString}:
      d.storage = OnStatic

proc expr(p: BProc, n: PNode, d: var TLoc) =
  p.currLineInfo = n.info
  case n.kind
  of nkSym:
    var sym = n.sym
    case sym.kind
    of skMethod:
      if {sfDispatcher, sfForward} * sym.flags != {}:
        # we cannot produce code for the dispatcher yet:
        fillProcLoc(p.module, n)
        genProcPrototype(p.module, sym)
      else:
        genProc(p.module, sym)
      putLocIntoDest(p, d, sym.loc)
    of skProc, skConverter, skIterator, skFunc:
      #if sym.kind == skIterator:
      #  echo renderTree(sym.getBody, {renderIds})
      if sfCompileTime in sym.flags:
        localError(n.info, "request to generate code for .compileTime proc: " &
           sym.name.s)
      genProc(p.module, sym)
      if sym.loc.r == nil or sym.loc.lode == nil:
        internalError(n.info, "expr: proc not init " & sym.name.s)
      putLocIntoDest(p, d, sym.loc)
    of skConst:
      if isSimpleConst(sym.typ):
        putIntoDest(p, d, n, genLiteral(p, sym.ast, sym.typ), OnStatic)
      else:
        genComplexConst(p, sym, d)
    of skEnumField:
      putIntoDest(p, d, n, rope(sym.position))
    of skVar, skForVar, skResult, skLet:
      if {sfGlobal, sfThread} * sym.flags != {}:
        genVarPrototype(p.module, n)
      if sym.loc.r == nil or sym.loc.t == nil:
        #echo "FAILED FOR PRCO ", p.prc.name.s
        #echo renderTree(p.prc.ast, {renderIds})
        internalError n.info, "expr: var not init " & sym.name.s & "_" & $sym.id
      if sfThread in sym.flags:
        accessThreadLocalVar(p, sym)
        if emulatedThreadVars():
          putIntoDest(p, d, sym.loc.lode, "NimTV_->" & sym.loc.r)
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
        # echo "FAILED FOR PRCO ", p.prc.name.s
        # debug p.prc.typ.n
        # echo renderTree(p.prc.ast, {renderIds})
        internalError(n.info, "expr: param not init " & sym.name.s & "_" & $sym.id)
      putLocIntoDest(p, d, sym.loc)
    else: internalError(n.info, "expr(" & $sym.kind & "); unknown symbol")
  of nkNilLit:
    if not isEmptyType(n.typ):
      putIntoDest(p, d, n, genLiteral(p, n))
  of nkStrLit..nkTripleStrLit:
    putDataIntoDest(p, d, n, genLiteral(p, n))
  of nkIntLit..nkUInt64Lit,
     nkFloatLit..nkFloat128Lit, nkCharLit:
    putIntoDest(p, d, n, genLiteral(p, n))
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
      putIntoDest(p, d, n, genSetNode(p, n))
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
  of nkWhen:
    # This should be a "when nimvm" node.
    expr(p, n.sons[1].sons[0], d)
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
    if sym.loc.r == nil or sym.loc.lode == nil:
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
  of nkAsgn:
    if nfPreventCg notin n.flags:
      genAsgn(p, n, fastAsgn=false)
  of nkFastAsgn:
    if nfPreventCg notin n.flags:
      # transf is overly aggressive with 'nkFastAsgn', so we work around here.
      # See tests/run/tcnstseq3 for an example that would fail otherwise.
      genAsgn(p, n, fastAsgn=p.prc != nil)
  of nkDiscardStmt:
    let ex = n[0]
    if ex.kind != nkEmpty:
      genLineDir(p, n)
      var a: TLoc
      if ex.kind in nkCallKinds and (ex[0].kind != nkSym or
                                     ex[0].sym.magic == mNone):
        # bug #6037: do not assign to a temp in C++ mode:
        incl a.flags, lfSingleUse
        genCall(p, ex, a)
        if lfSingleUse notin a.flags:
          line(p, cpsStmts, a.r & ";" & tnl)
      else:
        initLocExpr(p, ex, a)
  of nkAsmStmt: genAsmStmt(p, n)
  of nkTryStmt:
    if p.module.compileToCpp and optNoCppExceptions notin gGlobalOptions:
      genTryCpp(p, n, d)
    else:
      genTry(p, n, d)
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
  of nkProcDef, nkFuncDef, nkMethodDef, nkConverterDef:
    if n.sons[genericParamsPos].kind == nkEmpty:
      var prc = n.sons[namePos].sym
      # due to a bug/limitation in the lambda lifting, unused inner procs
      # are not transformed correctly. We work around this issue (#411) here
      # by ensuring it's no inner proc (owner is a module):
      if prc.skipGenericOwner.kind == skModule and sfCompileTime notin prc.flags:
        if (not emitLazily(prc)) or
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

proc genNamedConstExpr(p: BProc, n: PNode): Rope =
  if n.kind == nkExprColonExpr: result = genConstExpr(p, n.sons[1])
  else: result = genConstExpr(p, n)

proc getDefaultValue(p: BProc; typ: PType; info: TLineInfo): Rope =
  var t = skipTypes(typ, abstractRange-{tyTypeDesc})
  case t.kind
  of tyBool: result = rope"NIM_FALSE"
  of tyEnum, tyChar, tyInt..tyInt64, tyUInt..tyUInt64: result = rope"0"
  of tyFloat..tyFloat128: result = rope"0.0"
  of tyCString, tyString, tyVar, tyPointer, tyPtr, tySequence, tyExpr,
     tyStmt, tyTypeDesc, tyStatic, tyRef, tyNil:
    result = rope"NIM_NIL"
  of tyProc:
    if t.callConv != ccClosure:
      result = rope"NIM_NIL"
    else:
      result = rope"{NIM_NIL, NIM_NIL}"
  of tyObject:
    if not isObjLackingTypeField(t) and not p.module.compileToCpp:
      result = "{{$1}}" % [genTypeInfo(p.module, t, info)]
    else:
      result = rope"{}"
  of tyTuple:
    result = rope"{"
    for i in 0 ..< typ.len:
      if i > 0: result.add ", "
      result.add getDefaultValue(p, typ.sons[i], info)
    result.add "}"
  of tyArray: result = rope"{}"
  of tySet:
    if mapType(t) == ctArray: result = rope"{}"
    else: result = rope"0"
  else:
    globalError(info, "cannot create null element for: " & $t.kind)

proc getNullValueAux(p: BProc; t: PType; obj, cons: PNode, result: var Rope; count: var int) =
  case obj.kind
  of nkRecList:
    for i in countup(0, sonsLen(obj) - 1):
      getNullValueAux(p, t, obj.sons[i], cons, result, count)
  of nkRecCase:
    getNullValueAux(p, t, obj.sons[0], cons, result, count)
    for i in countup(1, sonsLen(obj) - 1):
      getNullValueAux(p, t, lastSon(obj.sons[i]), cons, result, count)
  of nkSym:
    if count > 0: result.add ", "
    inc count
    let field = obj.sym
    for i in 1..<cons.len:
      if cons[i].kind == nkExprColonExpr:
        if cons[i][0].sym.name.id == field.name.id:
          result.add genConstExpr(p, cons[i][1])
          return
      elif i == field.position:
        result.add genConstExpr(p, cons[i])
        return
    # not found, produce default value:
    result.add getDefaultValue(p, field.typ, cons.info)
  else:
    localError(cons.info, "cannot create null element for: " & $obj)

proc getNullValueAuxT(p: BProc; orig, t: PType; obj, cons: PNode, result: var Rope; count: var int) =
  var base = t.sons[0]
  let oldRes = result
  if not p.module.compileToCpp: result.add "{"
  let oldcount = count
  if base != nil:
    base = skipTypes(base, skipPtrs)
    getNullValueAuxT(p, orig, base, base.n, cons, result, count)
  elif not isObjLackingTypeField(t) and not p.module.compileToCpp:
    addf(result, "$1", [genTypeInfo(p.module, orig, obj.info)])
    inc count
  getNullValueAux(p, t, obj, cons, result, count)
  # do not emit '{}' as that is not valid C:
  if oldcount == count: result = oldres
  elif not p.module.compileToCpp: result.add "}"

proc genConstObjConstr(p: BProc; n: PNode): Rope =
  result = nil
  let t = n.typ.skipTypes(abstractInst)
  var count = 0
  #if not isObjLackingTypeField(t) and not p.module.compileToCpp:
  #  addf(result, "{$1}", [genTypeInfo(p.module, t)])
  #  inc count
  getNullValueAuxT(p, t, t, t.n, n, result, count)
  if p.module.compileToCpp:
    result = "{$1}$n" % [result]

proc genConstSimpleList(p: BProc, n: PNode): Rope =
  var length = sonsLen(n)
  result = rope("{")
  let t = n.typ.skipTypes(abstractInst)
  for i in countup(0, length - 2):
    addf(result, "$1,$n", [genNamedConstExpr(p, n.sons[i])])
  if length > 0:
    add(result, genNamedConstExpr(p, n.sons[length - 1]))
  addf(result, "}$n", [])

proc genConstSeq(p: BProc, n: PNode, t: PType): Rope =
  var data = "{{$1, $1}" % [n.len.rope]
  if n.len > 0:
    # array part needs extra curlies:
    data.add(", {")
    for i in countup(0, n.len - 1):
      if i > 0: data.addf(",$n", [])
      data.add genConstExpr(p, n.sons[i])
    data.add("}")
  data.add("}")

  result = getTempName(p.module)
  let base = t.skipTypes(abstractInst).sons[0]

  appcg(p.module, cfsData,
        "NIM_CONST struct {$n" &
        "  #TGenericSeq Sup;$n" &
        "  $1 data[$2];$n" &
        "} $3 = $4;$n", [
        getTypeDesc(p.module, base), n.len.rope, result, data])

  result = "(($1)&$2)" % [getTypeDesc(p.module, t), result]

proc genConstExpr(p: BProc, n: PNode): Rope =
  case n.kind
  of nkHiddenStdConv, nkHiddenSubConv:
    result = genConstExpr(p, n.sons[1])
  of nkCurly:
    var cs: TBitSet
    toBitSet(n, cs)
    result = genRawSetData(cs, int(getSize(n.typ)))
  of nkBracket, nkPar, nkClosure:
    var t = skipTypes(n.typ, abstractInst)
    if t.kind == tySequence:
      result = genConstSeq(p, n, n.typ)
    elif t.kind == tyProc and t.callConv == ccClosure and not n.sons.isNil and
         n.sons[0].kind == nkNilLit and n.sons[1].kind == nkNilLit:
      # this hack fixes issue that nkNilLit is expanded to {NIM_NIL,NIM_NIL}
      # this behaviour is needed since closure_var = nil must be
      # expanded to {NIM_NIL,NIM_NIL}
      # in VM closures are initialized with nkPar(nkNilLit, nkNilLit)
      # leading to duplicate code like this:
      # "{NIM_NIL,NIM_NIL}, {NIM_NIL,NIM_NIL}"
      result = ~"{NIM_NIL,NIM_NIL}"
    else:
      result = genConstSimpleList(p, n)
  of nkObjConstr:
    result = genConstObjConstr(p, n)
  else:
    var d: TLoc
    initLocExpr(p, n, d)
    result = rdLoc(d)
