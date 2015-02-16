#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module is responsible for writing of rod files. Note that writing of
# rod files is a pass, reading of rod files is not! This is why reading and
# writing of rod files is split into two different modules.

import 
  intsets, os, options, strutils, nversion, ast, astalgo, msgs, platform,
  condsyms, ropes, idents, crc, rodread, passes, importer, idgen, rodutils

# implementation

type 
  TRodWriter = object of TPassContext
    module: PSym
    crc: TCrc32
    options: TOptions
    defines: string
    inclDeps: string
    modDeps: string
    interf: string
    compilerProcs: string
    index, imports: TIndex
    converters, methods: string
    init: string
    data: string
    sstack: TSymSeq          # a stack of symbols to process
    tstack: TTypeSeq         # a stack of types to process
    files: TStringSeq
    origFile: string

  PRodWriter = ref TRodWriter

proc newRodWriter(crc: TCrc32, module: PSym): PRodWriter
proc addModDep(w: PRodWriter, dep: string)
proc addInclDep(w: PRodWriter, dep: string)
proc addInterfaceSym(w: PRodWriter, s: PSym)
proc addStmt(w: PRodWriter, n: PNode)
proc writeRod(w: PRodWriter)

proc getDefines(): string = 
  result = ""
  for d in definedSymbolNames():
    if result.len != 0: add(result, " ")
    add(result, d)

proc fileIdx(w: PRodWriter, filename: string): int = 
  for i in countup(0, high(w.files)): 
    if w.files[i] == filename: 
      return i
  result = len(w.files)
  setLen(w.files, result + 1)
  w.files[result] = filename

template filename*(w: PRodWriter): string =
  w.module.filename

proc newRodWriter(crc: TCrc32, module: PSym): PRodWriter = 
  new(result)
  result.sstack = @[]
  result.tstack = @[]
  initIiTable(result.index.tab)
  initIiTable(result.imports.tab)
  result.index.r = ""
  result.imports.r = ""
  result.crc = crc
  result.module = module
  result.defines = getDefines()
  result.options = options.gOptions
  result.files = @[]
  result.inclDeps = ""
  result.modDeps = ""
  result.interf = newStringOfCap(2_000)
  result.compilerProcs = ""
  result.converters = ""
  result.methods = ""
  result.init = ""
  result.origFile = module.info.toFilename
  result.data = newStringOfCap(12_000)
  
proc addModDep(w: PRodWriter, dep: string) =
  if w.modDeps.len != 0: add(w.modDeps, ' ')
  encodeVInt(fileIdx(w, dep), w.modDeps)

const 
  rodNL = "\x0A"

proc addInclDep(w: PRodWriter, dep: string) =
  var resolved = dep.findModule(w.module.info.toFullPath)
  encodeVInt(fileIdx(w, dep), w.inclDeps)
  add(w.inclDeps, " ")
  encodeVInt(crcFromFile(resolved), w.inclDeps)
  add(w.inclDeps, rodNL)

proc pushType(w: PRodWriter, t: PType) =
  # check so that the stack does not grow too large:
  if iiTableGet(w.index.tab, t.id) == InvalidKey:
    w.tstack.add(t)

proc pushSym(w: PRodWriter, s: PSym) =
  # check so that the stack does not grow too large:
  if iiTableGet(w.index.tab, s.id) == InvalidKey:
    w.sstack.add(s)

