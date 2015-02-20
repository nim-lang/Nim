#
#
#           The Nim Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module is responsible for loading of rod files.
#
# Reading and writing binary files are really hard to debug. Therefore we use
# a "creative" text/binary hybrid format. ROD-files are more efficient
# to process because symbols can be loaded on demand.
# 
# A ROD file consists of:
#
#  - a header:
#    NIM:$fileversion\n
#  - the module's id (even if the module changed, its ID will not!):
#    ID:Ax3\n
#  - CRC value of this module:
#    CRC:CRC-val\n
#  - a section containing the compiler options and defines this
#    module has been compiled with:
#    OPTIONS:options\n
#    GOPTIONS:options\n # global options
#    CMD:command\n
#    DEFINES:defines\n
#  - FILES(
#    myfile.inc
#    lib/mymodA
#    )
#  - an include file dependency section:
#    INCLUDES(
#    <fileidx> <CRC of myfile.inc>\n # fileidx is the LINE in the file section!
#    )
#  - a module dependency section:
#    DEPS: <fileidx> <fileidx>\n
#  - an interface section:
#    INTERF(
#    identifier1 id\n # id is the symbol's id
#    identifier2 id\n
#    )
#  - a compiler proc section:
#    COMPILERPROCS(
#    identifier1 id\n # id is the symbol's id    
#    )
#  - an index consisting of (ID, linenumber)-pairs:
#    INDEX(
#    id-diff idx-diff\n
#    id-diff idx-diff\n
#    )
#
#    Since the whole index has to be read in advance, we compress it by 
#    storing the integer differences to the last entry instead of using the
#    real numbers.
#
#  - an import index consisting of (ID, moduleID)-pairs:
#    IMPORTS(
#    id-diff moduleID-diff\n
#    id-diff moduleID-diff\n
#    )
#  - a list of all exported type converters because they are needed for correct
#    semantic checking:
#    CONVERTERS:id id\n   # symbol ID
#
#    This is a misnomer now; it's really a "load unconditionally" section as
#    it is also used for pattern templates.
#
#  - a list of all (private or exported) methods because they are needed for
#    correct dispatcher generation:
#    METHODS: id id\n   # symbol ID
#  - an AST section that contains the module's AST:
#    INIT(
#    idx\n  # position of the node in the DATA section
#    idx\n
#    )
#  - a data section, where each type, symbol or AST is stored.
#    DATA(
#    type
#    (node)
#    sym
#    )
#
#    The data section MUST be the last section of the file, because processing
#    stops immediately after ``DATA(`` and the rest is only loaded on demand
#    by using a mem'mapped file.
#

import 
  os, options, strutils, nversion, ast, astalgo, msgs, platform, condsyms, 
  ropes, idents, crc, idgen, types, rodutils, memfiles

type 
  TReasonForRecompile* = enum ## all the reasons that can trigger recompilation
    rrEmpty,                  # dependencies not yet computed
    rrNone,                   # no need to recompile
    rrRodDoesNotExist,        # rod file does not exist
    rrRodInvalid,             # rod file is invalid
    rrCrcChange,              # file has been edited since last recompilation
    rrDefines,                # defines have changed
    rrOptions,                # options have changed
    rrInclDeps,               # an include has changed
    rrModDeps                 # a module this module depends on has been changed

const 
  reasonToFrmt*: array[TReasonForRecompile, string] = ["", 
    "no need to recompile: $1", "symbol file for $1 does not exist", 
    "symbol file for $1 has the wrong version", 
    "file edited since last compilation: $1", 
    "list of conditional symbols changed for: $1", 
    "list of options changed for: $1", 
    "an include file edited: $1", 
    "a module $1 depends on has changed"]

type
  TIndex*{.final.} = object   # an index with compression
    lastIdxKey*, lastIdxVal*: int
    tab*: TIITable
    r*: string                # writers use this
    offset*: int              # readers use this
  
  TRodReader* = object of RootObj
    pos: int                 # position; used for parsing
    s: cstring               # mmap'ed file contents
    options: TOptions
    reason: TReasonForRecompile
    modDeps: seq[int32]
    files: seq[int32]
    dataIdx: int             # offset of start of data section
    convertersIdx: int       # offset of start of converters section
    initIdx, interfIdx, compilerProcsIdx, methodsIdx: int
    filename: string
    index, imports: TIndex
    readerIndex: int
    line: int            # only used for debugging, but is always in the code
    moduleID: int
    syms: TIdTable       # already processed symbols
    memfile: MemFile     # unfortunately there is no point in time where we
                         # can close this! XXX
    methods*: TSymSeq
    origFile: string
    inViewMode: bool
  
  PRodReader* = ref TRodReader

var rodCompilerprocs*: TStrTable

proc handleSymbolFile*(module: PSym): PRodReader
# global because this is needed by magicsys
proc loadInitSection*(r: PRodReader): PNode

# implementation

proc rawLoadStub(s: PSym)

var gTypeTable: TIdTable

proc rrGetSym(r: PRodReader, id: int, info: TLineInfo): PSym
  # `info` is only used for debugging purposes
proc rrGetType(r: PRodReader, id: int, info: TLineInfo): PType

proc decodeLineInfo(r: PRodReader, info: var TLineInfo) = 
  if r.s[r.pos] == '?': 
    inc(r.pos)
    if r.s[r.pos] == ',': info.col = -1'i16
    else: info.col = int16(decodeVInt(r.s, r.pos))
    if r.s[r.pos] == ',': 
      inc(r.pos)
      if r.s[r.pos] == ',': info.line = -1'i16
      else: info.line = int16(decodeVInt(r.s, r.pos))
      if r.s[r.pos] == ',': 
        inc(r.pos)
        info = newLineInfo(r.files[decodeVInt(r.s, r.pos)], info.line, info.col)

