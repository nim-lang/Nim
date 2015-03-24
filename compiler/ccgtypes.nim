#
#
#           The Nim Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# included from cgen.nim

# ------------------------- Name Mangling --------------------------------

proc mangleField(name: string): string =
  result = mangle(name)
  result[0] = result[0].toUpper # Mangling makes everything lowercase,
                                # but some identifiers are C keywords

proc isKeyword(w: PIdent): bool =
  # nimrod and C++ share some keywords
  # it's more efficient to test the whole nimrod keywords range
  case w.id
  of ccgKeywordsLow..ccgKeywordsHigh,
     nimKeywordsLow..nimKeywordsHigh,
     ord(wInline): return true
  else: return false

proc mangleName(s: PSym): PRope =
  result = s.loc.r
  if result == nil:
    when oKeepVariableNames:
      let keepOrigName = s.kind in skLocalVars - {skForVar} and
        {sfFromGeneric, sfGlobal, sfShadowed, sfGenSym} * s.flags == {} and
        not isKeyword(s.name)
      # XXX: This is still very experimental
      #
      # Even with all these inefficient checks, the bootstrap
      # time is actually improved. This is probably because so many
      # rope concatenations are now eliminated.
      #
      # Future notes:
      # sfFromGeneric seems to be needed in order to avoid multiple
      # definitions of certain variables generated in transf with
      # names such as:
      # `r`, `res`
      # I need to study where these come from.
      #
      # about sfShadowed:
      # consider the following nimrod code:
      #   var x = 10
      #   block:
      #     var x = something(x)
      # The generated C code will be:
      #   NI x;
      #   x = 10;
      #   {
      #     NI x;
      #     x = something(x); // Oops, x is already shadowed here
      #   }
      # Right now, we work-around by not keeping the original name
      # of the shadowed variable, but we can do better - we can
      # create an alternative reference to it in the outer scope and
      # use that in the inner scope.
      #
      # about isCKeyword:
      # nimrod variable names can be C keywords.
      # We need to avoid such names in the generated code.
      # XXX: Study whether mangleName is called just once per variable.
      # Otherwise, there might be better place to do this.
      #
      # about sfGlobal:
      # This seems to be harder - a top level extern variable from
      # another modules can have the same name as a local one.
      # Maybe we should just implement sfShadowed for them too.
      #
      # about skForVar:
      # These are not properly scoped now - we need to add blocks
      # around for loops in transf
      if keepOrigName:
        result = s.name.s.mangle.newRope
      else:
        app(result, newRope(mangle(s.name.s)))
        app(result, ~"_")
        app(result, toRope(s.id))
    else:
      app(result, newRope(mangle(s.name.s)))
      app(result, ~"_")
      app(result, toRope(s.id))
    s.loc.r = result

proc typeName(typ: PType): PRope =
  result = if typ.sym != nil: typ.sym.name.s.mangle.toRope
           else: ~"TY"

proc getTypeName(typ: PType): PRope =
  if typ.sym != nil and {sfImportc, sfExportc} * typ.sym.flags != {}:
    result = typ.sym.loc.r
  else:
    if typ.loc.r == nil:
      typ.loc.r = con(typ.typeName, typ.id.toRope)
    result = typ.loc.r
  if result == nil: internalError("getTypeName: " & $typ.kind)

proc mapSetType(typ: PType): TCTypeKind =
  case int(getSize(typ))
  of 1: result = ctInt8
  of 2: result = ctInt16
  of 4: result = ctInt32
  of 8: result = ctInt64
  else: result = ctArray

proc mapType(typ: PType): TCTypeKind =
  ## Maps a nimrod type to a C type
  case typ.kind
  of tyNone, tyStmt: result = ctVoid
  of tyBool: result = ctBool
  of tyChar: result = ctChar
  of tySet: result = mapSetType(typ)
  of tyOpenArray, tyArrayConstr, tyArray, tyVarargs: result = ctArray
  of tyObject, tyTuple: result = ctStruct
  of tyGenericBody, tyGenericInst, tyGenericParam, tyDistinct, tyOrdinal,
     tyConst, tyMutable, tyIter, tyTypeDesc:
    result = mapType(lastSon(typ))
  of tyEnum:
    if firstOrd(typ) < 0:
      result = ctInt32
    else:
      case int(getSize(typ))
      of 1: result = ctUInt8
      of 2: result = ctUInt16
      of 4: result = ctInt32
      of 8: result = ctInt64
      else: internalError("mapType")
  of tyRange: result = mapType(typ.sons[0])
  of tyPtr, tyVar, tyRef:
    var base = skipTypes(typ.lastSon, typedescInst)
    case base.kind
    of tyOpenArray, tyArrayConstr, tyArray, tyVarargs: result = ctPtrToArray
    else: result = ctPtr
  of tyPointer: result = ctPtr
  of tySequence: result = ctNimSeq
  of tyProc: result = if typ.callConv != ccClosure: ctProc else: ctStruct
  of tyString: result = ctNimStr
  of tyCString: result = ctCString
  of tyInt..tyUInt64:
    result = TCTypeKind(ord(typ.kind) - ord(tyInt) + ord(ctInt))
  else: internalError("mapType")

proc mapReturnType(typ: PType): TCTypeKind =
  if skipTypes(typ, typedescInst).kind == tyArray: result = ctPtr
  else: result = mapType(typ)

proc isImportedType(t: PType): bool =
  result = t.sym != nil and sfImportc in t.sym.flags

proc isImportedCppType(t: PType): bool =
  result = t.sym != nil and sfInfixCall in t.sym.flags

