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

proc opGorge*(cmd, input, cache: string): string =
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
      var p = startProcess(cmd, options={poEvalCommand, poStderrToStdout})
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
      var p = startProcess(cmd, options={poEvalCommand, poStderrToStdout})
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

proc mapTypeToAstX(t: PType; info: TLineInfo;
                   inst=false; allowRecursionX=false): PNode

proc mapTypeToBracketX(name: string; m: TMagic; t: PType; info: TLineInfo;
                       inst=false): PNode =
  result = newNodeIT(nkBracketExpr, if t.n.isNil: info else: t.n.info, t)
  result.add(atomicTypeX(name, m, t, info))
  for i in 0 .. < t.len:
    if t.sons[i] == nil:
      let void = atomicTypeX("void", mVoid, t, info)
      void.typ = newType(tyVoid, t.owner)
      result.add(void)
    else:
      result.add(mapTypeToAstX(t.sons[i], info, inst))

proc objectNode(n: PNode): PNode =
  if n.kind == nkSym:
    result = newNodeI(nkIdentDefs, n.info, 3)
    result.sons[0] = n  # name
    result.sons[1] = mapTypeToAstX(n.sym.typ, n.info, true, false)  # type
    result.sons[2] = ast.emptyNode  # no assigned value
  else:
    result = copyNode(n)
    let sonsLen = n.safeLen
    result.sons = newSeq[PNode](sonsLen)
    for i in 0 ..< sonsLen:
      result.sons[i] = objectNode(n[i])

