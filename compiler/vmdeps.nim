#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import ast, types, msgs, os, osproc, streams, options, idents, securehash

proc readOutput(p: Process): string =
  result = ""
  var output = p.outputStream
  while not output.atEnd:
    result.add(output.readLine)
    result.add("\n")
  if result.len > 0:
    result.setLen(result.len - "\n".len)
  discard p.waitForExit

proc opGorge*(cmd, input, cache: string, info: TLineInfo): string =
  let workingDir = parentDir(info.toFullPath)
  if cache.len > 0:# and optForceFullMake notin gGlobalOptions:
    let h = secureHash(cmd & "\t" & input & "\t" & cache)
    let filename = options.toGeneratedFile("gorge_" & $h, "txt")
    var f: File
    if open(f, filename):
      result = f.readAll
      f.close
      return
    var readSuccessful = false
    try:
      var p = startProcess(cmd, workingDir,
                           options={poEvalCommand, poStderrToStdout})
      if input.len != 0:
        p.inputStream.write(input)
        p.inputStream.close()
      result = p.readOutput
      readSuccessful = true
      writeFile(filename, result)
    except IOError, OSError:
      if not readSuccessful: result = ""
  else:
    try:
      var p = startProcess(cmd, workingDir,
                           options={poEvalCommand, poStderrToStdout})
      if input.len != 0:
        p.inputStream.write(input)
        p.inputStream.close()
      result = p.readOutput
    except IOError, OSError:
      result = ""

proc opSlurp*(file: string, info: TLineInfo, module: PSym): string =
  try:
    var filename = parentDir(info.toFullPath) / file
    if not fileExists(filename):
      filename = file.findFile
    result = readFile(filename)
    # we produce a fake include statement for every slurped filename, so that
    # the module dependencies are accurate:
    appendToModule(module, newNode(nkIncludeStmt, info, @[
      newStrNode(nkStrLit, filename)]))
  except IOError:
    localError(info, errCannotOpenFile, file)
    result = ""

proc atomicTypeX(name: string; m: TMagic; t: PType; info: TLineInfo): PNode =
  let sym = newSym(skType, getIdent(name), t.owner, info)
  sym.magic = m
  sym.typ = t
  result = newSymNode(sym)
  result.typ = t

proc atomicTypeX(s: PSym; info: TLineInfo): PNode =
  result = newSymNode(s)
  result.info = info

proc mapTypeToAstX(t: PType; info: TLineInfo;
                   inst=false; allowRecursionX=false): PNode

proc mapTypeToBracketX(name: string; m: TMagic; t: PType; info: TLineInfo;
                       inst=false): PNode =
  result = newNodeIT(nkBracketExpr, if t.n.isNil: info else: t.n.info, t)
  result.add atomicTypeX(name, m, t, info)
  for i in 0 .. < t.len:
    if t.sons[i] == nil:
      let void = atomicTypeX("void", mVoid, t, info)
      void.typ = newType(tyVoid, t.owner)
      result.add void
    else:
      result.add mapTypeToAstX(t.sons[i], info, inst)

proc objectNode(n: PNode): PNode =
  if n.kind == nkSym:
    result = newNodeI(nkIdentDefs, n.info)
    result.add n  # name
    result.add mapTypeToAstX(n.sym.typ, n.info, true, false)  # type
    result.add ast.emptyNode  # no assigned value
  else:
    result = copyNode(n)
    for i in 0 ..< n.safeLen:
      result.add objectNode(n[i])