proc encodeNode(w: PRodWriter, fInfo: TLineInfo, n: PNode, 
                result: var string) = 
  if n == nil: 
    # nil nodes have to be stored too:
    result.add("()")
    return
  result.add('(')
  encodeVInt(ord(n.kind), result) 
  # we do not write comments for now
  # Line information takes easily 20% or more of the filesize! Therefore we
  # omit line information if it is the same as the father's line information:
  if fInfo.fileIndex != n.info.fileIndex: 
    result.add('?')
    encodeVInt(n.info.col, result)
    result.add(',')
    encodeVInt(n.info.line, result)
    result.add(',')
    encodeVInt(fileIdx(w, toFilename(n.info)), result)
  elif fInfo.line != n.info.line:
    result.add('?')
    encodeVInt(n.info.col, result)
    result.add(',')
    encodeVInt(n.info.line, result)
  elif fInfo.col != n.info.col:
    result.add('?')
    encodeVInt(n.info.col, result)
  # No need to output the file index, as this is the serialization of one
  # file.
  var f = n.flags * PersistentNodeFlags
  if f != {}: 
    result.add('$')
    encodeVInt(cast[int32](f), result)
  if n.typ != nil:
    result.add('^')
    encodeVInt(n.typ.id, result)
    pushType(w, n.typ)
  case n.kind
  of nkCharLit..nkInt64Lit: 
    if n.intVal != 0:
      result.add('!')
      encodeVBiggestInt(n.intVal, result)
  of nkFloatLit..nkFloat64Lit: 
    if n.floatVal != 0.0: 
      result.add('!')
      encodeStr($n.floatVal, result)
  of nkStrLit..nkTripleStrLit:
    if n.strVal != "": 
      result.add('!')
      encodeStr(n.strVal, result)
  of nkIdent:
    result.add('!')
    encodeStr(n.ident.s, result)
  of nkSym:
    result.add('!')
    encodeVInt(n.sym.id, result)
    pushSym(w, n.sym)
  else:
    for i in countup(0, sonsLen(n) - 1): 
      encodeNode(w, n.info, n.sons[i], result)
  add(result, ')')

proc encodeLoc(w: PRodWriter, loc: TLoc, result: var string) = 
  var oldLen = result.len
  result.add('<')
  if loc.k != low(loc.k): encodeVInt(ord(loc.k), result)
  if loc.s != low(loc.s): 
    add(result, '*')
    encodeVInt(ord(loc.s), result)
  if loc.flags != {}: 
    add(result, '$')
    encodeVInt(cast[int32](loc.flags), result)
  if loc.t != nil:
    add(result, '^')
    encodeVInt(cast[int32](loc.t.id), result)
    pushType(w, loc.t)
  if loc.r != nil: 
    add(result, '!')
    encodeStr(ropeToStr(loc.r), result)
  if oldLen + 1 == result.len:
    # no data was necessary, so remove the '<' again:
    setLen(result, oldLen)
  else:
    add(result, '>')
  
proc encodeType(w: PRodWriter, t: PType, result: var string) = 
  if t == nil: 
    # nil nodes have to be stored too:
    result.add("[]")
    return
  # we need no surrounding [] here because the type is in a line of its own
  if t.kind == tyForward: internalError("encodeType: tyForward")
  # for the new rodfile viewer we use a preceding [ so that the data section
  # can easily be disambiguated:
  add(result, '[')
  encodeVInt(ord(t.kind), result)
  add(result, '+')
  encodeVInt(t.id, result)
  if t.n != nil: 
    encodeNode(w, unknownLineInfo(), t.n, result)
  if t.flags != {}: 
    add(result, '$')
    encodeVInt(cast[int32](t.flags), result)
  if t.callConv != low(t.callConv): 
    add(result, '?')
    encodeVInt(ord(t.callConv), result)
  if t.owner != nil: 
    add(result, '*')
    encodeVInt(t.owner.id, result)
    pushSym(w, t.owner)
  if t.sym != nil: 
    add(result, '&')
    encodeVInt(t.sym.id, result)
    pushSym(w, t.sym)
  if t.size != - 1: 
    add(result, '/')
    encodeVBiggestInt(t.size, result)
  if t.align != 2: 
    add(result, '=')
    encodeVInt(t.align, result)
  encodeLoc(w, t.loc, result)
  for i in countup(0, sonsLen(t) - 1): 
    if t.sons[i] == nil: 
      add(result, "^()")
    else: 
      add(result, '^') 
      encodeVInt(t.sons[i].id, result)
      pushType(w, t.sons[i])

proc encodeLib(w: PRodWriter, lib: PLib, info: TLineInfo, result: var string) = 
  add(result, '|')
  encodeVInt(ord(lib.kind), result)
  add(result, '|')
  encodeStr(ropeToStr(lib.name), result)
  add(result, '|')
  encodeNode(w, info, lib.path, result)