proc skipNode(r: PRodReader) =
  assert r.s[r.pos] == '('
  var par = 0
  var pos = r.pos+1
  while true:
    case r.s[pos]
    of ')':
      if par == 0: break
      dec par
    of '(': inc par
    else: discard
    inc pos
  r.pos = pos+1 # skip ')'

proc decodeNodeLazyBody(r: PRodReader, fInfo: TLineInfo, 
                        belongsTo: PSym): PNode = 
  result = nil
  if r.s[r.pos] == '(': 
    inc(r.pos)
    if r.s[r.pos] == ')': 
      inc(r.pos)
      return                  # nil node
    result = newNodeI(TNodeKind(decodeVInt(r.s, r.pos)), fInfo)
    decodeLineInfo(r, result.info)
    if r.s[r.pos] == '$': 
      inc(r.pos)
      result.flags = cast[TNodeFlags](int32(decodeVInt(r.s, r.pos)))
    if r.s[r.pos] == '^': 
      inc(r.pos)
      var id = decodeVInt(r.s, r.pos)
      result.typ = rrGetType(r, id, result.info)
    case result.kind
    of nkCharLit..nkInt64Lit: 
      if r.s[r.pos] == '!': 
        inc(r.pos)
        result.intVal = decodeVBiggestInt(r.s, r.pos)
    of nkFloatLit..nkFloat64Lit: 
      if r.s[r.pos] == '!': 
        inc(r.pos)
        var fl = decodeStr(r.s, r.pos)
        result.floatVal = parseFloat(fl)
    of nkStrLit..nkTripleStrLit: 
      if r.s[r.pos] == '!': 
        inc(r.pos)
        result.strVal = decodeStr(r.s, r.pos)
      else: 
        result.strVal = ""    # BUGFIX
    of nkIdent: 
      if r.s[r.pos] == '!': 
        inc(r.pos)
        var fl = decodeStr(r.s, r.pos)
        result.ident = getIdent(fl)
      else: 
        internalError(result.info, "decodeNode: nkIdent")
    of nkSym: 
      if r.s[r.pos] == '!': 
        inc(r.pos)
        var id = decodeVInt(r.s, r.pos)
        result.sym = rrGetSym(r, id, result.info)
      else: 
        internalError(result.info, "decodeNode: nkSym")
    else:
      var i = 0
      while r.s[r.pos] != ')': 
        if belongsTo != nil and i == bodyPos:
          addSonNilAllowed(result, nil)
          belongsTo.offset = r.pos
          skipNode(r)
        else:
          addSonNilAllowed(result, decodeNodeLazyBody(r, result.info, nil))
        inc i
    if r.s[r.pos] == ')': inc(r.pos)
    else: internalError(result.info, "decodeNode: ')' missing")
  else:
    internalError(fInfo, "decodeNode: '(' missing " & $r.pos)

proc decodeNode(r: PRodReader, fInfo: TLineInfo): PNode =
  result = decodeNodeLazyBody(r, fInfo, nil)
  
proc decodeLoc(r: PRodReader, loc: var TLoc, info: TLineInfo) = 
  if r.s[r.pos] == '<': 
    inc(r.pos)
    if r.s[r.pos] in {'0'..'9', 'a'..'z', 'A'..'Z'}: 
      loc.k = TLocKind(decodeVInt(r.s, r.pos))
    else: 
      loc.k = low(loc.k)
    if r.s[r.pos] == '*': 
      inc(r.pos)
      loc.s = TStorageLoc(decodeVInt(r.s, r.pos))
    else: 
      loc.s = low(loc.s)
    if r.s[r.pos] == '$': 
      inc(r.pos)
      loc.flags = cast[TLocFlags](int32(decodeVInt(r.s, r.pos)))
    else: 
      loc.flags = {}
    if r.s[r.pos] == '^': 
      inc(r.pos)
      loc.t = rrGetType(r, decodeVInt(r.s, r.pos), info)
    else: 
      loc.t = nil
    if r.s[r.pos] == '!': 
      inc(r.pos)
      loc.r = toRope(decodeStr(r.s, r.pos))
    else: 
      loc.r = nil
    if r.s[r.pos] == '>': inc(r.pos)
    else: internalError(info, "decodeLoc " & r.s[r.pos])
  