proc mapTypeToAstX(t: PType; info: TLineInfo;
                   inst=false; allowRecursionX=false): PNode =
  var allowRecursion = allowRecursionX
  template atomicType(name, m): untyped = atomicTypeX(name, m, t, info)
  template mapTypeToAst(t,info): untyped = mapTypeToAstX(t, info, inst)
  template mapTypeToAstR(t,info): untyped = mapTypeToAstX(t, info, inst, true)
  template mapTypeToAst(t,i,info): untyped =
    if i<t.len and t.sons[i]!=nil: mapTypeToAstX(t.sons[i], info, inst)
    else: ast.emptyNode
  template mapTypeToBracket(name, m, t, info): untyped =
    mapTypeToBracketX(name, m, t, info, inst)
  template newNodeX(kind, children): untyped =
    let n = newNodeI(kind, if t.n.isNil: info else: t.n.info, children)
    n.typ = t
    n
  template newIdentDefs(n,t): untyped =
    var id = newNodeX(nkIdentDefs, 3)
    id.sons[0] = n  # name
    id.sons[1] = mapTypeToAst(t, info)  # type
    id.sons[2] = ast.emptyNode  # no assigned value
    id
  template newIdentDefs(s): untyped = newIdentDefs(s, s.typ)

  if inst:
    if t.sym != nil:  # if this node has a symbol
      if allowRecursion:  # getTypeImpl behavior: turn off recursion
        allowRecursion = false
      else:  # getTypeInst behavior: return symbol
        return atomicType(t.sym.name.s, t.sym.magic)

  case t.kind
  of tyNone: result = atomicType("none", mNone)
  of tyBool: result = atomicType("bool", mBool)
  of tyChar: result = atomicType("char", mChar)
  of tyNil: result = atomicType("nil", mNil)
  of tyExpr: result = atomicType("expr", mExpr)
  of tyStmt: result = atomicType("stmt", mStmt)
  of tyVoid: result = atomicType("void", mVoid)
  of tyEmpty: result = atomicType("empty", mNone)
  of tyArrayConstr, tyArray:
    result = newNodeIT(nkBracketExpr, if t.n.isNil: info else: t.n.info, t)
    result.add(atomicType("array", mArray))
    if inst and t.sons[0].kind == tyRange:
      var rng = newNodeX(nkInfix, 3)
      rng.sons[0] = newIdentNode(getIdent(".."), info)
      rng.sons[1] = t.sons[0].n.sons[0].copyTree
      rng.sons[2] = t.sons[0].n.sons[1].copyTree
      result.add(rng)
    else:
      result.add(mapTypeToAst(t.sons[0], info))
    result.add( mapTypeToAst(t.sons[1], info))
  of tyTypeDesc:
    if t.base != nil:
      result = newNodeIT(nkBracketExpr, if t.n.isNil: info else: t.n.info, t)
      result.add(atomicType("typeDesc", mTypeDesc))
      result.add(mapTypeToAst(t.base, info))
    else:
      result = atomicType("typeDesc", mTypeDesc)
  of tyGenericInvocation:
    result = newNodeIT(nkBracketExpr, if t.n.isNil: info else: t.n.info, t)
    for i in 0 .. < t.len:
      result.add(mapTypeToAst(t.sons[i], info))
  of tyGenericInst:
    if inst:
      if allowRecursion:
        result = mapTypeToAstR(t.lastSon, info)
      else:
        result = newNodeX(nkBracketExpr, t.len - 1)
        result.sons[0] = mapTypeToAst(t.lastSon, info)
        for i in 1 .. < t.len-1:
          result.sons[i] = mapTypeToAst(t.sons[i], info)
    else:
      result = mapTypeToAst(t.lastSon, info)
  of tyGenericBody, tyOrdinal, tyUserTypeClassInst:
    result = mapTypeToAst(t.lastSon, info)
  of tyDistinct:
    if inst:
      result = newNodeX(nkDistinctTy, 1)
      result.sons[0] = mapTypeToAst(t.sons[0], info)
    else:
      if allowRecursion or t.sym == nil:
        result = mapTypeToBracket("distinct", mDistinct, t, info)
      else:
        result = atomicType(t.sym.name.s, t.sym.magic)
  of tyGenericParam, tyForward:
    result = atomicType(t.sym.name.s, t.sym.magic)
  of tyObject:
    if inst:
      result = newNodeX(nkObjectTy, 1)
      result.sons[0] = ast.emptyNode  # pragmas not reconstructed yet
      if t.sons[0] == nil: result.add(ast.emptyNode)  # handle parent object
      else:
        var nn = newNodeX(nkOfInherit, 1)
        nn.sons[0] = mapTypeToAst(t.sons[0], info)
        result.add(nn)
      if t.n.len > 0:
        result.add(objectNode(t.n))
      else:
        result.add(ast.emptyNode)
    else:
      if allowRecursion or t.sym == nil:
        result = newNodeIT(nkObjectTy, if t.n.isNil: info else: t.n.info, t)
        result.add(ast.emptyNode)
        if t.sons[0] == nil:
          result.add(ast.emptyNode)
        else:
          result.add(mapTypeToAst(t.sons[0], info))
        result.add(copyTree(t.n))
      else:
        result = atomicType(t.sym.name.s, t.sym.magic)
  of tyEnum:
    result = newNodeIT(nkEnumTy, if t.n.isNil: info else: t.n.info, t)
    result.add(copyTree(t.n))
  of tyTuple:
    if inst:
      let sonsLen = t.n.sons.len
      result = newNodeX(nkTupleTy, sonslen)
      for i in 0 ..< sonsLen:
        result.sons[i] = newIdentDefs(t.n.sons[i])
    else:
      result = mapTypeToBracket("tuple", mTuple, t, info)
  of tySet: result = mapTypeToBracket("set", mSet, t, info)
  of tyPtr:
    if inst:
      result = newNodeX(nkPtrTy, 1)
      result.sons[0] = mapTypeToAst(t.sons[0], info)
    else:
      result = mapTypeToBracket("ptr", mPtr, t, info)
  of tyRef:
    if inst:
      result = newNodeX(nkRefTy, 1)
      result.sons[0] = mapTypeToAst(t.sons[0], info)
    else:
      result = mapTypeToBracket("ref", mRef, t, info)
  of tyVar: result = mapTypeToBracket("var", mVar, t, info)
  of tySequence: result = mapTypeToBracket("seq", mSeq, t, info)
  of tyProc:
    if inst:
      result = newNodeX(nkProcTy, 2)
      var fp = newNodeX(nkFormalParams, t.sons.len)
      if t.sons[0] == nil:
        fp.sons[0] = ast.emptyNode
      else:
        fp.sons[0] = mapTypeToAst(t.sons[0], t.n[0].info)
      for i in 1..<t.sons.len:
        fp.sons[i] = newIdentDefs(t.n[i], t.sons[i])
      result.sons[0] = fp
      result.sons[1] = ast.emptyNode  # pragmas aren't reconstructed yet
    else:
      result = mapTypeToBracket("proc", mNone, t, info)
  of tyOpenArray: result = mapTypeToBracket("openArray", mOpenArray, t, info)
  of tyRange:
    result = newNodeIT(nkBracketExpr, if t.n.isNil: info else: t.n.info, t)
    result.add(atomicType("range", mRange))
    result.add(t.n.sons[0].copyTree)
    result.add(t.n.sons[1].copyTree)
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
  of tyBigNum: result = atomicType("bignum", mNone)
  of tyConst: result = mapTypeToBracket("const", mNone, t, info)
  of tyMutable: result = mapTypeToBracket("mutable", mNone, t, info)
  of tyVarargs: result = mapTypeToBracket("varargs", mVarargs, t, info)
  of tyIter: result = mapTypeToBracket("iter", mNone, t, info)
  of tyProxy: result = atomicType("error", mNone)
  of tyBuiltInTypeClass:
    result = mapTypeToBracket("builtinTypeClass", mNone, t, info)
  of tyUserTypeClass:
    result = mapTypeToBracket("concept", mNone, t, info)
    result.add(t.n.copyTree)
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
      result.add(atomicType("static", mNone))
      if t.n != nil:
        result.add(t.n.copyTree)

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
