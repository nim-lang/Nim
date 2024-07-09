#
#
#           The Nim Compiler
#        (c) Copyright 2023 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import std / [assertions, tables, sets]
import ".." / [ast, types, options, sighashes, modulegraphs]
import nirtypes

type
  TypesCon* = object
    processed: Table[ItemId, TypeId]
    recursionCheck: HashSet[ItemId]
    g*: TypeGraph
    conf: ConfigRef

proc initTypesCon*(conf: ConfigRef; lit: Literals): TypesCon =
  TypesCon(g: initTypeGraph(lit), conf: conf)

proc mangle(c: var TypesCon; t: PType): string =
  result = $sighashes.hashType(t, c.conf)

template cached(c: var TypesCon; t: PType; body: untyped) =
  result = c.processed.getOrDefault(t.itemId)
  if result.int == 0:
    body
    c.processed[t.itemId] = result

proc typeToIr*(c: var TypesCon; t: PType): TypeId

proc collectFieldTypes(c: var TypesCon; n: PNode; dest: var Table[ItemId, TypeId]) =
  case n.kind
  of nkRecList:
    for i in 0..<n.len:
      collectFieldTypes(c, n[i], dest)
  of nkRecCase:
    assert(n[0].kind == nkSym)
    collectFieldTypes(c, n[0], dest)
    for i in 1..<n.len:
      case n[i].kind
      of nkOfBranch, nkElse:
        collectFieldTypes c, lastSon(n[i]), dest
      else: discard
  of nkSym:
    dest[n.sym.itemId] = typeToIr(c, n.sym.typ)
  else:
    assert false, "unknown node kind: " & $n.kind

proc objectToIr(c: var TypesCon; n: PNode; fieldTypes: Table[ItemId, TypeId]; unionId: var int) =
  case n.kind
  of nkRecList:
    for i in 0..<n.len:
      objectToIr(c, n[i], fieldTypes, unionId)
  of nkRecCase:
    assert(n[0].kind == nkSym)
    objectToIr(c, n[0], fieldTypes, unionId)
    let u = openType(c.g, UnionDecl)
    c.g.addName "u_" & $unionId
    inc unionId
    for i in 1..<n.len:
      case n[i].kind
      of nkOfBranch, nkElse:
        let subObj = openType(c.g, ObjectDecl)
        c.g.addName "uo_" & $unionId & "_" & $i
        objectToIr c, lastSon(n[i]), fieldTypes, unionId
        sealType(c.g, subObj)
      else: discard
    sealType(c.g, u)
  of nkSym:
    c.g.addField n.sym.name.s & "_" & $n.sym.position, fieldTypes[n.sym.itemId], n.sym.offset
  else:
    assert false, "unknown node kind: " & $n.kind

<<<<<<< HEAD
proc objectToIr(c: var TypesCon; g: var TypeGraph; t: PType): TypeId =
  if t.baseClass != nil:
    # ensure we emitted the base type:
    discard typeToIr(c, g, t.baseClass)
=======
proc objectToIr(c: var TypesCon; t: PType): TypeId =
  if t[0] != nil:
    # ensure we emitted the base type:
    discard typeToIr(c, t[0])
