#
#
#           The Nimrod Compiler
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Converts Nimrod types to LLVM types.

import llvm

proc intFromSize(size: int): TypeRef =
  case size
  of 8: result = llvm.Int64Type()
  of 4: result = llvm.Int32Type()
  of 2: result = llvm.Int16Type()
  of 1: result = llvm.Int8Type()
  else: InternalError("unknown type size")

type
  TPending = TTypeHandleMap

proc convertProcType(m: BModule, t: PType, pending: var TPending): TypeRef =
  
  
proc simpleType(m: BModule, t: PType): TypeRef =
  case t.kind
  of tyBool, tyChar, tyInt8: result = llvm.Int8Type()
  of tyEnum:
    if firstOrd(t) < 0: 
      result = llvm.Int32Type()
    else: 
      case int(getSize(t))
      of 1: result = llvm.Int8Type()
      of 2: result = llvm.Int16Type()
      of 4: result = llvm.Int32Type()
      of 8: result = llvm.Int64Type()
      else: internalError(t.sym.info, "convertTypeAux")
  of tyInt: result = intFromSize(getSize(t))
  of tyInt16: result = llvm.Int16Type()
  of tyInt32: result = llvm.Int32Type()
  of tyInt64: result = llvm.Int64Type()
  of tyFloat, tyFloat64: result = llvm.DoubleType()
  of tyFloat32: result = llvm.FloatType()
  of tyCString, tyPointer, tyNil: result = llvm.PointerType(llvm.Int8Type())
  else: result = nil
  
proc convertTypeAux(m: BModule, t: PType, pending: var TPending): TypeRef =
  case t.kind
  of tyDistinct, tyRange:
    result = convertTypeAux(m, t.sons[0], pending)
  of tyArray: 
    result = m.typeCache[t]
    if result == nil:
      var handle = pending[t]
      if handle == nil:
        handle = llvm.CreateTypeHandle(llvm.OpaqueType())
        pending[t] = handle
        result = llvm.ArrayType(ResolveTypeHandle(handle), int32(lengthOrd(t)))
        var elemConcrete = convertTypeAux(m, elemType(t), pending)
        # this may destroy the types!
        refineType(ResolveTypeHandle(handle), elemConcrete)
        
        # elemConcrete is potentially invalidated, but handle
        # (a PATypeHolder) is kept up-to-date
        elemConcrete = ResolveTypeHandle(handle)

        
      else:
        # we are pending!
        result = ResolveTypeHandle(handle)
      # now we have the correct type:
      m.typeCache[t] = result
  of tyOpenArray:
  
  of tySeq:
  
  of tyObject: 
  of tyTuple: 
    
  of tyProc:
  else: result = simpleType(m, t)

proc CreateTypeHandle*(PotentiallyAbstractTy: TypeRef): TypeHandleRef{.cdecl, 
    dynlib: libname, importc: "LLVMCreateTypeHandle".}
proc RefineType*(AbstractTy: TypeRef, ConcreteTy: TypeRef){.cdecl, 
    dynlib: libname, importc: "LLVMRefineType".}
proc ResolveTypeHandle*(TypeHandle: TypeHandleRef): TypeRef{.cdecl, 
    dynlib: libname, importc: "LLVMResolveTypeHandle".}
proc DisposeTypeHandle*(TypeHandle: TypeHandleRef){.cdecl, dynlib: libname, 
    importc: "LLVMDisposeTypeHandle".}    


proc `!`*(m: BModule, t: PType): TypeRef =
  ## converts a Nimrod type to an LLVM type. Since this is so common, we use
  ## an infix operator for this.
  result = simpleType(m, t)
  if result == nil:
    var cl: TTypeMap
    init(cl)
    result = convertTypeAux(m, t, cl)

proc FunctionType*(ReturnType: TypeRef, ParamTypes: ptr TypeRef,
                   ParamCount: int32, IsVarArg: int32): TypeRef {.
    cdecl, dynlib: libname, importc: "LLVMFunctionType".}
    

proc VoidType*(): TypeRef{.cdecl, dynlib: libname, importc: "LLVMVoidType".}
proc LabelType*(): TypeRef{.cdecl, dynlib: libname, importc: "LLVMLabelType".}
proc OpaqueType*(): TypeRef{.cdecl, dynlib: libname, importc: "LLVMOpaqueType".}
  # Operations on type handles  
proc CreateTypeHandle*(PotentiallyAbstractTy: TypeRef): TypeHandleRef{.cdecl, 
    dynlib: libname, importc: "LLVMCreateTypeHandle".}
proc RefineType*(AbstractTy: TypeRef, ConcreteTy: TypeRef){.cdecl, 
    dynlib: libname, importc: "LLVMRefineType".}
proc ResolveTypeHandle*(TypeHandle: TypeHandleRef): TypeRef{.cdecl, 
    dynlib: libname, importc: "LLVMResolveTypeHandle".}
proc DisposeTypeHandle*(TypeHandle: TypeHandleRef){.cdecl, dynlib: libname, 
    importc: "LLVMDisposeTypeHandle".}

    
#  m!typ, m!a[i]

