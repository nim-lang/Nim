#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This file implements the FFI part of the evaluator for Nimrod code.

import ast, astalgo, ropes, types, options, tables, dynlib, libffi, msgs

when defined(windows):
  const libcDll = "msvcrt.dll"
else:
  const libcDll = "libc.so(.6|.5|)"

type
  TDllCache* = tables.TTable[string, TLibHandle]
var
  gDllCache = initTable[string, TLibHandle]()

proc getDll(cache: var TDllCache; dll: string): pointer =
  result = cache[dll]
  if result.isNil:
    var libs: seq[string] = @[]
    libCandidates(dll, libs)
    for c in libs:
      result = LoadLib(c)
      if not result.isNil: break
    if result.isNil:
      InternalError("cannot load: " & dll)
    cache[dll] = result

proc importcSymbol*(sym: PSym): PNode =
  let lib = sym.annex
  if lib != nil and lib.path.kind notin {nkStrLit..nkTripleStrLit}:
    InternalError("dynlib needs to be a string literal for the REPL")
  
  let dllpath = if lib.isNil: libcDll else: lib.path.strVal
  let dllhandle = gDllCache.getDll(dllpath)
  let name = ropeToStr(sym.loc.r)
  let theAddr = dllhandle.checkedSymAddr(name)
  
  # the AST does not support untyped pointers directly, so we use an nkIntLit
  # that contains the address instead:
  result = newNodeIT(nkIntLit, sym.info, sym.typ)
  result.intVal = cast[TAddress](theAddr)

proc mapType(t: ast.PType): ptr libffi.TType =
  if t == nil: return addr libffi.type_void
  
  case t.kind
  of tyBool, tyEnum, tyChar, tyInt..tyInt64, tyUInt..tyUInt64, tySet:
    case t.getSize
    of 1: result = addr libffi.type_uint8
    of 2: result = addr libffi.type_sint16
    of 4: result = addr libffi.type_sint32
    of 8: result = addr libffi.type_sint64
    else:
      InternalError("cannot map type to FFI")
  of tyFloat, tyFloat64: result = addr libffi.type_double
  of tyFloat32: result = addr libffi.type_float
  of tyVar, tyPointer, tyPtr, tyRef, tyCString, tySequence, tyString, tyExpr,
     tyStmt, tyTypeDesc, tyProc, tyArray, tyArrayConstr:
    result = addr libffi.type_pointer
  else:
    InternalError("cannot map type to FFI")
  # too risky:
  #of tyFloat128: result = addr libffi.type_longdouble

proc mapCallConv(cc: TCallingConvention): TABI =
  case cc
  of ccDefault: result = DEFAULT_ABI
  of ccStdCall: result = when defined(windows): STDCALL else: DEFAULT_ABI
  of ccCDecl: result = DEFAULT_ABI
  else: InternalError("cannot map calling convention to FFI")

template rd(T, p: expr): expr {.immediate.} = (cast[ptr T](p))[]
template wr(T, p, v: expr) {.immediate.} = (cast[ptr T](p))[] = v

proc pack(v: PNode): pointer =
  template awr(T, v: expr) {.immediate, dirty.} =
    result = alloc0(sizeof(T))
    wr(T, result, v)

  case v.typ.kind
  of tyBool: awr(bool, v.intVal != 0)
  of tyChar: awr(char, v.intVal.chr)
  of tyInt:  awr(int, v.intVal.int)
  of tyInt8: awr(int8, v.intVal.int8)
  of tyInt16: awr(int16, v.intVal.int16)
  of tyInt32: awr(int32, v.intVal.int32)
  of tyInt64: awr(int64, v.intVal.int64)
  of tyUInt: awr(uint, v.intVal.uint)
  of tyUInt8: awr(uint8, v.intVal.uint8)
  of tyUInt16: awr(uint16, v.intVal.uint16)
  of tyUInt32: awr(uint32, v.intVal.uint32)
  of tyUInt64: awr(uint64, v.intVal.uint64)
  of tyEnum, tySet:
    case v.typ.getSize
    of 1: awr(uint8, v.intVal.uint8)
    of 2: awr(uint16, v.intVal.uint16)
    of 4: awr(int32, v.intVal.int32)
    of 8: awr(int64, v.intVal.int64)
    else:
      InternalError("cannot map value to FFI (tyEnum, tySet)")
  of tyFloat: awr(float, v.floatVal)
  of tyFloat32: awr(float32, v.floatVal)
  of tyFloat64: awr(float64, v.floatVal)
  
  of tyPointer, tyProc, tyPtr, tyRef:
    if v.kind == nkNilLit:
      result = alloc0(sizeof(pointer))
    else:
      awr(pointer, cast[pointer](v.intVal))
  of tyCString, tyString:
    if v.kind == nkNilLit:
      result = alloc0(sizeof(pointer))
    else:
      awr(cstring, cstring(v.strVal))
  else:
    InternalError("cannot map value to FFI " & typeToString(v.typ))