proc decodeType(r: PRodReader, info: TLineInfo): PType = 
  result = nil
  if r.s[r.pos] == '[': 
    inc(r.pos)
    if r.s[r.pos] == ']': 
      inc(r.pos)
      return                  # nil type
  new(result)
  result.kind = TTypeKind(decodeVInt(r.s, r.pos))
  if r.s[r.pos] == '+': 
    inc(r.pos)
    result.id = decodeVInt(r.s, r.pos)
    setId(result.id)
    if debugIds: registerID(result)
  else: 
    internalError(info, "decodeType: no id")
  # here this also avoids endless recursion for recursive type
  idTablePut(gTypeTable, result, result) 
  if r.s[r.pos] == '(': result.n = decodeNode(r, unknownLineInfo())
  if r.s[r.pos] == '$': 
    inc(r.pos)
    result.flags = cast[TTypeFlags](int32(decodeVInt(r.s, r.pos)))
  if r.s[r.pos] == '?': 
    inc(r.pos)
    result.callConv = TCallingConvention(decodeVInt(r.s, r.pos))
  if r.s[r.pos] == '*': 
    inc(r.pos)
    result.owner = rrGetSym(r, decodeVInt(r.s, r.pos), info)
  if r.s[r.pos] == '&': 
    inc(r.pos)
    result.sym = rrGetSym(r, decodeVInt(r.s, r.pos), info)
  if r.s[r.pos] == '/': 
    inc(r.pos)
    result.size = decodeVInt(r.s, r.pos)
  else: 
    result.size = - 1
  if r.s[r.pos] == '=': 
    inc(r.pos)
    result.align = decodeVInt(r.s, r.pos).int16
  else: 
    result.align = 2
  decodeLoc(r, result.loc, info)
  while r.s[r.pos] == '^': 
    inc(r.pos)
    if r.s[r.pos] == '(': 
      inc(r.pos)
      if r.s[r.pos] == ')': inc(r.pos)
      else: internalError(info, "decodeType ^(" & r.s[r.pos])
      rawAddSon(result, nil)
    else: 
      var d = decodeVInt(r.s, r.pos)
      rawAddSon(result, rrGetType(r, d, info))

proc decodeLib(r: PRodReader, info: TLineInfo): PLib = 
  result = nil
  if r.s[r.pos] == '|': 
    new(result)
    inc(r.pos)
    result.kind = TLibKind(decodeVInt(r.s, r.pos))
    if r.s[r.pos] != '|': internalError("decodeLib: 1")
    inc(r.pos)
    result.name = toRope(decodeStr(r.s, r.pos))
    if r.s[r.pos] != '|': internalError("decodeLib: 2")
    inc(r.pos)
    result.path = decodeNode(r, info)

proc decodeSym(r: PRodReader, info: TLineInfo): PSym = 
  var 
    id: int
    ident: PIdent
  result = nil
  if r.s[r.pos] == '{': 
    inc(r.pos)
    if r.s[r.pos] == '}': 
      inc(r.pos)
      return                  # nil sym
  var k = TSymKind(decodeVInt(r.s, r.pos))
  if r.s[r.pos] == '+': 
    inc(r.pos)
    id = decodeVInt(r.s, r.pos)
    setId(id)
  else:
    internalError(info, "decodeSym: no id")
  if r.s[r.pos] == '&': 
    inc(r.pos)
    ident = getIdent(decodeStr(r.s, r.pos))
  else:
    internalError(info, "decodeSym: no ident")
  #echo "decoding: {", ident.s
  result = PSym(idTableGet(r.syms, id))
  if result == nil: 
    new(result)
    result.id = id
    idTablePut(r.syms, result, result)
    if debugIds: registerID(result)
  elif result.id != id:
    internalError(info, "decodeSym: wrong id")
  elif result.kind != skStub and not r.inViewMode:
    # we already loaded the symbol
    return
  else:
    reset(result[])
    result.id = id
  result.kind = k
  result.name = ident         # read the rest of the symbol description:
  if r.s[r.pos] == '^': 
    inc(r.pos)
    result.typ = rrGetType(r, decodeVInt(r.s, r.pos), info)
  decodeLineInfo(r, result.info)
  if r.s[r.pos] == '*': 
    inc(r.pos)
    result.owner = rrGetSym(r, decodeVInt(r.s, r.pos), result.info)
  if r.s[r.pos] == '$': 
    inc(r.pos)
    result.flags = cast[TSymFlags](int32(decodeVInt(r.s, r.pos)))
  if r.s[r.pos] == '@': 
    inc(r.pos)
    result.magic = TMagic(decodeVInt(r.s, r.pos))
  if r.s[r.pos] == '!': 
    inc(r.pos)
    result.options = cast[TOptions](int32(decodeVInt(r.s, r.pos)))
  else: 
    result.options = r.options
  if r.s[r.pos] == '%': 
    inc(r.pos)
    result.position = decodeVInt(r.s, r.pos)
  elif result.kind notin routineKinds + {skModule}:
    result.position = 0
    # this may have been misused as reader index! But we still
    # need it for routines as the body is loaded lazily.
  if r.s[r.pos] == '`': 
    inc(r.pos)
    result.offset = decodeVInt(r.s, r.pos)
  else: 
    result.offset = - 1
  decodeLoc(r, result.loc, result.info)
  result.annex = decodeLib(r, info)
  if r.s[r.pos] == '#':
    inc(r.pos)
    result.constraint = decodeNode(r, unknownLineInfo())
  if r.s[r.pos] == '(':
    if result.kind in routineKinds:
      result.ast = decodeNodeLazyBody(r, result.info, result)
      # since we load the body lazily, we need to set the reader to
      # be able to reload:
      result.position = r.readerIndex
    else:
      result.ast = decodeNode(r, result.info)
  #echo "decoded: ", ident.s, "}"

proc skipSection(r: PRodReader) = 
  if r.s[r.pos] == ':': 
    while r.s[r.pos] > '\x0A': inc(r.pos)
  elif r.s[r.pos] == '(': 
    var c = 0                 # count () pairs
    inc(r.pos)
    while true: 
      case r.s[r.pos]
      of '\x0A': inc(r.line)
      of '(': inc(c)
      of ')': 
        if c == 0: 
          inc(r.pos)
          break 
        elif c > 0: 
          dec(c)
      of '\0': break          # end of file
      else: discard
      inc(r.pos)
  else: 
    internalError("skipSection " & $r.line)
  