proc encodeSym(w: PRodWriter, s: PSym, result: var string) =
  if s == nil:
    # nil nodes have to be stored too:
    result.add("{}")
    return
  # we need no surrounding {} here because the symbol is in a line of its own
  encodeVInt(ord(s.kind), result)
  result.add('+')
  encodeVInt(s.id, result)
  result.add('&')
  encodeStr(s.name.s, result)
  if s.typ != nil:
    result.add('^')
    encodeVInt(s.typ.id, result)
    pushType(w, s.typ)
  result.add('?')
  if s.info.col != -1'i16: encodeVInt(s.info.col, result)
  result.add(',')
  if s.info.line != -1'i16: encodeVInt(s.info.line, result)
  result.add(',')
  encodeVInt(fileIdx(w, toFilename(s.info)), result)
  if s.owner != nil:
    result.add('*')
    encodeVInt(s.owner.id, result)
    pushSym(w, s.owner)
  if s.flags != {}:
    result.add('$')
    encodeVInt(cast[int32](s.flags), result)
  if s.magic != mNone:
    result.add('@')
    encodeVInt(ord(s.magic), result)
  if s.options != w.options: 
    result.add('!')
    encodeVInt(cast[int32](s.options), result)
  if s.position != 0: 
    result.add('%')
    encodeVInt(s.position, result)
  if s.offset != - 1:
    result.add('`')
    encodeVInt(s.offset, result)
  encodeLoc(w, s.loc, result)
  if s.annex != nil: encodeLib(w, s.annex, s.info, result)
  if s.constraint != nil:
    add(result, '#')
    encodeNode(w, unknownLineInfo(), s.constraint, result)
  # lazy loading will soon reload the ast lazily, so the ast needs to be
  # the last entry of a symbol:
  if s.ast != nil:
    # we used to attempt to save space here by only storing a dummy AST if
    # it is not necessary, but Nim's heavy compile-time evaluation features
    # make that unfeasible nowadays:
    encodeNode(w, s.info, s.ast, result)
    when false:
      var codeAst: PNode = nil
      if not astNeeded(s):
        codeAst = s.ast.sons[codePos]
        # ugly hack to not store the AST:
        s.ast.sons[codePos] = ast.emptyNode
      encodeNode(w, s.info, s.ast, result)
      if codeAst != nil:
        # resore the AST:
        s.ast.sons[codePos] = codeAst
  
proc addToIndex(w: var TIndex, key, val: int) =
  if key - w.lastIdxKey == 1:
    # we do not store a key-diff of 1 to safe space
    encodeVInt(val - w.lastIdxVal, w.r)
  else:
    encodeVInt(key - w.lastIdxKey, w.r)
    add(w.r, ' ')
    encodeVInt(val - w.lastIdxVal, w.r)
  add(w.r, rodNL)
  w.lastIdxKey = key
  w.lastIdxVal = val
  iiTablePut(w.tab, key, val)

const debugWrittenIds = false

when debugWrittenIds:
  var debugWritten = initIntSet()

proc symStack(w: PRodWriter): int =
  var i = 0
  while i < len(w.sstack): 
    var s = w.sstack[i]
    if sfForward in s.flags:
      w.sstack[result] = s
      inc result
    elif iiTableGet(w.index.tab, s.id) == InvalidKey:
      var m = getModule(s)
      if m == nil: internalError("symStack: module nil: " & s.name.s)
      if (m.id == w.module.id) or (sfFromGeneric in s.flags): 
        # put definition in here
        var L = w.data.len
        addToIndex(w.index, s.id, L) 
        when debugWrittenIds: incl(debugWritten, s.id)
        encodeSym(w, s, w.data)
        add(w.data, rodNL)
        # put into interface section if appropriate:
        if {sfExported, sfFromGeneric} * s.flags == {sfExported} and 
            s.kind in ExportableSymKinds: 
          encodeStr(s.name.s, w.interf)
          add(w.interf, ' ')
          encodeVInt(s.id, w.interf)
          add(w.interf, rodNL)
        if sfCompilerProc in s.flags:
          encodeStr(s.name.s, w.compilerProcs)
          add(w.compilerProcs, ' ')
          encodeVInt(s.id, w.compilerProcs)
          add(w.compilerProcs, rodNL)
        if s.kind == skConverter or hasPattern(s):
          if w.converters.len != 0: add(w.converters, ' ')
          encodeVInt(s.id, w.converters)
        if s.kind == skMethod and sfDispatcher notin s.flags:
          if w.methods.len != 0: add(w.methods, ' ')
          encodeVInt(s.id, w.methods)
      elif iiTableGet(w.imports.tab, s.id) == InvalidKey: 
        addToIndex(w.imports, s.id, m.id)
        when debugWrittenIds:
          if not Contains(debugWritten, s.id):
            echo(w.filename)
            debug(s)
            debug(s.owner)
            debug(m)
            InternalError("Symbol referred to but never written")
    inc(i)
  setLen(w.sstack, result)

