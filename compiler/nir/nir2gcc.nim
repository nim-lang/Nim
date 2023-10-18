#
#
#           The Nim Compiler
#        (c) Copyright 2023 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import ".." / ic / [bitabs, rodfiles]
import nirinsts, nirtypes, nirlineinfos, libgccjit

type
  GenContext = object
    jit: GContext
    filename: string
    jittypes: Table[TypeId, ptr GType]
    namesToTypes: Table[string, ptr GType]
    lit: Literals
    types: TypeGraph

proc createContext(filename: sink string; lit: sink Literals; types: sink TypeGraph): GenContext =
  let jit = contextAcquire()
  if jit == nil: raise newException(ValueError, "could not create GCC context")
  contextSetBoolAllowUnreachableBlocks jit, 1
  GenContext(jit: jit, filename: filename, lit: lit, types: types)

proc destroyContext(c: var GenContext) =
  contextCompileToFile c.jit, OUTPUT_KIND_OBJECT_FILE, c.filename.changeFileExt(".o")
  contextRelease c.jit

template toUncheckedArray[T](s: seq[T]): ptr UncheckedArray[T] =
  cast[ptr UncheckedArray[T]](addr s[0])

proc genType(c: var GenContext; t: TypeId): ptr GType

proc mapObjectType(c: var GenContext; t: PTypeId): ptr GType =
  # NameVal:
  #  IntVal, SizeVal, AlignVal, OffsetVal,
  #  AnnotationVal,
  #  VarargsTy, # the `...` in a C prototype; also the last "atom"
  #  FieldDecl
  for x in sons(c.types, t):
    case c.types[x].kind
    of FieldDecl:


proc genTypeRaw(c: var GenContext; t: TypeId): ptr GType =
  case c.types[t].kind
  of VoidTy:
    result = contextGetType(c.jit, TYPE_VOID)
  of IntTy:
    case c.types[t].integralBits
    of 8: result = contextGetType(c.jit, TYPE_INT8_T)
    of 16: result = contextGetType(c.jit, TYPE_INT16_T)
    of 32: result = contextGetType(c.jit, TYPE_INT32_T)
    of 64: result = contextGetType(c.jit, TYPE_INT64_T)
    else: raiseAssert "unreachable"
  of UIntTy, BoolTy, CharTy:
    case c.types[t].integralBits
    of 8: result = contextGetType(c.jit, TYPE_UINT8_T)
    of 16: result = contextGetType(c.jit, TYPE_UINT16_T)
    of 32: result = contextGetType(c.jit, TYPE_UINT32_T)
    of 64: result = contextGetType(c.jit, TYPE_UINT64_T)
    else: raiseAssert "unreachable"
  of FloatTy:
    case c.types[t].integralBits
    of 32: result = contextGetType(c.jit, TYPE_FLOAT)
    of 64: result = contextGetType(c.jit, TYPE_DOUBLE)
    of 128: result = contextGetType(c.jit, TYPE_LONG_DOUBLE)
    else: raiseAssert "unreachable"
  of APtrTy, UPtrTy, AArrayPtrTy, UArrayPtrTy:
    result = typeGetPointer(c.jit, genType(c, elementType(c.types, t)))
  of ArrayTy:
    let e = genType(c, elementType(c.types, t))
    let n = arrayLen(c.types, t)
    result = contextNewArrayType(c.jit, nil, e, cint(n))
  of LastArrayTy:
    let e = genType(c, elementType(c.types, t))
    result = contextNewArrayType(c.jit, nil, e, cint(0))
  of ProcTy:
    var i = 0
    var isVariadic = false
    var params: seq[ptr GType] = @[]
    var retType: ptr GType = nil
    for e in sons(c.types, t):
      if c.types[e].kind == VarargsTy:
        isVariadic = true
      elif i == 0:
        retType = genType(c, e)
      else:
        params.add genType(c, e)
      inc i
    result = contextNewFunctionPtrType(c.jit, nil, retType, cint(params.len),
                                      toUncheckedArray(params), cint(isVariadic))

  of ObjectTy, UnionTy:
    let tag = getTypeTag(c.types, t)
    result = namesToTypes.getOrDefault(tag)
    assert result != nil, "could not struct/union of name: " & tag
  of ObjectDecl:
    assert g[t.firstSon].kind == NameVal
    let name = g.lit.strings[LitId g[t.firstSon].operand]
    result = namesToTypes.getOrDefault(name)
    if result == nil:
      result = mapObjectType(g, t)
      namesToTypes[name] = result
  #of UnionDecl:
  #  result = contextNewUnionType(c.jit, )
  else: raiseAssert "unreachable"
  # NameVal:
  #  IntVal, SizeVal, AlignVal, OffsetVal,
  #  AnnotationVal,
  #  VarargsTy, # the `...` in a C prototype; also the last "atom"
  #  FieldDecl

proc genType(c: var GenContext; t: TypeId): ptr GType =
  result = c.jittypes.getOrDefault(t)
  if result == nil:
    result = genTypeRaw(c, t)
    c.jittypes[t] = result

proc gcc*(m: sink NirModule; filename: sink string) =
  var c = createContext(filename, move m.lit, move m.types)
  #genTypes(c, m.types)
  #genGlobals(c, m.tree)
  #genProcs(c, m.tree)
  #genInitStmts(c, m.tree)
  destroyContext c