proc getTypeDescAux(m: BModule, typ: PType, check: var IntSet): PRope
proc needsComplexAssignment(typ: PType): bool =
  result = containsGarbageCollectedRef(typ)

proc isObjLackingTypeField(typ: PType): bool {.inline.} =
  result = (typ.kind == tyObject) and ((tfFinal in typ.flags) and
      (typ.sons[0] == nil) or isPureObject(typ))

proc isInvalidReturnType(rettype: PType): bool =
  # Arrays and sets cannot be returned by a C procedure, because C is
  # such a poor programming language.
  # We exclude records with refs too. This enhances efficiency and
  # is necessary for proper code generation of assignments.
  if rettype == nil: result = true
  else:
    case mapType(rettype)
    of ctArray:
      result = not (skipTypes(rettype, typedescInst).kind in
          {tyVar, tyRef, tyPtr})
    of ctStruct:
      let t = skipTypes(rettype, typedescInst)
      if rettype.isImportedCppType or t.isImportedCppType: return false
      result = needsComplexAssignment(t) or
          (t.kind == tyObject and not isObjLackingTypeField(t))
    else: result = false

const
  CallingConvToStr: array[TCallingConvention, string] = ["N_NIMCALL",
    "N_STDCALL", "N_CDECL", "N_SAFECALL",
    "N_SYSCALL", # this is probably not correct for all platforms,
                 # but one can #define it to what one wants
    "N_INLINE", "N_NOINLINE", "N_FASTCALL", "N_CLOSURE", "N_NOCONV"]

proc cacheGetType(tab: TIdTable, key: PType): PRope =
  # returns nil if we need to declare this type
  # since types are now unique via the ``getUniqueType`` mechanism, this slow
  # linear search is not necessary anymore:
  result = PRope(idTableGet(tab, key))

proc getTempName(): PRope =
  result = rfmt(nil, "TMP$1", toRope(backendId()))

proc getGlobalTempName(): PRope =
  result = rfmt(nil, "TMP$1", toRope(backendId()))

proc ccgIntroducedPtr(s: PSym): bool =
  var pt = skipTypes(s.typ, typedescInst)
  assert skResult != s.kind
  if tfByRef in pt.flags: return true
  elif tfByCopy in pt.flags: return false
  case pt.kind
  of tyObject:
    if (optByRef in s.options) or (getSize(pt) > platform.floatSize * 2):
      result = true           # requested anyway
    elif (tfFinal in pt.flags) and (pt.sons[0] == nil):
      result = false          # no need, because no subtyping possible
    else:
      result = true           # ordinary objects are always passed by reference,
                              # otherwise casting doesn't work
  of tyTuple:
    result = (getSize(pt) > platform.floatSize*2) or (optByRef in s.options)
  else: result = false

proc fillResult(param: PSym) =
  fillLoc(param.loc, locParam, param.typ, ~"Result",
          OnStack)
  if (mapReturnType(param.typ) != ctArray) and isInvalidReturnType(param.typ):
    incl(param.loc.flags, lfIndirect)
    param.loc.s = OnUnknown

proc typeNameOrLiteral(t: PType, literal: string): PRope =
  if t.sym != nil and sfImportc in t.sym.flags and t.sym.magic == mNone:
    result = getTypeName(t)
  else:
    result = toRope(literal)

proc getSimpleTypeDesc(m: BModule, typ: PType): PRope =
  const
    NumericalTypeToStr: array[tyInt..tyUInt64, string] = [
      "NI", "NI8", "NI16", "NI32", "NI64",
      "NF", "NF32", "NF64", "NF128",
      "NU", "NU8", "NU16", "NU32", "NU64",]
  case typ.kind
  of tyPointer:
    result = typeNameOrLiteral(typ, "void*")
  of tyEnum:
    if firstOrd(typ) < 0:
      result = typeNameOrLiteral(typ, "NI32")
    else:
      case int(getSize(typ))
      of 1: result = typeNameOrLiteral(typ, "NU8")
      of 2: result = typeNameOrLiteral(typ, "NU16")
      of 4: result = typeNameOrLiteral(typ, "NI32")
      of 8: result = typeNameOrLiteral(typ, "NI64")
      else:
        internalError(typ.sym.info, "getSimpleTypeDesc: " & $(getSize(typ)))
        result = nil
  of tyString:
    discard cgsym(m, "NimStringDesc")
    result = typeNameOrLiteral(typ, "NimStringDesc*")
  of tyCString: result = typeNameOrLiteral(typ, "NCSTRING")
  of tyBool: result = typeNameOrLiteral(typ, "NIM_BOOL")
  of tyChar: result = typeNameOrLiteral(typ, "NIM_CHAR")
  of tyNil: result = typeNameOrLiteral(typ, "0")
  of tyInt..tyUInt64:
    result = typeNameOrLiteral(typ, NumericalTypeToStr[typ.kind])
  of tyDistinct, tyRange, tyOrdinal: result = getSimpleTypeDesc(m, typ.sons[0])
  else: result = nil

proc pushType(m: BModule, typ: PType) =
  add(m.typeStack, typ)

proc getTypePre(m: BModule, typ: PType): PRope =
  if typ == nil: result = toRope("void")
  else:
    result = getSimpleTypeDesc(m, typ)
    if result == nil: result = cacheGetType(m.typeCache, typ)

proc structOrUnion(t: PType): PRope =
  (if tfUnion in t.flags: toRope("union") else: toRope("struct"))

