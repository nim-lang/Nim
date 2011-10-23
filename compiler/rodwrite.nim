#
#
#           The Nimrod Compiler
#        (c) Copyright 2011 Andreas Rumpf
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

proc rodwritePass*(): TPass
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
    filename: string
    sstack: TSymSeq          # a stack of symbols to process
    tstack: TTypeSeq         # a stack of types to process
    files: TStringSeq

  PRodWriter = ref TRodWriter

proc newRodWriter(modfilename: string, crc: TCrc32, module: PSym): PRodWriter
proc addModDep(w: PRodWriter, dep: string)
proc addInclDep(w: PRodWriter, dep: string)
proc addInterfaceSym(w: PRodWriter, s: PSym)
proc addStmt(w: PRodWriter, n: PNode)
proc writeRod(w: PRodWriter)

proc processStacks(w: PRodWriter)

proc getDefines(): string = 
  var it: TTabIter
  var s = InitTabIter(it, gSymbols)
  result = ""
  while s != nil: 
    if s.position == 1: 
      if result.len != 0: add(result, " ")
      add(result, s.name.s)
    s = nextIter(it, gSymbols)

proc fileIdx(w: PRodWriter, filename: string): int = 
  for i in countup(0, high(w.files)): 
    if w.files[i] == filename: 
      return i
  result = len(w.files)
  setlen(w.files, result + 1)
  w.files[result] = filename

proc newRodWriter(modfilename: string, crc: TCrc32, module: PSym): PRodWriter = 
  new(result)
  result.sstack = @[]
  result.tstack = @[]
  InitIITable(result.index.tab)
  InitIITable(result.imports.tab)
  result.index.r = ""
  result.imports.r = ""
  result.filename = modfilename
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
  result.data = newStringOfCap(12_000)
  
proc addModDep(w: PRodWriter, dep: string) = 
  if w.modDeps.len != 0: add(w.modDeps, ' ')
  encodeVInt(fileIdx(w, dep), w.modDeps)

const 
  rodNL = "\x0A"

proc addInclDep(w: PRodWriter, dep: string) = 
  encodeVInt(fileIdx(w, dep), w.inclDeps)
  add(w.inclDeps, " ")
  encodeVInt(crcFromFile(dep), w.inclDeps)
  add(w.inclDeps, rodNL)

proc pushType(w: PRodWriter, t: PType) =
  # check so that the stack does not grow too large:
  if IiTableGet(w.index.tab, t.id) == invalidKey:
    w.tstack.add(t)

proc pushSym(w: PRodWriter, s: PSym) =
  # check so that the stack does not grow too large:
  if IiTableGet(w.index.tab, s.id) == invalidKey:
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
  if finfo.fileIndex != n.info.fileIndex: 
    result.add('?')
    encodeVInt(n.info.col, result)
    result.add(',')
    encodeVInt(n.info.line, result)
    result.add(',')
    encodeVInt(fileIdx(w, toFilename(n.info)), result)
  elif finfo.line != n.info.line:
    result.add('?')
    encodeVInt(n.info.col, result)
    result.add(',')
    encodeVInt(n.info.line, result)
  elif finfo.col != n.info.col:
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
  if loc.a != 0: 
    add(result, '?')
    encodeVInt(loc.a, result)
  if oldlen + 1 == result.len:
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
  if t.kind == tyForward: InternalError("encodeType: tyForward")
  encodeVInt(ord(t.kind), result)
  add(result, '+')
  encodeVInt(t.id, result)
  if t.n != nil: 
    encodeNode(w, UnknownLineInfo(), t.n, result)
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
  if t.containerID != 0: 
    add(result, '@')
    encodeVInt(t.containerID, result)
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
  if s.ast != nil: 
    # we used to attempt to save space here by only storing a dummy AST if
    # it is not necessary, but Nimrod's heavy compile-time evaluation features
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
  IiTablePut(w.tab, key, val)

#var debugWritten = initIntSet()

proc symStack(w: PRodWriter) =
  var i = 0
  while i < len(w.sstack): 
    var s = w.sstack[i]
    if IiTableGet(w.index.tab, s.id) == invalidKey: 
      var m = getModule(s)
      if m == nil: InternalError("symStack: module nil: " & s.name.s)
      if (m.id == w.module.id) or (sfFromGeneric in s.flags): 
        # put definition in here
        var L = w.data.len
        addToIndex(w.index, s.id, L) 
        #intSetIncl(debugWritten, s.id)
        encodeSym(w, s, w.data)
        add(w.data, rodNL)
        if sfExported in s.flags and s.kind in ExportableSymKinds: 
          encodeStr(s.name.s, w.interf)
          add(w.interf, ' ')
          encodeVInt(s.id, w.interf)
          add(w.interf, rodNL)
        if sfCompilerProc in s.flags:
          encodeStr(s.name.s, w.compilerProcs)
          add(w.compilerProcs, ' ')
          encodeVInt(s.id, w.compilerProcs)
          add(w.compilerProcs, rodNL)
        if s.kind == skConverter: 
          if w.converters.len != 0: add(w.converters, ' ')
          encodeVInt(s.id, w.converters)
        elif s.kind == skMethod and sfDispatcher notin s.flags:
          if w.methods.len != 0: add(w.methods, ' ')
          encodeVInt(s.id, w.methods)
      elif IiTableGet(w.imports.tab, s.id) == invalidKey: 
        addToIndex(w.imports, s.id, m.id) #if not Contains(debugWritten, s.id):
                                          #  MessageOut(w.filename);
                                          #  debug(s.owner);
                                          #  debug(s);
                                          #  InternalError('BUG!!!!');
                                          #end
    inc(i)
  setlen(w.sstack, 0)