>>>>>>> parent of 0c26d19e2 (NIR: VM + refactorings (#22835))

  var unionId = 0
  var fieldTypes = initTable[ItemId, TypeId]()
  collectFieldTypes c, t.n, fieldTypes
  let obj = openType(c.g, ObjectDecl)
  c.g.addName mangle(c, t)
  c.g.addSize c.conf.getSize(t)
  c.g.addAlign c.conf.getAlign(t)

<<<<<<< HEAD
  if t.baseClass != nil:
    g.addNominalType(ObjectTy, mangle(c, t.baseClass))
=======
  if t[0] != nil:
    c.g.addNominalType(ObjectTy, mangle(c, t[0]))
>>>>>>> parent of 0c26d19e2 (NIR: VM + refactorings (#22835))
  else:
    c.g.addBuiltinType VoidId # object does not inherit
    if not lacksMTypeField(t):
      let f2 = c.g.openType FieldDecl
      let voidPtr = openType(c.g, APtrTy)
      c.g.addBuiltinType(VoidId)
      sealType(c.g, voidPtr)
      c.g.addOffset 0 # type field is always at offset 0
      c.g.addName "m_type"
      sealType(c.g, f2) # FieldDecl

  objectToIr c, t.n, fieldTypes, unionId
  result = finishType(c.g, obj)

proc objectHeaderToIr(c: var TypesCon; t: PType): TypeId =
  result = c.g.nominalType(ObjectTy, mangle(c, t))

proc tupleToIr(c: var TypesCon; t: PType): TypeId =
  var fieldTypes = newSeq[TypeId](t.len)
  for i in 0..<t.len:
    fieldTypes[i] = typeToIr(c, t[i])
  let obj = openType(c.g, ObjectDecl)
  c.g.addName mangle(c, t)
  c.g.addSize c.conf.getSize(t)
  c.g.addAlign c.conf.getAlign(t)

  var accum = OffsetAccum(maxAlign: 1)
  for i in 0..<t.len:
    let child = t[i]
    c.g.addField "f_" & $i, fieldTypes[i], accum.offset

    computeSizeAlign(c.conf, child)
    accum.align(child.align)
    accum.inc(int32(child.size))
  result = finishType(c.g, obj)

proc procToIr(c: var TypesCon; t: PType; addEnv = false): TypeId =
  var fieldTypes = newSeq[TypeId](0)
  for i in 0..<t.len:
    if t[i] == nil or not isCompileTimeOnly(t[i]):
      fieldTypes.add typeToIr(c, t[i])
  let obj = openType(c.g, ProcTy)

  case t.callConv
<<<<<<< HEAD
  of ccNimCall, ccFastCall, ccClosure: g.addAnnotation "__fastcall"
  of ccStdCall: g.addAnnotation "__stdcall"
  of ccCDecl: g.addAnnotation "__cdecl"
  of ccSafeCall: g.addAnnotation "__safecall"
  of ccSysCall: g.addAnnotation "__syscall"
  of ccInline: g.addAnnotation "__inline"
  of ccNoInline: g.addAnnotation "__noinline"
  of ccThisCall: g.addAnnotation "__thiscall"
  of ccNoConvention, ccMember: g.addAnnotation ""
=======
  of ccNimCall, ccFastCall, ccClosure: c.g.addAnnotation "__fastcall"
  of ccStdCall: c.g.addAnnotation "__stdcall"
  of ccCDecl: c.g.addAnnotation "__cdecl"
  of ccSafeCall: c.g.addAnnotation "__safecall"
  of ccSysCall: c.g.addAnnotation "__syscall"
  of ccInline: c.g.addAnnotation "__inline"
  of ccNoInline: c.g.addAnnotation "__noinline"
  of ccThisCall: c.g.addAnnotation "__thiscall"
  of ccNoConvention: c.g.addAnnotation ""
>>>>>>> parent of 0c26d19e2 (NIR: VM + refactorings (#22835))

  for i in 0..<fieldTypes.len:
    c.g.addType fieldTypes[i]

  if addEnv:
    let a = openType(c.g, APtrTy)
    c.g.addBuiltinType(VoidId)
    sealType(c.g, a)

  if tfVarargs in t.flags:
    c.g.addVarargs()
  result = finishType(c.g, obj)

proc nativeInt(c: TypesCon): TypeId =
  case c.conf.target.intSize
  of 2: result = Int16Id
  of 4: result = Int32Id
  else: result = Int64Id

<<<<<<< HEAD
proc openArrayPayloadType*(c: var TypesCon; g: var TypeGraph; t: PType): TypeId =
  let e = elementType(t)
  let elementType = typeToIr(c, g, e)
  let arr = g.openType AArrayPtrTy
  g.addType elementType
  result = finishType(g, arr) # LastArrayTy
=======
proc openArrayPayloadType*(c: var TypesCon; t: PType): TypeId =
  let e = lastSon(t)
  let elementType = typeToIr(c, e)
  let arr = c.g.openType AArrayPtrTy
  c.g.addType elementType
  result = finishType(c.g, arr) # LastArrayTy
>>>>>>> parent of 0c26d19e2 (NIR: VM + refactorings (#22835))

proc openArrayToIr(c: var TypesCon; t: PType): TypeId =
  # object (a: ArrayPtr[T], len: int)
  let e = elementType(t)
  let mangledBase = mangle(c, e)
  let typeName = "NimOpenArray" & mangledBase

  let elementType = typeToIr(c, e)
  #assert elementType.int >= 0, typeToString(t)

  let p = openType(c.g, ObjectDecl)
  c.g.addName typeName
  c.g.addSize c.conf.target.ptrSize*2
  c.g.addAlign c.conf.target.ptrSize

  let f = c.g.openType FieldDecl
  let arr = c.g.openType AArrayPtrTy
  c.g.addType elementType
  sealType(c.g, arr) # LastArrayTy
  c.g.addOffset 0
  c.g.addName "data"
  sealType(c.g, f) # FieldDecl

  c.g.addField "len", c.nativeInt, c.conf.target.ptrSize

  result = finishType(c.g, p) # ObjectDecl

proc strPayloadType(c: var TypesCon): string =
  result = "NimStrPayload"
  let p = openType(c.g, ObjectDecl)
  c.g.addName result
  c.g.addSize c.conf.target.ptrSize*2
  c.g.addAlign c.conf.target.ptrSize

  c.g.addField "cap", c.nativeInt, 0

  let f = c.g.openType FieldDecl
  let arr = c.g.openType LastArrayTy
  c.g.addBuiltinType Char8Id
  sealType(c.g, arr) # LastArrayTy
  c.g.addOffset c.conf.target.ptrSize # comes after the len field
  c.g.addName "data"
  sealType(c.g, f) # FieldDecl

  sealType(c.g, p)

proc strPayloadPtrType*(c: var TypesCon): TypeId =
  let mangled = strPayloadType(c)
  let ffp = c.g.openType APtrTy
  c.g.addNominalType ObjectTy, mangled
  result = finishType(c.g, ffp) # APtrTy

proc stringToIr(c: var TypesCon): TypeId =
  #[

    NimStrPayload = object
      cap: int
      data: UncheckedArray[char]

    NimStringV2 = object
      len: int
      p: ptr NimStrPayload

  ]#
  let payload = strPayloadType(c)

  let str = openType(c.g, ObjectDecl)
  c.g.addName "NimStringV2"
  c.g.addSize c.conf.target.ptrSize*2
  c.g.addAlign c.conf.target.ptrSize

  c.g.addField "len", c.nativeInt, 0

  let fp = c.g.openType FieldDecl
  let ffp = c.g.openType APtrTy
  c.g.addNominalType ObjectTy, "NimStrPayload"
  sealType(c.g, ffp) # APtrTy
  c.g.addOffset c.conf.target.ptrSize # comes after 'len' field
  c.g.addName "p"
  sealType(c.g, fp) # FieldDecl

  result = finishType(c.g, str) # ObjectDecl

proc seqPayloadType(c: var TypesCon; t: PType): string =
  #[
    NimSeqPayload[T] = object
      cap: int
      data: UncheckedArray[T]
  ]#
<<<<<<< HEAD
  let e = elementType(t)
  result = (mangle(c, e), TypeId(-1))
  let payloadName = "NimSeqPayload" & result[0]
=======
  let e = lastSon(t)
  result = mangle(c, e)
  let payloadName = "NimSeqPayload" & result
>>>>>>> parent of 0c26d19e2 (NIR: VM + refactorings (#22835))

  let elementType = typeToIr(c, e)

  let p = openType(c.g, ObjectDecl)
  c.g.addName payloadName
  c.g.addSize c.conf.target.intSize
  c.g.addAlign c.conf.target.intSize

  c.g.addField "cap", c.nativeInt, 0

  let f = c.g.openType FieldDecl
  let arr = c.g.openType LastArrayTy
  c.g.addType elementType
  sealType(c.g, arr) # LastArrayTy
  c.g.addOffset c.conf.target.ptrSize
  c.g.addName "data"
  sealType(c.g, f) # FieldDecl
  sealType(c.g, p)

proc seqPayloadPtrType*(c: var TypesCon; t: PType): TypeId =
  let mangledBase = seqPayloadType(c, t)
  let ffp = c.g.openType APtrTy
  c.g.addNominalType ObjectTy, "NimSeqPayload" & mangledBase
  result = finishType(c.g, ffp) # APtrTy

proc seqToIr(c: var TypesCon; t: PType): TypeId =
  #[
    NimSeqV2*[T] = object
      len: int
      p: ptr NimSeqPayload[T]
  ]#
  let mangledBase = seqPayloadType(c, t)

  let sq = openType(c.g, ObjectDecl)
  c.g.addName "NimSeqV2" & mangledBase
  c.g.addSize c.conf.getSize(t)
  c.g.addAlign c.conf.getAlign(t)

  c.g.addField "len", c.nativeInt, 0

  let fp = c.g.openType FieldDecl
  let ffp = c.g.openType APtrTy
  c.g.addNominalType ObjectTy, "NimSeqPayload" & mangledBase
  sealType(c.g, ffp) # APtrTy
  c.g.addOffset c.conf.target.ptrSize
  c.g.addName "p"
  sealType(c.g, fp) # FieldDecl

  result = finishType(c.g, sq) # ObjectDecl


proc closureToIr(c: var TypesCon; t: PType): TypeId =
  # struct {fn(args, void* env), env}
  # typedef struct {$n" &
  #        "N_NIMCALL_PTR($2, ClP_0) $3;$n" &
  #        "void* ClE_0;$n} $1;$n"
  let mangledBase = mangle(c, t)
  let typeName = "NimClosure" & mangledBase

  let procType = procToIr(c, t, addEnv=true)

  let p = openType(c.g, ObjectDecl)
  c.g.addName typeName
  c.g.addSize c.conf.getSize(t)
  c.g.addAlign c.conf.getAlign(t)

  let f = c.g.openType FieldDecl
  c.g.addType procType
  c.g.addOffset 0
  c.g.addName "ClP_0"
  sealType(c.g, f) # FieldDecl

  let f2 = c.g.openType FieldDecl
  let voidPtr = openType(c.g, APtrTy)
  c.g.addBuiltinType(VoidId)
  sealType(c.g, voidPtr)

  c.g.addOffset c.conf.target.ptrSize
  c.g.addName "ClE_0"
  sealType(c.g, f2) # FieldDecl

  result = finishType(c.g, p) # ObjectDecl

proc bitsetBasetype*(c: var TypesCon; t: PType): TypeId =
  let s = int(getSize(c.conf, t))
  case s
  of 1: result = UInt8Id
  of 2: result = UInt16Id
  of 4: result = UInt32Id
  of 8: result = UInt64Id
  else: result = UInt8Id

proc typeToIr*(c: var TypesCon; t: PType): TypeId =
  if t == nil: return VoidId
  case t.kind
  of tyInt:
    case int(getSize(c.conf, t))
    of 2: result = Int16Id
    of 4: result = Int32Id
    else: result = Int64Id
  of tyInt8: result = Int8Id
  of tyInt16: result = Int16Id
  of tyInt32: result = Int32Id
  of tyInt64: result = Int64Id
  of tyFloat:
    case int(getSize(c.conf, t))
    of 4: result = Float32Id
    else: result = Float64Id
  of tyFloat32: result = Float32Id
  of tyFloat64: result = Float64Id
  of tyFloat128: result = getFloat128Type(c.g)
  of tyUInt:
    case int(getSize(c.conf, t))
    of 2: result = UInt16Id
    of 4: result = UInt32Id
    else: result = UInt64Id
  of tyUInt8: result = UInt8Id
  of tyUInt16: result = UInt16Id
  of tyUInt32: result = UInt32Id
  of tyUInt64: result = UInt64Id
  of tyBool: result = Bool8Id
  of tyChar: result = Char8Id
  of tyVoid: result = VoidId
  of tySink, tyGenericInst, tyDistinct, tyAlias, tyOwned, tyRange:
<<<<<<< HEAD
    result = typeToIr(c, g, t.skipModifier)
=======
    result = typeToIr(c, t.lastSon)
>>>>>>> parent of 0c26d19e2 (NIR: VM + refactorings (#22835))
  of tyEnum:
    if firstOrd(c.conf, t) < 0:
      result = Int32Id
    else:
      case int(getSize(c.conf, t))
      of 1: result = UInt8Id
      of 2: result = UInt16Id
      of 4: result = Int32Id
      of 8: result = Int64Id
      else: result = Int32Id
  of tyOrdinal, tyGenericBody, tyGenericParam, tyInferred, tyStatic:
    if t.len > 0:
<<<<<<< HEAD
      result = typeToIr(c, g, t.skipModifier)
=======
      result = typeToIr(c, t.lastSon)
>>>>>>> parent of 0c26d19e2 (NIR: VM + refactorings (#22835))
    else:
      result = TypeId(-1)
  of tyFromExpr:
    if t.n != nil and t.n.typ != nil:
      result = typeToIr(c, t.n.typ)
    else:
      result = TypeId(-1)
  of tyArray:
    cached(c, t):
      var n = toInt64(lengthOrd(c.conf, t))
      if n <= 0: n = 1   # make an array of at least one element
<<<<<<< HEAD
      let elemType = typeToIr(c, g, t.elementType)
      let a = openType(g, ArrayTy)
      g.addType(elemType)
      g.addArrayLen n
      result = finishType(g, a)
=======
      let elemType = typeToIr(c, t[1])
      let a = openType(c.g, ArrayTy)
      c.g.addType(elemType)
      c.g.addArrayLen n
      result = finishType(c.g, a)
>>>>>>> parent of 0c26d19e2 (NIR: VM + refactorings (#22835))
  of tyPtr, tyRef:
    cached(c, t):
      let e = t.elementType
      if e.kind == tyUncheckedArray:
<<<<<<< HEAD
        let elemType = typeToIr(c, g, e.elementType)
        let a = openType(g, AArrayPtrTy)
        g.addType(elemType)
        result = finishType(g, a)
      else:
        let elemType = typeToIr(c, g, t.elementType)
        let a = openType(g, APtrTy)
        g.addType(elemType)
        result = finishType(g, a)
=======
        let elemType = typeToIr(c, e.lastSon)
        let a = openType(c.g, AArrayPtrTy)
        c.g.addType(elemType)
        result = finishType(c.g, a)
      else:
        let elemType = typeToIr(c, t.lastSon)
        let a = openType(c.g, APtrTy)
        c.g.addType(elemType)
        result = finishType(c.g, a)
>>>>>>> parent of 0c26d19e2 (NIR: VM + refactorings (#22835))
  of tyVar, tyLent:
    cached(c, t):
      let e = t.elementType
      if e.skipTypes(abstractInst).kind in {tyOpenArray, tyVarargs}:
        # skip the modifier, `var openArray` is a (ptr, len) pair too:
        result = typeToIr(c, e)
      else:
        let elemType = typeToIr(c, e)
        let a = openType(c.g, APtrTy)
        c.g.addType(elemType)
        result = finishType(c.g, a)
  of tySet:
    let s = int(getSize(c.conf, t))
    case s
    of 1: result = UInt8Id
    of 2: result = UInt16Id
    of 4: result = UInt32Id
    of 8: result = UInt64Id
    else:
      # array[U8, s]
      cached(c, t):
        let a = openType(c.g, ArrayTy)
        c.g.addType(UInt8Id)
        c.g.addArrayLen s
        result = finishType(c.g, a)
  of tyPointer, tyNil:
    # tyNil can happen for code like: `const CRAP = nil` which we have in posix.nim
    let a = openType(c.g, APtrTy)
    c.g.addBuiltinType(VoidId)
    result = finishType(c.g, a)
  of tyObject:
    # Objects are special as they can be recursive in Nim. This is easily solvable.
    # We check if we are already "processing" t. If so, we produce `ObjectTy`
    # instead of `ObjectDecl`.
    cached(c, t):
      if not c.recursionCheck.containsOrIncl(t.itemId):
        result = objectToIr(c, t)
      else:
        result = objectHeaderToIr(c, t)
  of tyTuple:
    cached(c, t):
      result = tupleToIr(c, t)
  of tyProc:
    cached(c, t):
      if t.callConv == ccClosure:
        result = closureToIr(c, t)
      else:
        result = procToIr(c, t)
  of tyVarargs, tyOpenArray:
    cached(c, t):
      result = openArrayToIr(c, t)
  of tyString:
    cached(c, t):
      result = stringToIr(c)
  of tySequence:
    cached(c, t):
      result = seqToIr(c, t)
  of tyCstring:
    cached(c, t):
      let a = openType(c.g, AArrayPtrTy)
      c.g.addBuiltinType Char8Id
      result = finishType(c.g, a)
  of tyUncheckedArray:
    # We already handled the `ptr UncheckedArray` in a special way.
    cached(c, t):
<<<<<<< HEAD
      let elemType = typeToIr(c, g, t.elementType)
      let a = openType(g, LastArrayTy)
      g.addType(elemType)
      result = finishType(g, a)
=======
      let elemType = typeToIr(c, t.lastSon)
      let a = openType(c.g, LastArrayTy)
      c.g.addType(elemType)
      result = finishType(c.g, a)
>>>>>>> parent of 0c26d19e2 (NIR: VM + refactorings (#22835))
  of tyUntyped, tyTyped:
    # this avoids a special case for system.echo which is not a generic but
    # uses `varargs[typed]`:
    result = VoidId
  of tyNone, tyEmpty, tyTypeDesc,
     tyGenericInvocation, tyProxy, tyBuiltInTypeClass,
     tyUserTypeClass, tyUserTypeClassInst, tyCompositeTypeClass,
     tyAnd, tyOr, tyNot, tyAnything, tyConcept, tyIterable, tyForward:
    result = TypeId(-1)