proc getForwardStructFormat(m: BModule): string =
  if m.compileToCpp: result = "$1 $2;$n"
  else: result = "typedef $1 $2 $2;$n"

proc getTypeForward(m: BModule, typ: PType): PRope =
  result = cacheGetType(m.forwTypeCache, typ)
  if result != nil: return
  result = getTypePre(m, typ)
  if result != nil: return
  case typ.kind
  of tySequence, tyTuple, tyObject:
    result = getTypeName(typ)
    if not isImportedType(typ):
      appf(m.s[cfsForwardTypes], getForwardStructFormat(m),
          [structOrUnion(typ), result])
    idTablePut(m.forwTypeCache, typ, result)
  else: internalError("getTypeForward(" & $typ.kind & ')')

proc getTypeDescWeak(m: BModule; t: PType; check: var IntSet): PRope =
  ## like getTypeDescAux but creates only a *weak* dependency. In other words
  ## we know we only need a pointer to it so we only generate a struct forward
  ## declaration:
  var etB = t.skipTypes(abstractInst)
  case etB.kind
  of tyObject, tyTuple:
    if isImportedCppType(etB) and t.kind == tyGenericInst:
      result = getTypeDescAux(m, t, check)
    else:
      let x = getUniqueType(etB)
      result = getTypeForward(m, x)
      pushType(m, x)
  of tySequence:
    let x = getUniqueType(etB)
    result = getTypeForward(m, x).con("*")
    pushType(m, x)
  else:
    result = getTypeDescAux(m, t, check)

proc paramStorageLoc(param: PSym): TStorageLoc =
  if param.typ.skipTypes({tyVar, tyTypeDesc}).kind notin {tyArray, tyOpenArray}:
    result = OnStack
  else:
    result = OnUnknown

proc genProcParams(m: BModule, t: PType, rettype, params: var PRope,
                   check: var IntSet, declareEnvironment=true) =
  params = nil
  if (t.sons[0] == nil) or isInvalidReturnType(t.sons[0]):
    rettype = ~"void"
  else:
    rettype = getTypeDescAux(m, t.sons[0], check)
  for i in countup(1, sonsLen(t.n) - 1):
    if t.n.sons[i].kind != nkSym: internalError(t.n.info, "genProcParams")
    var param = t.n.sons[i].sym
    if isCompileTimeOnly(param.typ): continue
    if params != nil: app(params, ~", ")
    fillLoc(param.loc, locParam, param.typ, mangleName(param),
            param.paramStorageLoc)
    if ccgIntroducedPtr(param):
      app(params, getTypeDescWeak(m, param.typ, check))
      app(params, ~"*")
      incl(param.loc.flags, lfIndirect)
      param.loc.s = OnUnknown
    else:
      app(params, getTypeDescAux(m, param.typ, check))
    app(params, ~" ")
    app(params, param.loc.r)
    # declare the len field for open arrays:
    var arr = param.typ
    if arr.kind == tyVar: arr = arr.sons[0]
    var j = 0
    while arr.kind in {tyOpenArray, tyVarargs}:
      # this fixes the 'sort' bug:
      if param.typ.kind == tyVar: param.loc.s = OnUnknown
      # need to pass hidden parameter:
      appf(params, ", NI $1Len$2", [param.loc.r, j.toRope])
      inc(j)
      arr = arr.sons[0]
  if (t.sons[0] != nil) and isInvalidReturnType(t.sons[0]):
    var arr = t.sons[0]
    if params != nil: app(params, ", ")
    if (mapReturnType(t.sons[0]) != ctArray):
      app(params, getTypeDescWeak(m, arr, check))
      app(params, "*")
    else:
      app(params, getTypeDescAux(m, arr, check))
    appf(params, " Result", [])
  if t.callConv == ccClosure and declareEnvironment:
    if params != nil: app(params, ", ")
    app(params, "void* ClEnv")
  if tfVarargs in t.flags:
    if params != nil: app(params, ", ")
    app(params, "...")
  if params == nil: app(params, "void)")
  else: app(params, ")")
  params = con("(", params)

proc mangleRecFieldName(field: PSym, rectype: PType): PRope =
  if (rectype.sym != nil) and
      ({sfImportc, sfExportc} * rectype.sym.flags != {}):
    result = field.loc.r
  else:
    result = toRope(mangleField(field.name.s))
  if result == nil: internalError(field.info, "mangleRecFieldName")