proc mapTypeToAstX(t: PType; info: TLineInfo;
                   inst=false; allowRecursionX=false): PNode =
  var allowRecursion = allowRecursionX
  template atomicType(name, m): untyped = atomicTypeX(name, m, t, info)
  template atomicType(s): untyped = atomicTypeX(s, info)
  template mapTypeToAst(t,info): untyped = mapTypeToAstX(t, info, inst)
  template mapTypeToAstR(t,info): untyped = mapTypeToAstX(t, info, inst, true)
  template mapTypeToAst(t,i,info): untyped =
    if i<t.len and t.sons[i]!=nil: mapTypeToAstX(t.sons[i], info, inst)
    else: ast.emptyNode
  template mapTypeToBracket(name, m, t, info): untyped =
    mapTypeToBracketX(name, m, t, info, inst)
  template newNodeX(kind): untyped =
    newNodeIT(kind, if t.n.isNil: info else: t.n.info, t)
  template newIdentDefs(n,t): untyped =
    var id = newNodeX(nkIdentDefs)
    id.add n  # name
    id.add mapTypeToAst(t, info)  # type
    id.add ast.emptyNode  # no assigned value
    id
  template newIdentDefs(s): untyped = newIdentDefs(s, s.typ)

  if inst:
    if t.sym != nil:  # if this node has a symbol
      if allowRecursion:  # getTypeImpl behavior: turn off recursion
        allowRecursion = false
      else:  # getTypeInst behavior: return symbol
        return atomicType(t.sym)

  case t.kind
  of tyNone: result = atomicType("none", mNone)
  of tyBool: result = atomicType("bool", mBool)
  of tyChar: result = atomicType("char", mChar)
  of tyNil: result = atomicType("nil", mNil)
  of tyExpr: result = atomicType("expr", mExpr)
  of tyStmt: result = atomicType("stmt", mStmt)
  of tyVoid: result = atomicType("void", mVoid)
  of tyEmpty: result = atomicType("empty", mNone)
  of tyArray:
    result = newNodeIT(nkBracketExpr, if t.n.isNil: info else: t.n.info, t)
    result.add atomicType("array", mArray)
    if inst and t.sons[0].kind == tyRange:
      var rng = newNodeX(nkInfix)
      rng.add newIdentNode(getIdent(".."), info)
      rng.add t.sons[0].n.sons[0].copyTree
      rng.add t.sons[0].n.sons[1].copyTree
      result.add rng
    else:
      result.add mapTypeToAst(t.sons[0], info)
    result.add mapTypeToAst(t.sons[1], info)
  of tyTypeDesc:
    if t.base != nil:
      result = newNodeIT(nkBracketExpr, if t.n.isNil: info else: t.n.info, t)
      result.add atomicType("typeDesc", mTypeDesc)
      result.add mapTypeToAst(t.base, info)
    else:
      result = atomicType("typeDesc", mTypeDesc)
  of tyGenericInvocation:
    result = newNodeIT(nkBracketExpr, if t.n.isNil: info else: t.n.info, t)
    for i in 0 .. < t.len:
      result.add mapTypeToAst(t.sons[i], info)
  of tyGenericInst, tyAlias:
    if inst:
      if allowRecursion:
        result = mapTypeToAstR(t.lastSon, info)
      else:
        result = newNodeX(nkBracketExpr)
        result.add mapTypeToAst(t.lastSon, info)
        for i in 1 .. < t.len-1:
          result.add mapTypeToAst(t.sons[i], info)
    else:
      result = mapTypeToAstX(t.lastSon, info, inst, allowRecursion)
  of tyGenericBody, tyOrdinal, tyUserTypeClassInst:
    result = mapTypeToAst(t.lastSon, info)
  of tyDistinct:
    if inst:
      result = newNodeX(nkDistinctTy)
      result.add mapTypeToAst(t.sons[0], info)
    else:
      if allowRecursion or t.sym == nil:
        result = mapTypeToBracket("distinct", mDistinct, t, info)
      else:
        result = atomicType(t.sym)
  of tyGenericParam, tyForward:
    result = atomicType(t.sym)
  of tyObject:
    if inst:
      result = newNodeX(nkObjectTy)
      result.add ast.emptyNode  # pragmas not reconstructed yet
      if t.sons[0] == nil: result.add ast.emptyNode  # handle parent object
      else:
        var nn = newNodeX(nkOfInherit)
        nn.add mapTypeToAst(t.sons[0], info)
        result.add nn
      if t.n.len > 0:
        result.add objectNode(t.n)
      else:
        result.add ast.emptyNode
    else:
      if allowRecursion or t.sym == nil:
        result = newNodeIT(nkObjectTy, if t.n.isNil: info else: t.n.info, t)
        result.add ast.emptyNode
        if t.sons[0] == nil:
          result.add ast.emptyNode
        else:
          result.add mapTypeToAst(t.sons[0], info)
        result.add copyTree(t.n)
      else:
        result = atomicType(t.sym)
  of tyEnum:
    result = newNodeIT(nkEnumTy, if t.n.isNil: info else: t.n.info, t)
    result.add copyTree(t.n)
  of tyTuple:
    if inst:
      result = newNodeX(nkTupleTy)
      for s in t.n.sons:
        result.add newIdentDefs(s)
    else:
      result = mapTypeToBracket("tuple", mTuple, t, info)
  of tySet: result = mapTypeToBracket("set", mSet, t, info)
  of tyPtr:
    if inst:
      result = newNodeX(nkPtrTy)
      result.add mapTypeToAst(t.sons[0], info)
    else:
      result = mapTypeToBracket("ptr", mPtr, t, info)
  of tyRef:
    if inst:
      result = newNodeX(nkRefTy)
      result.add mapTypeToAst(t.sons[0], info)
    else:
      result = mapTypeToBracket("ref", mRef, t, info)
  of tyVar: result = mapTypeToBracket("var", mVar, t, info)
  of tySequence: result = mapTypeToBracket("seq", mSeq, t, info)
  of tyProc:
    if inst:
      result = newNodeX(nkProcTy)
      var fp = newNodeX(nkFormalParams)
      if t.sons[0] == nil:
        fp.add ast.emptyNode
      else:
        fp.add mapTypeToAst(t.sons[0], t.n[0].info)
      for i in 1..<t.sons.len:
        fp.add newIdentDefs(t.n[i], t.sons[i])
      result.add fp
      result.add ast.emptyNode  # pragmas aren't reconstructed yet
    else:
      result = mapTypeToBracket("proc", mNone, t, info)
  of tyOpenArray: result = mapTypeToBracket("openArray", mOpenArray, t, info)
  of tyRange:
    result = newNodeIT(nkBracketExpr, if t.n.isNil: info else: t.n.info, t)
    result.add atomicType("range", mRange)
    result.add t.n.sons[0].copyTree
    result.add t.n.sons[1].copyTree
  of tyPointer: result = atomicType("pointer", mPointer)
  of tyString: result = atomicType("string", mString)
  of tyCString: result = atomicType("cstring", mCString)
  of tyInt: result = atomicType("int", mInt)
  of tyInt8: result = atomicType("int8", mInt8)
  of tyInt16: result = atomicType("int16", mInt16)
  of tyInt32: result = atomicType("int32", mInt32)
  of tyInt64: result = atomicType("int64", mInt64)
  of tyFloat: result = atomicType("float", mFloat)
  of tyFloat32: result = atomicType("float32", mFloat32)
  of tyFloat64: result = atomicType("float64", mFloat64)
  of tyFloat128: result = atomicType("float128", mFloat128)
  of tyUInt: result = atomicType("uint", mUint)
  of tyUInt8: result = atomicType("uint8", mUint8)
  of tyUInt16: result = atomicType("uint16", mUint16)
  of tyUInt32: result = atomicType("uint32", mUint32)
  of tyUInt64: result = atomicType("uint64", mUint64)
  of tyVarargs: result = mapTypeToBracket("varargs", mVarargs, t, info)
  of tyProxy: result = atomicType("error", mNone)
  of tyBuiltInTypeClass:
    result = mapTypeToBracket("builtinTypeClass", mNone, t, info)
  of tyUserTypeClass:
    result = mapTypeToBracket("concept", mNone, t, info)
    result.add t.n.copyTree
  of tyCompositeTypeClass:
    result = mapTypeToBracket("compositeTypeClass", mNone, t, info)
  of tyAnd: result = mapTypeToBracket("and", mAnd, t, info)
  of tyOr: result = mapTypeToBracket("or", mOr, t, info)
  of tyNot: result = mapTypeToBracket("not", mNot, t, info)
  of tyAnything: result = atomicType("anything", mNone)
  of tyStatic, tyFromExpr, tyFieldAccessor:
    if inst:
      if t.n != nil: result = t.n.copyTree
      else: result = atomicType("void", mVoid)
    else:
      result = newNodeIT(nkBracketExpr, if t.n.isNil: info else: t.n.info, t)
      result.add atomicType("static", mNone)
      if t.n != nil:
        result.add t.n.copyTree
  of tyUnused, tyUnused0, tyUnused1, tyUnused2: internalError("mapTypeToAstX")

proc opMapTypeToAst*(t: PType; info: TLineInfo): PNode =
  result = mapTypeToAstX(t, info, false, true)

# the "Inst" version includes generic parameters in the resulting type tree
# and also tries to look like the corresponding Nim type declaration
proc opMapTypeInstToAst*(t: PType; info: TLineInfo): PNode =
  result = mapTypeToAstX(t, info, true, false)

# the "Impl" version includes generic parameters in the resulting type tree
# and also tries to look like the corresponding Nim type implementation
proc opMapTypeImplToAst*(t: PType; info: TLineInfo): PNode =
  result = mapTypeToAstX(t, info, true, true)
