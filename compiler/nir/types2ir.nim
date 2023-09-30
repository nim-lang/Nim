#
#
#           The Nim Compiler
#        (c) Copyright 2023 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import std / [assertions, tables]
import ".." / [ast, types, options]
import nirtypes

type
  Context = object
    processed: Table[ItemId, TypeId]
    g: TypeGraph
    conf: ConfigRef

proc mangle(t: PType): string =
  # XXX Improve!
  result = $t

template cached(c: var Context; t: PType; body: untyped) =
  result = c.processed.getOrDefault(t.itemId)
  if result.int == 0:
    body
    c.processed[t.itemId] = result

proc typeToIr*(c: var Context; t: PType): TypeId

proc collectFieldTypes(c: var Context; n: PNode; dest: var seq[TypeId]) =
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
    assert n.sym.position == dest.len
    dest.add typeToIr(c, n.sym.typ)
  else:
    assert false, "unknown node kind: " & $n.kind

proc objectToIr(c: var Context; n: PNode; fieldTypes: seq[TypeId]; unionId: var int) =
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
        discard sealType(c.g, subObj)
      else: discard
    discard sealType(c.g, u)
  of nkSym:
    c.g.addField n.sym.name.s & "_" & $n.sym.position, fieldTypes[n.sym.position]
  else:
    assert false, "unknown node kind: " & $n.kind

proc objectToIr(c: var Context; t: PType): TypeId =
  var unionId = 0
  var fieldTypes: seq[TypeId] = @[]
  collectFieldTypes c, t.n, fieldTypes
  let obj = openType(c.g, ObjectDecl)
  # XXX Inheritance?!
  c.g.addName mangle t
  objectToIr c, t.n, fieldTypes, unionId
  result = sealType(c.g, obj)

proc tupleToIr(c: var Context; t: PType): TypeId =
  var fieldTypes = newSeq[TypeId](t.len)
  for i in 0..<t.len:
    fieldTypes[i] = typeToIr(c, t[i])
  let obj = openType(c.g, ObjectDecl)
  c.g.addName mangle t
  for i in 0..<t.len:
    c.g.addField "f_" & $i, fieldTypes[i]
  result = sealType(c.g, obj)

proc procToIr(c: var Context; t: PType; addEnv = false): TypeId =
  var fieldTypes = newSeq[TypeId](t.len)
  for i in 0..<t.len:
    fieldTypes[i] = typeToIr(c, t[i])
  let obj = openType(c.g, ProcTy)
  # XXX Add Calling convention here!
  for i in 0..<t.len:
    c.g.addType fieldTypes[i]

  if addEnv:
    let a = openType(c.g, APtrTy)
    c.g.addBuiltinType(VoidId)
    discard sealType(c.g, a)

  if tfVarargs in t.flags:
    c.g.addVarargs()
  result = sealType(c.g, obj)

proc nativeInt(c: Context): TypeId =
  case c.conf.target.intSize
  of 2: result = Int16Id
  of 4: result = Int32Id
  else: result = Int64Id

proc openArrayToIr(c: var Context; t: PType): TypeId =
  # object (a: ArrayPtr[T], len: int)
  let e = lastSon(t)
  let mangledBase = mangle(e)
  let typeName = "NimOpenArray" & mangledBase

  let elementType = typeToIr(c, e)

  let p = openType(c.g, ObjectDecl)
  c.g.addName typeName

  let f = c.g.openType FieldDecl
  let arr = c.g.openType AArrayPtrTy
  c.g.addType elementType
  discard sealType(c.g, arr) # LastArrayTy
  c.g.addName "data"
  discard sealType(c.g, f) # FieldDecl

  c.g.addField "len", c.nativeInt

  result = sealType(c.g, p) # ObjectDecl


proc stringToIr(c: var Context; t: PType): TypeId =
  #[

    NimStrPayload = object
      cap: int
      data: UncheckedArray[char]

    NimStringV2 = object
      len: int
      p: ptr NimStrPayload

  ]#
  let p = openType(c.g, ObjectDecl)
  c.g.addName "NimStrPayload"
  c.g.addField "cap", c.nativeInt

  let f = c.g.openType FieldDecl
  let arr = c.g.openType LastArrayTy
  c.g.addBuiltinType Char8Id
  discard sealType(c.g, arr) # LastArrayTy
  c.g.addName "data"
  discard sealType(c.g, f) # FieldDecl

  let payload = sealType(c.g, p)

  let str = openType(c.g, ObjectDecl)
  c.g.addName "NimStringV2"
  c.g.addField "len", c.nativeInt

  let fp = c.g.openType FieldDecl
  let ffp = c.g.openType APtrTy
  c.g.addNominalType ObjectTy, "NimStrPayload"
  discard sealType(c.g, ffp) # APtrTy
  c.g.addName "p"
  discard sealType(c.g, fp) # FieldDecl

  result = sealType(c.g, str) # ObjectDecl