proc genRecordFieldsAux(m: BModule, n: PNode,
                        accessExpr: PRope, rectype: PType,
                        check: var IntSet): PRope =
  var
    ae, uname, sname, a: PRope
    k: PNode
    field: PSym
  result = nil
  case n.kind
  of nkRecList:
    for i in countup(0, sonsLen(n) - 1):
      app(result, genRecordFieldsAux(m, n.sons[i], accessExpr, rectype, check))
  of nkRecCase:
    if n.sons[0].kind != nkSym: internalError(n.info, "genRecordFieldsAux")
    app(result, genRecordFieldsAux(m, n.sons[0], accessExpr, rectype, check))
    uname = toRope(mangle(n.sons[0].sym.name.s) & 'U')
    if accessExpr != nil: ae = ropef("$1.$2", [accessExpr, uname])
    else: ae = uname
    var unionBody: PRope = nil
    for i in countup(1, sonsLen(n) - 1):
      case n.sons[i].kind
      of nkOfBranch, nkElse:
        k = lastSon(n.sons[i])
        if k.kind != nkSym:
          sname = con("S", toRope(i))
          a = genRecordFieldsAux(m, k, ropef("$1.$2", [ae, sname]), rectype,
                                 check)
          if a != nil:
            app(unionBody, "struct {")
            app(unionBody, a)
            appf(unionBody, "} $1;$n", [sname])
        else:
          app(unionBody, genRecordFieldsAux(m, k, ae, rectype, check))
      else: internalError("genRecordFieldsAux(record case branch)")
    if unionBody != nil:
      appf(result, "union{$n$1} $2;$n", [unionBody, uname])
  of nkSym:
    field = n.sym
    if field.typ.kind == tyEmpty: return
    #assert(field.ast == nil)
    sname = mangleRecFieldName(field, rectype)
    if accessExpr != nil: ae = ropef("$1.$2", [accessExpr, sname])
    else: ae = sname
    fillLoc(field.loc, locField, field.typ, ae, OnUnknown)
    # for importcpp'ed objects, we only need to set field.loc, but don't
    # have to recurse via 'getTypeDescAux'. And not doing so prevents problems
    # with heavily templatized C++ code:
    if not isImportedCppType(rectype):
      let fieldType = field.loc.t.skipTypes(abstractInst)
      if fieldType.kind == tyArray and tfUncheckedArray in fieldType.flags:
        appf(result, "$1 $2[SEQ_DECL_SIZE];$n",
            [getTypeDescAux(m, fieldType.elemType, check), sname])
      elif fieldType.kind == tySequence:
        # we need to use a weak dependency here for trecursive_table.
        appf(result, "$1 $2;$n", [getTypeDescWeak(m, field.loc.t, check), sname])
      else:
        # don't use fieldType here because we need the
        # tyGenericInst for C++ template support
        appf(result, "$1 $2;$n", [getTypeDescAux(m, field.loc.t, check), sname])
  else: internalError(n.info, "genRecordFieldsAux()")

proc getRecordFields(m: BModule, typ: PType, check: var IntSet): PRope =
  result = genRecordFieldsAux(m, typ.n, nil, typ, check)

proc getRecordDesc(m: BModule, typ: PType, name: PRope,
                   check: var IntSet): PRope =
  # declare the record:
  var hasField = false

  var attribute: PRope =
    if tfPacked in typ.flags: toRope(CC[cCompiler].packedPragma)
    else: nil

  result = ropecg(m, CC[cCompiler].structStmtFmt,
    [structOrUnion(typ), name, attribute])

  if typ.kind == tyObject:

    if typ.sons[0] == nil:
      if (typ.sym != nil and sfPure in typ.sym.flags) or tfFinal in typ.flags:
        appcg(m, result, " {$n", [])
      else:
        appcg(m, result, " {$n#TNimType* m_type;$n", [name, attribute])
        hasField = true
    elif m.compileToCpp:
      appcg(m, result, " : public $1 {$n",
                      [getTypeDescAux(m, typ.sons[0], check)])
      hasField = true
    else:
      appcg(m, result, " {$n  $1 Sup;$n",
                      [getTypeDescAux(m, typ.sons[0], check)])
      hasField = true
  else:
    appf(result, " {$n", [name])

  var desc = getRecordFields(m, typ, check)
  if desc == nil and not hasField:
    appf(result, "char dummy;$n", [])
  else:
    app(result, desc)
  app(result, "};" & tnl)

proc getTupleDesc(m: BModule, typ: PType, name: PRope,
                  check: var IntSet): PRope =
  result = ropef("$1 $2 {$n", [structOrUnion(typ), name])
  var desc: PRope = nil
  for i in countup(0, sonsLen(typ) - 1):
    appf(desc, "$1 Field$2;$n",
         [getTypeDescAux(m, typ.sons[i], check), toRope(i)])
  if desc == nil: app(result, "char dummy;" & tnl)
  else: app(result, desc)
  app(result, "};" & tnl)