proc typeStack(w: PRodWriter) = 
  var i = 0
  while i < len(w.tstack): 
    if IiTableGet(w.index.tab, w.tstack[i].id) == invalidKey: 
      var L = w.data.len
      addToIndex(w.index, w.tstack[i].id, L)
      encodeType(w, w.tstack[i], w.data)
      add(w.data, rodNL)
    inc(i)
  setlen(w.tstack, 0)

proc processStacks(w: PRodWriter) = 
  while (len(w.tstack) > 0) or (len(w.sstack) > 0): 
    symStack(w)
    typeStack(w)

proc rawAddInterfaceSym(w: PRodWriter, s: PSym) = 
  pushSym(w, s)
  processStacks(w)

proc addInterfaceSym(w: PRodWriter, s: PSym) = 
  if w == nil: return 
  if s.kind in ExportableSymKinds and 
      {sfExported, sfCompilerProc} * s.flags != {}: 
    rawAddInterfaceSym(w, s)

proc addStmt(w: PRodWriter, n: PNode) = 
  encodeVInt(w.data.len, w.init)
  add(w.init, rodNL)
  encodeNode(w, UnknownLineInfo(), n, w.data)
  add(w.data, rodNL)
  processStacks(w)

proc writeRod(w: PRodWriter) = 
  processStacks(w)
  var f: TFile
  if not open(f, completeGeneratedFilePath(changeFileExt(w.filename, "rod")),
              fmWrite):
    return
  # write header:
  f.write("NIM:")
  f.write(FileVersion)
  f.write(rodNL)
  var id = "ID:"
  encodeVInt(w.module.id, id)
  f.write(id)
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
  of nkTemplateDef, nkMacroDef: 
    var s = n.sons[namePos].sym
    addInterfaceSym(w, s)
  of nkProcDef, nkMethodDef, nkIteratorDef, nkConverterDef: 
    var s = n.sons[namePos].sym
    if s == nil: InternalError(n.info, "rodwrite.process")
    if n.sons[codePos].kind != nkEmpty or s.magic != mNone or
        sfForward notin s.flags:
      addInterfaceSym(w, s)
  of nkVarSection:
    for i in countup(0, sonsLen(n) - 1): 
      var a = n.sons[i]
      if a.kind == nkCommentStmt: continue 
      if a.kind != nkIdentDefs: InternalError(a.info, "rodwrite.process")
      addInterfaceSym(w, a.sons[0].sym)
  of nkConstSection: 
    for i in countup(0, sonsLen(n) - 1): 
      var a = n.sons[i]
      if a.kind == nkCommentStmt: continue 
      if a.kind != nkConstDef: InternalError(a.info, "rodwrite.process")
      addInterfaceSym(w, a.sons[0].sym)
  of nkTypeSection: 
    for i in countup(0, sonsLen(n) - 1): 
      var a = n.sons[i]
      if a.kind == nkCommentStmt: continue 
      if a.sons[0].kind != nkSym: InternalError(a.info, "rodwrite.process")
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
    for i in countup(0, sonsLen(n) - 1): addModDep(w, getModuleFile(n.sons[i]))
    addStmt(w, n)
  of nkFromStmt: 
    addModDep(w, getModuleFile(n.sons[0]))
    addStmt(w, n)
  of nkIncludeStmt: 
    for i in countup(0, sonsLen(n) - 1): addInclDep(w, getModuleFile(n.sons[i]))
  of nkPragma: 
    addStmt(w, n)
  else: 
    nil

proc myOpen(module: PSym, filename: string): PPassContext = 
  if module.id < 0: InternalError("rodwrite: module ID not set")
  var w = newRodWriter(filename, rodread.GetCRC(filename), module)
  rawAddInterfaceSym(w, module)
  result = w

proc myClose(c: PPassContext, n: PNode): PNode = 
  var w = PRodWriter(c)
  writeRod(w)
  result = n
  idgen.saveMaxIds(options.projectPath / options.projectName)

proc rodwritePass(): TPass = 
  initPass(result)
  if optSymbolFiles in gGlobalOptions: 
    result.open = myOpen
    result.close = myClose
    result.process = process