proc rdWord(r: PRodReader): string = 
  result = ""
  while r.s[r.pos] in {'A'..'Z', '_', 'a'..'z', '0'..'9'}: 
    add(result, r.s[r.pos])
    inc(r.pos)

proc newStub(r: PRodReader, name: string, id: int): PSym = 
  new(result)
  result.kind = skStub
  result.id = id
  result.name = getIdent(name)
  result.position = r.readerIndex
  setId(id)                   #MessageOut(result.name.s);
  if debugIds: registerID(result)
  
proc processInterf(r: PRodReader, module: PSym) = 
  if r.interfIdx == 0: internalError("processInterf")
  r.pos = r.interfIdx
  while (r.s[r.pos] > '\x0A') and (r.s[r.pos] != ')'): 
    var w = decodeStr(r.s, r.pos)
    inc(r.pos)
    var key = decodeVInt(r.s, r.pos)
    inc(r.pos)                # #10
    var s = newStub(r, w, key)
    s.owner = module
    strTableAdd(module.tab, s)
    idTablePut(r.syms, s, s)

proc processCompilerProcs(r: PRodReader, module: PSym) = 
  if r.compilerProcsIdx == 0: internalError("processCompilerProcs")
  r.pos = r.compilerProcsIdx
  while (r.s[r.pos] > '\x0A') and (r.s[r.pos] != ')'): 
    var w = decodeStr(r.s, r.pos)
    inc(r.pos)
    var key = decodeVInt(r.s, r.pos)
    inc(r.pos)                # #10
    var s = PSym(idTableGet(r.syms, key))
    if s == nil: 
      s = newStub(r, w, key)
      s.owner = module
      idTablePut(r.syms, s, s)
    strTableAdd(rodCompilerprocs, s)

proc processIndex(r: PRodReader; idx: var TIndex; outf: File = nil) = 
  var key, val, tmp: int
  inc(r.pos, 2)               # skip "(\10"
  inc(r.line)
  while (r.s[r.pos] > '\x0A') and (r.s[r.pos] != ')'): 
    tmp = decodeVInt(r.s, r.pos)
    if r.s[r.pos] == ' ': 
      inc(r.pos)
      key = idx.lastIdxKey + tmp
      val = decodeVInt(r.s, r.pos) + idx.lastIdxVal
    else:
      key = idx.lastIdxKey + 1
      val = tmp + idx.lastIdxVal
    iiTablePut(idx.tab, key, val)
    if not outf.isNil: outf.write(key, " ", val, "\n")
    idx.lastIdxKey = key
    idx.lastIdxVal = val
    setId(key)                # ensure that this id will not be used
    if r.s[r.pos] == '\x0A': 
      inc(r.pos)
      inc(r.line)
  if r.s[r.pos] == ')': inc(r.pos)
  
proc cmdChangeTriggersRecompilation(old, new: TCommands): bool =
  if old == new: return false
  # we use a 'case' statement without 'else' so that addition of a
  # new command forces us to consider it here :-)
  case old
  of cmdCompileToC, cmdCompileToCpp, cmdCompileToOC,
      cmdCompileToJS, cmdCompileToLLVM:
    if new in {cmdDoc, cmdCheck, cmdIdeTools, cmdPretty, cmdDef,
               cmdInteractive}:
      return false
  of cmdNone, cmdDoc, cmdInterpret, cmdPretty, cmdGenDepend, cmdDump,
      cmdCheck, cmdParse, cmdScan, cmdIdeTools, cmdDef, 
      cmdRst2html, cmdRst2tex, cmdInteractive, cmdRun:
    discard
  # else: trigger recompilation:
  result = true
  