proc getTypeDescAux(m: BModule, typ: PType, check: var IntSet): PRope =
  # returns only the type's name
  var t = getUniqueType(typ)
  if t == nil: internalError("getTypeDescAux: t == nil")
  if t.sym != nil: useHeader(m, t.sym)
  result = getTypePre(m, t)
  if result != nil: return
  if containsOrIncl(check, t.id):
    if isImportedCppType(typ) or isImportedCppType(t): return
    internalError("cannot generate C type for: " & typeToString(typ))
    # XXX: this BUG is hard to fix -> we need to introduce helper structs,
    # but determining when this needs to be done is hard. We should split
    # C type generation into an analysis and a code generation phase somehow.
  case t.kind
  of tyRef, tyPtr, tyVar:
    var star = if t.kind == tyVar and tfVarIsPtr notin typ.flags and
                    compileToCpp(m): "&" else: "*"
    var et = t.lastSon
    var etB = et.skipTypes(abstractInst)
    if etB.kind in {tyArrayConstr, tyArray, tyOpenArray, tyVarargs}:
      # this is correct! sets have no proper base type, so we treat
      # ``var set[char]`` in `getParamTypeDesc`
      et = elemType(etB)
      etB = et.skipTypes(abstractInst)
      star[0] = '*'
    case etB.kind
    of tyObject, tyTuple:
      if isImportedCppType(etB) and et.kind == tyGenericInst:
        result = con(getTypeDescAux(m, et, check), star)
      else:
        # no restriction! We have a forward declaration for structs
        let x = getUniqueType(etB)
        let name = getTypeForward(m, x)
        result = con(name, star)
        idTablePut(m.typeCache, t, result)
        pushType(m, x)
    of tySequence:
      # no restriction! We have a forward declaration for structs
      let x = getUniqueType(etB)
      let name = getTypeForward(m, x)
      result = con(name, "*" & star)
      idTablePut(m.typeCache, t, result)
      pushType(m, x)
    else:
      # else we have a strong dependency  :-(
      result = con(getTypeDescAux(m, et, check), star)
      idTablePut(m.typeCache, t, result)
  of tyOpenArray, tyVarargs:
    result = con(getTypeDescAux(m, t.sons[0], check), "*")
    idTablePut(m.typeCache, t, result)
  of tyProc:
    result = getTypeName(t)
    idTablePut(m.typeCache, t, result)
    var rettype, desc: PRope
    genProcParams(m, t, rettype, desc, check)
    if not isImportedType(t):
      if t.callConv != ccClosure: # procedure vars may need a closure!
        appf(m.s[cfsTypes], "typedef $1_PTR($2, $3) $4;$n",
             [toRope(CallingConvToStr[t.callConv]), rettype, result, desc])
      else:
        appf(m.s[cfsTypes], "typedef struct {$n" &
            "N_NIMCALL_PTR($2, ClPrc) $3;$n" &
            "void* ClEnv;$n} $1;$n",
             [result, rettype, desc])
  of tySequence:
    # we cannot use getTypeForward here because then t would be associated
    # with the name of the struct, not with the pointer to the struct:
    result = cacheGetType(m.forwTypeCache, t)
    if result == nil:
      result = getTypeName(t)
      if not isImportedType(t):
        appf(m.s[cfsForwardTypes], getForwardStructFormat(m),
            [structOrUnion(t), result])
      idTablePut(m.forwTypeCache, t, result)
    assert(cacheGetType(m.typeCache, t) == nil)
    idTablePut(m.typeCache, t, con(result, "*"))
    if not isImportedType(t):
      if skipTypes(t.sons[0], typedescInst).kind != tyEmpty:
        const
          cppSeq = "struct $2 : #TGenericSeq {$n"
          cSeq = "struct $2 {$n" &
                 "  #TGenericSeq Sup;$n"
        appcg(m, m.s[cfsSeqTypes],
            (if m.compileToCpp: cppSeq else: cSeq) &
            "  $1 data[SEQ_DECL_SIZE];$n" &
            "};$n", [getTypeDescAux(m, t.sons[0], check), result])
      else:
        result = toRope("TGenericSeq")
    app(result, "*")
  of tyArrayConstr, tyArray:
    var n: BiggestInt = lengthOrd(t)
    if n <= 0: n = 1   # make an array of at least one element
    result = getTypeName(t)
    idTablePut(m.typeCache, t, result)
    if not isImportedType(t):
      let foo = getTypeDescAux(m, t.sons[1], check)
      appf(m.s[cfsTypes], "typedef $1 $2[$3];$n",
           [foo, result, toRope(n)])
  of tyObject, tyTuple:
    if isImportedCppType(t) and typ.kind == tyGenericInst:
      # for instantiated templates we do not go through the type cache as the
      # the type cache is not aware of 'tyGenericInst'.
      result = getTypeName(t).con("<")
      for i in 1 .. typ.len-2:
        if i > 1: result.app(", ")
        result.app(getTypeDescAux(m, typ.sons[i], check))
      result.app("> ")
      # always call for sideeffects:
      assert t.kind != tyTuple
      discard getRecordDesc(m, t, result, check)
    else:
      result = cacheGetType(m.forwTypeCache, t)
      if result == nil:
        result = getTypeName(t)
        if not isImportedType(t):
          appf(m.s[cfsForwardTypes], getForwardStructFormat(m),
             [structOrUnion(t), result])
        idTablePut(m.forwTypeCache, t, result)
      idTablePut(m.typeCache, t, result) # always call for sideeffects:
      let recdesc = if t.kind != tyTuple: getRecordDesc(m, t, result, check)
                    else: getTupleDesc(m, t, result, check)
      if not isImportedType(t): app(m.s[cfsTypes], recdesc)
  of tySet:
    case int(getSize(t))
    of 1: result = toRope("NU8")
    of 2: result = toRope("NU16")
    of 4: result = toRope("NU32")
    of 8: result = toRope("NU64")
    else:
      result = getTypeName(t)
      idTablePut(m.typeCache, t, result)
      if not isImportedType(t):
        appf(m.s[cfsTypes], "typedef NU8 $1[$2];$n",
             [result, toRope(getSize(t))])
  of tyGenericInst, tyDistinct, tyOrdinal, tyConst, tyMutable,
      tyIter, tyTypeDesc:
    result = getTypeDescAux(m, lastSon(t), check)
  else:
    internalError("getTypeDescAux(" & $t.kind & ')')
    result = nil
  # fixes bug #145:
  excl(check, t.id)

proc getTypeDesc(m: BModule, typ: PType): PRope =
  var check = initIntSet()
  result = getTypeDescAux(m, typ, check)

type
  TClosureTypeKind = enum
    clHalf, clHalfWithEnv, clFull

proc getClosureType(m: BModule, t: PType, kind: TClosureTypeKind): PRope =
  assert t.kind == tyProc
  var check = initIntSet()
  result = getTempName()
  var rettype, desc: PRope
  genProcParams(m, t, rettype, desc, check, declareEnvironment=kind != clHalf)
  if not isImportedType(t):
    if t.callConv != ccClosure or kind != clFull:
      appf(m.s[cfsTypes], "typedef $1_PTR($2, $3) $4;$n",
           [toRope(CallingConvToStr[t.callConv]), rettype, result, desc])
    else:
      appf(m.s[cfsTypes], "typedef struct {$n" &
          "N_NIMCALL_PTR($2, ClPrc) $3;$n" &
          "void* ClEnv;$n} $1;$n",
           [result, rettype, desc])