proc unpack(x: pointer, typ: PType, info: TLineInfo): PNode =
  template aw(kind, v, field: expr) {.immediate, dirty.} =
    result = newNodeIT(kind, info, typ)
    result.field = v

  template awi(kind, v: expr) {.immediate, dirty.} = aw(kind, v, intVal)
  template awf(kind, v: expr) {.immediate, dirty.} = aw(kind, v, floatVal)
  template aws(kind, v: expr) {.immediate, dirty.} = aw(kind, v, strVal)
  
  case typ.kind
  of tyBool: awi(nkIntLit, rd(bool, x).ord)
  of tyChar: awi(nkIntLit, rd(char, x).ord)
  of tyInt:  awi(nkIntLit, rd(int, x))
  of tyInt8: awi(nkIntLit, rd(int8, x))
  of tyInt16: awi(nkIntLit, rd(int16, x))
  of tyInt32: awi(nkIntLit, rd(int32, x))
  of tyInt64: awi(nkIntLit, rd(int64, x))
  of tyUInt: awi(nkIntLit, rd(uint, x).biggestInt)
  of tyUInt8: awi(nkIntLit, rd(uint8, x).biggestInt)
  of tyUInt16: awi(nkIntLit, rd(uint16, x).biggestInt)
  of tyUInt32: awi(nkIntLit, rd(uint32, x).biggestInt)
  of tyUInt64: awi(nkIntLit, rd(uint64, x).biggestInt)
  of tyEnum:
    case typ.getSize
    of 1: awi(nkIntLit, rd(uint8, x).biggestInt)
    of 2: awi(nkIntLit, rd(uint16, x).biggestInt)
    of 4: awi(nkIntLit, rd(int32, x).biggestInt)
    of 8: awi(nkIntLit, rd(int64, x).biggestInt)
    else:
      InternalError("cannot map value from FFI (tyEnum, tySet)")
  of tyFloat: awf(nkFloatLit, rd(float, x))
  of tyFloat32: awf(nkFloatLit, rd(float32, x))
  of tyFloat64: awf(nkFloatLit, rd(float64, x))
  of tyPointer, tyProc, tyPtr:
    let p = rd(pointer, x)
    if p.isNil:
      result = newNodeIT(nkNilLit, info, typ)
    else:
      awi(nkIntLit, cast[TAddress](p))
  of tyCString, tyString:
    let p = rd(cstring, x)
    if p.isNil:
      result = newNodeIT(nkNilLit, info, typ)
    else:
      aws(nkStrLit, $p)
  else:
    InternalError("cannot map value from FFI " & typeToString(typ))

proc callForeignFunction*(call: PNode): PNode =
  InternalAssert call.sons[0].kind == nkIntLit
  let typ = call.sons[0].typ
  
  var cif: TCif
  var sig: TParamList
  for i in 1..typ.len-1: sig[i-1] = mapType(typ.sons[i])
  
  if prep_cif(cif, mapCallConv(typ.callConv), cuint(typ.len-1), 
              mapType(typ.sons[0]), sig) != OK:
    InternalError(call.info, "error in FFI call")
  
  var args: TArgList
  let fn = cast[pointer](call.sons[0].intVal)
  for i in 0 .. call.len-1:
    args[i] = pack(call.sons[i+1])
  let retVal = alloc(typ.sons[0].getSize.int)

  libffi.call(cif, fn, retVal, args)
  
  if isEmptyType(typ.sons[0]): result = emptyNode
  else: result = unpack(retVal, typ.sons[0], call.info)

  dealloc retVal
  for i in countdown(call.len-1, 0): dealloc args[i]