proc seqToIr(c: var Context; t: PType): TypeId =
  #[
    NimSeqPayload[T] = object
      cap: int
      data: UncheckedArray[T]

    NimSeqV2*[T] = object
      len: int
      p: ptr NimSeqPayload[T]

  ]#
  let e = lastSon(t)
  let mangledBase = mangle(e)
  let payloadName = "NimSeqPayload" & mangledBase

  let elementType = typeToIr(c, e)

  let p = openType(c.g, ObjectDecl)
  c.g.addName payloadName
  c.g.addField "cap", c.nativeInt

  let f = c.g.openType FieldDecl
  let arr = c.g.openType LastArrayTy
  c.g.addType elementType
  discard sealType(c.g, arr) # LastArrayTy
  c.g.addName "data"
  discard sealType(c.g, f) # FieldDecl

  let payload = sealType(c.g, p)

  let sq = openType(c.g, ObjectDecl)
  c.g.addName "NimSeqV2" & mangledBase
  c.g.addField "len", c.nativeInt

  let fp = c.g.openType FieldDecl
  let ffp = c.g.openType APtrTy
  c.g.addNominalType ObjectTy, "NimSeqPayload" & mangledBase
  discard sealType(c.g, ffp) # APtrTy
  c.g.addName "p"
  discard sealType(c.g, fp) # FieldDecl

  result = sealType(c.g, sq) # ObjectDecl


proc closureToIr(c: var Context; t: PType): TypeId =
  # struct {fn(args, void* env), env}
  # typedef struct {$n" &
  #        "N_NIMCALL_PTR($2, ClP_0) $3;$n" &
  #        "void* ClE_0;$n} $1;$n"
  let mangledBase = mangle(t)
  let typeName = "NimClosure" & mangledBase

  let procType = procToIr(c, t, addEnv=true)

  let p = openType(c.g, ObjectDecl)
  c.g.addName typeName

  let f = c.g.openType FieldDecl
  c.g.addType procType
  c.g.addName "ClP_0"
  discard sealType(c.g, f) # FieldDecl

  let f2 = c.g.openType FieldDecl
  let voidPtr = openType(c.g, APtrTy)
  c.g.addBuiltinType(VoidId)
  discard sealType(c.g, voidPtr)

  c.g.addName "ClE_0"
  discard sealType(c.g, f2) # FieldDecl

  result = sealType(c.g, p) # ObjectDecl

proc typeToIr*(c: var Context; t: PType): TypeId =
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
    result = typeToIr(c, t.lastSon)
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
      result = typeToIr(c, t.lastSon)
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
      let elemType = typeToIr(c, t[1])
      let a = openType(c.g, ArrayTy)
      c.g.addType(elemType)
      c.g.addArrayLen uint64(n)
      result = sealType(c.g, a)
  of tyPtr, tyRef:
    cached(c, t):
      let e = t.lastSon
      if e.kind == tyUncheckedArray:
        let elemType = typeToIr(c, e.lastSon)
        let a = openType(c.g, AArrayPtrTy)
        c.g.addType(elemType)
        result = sealType(c.g, a)
      else:
        let elemType = typeToIr(c, t.lastSon)
        let a = openType(c.g, APtrTy)
        c.g.addType(elemType)
        result = sealType(c.g, a)
  of tyVar, tyLent:
    cached(c, t):
      let elemType = typeToIr(c, t.lastSon)
      let a = openType(c.g, APtrTy)
      c.g.addType(elemType)
      result = sealType(c.g, a)
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
        c.g.addArrayLen uint64(s)
        result = sealType(c.g, a)
  of tyPointer:
    let a = openType(c.g, APtrTy)
    c.g.addBuiltinType(VoidId)
    result = sealType(c.g, a)
  of tyObject:
    cached(c, t):
      result = objectToIr(c, t)
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
      result = stringToIr(c, t)
  of tySequence:
    cached(c, t):
      result = seqToIr(c, t)
  of tyCstring:
    cached(c, t):
      let a = openType(c.g, AArrayPtrTy)
      c.g.addBuiltinType Char8Id
      result = sealType(c.g, a)
  of tyUncheckedArray:
    # We already handled the `ptr UncheckedArray` in a special way.
    cached(c, t):
      let elemType = typeToIr(c, t.lastSon)
      let a = openType(c.g, LastArrayTy)
      c.g.addType(elemType)
      result = sealType(c.g, a)
  of tyNone, tyEmpty, tyUntyped, tyTyped, tyTypeDesc,
     tyNil, tyGenericInvocation, tyProxy, tyBuiltInTypeClass,
     tyUserTypeClass, tyUserTypeClassInst, tyCompositeTypeClass,
     tyAnd, tyOr, tyNot, tyAnything, tyConcept, tyIterable, tyForward:
    result = TypeId(-1)