proc processRodFile(r: PRodReader, crc: TCrc32) = 
  var 
    w: string
    d, inclCrc: int
  while r.s[r.pos] != '\0': 
    var section = rdWord(r)
    if r.reason != rrNone: 
      break                   # no need to process this file further
    case section 
    of "CRC": 
      inc(r.pos)              # skip ':'
      if int(crc) != decodeVInt(r.s, r.pos): r.reason = rrCrcChange
    of "ID": 
      inc(r.pos)              # skip ':'
      r.moduleID = decodeVInt(r.s, r.pos)
      setId(r.moduleID)
    of "ORIGFILE":
      inc(r.pos)
      r.origFile = decodeStr(r.s, r.pos)
    of "OPTIONS": 
      inc(r.pos)              # skip ':'
      r.options = cast[TOptions](int32(decodeVInt(r.s, r.pos)))
      if options.gOptions != r.options: r.reason = rrOptions
    of "GOPTIONS":
      inc(r.pos)              # skip ':'
      var dep = cast[TGlobalOptions](int32(decodeVInt(r.s, r.pos)))
      if gGlobalOptions != dep: r.reason = rrOptions
    of "CMD":
      inc(r.pos)              # skip ':'
      var dep = cast[TCommands](int32(decodeVInt(r.s, r.pos)))
      if cmdChangeTriggersRecompilation(dep, gCmd): r.reason = rrOptions
    of "DEFINES":
      inc(r.pos)              # skip ':'
      d = 0
      while r.s[r.pos] > '\x0A': 
        w = decodeStr(r.s, r.pos)
        inc(d)
        if not condsyms.isDefined(getIdent(w)): 
          r.reason = rrDefines #MessageOut('not defined, but should: ' + w);
        if r.s[r.pos] == ' ': inc(r.pos)
      if (d != countDefinedSymbols()): r.reason = rrDefines
    of "FILES": 
      inc(r.pos, 2)           # skip "(\10"
      inc(r.line)
      while r.s[r.pos] != ')':
        let relativePath = decodeStr(r.s, r.pos)
        let resolvedPath = relativePath.findModule(r.origFile)
        let finalPath = if resolvedPath.len > 0: resolvedPath else: relativePath
        r.files.add(finalPath.fileInfoIdx)
        inc(r.pos)            # skip #10
        inc(r.line)
      if r.s[r.pos] == ')': inc(r.pos)
    of "INCLUDES": 
      inc(r.pos, 2)           # skip "(\10"
      inc(r.line)
      while r.s[r.pos] != ')': 
        w = r.files[decodeVInt(r.s, r.pos)].toFullPath
        inc(r.pos)            # skip ' '
        inclCrc = decodeVInt(r.s, r.pos)
        if r.reason == rrNone: 
          if not existsFile(w) or (inclCrc != int(crcFromFile(w))): 
            r.reason = rrInclDeps
        if r.s[r.pos] == '\x0A': 
          inc(r.pos)
          inc(r.line)
      if r.s[r.pos] == ')': inc(r.pos)
    of "DEPS":
      inc(r.pos)              # skip ':'
      while r.s[r.pos] > '\x0A':
        r.modDeps.add(r.files[int32(decodeVInt(r.s, r.pos))])
        if r.s[r.pos] == ' ': inc(r.pos)
    of "INTERF": 
      r.interfIdx = r.pos + 2
      skipSection(r)
    of "COMPILERPROCS": 
      r.compilerProcsIdx = r.pos + 2
      skipSection(r)
    of "INDEX": 
      processIndex(r, r.index)
    of "IMPORTS": 
      processIndex(r, r.imports)
    of "CONVERTERS": 
      r.convertersIdx = r.pos + 1
      skipSection(r)
    of "METHODS":
      r.methodsIdx = r.pos + 1
      skipSection(r)
    of "DATA": 
      r.dataIdx = r.pos + 2 # "(\10"
      # We do not read the DATA section here! We read the needed objects on
      # demand. And the DATA section comes last in the file, so we stop here:
      break
    of "INIT": 
      r.initIdx = r.pos + 2   # "(\10"
      skipSection(r)
    else:
      internalError("invalid section: '" & section &
                    "' at " & $r.line & " in " & r.filename)
      #MsgWriteln("skipping section: " & section &
      #           " at " & $r.line & " in " & r.filename)
      skipSection(r)
    if r.s[r.pos] == '\x0A': 
      inc(r.pos)
      inc(r.line)


proc startsWith(buf: cstring, token: string, pos = 0): bool =
  var s = 0
  while s < token.len and buf[pos+s] == token[s]: inc s
  result = s == token.len

proc newRodReader(modfilename: string, crc: TCrc32, 
                  readerIndex: int): PRodReader = 
  new(result)
  try:
    result.memfile = memfiles.open(modfilename)
  except OSError:
    return nil
  result.files = @[]
  result.modDeps = @[]
  result.methods = @[]
  var r = result
  r.reason = rrNone
  r.pos = 0
  r.line = 1
  r.readerIndex = readerIndex
  r.filename = modfilename
  initIdTable(r.syms)
  # we terminate the file explicitly with ``\0``, so the cast to `cstring`
  # is safe:
  r.s = cast[cstring](r.memfile.mem)
  if startsWith(r.s, "NIM:"): 
    initIiTable(r.index.tab)
    initIiTable(r.imports.tab) # looks like a ROD file
    inc(r.pos, 4)
    var version = ""
    while r.s[r.pos] notin {'\0', '\x0A'}:
      add(version, r.s[r.pos])
      inc(r.pos)
    if r.s[r.pos] == '\x0A': inc(r.pos)
    if version != RodFileVersion: 
      # since ROD files are only for caching, no backwards compatibility is
      # needed
      result = nil
  else:
    result = nil
  
proc rrGetType(r: PRodReader, id: int, info: TLineInfo): PType = 
  result = PType(idTableGet(gTypeTable, id))
  if result == nil: 
    # load the type:
    var oldPos = r.pos
    var d = iiTableGet(r.index.tab, id)
    if d == InvalidKey: internalError(info, "rrGetType")
    r.pos = d + r.dataIdx
    result = decodeType(r, info)
    r.pos = oldPos

type 
  TFileModuleRec{.final.} = object 
    filename*: string
    reason*: TReasonForRecompile
    rd*: PRodReader
    crc*: TCrc32
    crcDone*: bool

  TFileModuleMap = seq[TFileModuleRec]

var gMods*: TFileModuleMap = @[]

proc decodeSymSafePos(rd: PRodReader, offset: int, info: TLineInfo): PSym = 
  # all compiled modules
  if rd.dataIdx == 0: internalError(info, "dataIdx == 0")
  var oldPos = rd.pos
  rd.pos = offset + rd.dataIdx
  result = decodeSym(rd, info)
  rd.pos = oldPos

proc findSomeWhere(id: int) =
  for i in countup(0, high(gMods)): 
    var rd = gMods[i].rd
    if rd != nil: 
      var d = iiTableGet(rd.index.tab, id)
      if d != InvalidKey:
        echo "found id ", id, " in ", gMods[i].filename