proc typeStack(w: PRodWriter): int = 
  var i = 0
  while i < len(w.tstack): 
    var t = w.tstack[i]
    if t.kind == tyForward:
      w.tstack[result] = t
      inc result
    elif iiTableGet(w.index.tab, t.id) == InvalidKey: 
      var L = w.data.len
      addToIndex(w.index, t.id, L)
      encodeType(w, t, w.data)
      add(w.data, rodNL)
    inc(i)
  setLen(w.tstack, result)

proc processStacks(w: PRodWriter, finalPass: bool) =
  var oldS = 0
  var oldT = 0
  while true:
    var slen = symStack(w)
    var tlen = typeStack(w)
    if slen == oldS and tlen == oldT: break
    oldS = slen
    oldT = tlen
  if finalPass and (oldS != 0 or oldT != 0):
    internalError("could not serialize some forwarded symbols/types")

proc rawAddInterfaceSym(w: PRodWriter, s: PSym) = 
  pushSym(w, s)
  processStacks(w, false)

proc addInterfaceSym(w: PRodWriter, s: PSym) = 
  if w == nil: return 
  if s.kind in ExportableSymKinds and 
      {sfExported, sfCompilerProc} * s.flags != {}: 
    rawAddInterfaceSym(w, s)

proc addStmt(w: PRodWriter, n: PNode) = 
  encodeVInt(w.data.len, w.init)
  add(w.init, rodNL)
  encodeNode(w, unknownLineInfo(), n, w.data)
  add(w.data, rodNL)
  processStacks(w, false)

proc writeRod(w: PRodWriter) = 
  processStacks(w, true)
  var f: File
  if not open(f, completeGeneratedFilePath(changeFileExt(
                      w.filename.withPackageName, RodExt)),
              fmWrite):
    #echo "couldn't write rod file for: ", w.filename
    return
  # write header:
  f.write("NIM:")
  f.write(RodFileVersion)
  f.write(rodNL)
  var id = "ID:"
  encodeVInt(w.module.id, id)
  f.write(id)
  f.write(rodNL)

  var orig = "ORIGFILE:"
  encodeStr(w.origFile, orig)
  f.write(orig)
  f.write(rodNL)
  
  var crc = "CRC:"
  encodeVInt(w.crc, crc)
  f.write(crc)
  f.write(rodNL)
  
  var options = "OPTIONS:"
  encodeVInt(cast[int32](w.options), options)
  f.write(options)
  f.write(rodNL)

  var goptions = "GOPTIONS:"
  encodeVInt(cast[int32](gGlobalOptions), goptions)
  f.write(goptions)
  f.write(rodNL)

  var cmd = "CMD:"
  encodeVInt(cast[int32](gCmd), cmd)
  f.write(cmd)
  f.write(rodNL)  
  
  f.write("DEFINES:")
  f.write(w.defines)
  f.write(rodNL)
  
  var files = "FILES(" & rodNL
  for i in countup(0, high(w.files)): 
    encodeStr(w.files[i], files)
    files.add(rodNL)
  f.write(files)
  f.write(')' & rodNL)
  
  f.write("INCLUDES(" & rodNL)
  f.write(w.inclDeps)
  f.write(')' & rodNL)
  
  f.write("DEPS:")
  f.write(w.modDeps)
  f.write(rodNL)
  
  f.write("INTERF(" & rodNL)
  f.write(w.interf)
  f.write(')' & rodNL)
  
  f.write("COMPILERPROCS(" & rodNL)
  f.write(w.compilerProcs)
  f.write(')' & rodNL)

  f.write("INDEX(" & rodNL)
  f.write(w.index.r)
  f.write(')' & rodNL)
  
  f.write("IMPORTS(" & rodNL)
  f.write(w.imports.r)
  f.write(')' & rodNL)
  
  f.write("CONVERTERS:")
  f.write(w.converters)
  f.write(rodNL)

  f.write("METHODS:")
  f.write(w.methods)
  f.write(rodNL)
  
  f.write("INIT(" & rodNL)
  f.write(w.init)
  f.write(')' & rodNL)
  
  f.write("DATA(" & rodNL)
  f.write(w.data)
  f.write(')' & rodNL)
  # write trailing zero which is necessary because we use memory mapped files
  # for reading:
  f.write("\0")
  f.close()
  
  #echo "interf: ", w.interf.len
  #echo "index:  ", w.index.r.len
  #echo "init:   ", w.init.len
  #echo "data:   ", w.data.len

