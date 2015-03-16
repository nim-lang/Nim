#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import ast, types, msgs, osproc, streams, options, idents

proc readOutput(p: Process): string =
  result = ""
  var output = p.outputStream
  while not output.atEnd:
    result.add(output.readLine)
    result.add("\n")
  result.setLen(result.len - "\n".len)
  discard p.waitForExit

proc opGorge*(cmd, input: string): string =
  try:
    var p = startProcess(cmd, options={poEvalCommand})
    if input.len != 0:
      p.inputStream.write(input)
      p.inputStream.close()
    result = p.readOutput
  except IOError, OSError:
    result = ""

proc opSlurp*(file: string, info: TLineInfo, module: PSym): string =
  try:
    let filename = file.findFile
    result = readFile(filename)
    # we produce a fake include statement for every slurped filename, so that
    # the module dependencies are accurate:
    appendToModule(module, newNode(nkIncludeStmt, info, @[
      newStrNode(nkStrLit, filename)]))
  except IOError:
    localError(info, errCannotOpenFile, file)
    result = ""

proc atomicTypeX(name: string; t: PType; info: TLineInfo): PNode =
  let sym = newSym(skType, getIdent(name), t.owner, info)
  result = newSymNode(sym)
  result.typ = t

proc mapTypeToAst(t: PType, info: TLineInfo; allowRecursion=false): PNode

proc mapTypeToBracket(name: string; t: PType; info: TLineInfo): PNode =
  result = newNodeIT(nkBracketExpr, info, t)
  result.add atomicTypeX(name, t, info)
  for i in 0 .. < t.len:
    if t.sons[i] == nil:
      let void = atomicTypeX("void", t, info)
      void.typ = newType(tyEmpty, t.owner)
      result.add void
    else:
      result.add mapTypeToAst(t.sons[i], info)

proc mapTypeToAst(t: PType, info: TLineInfo; allowRecursion=false): PNode =
  template atomicType(name): expr = atomicTypeX(name, t, info)

  case t.kind
  of tyNone: result = atomicType("none")
  of tyBool: result = atomicType("bool")
  of tyChar: result = atomicType("char")
  of tyNil: result = atomicType("nil")
  of tyExpr: result = atomicType("expr")
  of tyStmt: result = atomicType("stmt")
  of tyEmpty: result = atomicType"void"
  of tyArrayConstr, tyArray:
    result = newNodeIT(nkBracketExpr, info, t)
    result.add atomicType("array")
    result.add mapTypeToAst(t.sons[0], info)
    result.add mapTypeToAst(t.sons[1], info)
  of tyTypeDesc:
    if t.base != nil:
      result = newNodeIT(nkBracketExpr, info, t)
      result.add atomicType("typeDesc")
      result.add mapTypeToAst(t.base, info)
    else:
      result = atomicType"typeDesc"
  of tyGenericInvocation:
    result = newNodeIT(nkBracketExpr, info, t)
    for i in 0 .. < t.len:
      result.add mapTypeToAst(t.sons[i], info)
  of tyGenericInst, tyGenericBody, tyOrdinal, tyUserTypeClassInst:
    result = mapTypeToAst(t.lastSon, info)
  of tyDistinct:
    if allowRecursion:
      result = mapTypeToBracket("distinct", t, info)
    else:
      result = atomicType(t.sym.name.s)
  of tyGenericParam, tyForward: result = atomicType(t.sym.name.s)
  of tyObject:
    if allowRecursion:
      result = newNodeIT(nkObjectTy, info, t)
      if t.sons[0] == nil:
        result.add ast.emptyNode
      else:
        result.add mapTypeToAst(t.sons[0], info)
      result.add copyTree(t.n)
    else:
      result = atomicType(t.sym.name.s)
  of tyEnum:
    result = newNodeIT(nkEnumTy, info, t)
    result.add copyTree(t.n)
  of tyTuple: result = mapTypeToBracket("tuple", t, info)
  of tySet: result = mapTypeToBracket("set", t, info)
  of tyPtr: result = mapTypeToBracket("ptr", t, info)
  of tyRef: result = mapTypeToBracket("ref", t, info)
  of tyVar: result = mapTypeToBracket("var", t, info)
  of tySequence: result = mapTypeToBracket("seq", t, info)
  of tyProc: result = mapTypeToBracket("proc", t, info)
  of tyOpenArray: result = mapTypeToBracket("openArray", t, info)
  of tyRange:
    result = newNodeIT(nkBracketExpr, info, t)
    result.add atomicType("range")
    result.add t.n.sons[0].copyTree
    result.add t.n.sons[1].copyTree
  of tyPointer: result = atomicType"pointer"
  of tyString: result = atomicType"string"
  of tyCString: result = atomicType"cstring"
  of tyInt: result = atomicType"int"
  of tyInt8: result = atomicType"int8"
  of tyInt16: result = atomicType"int16"
  of tyInt32: result = atomicType"int32"
  of tyInt64: result = atomicType"int64"
  of tyFloat: result = atomicType"float"
  of tyFloat32: result = atomicType"float32"
  of tyFloat64: result = atomicType"float64"
  of tyFloat128: result = atomicType"float128"
  of tyUInt: result = atomicType"uint"
  of tyUInt8: result = atomicType"uint8"
  of tyUInt16: result = atomicType"uint16"
  of tyUInt32: result = atomicType"uint32"
  of tyUInt64: result = atomicType"uint64"
  of tyBigNum: result = atomicType"bignum"
  of tyConst: result = mapTypeToBracket("const", t, info)
  of tyMutable: result = mapTypeToBracket("mutable", t, info)
  of tyVarargs: result = mapTypeToBracket("varargs", t, info)
  of tyIter: result = mapTypeToBracket("iter", t, info)
  of tyProxy: result = atomicType"error"
  of tyBuiltInTypeClass: result = mapTypeToBracket("builtinTypeClass", t, info)
  of tyUserTypeClass: result = mapTypeToBracket("userTypeClass", t, info)
  of tyCompositeTypeClass: result = mapTypeToBracket("compositeTypeClass", t, info)
  of tyAnd: result = mapTypeToBracket("and", t, info)
  of tyOr: result = mapTypeToBracket("or", t, info)
  of tyNot: result = mapTypeToBracket("not", t, info)
  of tyAnything: result = atomicType"anything"
  of tyStatic, tyFromExpr, tyFieldAccessor:
    result = newNodeIT(nkBracketExpr, info, t)
    result.add atomicType("static")
    if t.n != nil:
      result.add t.n.copyTree

proc opMapTypeToAst*(t: PType; info: TLineInfo): PNode =
  result = mapTypeToAst(t, info, true)