proc getReader(moduleId: int): PRodReader =
  # we can't index 'gMods' here as it's indexed by a *file index* which is not
  # the module ID! We could introduce a mapping ID->PRodReader but I'll leave
  # this for later versions if benchmarking shows the linear search causes
  # problems:
  for i in 0 .. <gMods.len:
    result = gMods[i].rd
    if result != nil and result.moduleID == moduleId: return result
  return nil

proc rrGetSym(r: PRodReader, id: int, info: TLineInfo): PSym = 
  result = PSym(idTableGet(r.syms, id))
  if result == nil: 
    # load the symbol:
    var d = iiTableGet(r.index.tab, id)
    if d == InvalidKey: 
      # import from other module:
      var moduleID = iiTableGet(r.imports.tab, id)
      if moduleID < 0:
        var x = ""
        encodeVInt(id, x)
        internalError(info, "missing from both indexes: +" & x)
      var rd = getReader(moduleID)
      d = iiTableGet(rd.index.tab, id)
      if d != InvalidKey: 
        result = decodeSymSafePos(rd, d, info)
      else:
        var x = ""
        encodeVInt(id, x)
        when false: findSomeWhere(id)
        internalError(info, "rrGetSym: no reader found: +" & x)
    else: 
      # own symbol:
      result = decodeSymSafePos(r, d, info)
  if result != nil and result.kind == skStub: rawLoadStub(result)
  
proc loadInitSection(r: PRodReader): PNode = 
  if r.initIdx == 0 or r.dataIdx == 0: internalError("loadInitSection")
  var oldPos = r.pos
  r.pos = r.initIdx
  result = newNode(nkStmtList)
  while r.s[r.pos] > '\x0A' and r.s[r.pos] != ')': 
    var d = decodeVInt(r.s, r.pos)
    inc(r.pos)                # #10
    var p = r.pos
    r.pos = d + r.dataIdx
    addSon(result, decodeNode(r, unknownLineInfo()))
    r.pos = p
  r.pos = oldPos

proc loadConverters(r: PRodReader) = 
  # We have to ensure that no exported converter is a stub anymore, and the
  # import mechanism takes care of the rest.
  if r.convertersIdx == 0 or r.dataIdx == 0: 
    internalError("importConverters")
  r.pos = r.convertersIdx
  while r.s[r.pos] > '\x0A': 
    var d = decodeVInt(r.s, r.pos)
    discard rrGetSym(r, d, unknownLineInfo())
    if r.s[r.pos] == ' ': inc(r.pos)

proc loadMethods(r: PRodReader) =
  if r.methodsIdx == 0 or r.dataIdx == 0:
    internalError("loadMethods")
  r.pos = r.methodsIdx
  while r.s[r.pos] > '\x0A':
    var d = decodeVInt(r.s, r.pos)
    r.methods.add(rrGetSym(r, d, unknownLineInfo()))
    if r.s[r.pos] == ' ': inc(r.pos)

proc getCRC*(fileIdx: int32): TCrc32 =
  internalAssert fileIdx >= 0 and fileIdx < gMods.len

  if gMods[fileIdx].crcDone:
    return gMods[fileIdx].crc
  
  result = crcFromFile(fileIdx.toFilename)
  gMods[fileIdx].crc = result

template growCache*(cache, pos) =
  if cache.len <= pos: cache.setLen(pos+1)

proc checkDep(fileIdx: int32): TReasonForRecompile =
  assert fileIdx != InvalidFileIDX
  growCache gMods, fileIdx
  if gMods[fileIdx].reason != rrEmpty: 
    # reason has already been computed for this module:
    return gMods[fileIdx].reason
  let filename = fileIdx.toFilename
  var crc = getCRC(fileIdx)
  gMods[fileIdx].reason = rrNone  # we need to set it here to avoid cycles
  result = rrNone
  var r: PRodReader = nil
  var rodfile = toGeneratedFile(filename.withPackageName, RodExt)
  r = newRodReader(rodfile, crc, fileIdx)
  if r == nil: 
    result = (if existsFile(rodfile): rrRodInvalid else: rrRodDoesNotExist)
  else:
    processRodFile(r, crc)
    result = r.reason
    if result == rrNone: 
      # check modules it depends on
      # NOTE: we need to process the entire module graph so that no ID will
      # be used twice! However, compilation speed does not suffer much from
      # this, since results are cached.
      var res = checkDep(systemFileIdx)
      if res != rrNone: result = rrModDeps
      for i in countup(0, high(r.modDeps)):
        res = checkDep(r.modDeps[i])
        if res != rrNone:
          result = rrModDeps
          # we cannot break here, because of side-effects of `checkDep`
  if result != rrNone and gVerbosity > 0:
    rawMessage(hintProcessing, reasonToFrmt[result] % filename)
  if result != rrNone or optForceFullMake in gGlobalOptions:
    # recompilation is necessary:
    if r != nil: memfiles.close(r.memfile)
    r = nil
  gMods[fileIdx].rd = r
  gMods[fileIdx].reason = result  # now we know better
  
proc handleSymbolFile(module: PSym): PRodReader = 
  let fileIdx = module.fileIdx
  if optSymbolFiles notin gGlobalOptions: 
    module.id = getID()
    return nil
  idgen.loadMaxIds(options.gProjectPath / options.gProjectName)

  discard checkDep(fileIdx)
  if gMods[fileIdx].reason == rrEmpty: internalError("handleSymbolFile")
  result = gMods[fileIdx].rd
  if result != nil: 
    module.id = result.moduleID
    idTablePut(result.syms, module, module)
    processInterf(result, module)
    processCompilerProcs(result, module)
    loadConverters(result)
    loadMethods(result)
  else:
    module.id = getID()