proc process(c: PPassContext, n: PNode): PNode = 
  result = n
  if c == nil: return 
  var w = PRodWriter(c)
  case n.kind
  of nkStmtList:
    for i in countup(0, sonsLen(n) - 1): discard process(c, n.sons[i])
    #var s = n.sons[namePos].sym
    #addInterfaceSym(w, s)
  of nkProcDef, nkMethodDef, nkIteratorDef, nkConverterDef, 
      nkTemplateDef, nkMacroDef: 
    var s = n.sons[namePos].sym
    if s == nil: internalError(n.info, "rodwrite.process")
    if n.sons[bodyPos] == nil:
      internalError(n.info, "rodwrite.process: body is nil")
    if n.sons[bodyPos].kind != nkEmpty or s.magic != mNone or
        sfForward notin s.flags:
      addInterfaceSym(w, s)
  of nkVarSection, nkLetSection, nkConstSection:
    for i in countup(0, sonsLen(n) - 1): 
      var a = n.sons[i]
      if a.kind == nkCommentStmt: continue
      addInterfaceSym(w, a.sons[0].sym)
  of nkTypeSection: 
    for i in countup(0, sonsLen(n) - 1): 
      var a = n.sons[i]
      if a.kind == nkCommentStmt: continue 
      if a.sons[0].kind != nkSym: internalError(a.info, "rodwrite.process")
      var s = a.sons[0].sym
      addInterfaceSym(w, s) 
      # this takes care of enum fields too
      # Note: The check for ``s.typ.kind = tyEnum`` is wrong for enum
      # type aliasing! Otherwise the same enum symbol would be included
      # several times!
      #
      #        if (a.sons[2] <> nil) and (a.sons[2].kind = nkEnumTy) then begin
      #          a := s.typ.n;
      #          for j := 0 to sonsLen(a)-1 do 
      #            addInterfaceSym(w, a.sons[j].sym);        
      #        end 
  of nkImportStmt: 
    for i in countup(0, sonsLen(n) - 1): addModDep(w, getModuleName(n.sons[i]))
    addStmt(w, n)
  of nkFromStmt: 
    addModDep(w, getModuleName(n.sons[0]))
    addStmt(w, n)
  of nkIncludeStmt: 
    for i in countup(0, sonsLen(n) - 1): addInclDep(w, getModuleName(n.sons[i]))
  of nkPragma: 
    addStmt(w, n)
  else: 
    discard

proc myOpen(module: PSym): PPassContext =
  if module.id < 0: internalError("rodwrite: module ID not set")
  var w = newRodWriter(module.fileIdx.getCRC, module)
  rawAddInterfaceSym(w, module)
  result = w

proc myClose(c: PPassContext, n: PNode): PNode = 
  result = process(c, n)
  var w = PRodWriter(c)
  writeRod(w)
  idgen.saveMaxIds(options.gProjectPath / options.gProjectName)

const rodwritePass* = makePass(open = myOpen, close = myClose, process = process)