proc getTypeDesc(m: BModule, magic: string): PRope =
  var sym = magicsys.getCompilerProc(magic)
  if sym != nil:
    result = getTypeDesc(m, sym.typ)
  else:
    rawMessage(errSystemNeeds, magic)
    result = nil

proc finishTypeDescriptions(m: BModule) =
  var i = 0
  while i < len(m.typeStack):
    discard getTypeDesc(m, m.typeStack[i])
    inc(i)

template cgDeclFrmt*(s: PSym): string = s.constraint.strVal

proc genProcHeader(m: BModule, prc: PSym): PRope =
  var
    rettype, params: PRope
  genCLineDir(result, prc.info)
  # using static is needed for inline procs
  if lfExportLib in prc.loc.flags:
    if m.isHeaderFile:
      result.app "N_LIB_IMPORT "
    else:
      result.app "N_LIB_EXPORT "
  elif prc.typ.callConv == ccInline:
    result.app "static "
  var check = initIntSet()
  fillLoc(prc.loc, locProc, prc.typ, mangleName(prc), OnUnknown)
  genProcParams(m, prc.typ, rettype, params, check)
  # careful here! don't access ``prc.ast`` as that could reload large parts of
  # the object graph!
  if prc.constraint.isNil:
    appf(result, "$1($2, $3)$4",
         [toRope(CallingConvToStr[prc.typ.callConv]), rettype, prc.loc.r,
         params])
  else:
    result = ropef(prc.cgDeclFrmt, [rettype, prc.loc.r, params])

# ------------------ type info generation -------------------------------------

proc genTypeInfo(m: BModule, t: PType): PRope
proc getNimNode(m: BModule): PRope =
  result = ropef("$1[$2]", [m.typeNodesName, toRope(m.typeNodes)])
  inc(m.typeNodes)

proc genTypeInfoAuxBase(m: BModule; typ, origType: PType; name, base: PRope) =
  var nimtypeKind: int
  #allocMemTI(m, typ, name)
  if isObjLackingTypeField(typ):
    nimtypeKind = ord(tyPureObject)
  else:
    nimtypeKind = ord(typ.kind)

  var size: PRope
  if tfIncompleteStruct in typ.flags: size = toRope"void*"
  elif m.compileToCpp: size = getTypeDesc(m, origType)
  else: size = getTypeDesc(m, typ)
  appf(m.s[cfsTypeInit3],
       "$1.size = sizeof($2);$n" & "$1.kind = $3;$n" & "$1.base = $4;$n",
       [name, size, toRope(nimtypeKind), base])
  # compute type flags for GC optimization
  var flags = 0
  if not containsGarbageCollectedRef(typ): flags = flags or 1
  if not canFormAcycle(typ): flags = flags or 2
  #else MessageOut("can contain a cycle: " & typeToString(typ))
  if flags != 0:
    appf(m.s[cfsTypeInit3], "$1.flags = $2;$n", [name, toRope(flags)])
  discard cgsym(m, "TNimType")
  appf(m.s[cfsVars], "TNimType $1; /* $2 */$n",
       [name, toRope(typeToString(typ))])

proc genTypeInfoAux(m: BModule, typ, origType: PType, name: PRope) =
  var base: PRope
  if (sonsLen(typ) > 0) and (typ.sons[0] != nil):
    base = genTypeInfo(m, typ.sons[0])
  else:
    base = toRope("0")
  genTypeInfoAuxBase(m, typ, origType, name, base)

proc discriminatorTableName(m: BModule, objtype: PType, d: PSym): PRope =
  # bugfix: we need to search the type that contains the discriminator:
  var objtype = objtype
  while lookupInRecord(objtype.n, d.name) == nil:
    objtype = objtype.sons[0]
  if objtype.sym == nil:
    internalError(d.info, "anonymous obj with discriminator")
  result = ropef("NimDT_$1_$2", [
    toRope(objtype.id), toRope(d.name.s.mangle)])

proc discriminatorTableDecl(m: BModule, objtype: PType, d: PSym): PRope =
  discard cgsym(m, "TNimNode")
  var tmp = discriminatorTableName(m, objtype, d)
  result = ropef("TNimNode* $1[$2];$n", [tmp, toRope(lengthOrd(d.typ)+1)])