proc rawLoadStub(s: PSym) =
  if s.kind != skStub: internalError("loadStub")
  var rd = gMods[s.position].rd
  var theId = s.id                # used for later check
  var d = iiTableGet(rd.index.tab, s.id)
  if d == InvalidKey: internalError("loadStub: invalid key")
  var rs = decodeSymSafePos(rd, d, unknownLineInfo())
  if rs != s:
    #echo "rs: ", toHex(cast[int](rs.position), int.sizeof * 2),
    #     "\ns:  ", toHex(cast[int](s.position), int.sizeof * 2)
    internalError(rs.info, "loadStub: wrong symbol")
  elif rs.id != theId: 
    internalError(rs.info, "loadStub: wrong ID") 
  #MessageOut('loaded stub: ' + s.name.s);
  
proc loadStub*(s: PSym) =
  ## loads the stub symbol `s`.
  
  # deactivate the GC here because we do a deep recursion and generate no
  # garbage when restoring parts of the object graph anyway.
  # Since we die with internal errors if this fails, no try-finally is
  # necessary.
  GC_disable()
  rawLoadStub(s)
  GC_enable()
  
proc getBody*(s: PSym): PNode =
  ## retrieves the AST's body of `s`. If `s` has been loaded from a rod-file
  ## it may perform an expensive reload operation. Otherwise it's a simple
  ## accessor.
  assert s.kind in routineKinds
  result = s.ast.sons[bodyPos]
  if result == nil:
    assert s.offset != 0
    var r = gMods[s.position].rd
    var oldPos = r.pos
    r.pos = s.offset
    result = decodeNode(r, s.info)
    r.pos = oldPos
    s.ast.sons[bodyPos] = result
    s.offset = 0
  
initIdTable(gTypeTable)
initStrTable(rodCompilerprocs)

# viewer:
proc writeNode(f: File; n: PNode) =
  f.write("(")
  if n != nil:
    f.write($n.kind)
    if n.typ != nil:
      f.write('^')
      f.write(n.typ.id)
    case n.kind
    of nkCharLit..nkInt64Lit: 
      if n.intVal != 0:
        f.write('!')
        f.write(n.intVal)
    of nkFloatLit..nkFloat64Lit: 
      if n.floatVal != 0.0: 
        f.write('!')
        f.write($n.floatVal)
    of nkStrLit..nkTripleStrLit:
      if n.strVal != "": 
        f.write('!')
        f.write(n.strVal.escape)
    of nkIdent:
      f.write('!')
      f.write(n.ident.s)
    of nkSym:
      f.write('!')
      f.write(n.sym.id)
    else:
      for i in countup(0, sonsLen(n) - 1): 
        writeNode(f, n.sons[i])
  f.write(")")

proc writeSym(f: File; s: PSym) =
  if s == nil:
    f.write("{}\n")
    return
  f.write("{")
  f.write($s.kind)
  f.write('+')
  f.write(s.id)
  f.write('&')
  f.write(s.name.s)
  if s.typ != nil:
    f.write('^')
    f.write(s.typ.id)
  if s.owner != nil:
    f.write('*')
    f.write(s.owner.id)
  if s.flags != {}:
    f.write('$')
    f.write($s.flags)
  if s.magic != mNone:
    f.write('@')
    f.write($s.magic)
  if s.options != gOptions: 
    f.write('!')
    f.write($s.options)
  if s.position != 0: 
    f.write('%')
    f.write($s.position)
  if s.offset != -1:
    f.write('`')
    f.write($s.offset)
  if s.constraint != nil:
    f.write('#')
    f.writeNode(s.constraint)
  if s.ast != nil:
    f.writeNode(s.ast)
  f.write("}\n")

proc writeType(f: File; t: PType) =
  if t == nil:
    f.write("[]\n")
    return
  f.write('[')
  f.write($t.kind)
  f.write('+')
  f.write($t.id)
  if t.n != nil: 
    f.writeNode(t.n)
  if t.flags != {}:
    f.write('$')
    f.write($t.flags)
  if t.callConv != low(t.callConv): 
    f.write('?')
    f.write($t.callConv)
  if t.owner != nil:
    f.write('*')
    f.write($t.owner.id)
  if t.sym != nil:
    f.write('&')
    f.write(t.sym.id)
  if t.size != -1:
    f.write('/')
    f.write($t.size)
  if t.align != 2:
    f.write('=')
    f.write($t.align)
  for i in countup(0, sonsLen(t) - 1): 
    if t.sons[i] == nil: 
      f.write("^()")
    else:
      f.write('^') 
      f.write($t.sons[i].id)
  f.write("]\n")

proc viewFile(rodfile: string) =
  var r = newRodReader(rodfile, 0, 0)
  if r == nil:
    rawMessage(errGenerated, "cannot open file (or maybe wrong version):" &
       rodfile)
    return
  r.inViewMode = true
  var outf = system.open(rodfile.changeFileExt(".rod.txt"), fmWrite)
  while r.s[r.pos] != '\0':
    let section = rdWord(r)
    case section
    of "CRC":
      inc(r.pos)              # skip ':'
      outf.writeln("CRC:", $decodeVInt(r.s, r.pos))
    of "ID": 
      inc(r.pos)              # skip ':'
      r.moduleID = decodeVInt(r.s, r.pos)
      setId(r.moduleID)
      outf.writeln("ID:", $r.moduleID)
    of "ORIGFILE":
      inc(r.pos)
      r.origFile = decodeStr(r.s, r.pos)
      outf.writeln("ORIGFILE:", r.origFile)
    of "OPTIONS":
      inc(r.pos)              # skip ':'
      r.options = cast[TOptions](int32(decodeVInt(r.s, r.pos)))
      outf.writeln("OPTIONS:", $r.options)
    of "GOPTIONS":
      inc(r.pos)              # skip ':'
      let dep = cast[TGlobalOptions](int32(decodeVInt(r.s, r.pos)))
      outf.writeln("GOPTIONS:", $dep)
    of "CMD":
      inc(r.pos)              # skip ':'
      let dep = cast[TCommands](int32(decodeVInt(r.s, r.pos)))
      outf.writeln("CMD:", $dep)
    of "DEFINES":
      inc(r.pos)              # skip ':'
      var d = 0
      outf.write("DEFINES:")
      while r.s[r.pos] > '\x0A':
        let w = decodeStr(r.s, r.pos)
        inc(d)
        outf.write(" ", w)
        if r.s[r.pos] == ' ': inc(r.pos)
      outf.write("\n")
    of "FILES":
      inc(r.pos, 2)           # skip "(\10"
      inc(r.line)
      outf.write("FILES(\n")
      while r.s[r.pos] != ')':
        let relativePath = decodeStr(r.s, r.pos)
        let resolvedPath = relativePath.findModule(r.origFile)
        let finalPath = if resolvedPath.len > 0: resolvedPath else: relativePath
        r.files.add(finalPath.fileInfoIdx)
        inc(r.pos)            # skip #10
        inc(r.line)
        outf.writeln finalPath
      if r.s[r.pos] == ')': inc(r.pos)
      outf.write(")\n")
    of "INCLUDES": 
      inc(r.pos, 2)           # skip "(\10"
      inc(r.line)
      outf.write("INCLUDES(\n")
      while r.s[r.pos] != ')': 
        let w = r.files[decodeVInt(r.s, r.pos)]
        inc(r.pos)            # skip ' '
        let inclCrc = decodeVInt(r.s, r.pos)
        if r.s[r.pos] == '\x0A': 
          inc(r.pos)
          inc(r.line)
        outf.write(w, " ", inclCrc, "\n")
      if r.s[r.pos] == ')': inc(r.pos)
      outf.write(")\n")
    of "DEPS":
      inc(r.pos)              # skip ':'
      outf.write("DEPS:")
      while r.s[r.pos] > '\x0A': 
        let v = int32(decodeVInt(r.s, r.pos))
        r.modDeps.add(r.files[v])
        if r.s[r.pos] == ' ': inc(r.pos)
        outf.write(" ", r.files[v])
      outf.write("\n")
    of "INTERF",  "COMPILERPROCS":
      inc r.pos, 2
      if section == "INTERF": r.interfIdx = r.pos
      else: r.compilerProcsIdx = r.pos
      outf.write(section, "(\n")
      while (r.s[r.pos] > '\x0A') and (r.s[r.pos] != ')'):
        let w = decodeStr(r.s, r.pos)
        inc(r.pos)
        let key = decodeVInt(r.s, r.pos)
        inc(r.pos)                # #10
        outf.write(w, " ", key, "\n")
      if r.s[r.pos] == ')': inc r.pos
      outf.write(")\n")
    of "INDEX":
      outf.write(section, "(\n")
      processIndex(r, r.index, outf)
      outf.write(")\n")
    of "IMPORTS":
      outf.write(section, "(\n")
      processIndex(r, r.imports, outf)
      outf.write(")\n")
    of "CONVERTERS",  "METHODS":
      inc r.pos
      if section == "METHODS": r.methodsIdx = r.pos
      else: r.convertersIdx = r.pos
      outf.write(section, ":")
      while r.s[r.pos] > '\x0A': 
        let d = decodeVInt(r.s, r.pos)
        outf.write(" ", $d)
        if r.s[r.pos] == ' ': inc(r.pos)
      outf.write("\n")
    of "DATA":
      inc(r.pos, 2)
      r.dataIdx = r.pos
      outf.write("DATA(\n")
      while r.s[r.pos] != ')':
        if r.s[r.pos] == '(':
          outf.writeNode decodeNode(r, unknownLineInfo())
          outf.write("\n")
        elif r.s[r.pos] == '[':
          outf.writeType decodeType(r, unknownLineInfo())
        else:
          outf.writeSym decodeSym(r, unknownLineInfo())
        if r.s[r.pos] == '\x0A':
          inc(r.pos)
          inc(r.line)
      if r.s[r.pos] == ')': inc r.pos
      outf.write(")\n")
    of "INIT":
      outf.write("INIT(\n")
      inc r.pos, 2
      r.initIdx = r.pos
      while r.s[r.pos] > '\x0A' and r.s[r.pos] != ')': 
        let d = decodeVInt(r.s, r.pos)
        inc(r.pos)                # #10
        #let p = r.pos
        #r.pos = d + r.dataIdx
        #outf.writeNode decodeNode(r, UnknownLineInfo())
        #outf.write("\n")
        #r.pos = p
      if r.s[r.pos] == ')': inc r.pos
      outf.write("<not supported by viewer>)\n")
    else:
      internalError("invalid section: '" & section &
                    "' at " & $r.line & " in " & r.filename)
      skipSection(r)
    if r.s[r.pos] == '\x0A':
      inc(r.pos)
      inc(r.line)
  outf.close

when isMainModule:
  viewFile(paramStr(1).addFileExt(rodExt))