proc genObjectFields(m: BModule, typ: PType, n: PNode, expr: PRope) =
  case n.kind
  of nkRecList:
    var L = sonsLen(n)
    if L == 1:
      genObjectFields(m, typ, n.sons[0], expr)
    elif L > 0:
      var tmp = getTempName()
      appf(m.s[cfsTypeInit1], "static TNimNode* $1[$2];$n", [tmp, toRope(L)])
      for i in countup(0, L-1):
        var tmp2 = getNimNode(m)
        appf(m.s[cfsTypeInit3], "$1[$2] = &$3;$n", [tmp, toRope(i), tmp2])
        genObjectFields(m, typ, n.sons[i], tmp2)
      appf(m.s[cfsTypeInit3], "$1.len = $2; $1.kind = 2; $1.sons = &$3[0];$n",
           [expr, toRope(L), tmp])
    else:
      appf(m.s[cfsTypeInit3], "$1.len = $2; $1.kind = 2;$n", [expr, toRope(L)])
  of nkRecCase:
    assert(n.sons[0].kind == nkSym)
    var field = n.sons[0].sym
    var tmp = discriminatorTableName(m, typ, field)
    var L = lengthOrd(field.typ)
    assert L > 0
    appf(m.s[cfsTypeInit3], "$1.kind = 3;$n" &
        "$1.offset = offsetof($2, $3);$n" & "$1.typ = $4;$n" &
        "$1.name = $5;$n" & "$1.sons = &$6[0];$n" &
        "$1.len = $7;$n", [expr, getTypeDesc(m, typ), field.loc.r,
                           genTypeInfo(m, field.typ),
                           makeCString(field.name.s),
                           tmp, toRope(L)])
    appf(m.s[cfsData], "TNimNode* $1[$2];$n", [tmp, toRope(L+1)])
    for i in countup(1, sonsLen(n)-1):
      var b = n.sons[i]           # branch
      var tmp2 = getNimNode(m)
      genObjectFields(m, typ, lastSon(b), tmp2)
      case b.kind
      of nkOfBranch:
        if sonsLen(b) < 2:
          internalError(b.info, "genObjectFields; nkOfBranch broken")
        for j in countup(0, sonsLen(b) - 2):
          if b.sons[j].kind == nkRange:
            var x = int(getOrdValue(b.sons[j].sons[0]))
            var y = int(getOrdValue(b.sons[j].sons[1]))
            while x <= y:
              appf(m.s[cfsTypeInit3], "$1[$2] = &$3;$n", [tmp, toRope(x), tmp2])
              inc(x)
          else:
            appf(m.s[cfsTypeInit3], "$1[$2] = &$3;$n",
                 [tmp, toRope(getOrdValue(b.sons[j])), tmp2])
      of nkElse:
        appf(m.s[cfsTypeInit3], "$1[$2] = &$3;$n",
             [tmp, toRope(L), tmp2])
      else: internalError(n.info, "genObjectFields(nkRecCase)")
  of nkSym:
    var field = n.sym
    appf(m.s[cfsTypeInit3], "$1.kind = 1;$n" &
        "$1.offset = offsetof($2, $3);$n" & "$1.typ = $4;$n" &
        "$1.name = $5;$n", [expr, getTypeDesc(m, typ),
        field.loc.r, genTypeInfo(m, field.typ), makeCString(field.name.s)])
  else: internalError(n.info, "genObjectFields")

proc genObjectInfo(m: BModule, typ, origType: PType, name: PRope) =
  if typ.kind == tyObject: genTypeInfoAux(m, typ, origType, name)
  else: genTypeInfoAuxBase(m, typ, origType, name, toRope("0"))
  var tmp = getNimNode(m)
  if not isImportedCppType(typ):
    genObjectFields(m, typ, typ.n, tmp)
  appf(m.s[cfsTypeInit3], "$1.node = &$2;$n", [name, tmp])
  var t = typ.sons[0]
  while t != nil:
    t = t.skipTypes(abstractInst)
    t.flags.incl tfObjHasKids
    t = t.sons[0]

proc genTupleInfo(m: BModule, typ: PType, name: PRope) =
  genTypeInfoAuxBase(m, typ, typ, name, toRope("0"))
  var expr = getNimNode(m)
  var length = sonsLen(typ)
  if length > 0:
    var tmp = getTempName()
    appf(m.s[cfsTypeInit1], "static TNimNode* $1[$2];$n", [tmp, toRope(length)])
    for i in countup(0, length - 1):
      var a = typ.sons[i]
      var tmp2 = getNimNode(m)
      appf(m.s[cfsTypeInit3], "$1[$2] = &$3;$n", [tmp, toRope(i), tmp2])
      appf(m.s[cfsTypeInit3], "$1.kind = 1;$n" &
          "$1.offset = offsetof($2, Field$3);$n" &
          "$1.typ = $4;$n" &
          "$1.name = \"Field$3\";$n",
           [tmp2, getTypeDesc(m, typ), toRope(i), genTypeInfo(m, a)])
    appf(m.s[cfsTypeInit3], "$1.len = $2; $1.kind = 2; $1.sons = &$3[0];$n",
         [expr, toRope(length), tmp])
  else:
    appf(m.s[cfsTypeInit3], "$1.len = $2; $1.kind = 2;$n",
         [expr, toRope(length)])
  appf(m.s[cfsTypeInit3], "$1.node = &$2;$n", [name, expr])

proc genEnumInfo(m: BModule, typ: PType, name: PRope) =
  # Type information for enumerations is quite heavy, so we do some
  # optimizations here: The ``typ`` field is never set, as it is redundant
  # anyway. We generate a cstring array and a loop over it. Exceptional
  # positions will be reset after the loop.
  genTypeInfoAux(m, typ, typ, name)
  var nodePtrs = getTempName()
  var length = sonsLen(typ.n)
  appf(m.s[cfsTypeInit1], "static TNimNode* $1[$2];$n",
       [nodePtrs, toRope(length)])
  var enumNames, specialCases: PRope
  var firstNimNode = m.typeNodes
  var hasHoles = false
  for i in countup(0, length - 1):
    assert(typ.n.sons[i].kind == nkSym)
    var field = typ.n.sons[i].sym
    var elemNode = getNimNode(m)
    if field.ast == nil:
      # no explicit string literal for the enum field, so use field.name:
      app(enumNames, makeCString(field.name.s))
    else:
      app(enumNames, makeCString(field.ast.strVal))
    if i < length - 1: app(enumNames, ", " & tnl)
    if field.position != i or tfEnumHasHoles in typ.flags:
      appf(specialCases, "$1.offset = $2;$n", [elemNode, toRope(field.position)])
      hasHoles = true
  var enumArray = getTempName()
  var counter = getTempName()
  appf(m.s[cfsTypeInit1], "NI $1;$n", [counter])
  appf(m.s[cfsTypeInit1], "static char* NIM_CONST $1[$2] = {$n$3};$n",
       [enumArray, toRope(length), enumNames])
  appf(m.s[cfsTypeInit3], "for ($1 = 0; $1 < $2; $1++) {$n" &
      "$3[$1+$4].kind = 1;$n" & "$3[$1+$4].offset = $1;$n" &
      "$3[$1+$4].name = $5[$1];$n" & "$6[$1] = &$3[$1+$4];$n" & "}$n", [counter,
      toRope(length), m.typeNodesName, toRope(firstNimNode), enumArray, nodePtrs])
  app(m.s[cfsTypeInit3], specialCases)
  appf(m.s[cfsTypeInit3],
       "$1.len = $2; $1.kind = 2; $1.sons = &$3[0];$n$4.node = &$1;$n",
       [getNimNode(m), toRope(length), nodePtrs, name])
  if hasHoles:
    # 1 << 2 is {ntfEnumHole}
    appf(m.s[cfsTypeInit3], "$1.flags = 1<<2;$n", [name])

proc genSetInfo(m: BModule, typ: PType, name: PRope) =
  assert(typ.sons[0] != nil)
  genTypeInfoAux(m, typ, typ, name)
  var tmp = getNimNode(m)
  appf(m.s[cfsTypeInit3], "$1.len = $2; $1.kind = 0;$n" & "$3.node = &$1;$n",
       [tmp, toRope(firstOrd(typ)), name])

proc genArrayInfo(m: BModule, typ: PType, name: PRope) =
  genTypeInfoAuxBase(m, typ, typ, name, genTypeInfo(m, typ.sons[1]))

proc fakeClosureType(owner: PSym): PType =
  # we generate the same RTTI as for a tuple[pointer, ref tuple[]]
  result = newType(tyTuple, owner)
  result.rawAddSon(newType(tyPointer, owner))
  var r = newType(tyRef, owner)
  r.rawAddSon(newType(tyTuple, owner))
  result.rawAddSon(r)

type
  TTypeInfoReason = enum  ## for what do we need the type info?
    tiNew,                ## for 'new'
    tiNewSeq,             ## for 'newSeq'
    tiNonVariantAsgn,     ## for generic assignment without variants
    tiVariantAsgn         ## for generic assignment with variants

include ccgtrav

proc genDeepCopyProc(m: BModule; s: PSym; result: PRope) =
  genProc(m, s)
  appf(m.s[cfsTypeInit3], "$1.deepcopy =(void* (N_RAW_NIMCALL*)(void*))$2;$n",
     [result, s.loc.r])

proc genTypeInfo(m: BModule, t: PType): PRope =
  let origType = t
  var t = getUniqueType(t)
  result = ropef("NTI$1", [toRope(t.id)])
  if containsOrIncl(m.typeInfoMarker, t.id):
    return con("(&".toRope, result, ")".toRope)

  # getUniqueType doesn't skip tyDistinct when that has an overriden operation:
  while t.kind == tyDistinct: t = t.lastSon
  let owner = t.skipTypes(typedescPtrs).owner.getModule
  if owner != m.module:
    # make sure the type info is created in the owner module
    discard genTypeInfo(owner.bmod, t)
    # reference the type info as extern here
    discard cgsym(m, "TNimType")
    discard cgsym(m, "TNimNode")
    appf(m.s[cfsVars], "extern TNimType $1; /* $2 */$n",
         [result, toRope(typeToString(t))])
    return con("(&".toRope, result, ")".toRope)
  case t.kind
  of tyEmpty: result = toRope"0"
  of tyPointer, tyBool, tyChar, tyCString, tyString, tyInt..tyUInt64, tyVar:
    genTypeInfoAuxBase(m, t, t, result, toRope"0")
  of tyProc:
    if t.callConv != ccClosure:
      genTypeInfoAuxBase(m, t, t, result, toRope"0")
    else:
      genTupleInfo(m, fakeClosureType(t.owner), result)
  of tySequence, tyRef:
    genTypeInfoAux(m, t, t, result)
    if gSelectedGC >= gcMarkAndSweep:
      let markerProc = genTraverseProc(m, t, tiNew)
      appf(m.s[cfsTypeInit3], "$1.marker = $2;$n", [result, markerProc])
  of tyPtr, tyRange: genTypeInfoAux(m, t, t, result)
  of tyArrayConstr, tyArray: genArrayInfo(m, t, result)
  of tySet: genSetInfo(m, t, result)
  of tyEnum: genEnumInfo(m, t, result)
  of tyObject: genObjectInfo(m, t, origType, result)
  of tyTuple:
    # if t.n != nil: genObjectInfo(m, t, result)
    # else:
    # BUGFIX: use consistently RTTI without proper field names; otherwise
    # results are not deterministic!
    genTupleInfo(m, t, result)
  else: internalError("genTypeInfo(" & $t.kind & ')')
  if t.deepCopy != nil:
    genDeepCopyProc(m, t.deepCopy, result)
  elif origType.deepCopy != nil:
    genDeepCopyProc(m, origType.deepCopy, result)
  result = con("(&".toRope, result, ")".toRope)

proc genTypeSection(m: BModule, n: PNode) =
  discard
