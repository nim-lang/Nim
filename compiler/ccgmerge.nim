#
#
#           The Nimrod Compiler
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the merge operation of 2 different C files. This
## is needed for incremental compilation.

import
  ast, astalgo, ropes, options, strutils, lexbase, msgs, cgendata, rodutils,
  intsets, platform, llstream

# Careful! Section marks need to contain a tabulator so that they cannot
# be part of C string literals.

const
  CFileSectionNames: array[TCFileSection, string] = [
    cfsMergeInfo: "",
    cfsHeaders: "NIM_merge_HEADERS",
    cfsForwardTypes: "NIM_merge_FORWARD_TYPES",
    cfsTypes: "NIM_merge_TYPES",
    cfsSeqTypes: "NIM_merge_SEQ_TYPES",
    cfsFieldInfo: "NIM_merge_FIELD_INFO",
    cfsTypeInfo: "NIM_merge_TYPE_INFO",
    cfsProcHeaders: "NIM_merge_PROC_HEADERS",
    cfsData: "NIM_merge_DATA",
    cfsVars: "NIM_merge_VARS",
    cfsProcs: "NIM_merge_PROCS",
    cfsInitProc: "NIM_merge_INIT_PROC",
    cfsTypeInit1: "NIM_merge_TYPE_INIT1",
    cfsTypeInit2: "NIM_merge_TYPE_INIT2",
    cfsTypeInit3: "NIM_merge_TYPE_INIT3",
    cfsDebugInit: "NIM_merge_DEBUG_INIT",
    cfsDynLibInit: "NIM_merge_DYNLIB_INIT",
    cfsDynLibDeinit: "NIM_merge_DYNLIB_DEINIT",
  ]
  CProcSectionNames: array[TCProcSection, string] = [
    cpsLocals: "NIM_merge_PROC_LOCALS",
    cpsInit: "NIM_merge_PROC_INIT",
    cpsStmts: "NIM_merge_PROC_BODY"
  ]
  
proc genSectionStart*(fs: TCFileSection): PRope =
  if optSymbolFiles in gGlobalOptions:
    result = toRope(tnl)
    app(result, "/*\t")
    app(result, CFileSectionNames[fs])
    app(result, "*/")
    app(result, tnl)

proc genSectionEnd*(fs: TCFileSection): PRope =
  if optSymbolFiles in gGlobalOptions:
    result = toRope("/*\tNIM_merge_END*/" & tnl)

proc genSectionStart*(ps: TCProcSection): PRope =
  if optSymbolFiles in gGlobalOptions:
    result = toRope(tnl)
    app(result, "/*\t")
    app(result, CProcSectionNames[ps])
    app(result, "*/")
    app(result, tnl)

proc genSectionEnd*(ps: TCProcSection): PRope =
  if optSymbolFiles in gGlobalOptions:
    result = toRope("/*\tNIM_merge_END*/" & tnl)

proc writeTypeCache(a: TIdTable, s: var string) =
  var i = 0
  for id, value in pairs(a):
    if i == 10:
      i = 0
      s.add(tnl)
    else:
      s.add(' ')
    encodeVInt(id, s)
    s.add(':')
    encodeStr(PRope(value).ropeToStr, s)
    inc i
  s.add('}')

proc writeIntSet(a: TIntSet, s: var string) =
  var i = 0
  for x in items(a):
    if i == 10:
      i = 0
      s.add(tnl)
    else:
      s.add(' ')
    encodeVInt(x, s)
    inc i
  s.add('}')
  
proc genMergeInfo*(m: BModule): PRope =
  if optSymbolFiles notin gGlobalOptions: return nil
  var s = "/*\tNIM_merge_INFO:"
  s.add(tnl)
  s.add("typeCache:{")
  writeTypeCache(m.typeCache, s)
  s.add("declared:{")
  writeIntSet(m.declaredThings, s)
  s.add("typeInfo:{")
  writeIntSet(m.typeInfoMarker, s)
  s.add("labels:")
  encodeVInt(m.labels, s)
  s.add(tnl)
  s.add("*/")
  result = s.toRope

template `^`(pos: expr): expr = L.buf[pos]

proc skipWhite(L: var TBaseLexer) =
  var pos = L.bufpos
  while true:
    case ^pos
    of CR: pos = lexbase.HandleCR(L, pos)
    of LF: pos = lexbase.HandleLF(L, pos)
    of ' ': inc pos
    else: break
  L.bufpos = pos

proc skipUntilCmd(L: var TBaseLexer) =
  var pos = L.bufpos
  while true:
    case ^pos
    of CR: pos = lexbase.HandleCR(L, pos)
    of LF: pos = lexbase.HandleLF(L, pos)
    of '\0': break
    of '/': 
      if ^(pos+1) == '*' and ^(pos+2) == '\t':
        inc pos, 3
        break
      inc pos
    else: inc pos
  L.bufpos = pos

proc readVerbatimSection(L: var TBaseLexer): PRope = 
  const section = "/*\tNIM_merge_END*/"
  var pos = L.bufpos
  var buf = L.buf
  result = newMutableRope(30_000)
  while true:
    case buf[pos]
    of CR:
      pos = lexbase.HandleCR(L, pos)
      buf = L.buf
      result.data.add(tnl)
    of LF:
      pos = lexbase.HandleLF(L, pos)
      buf = L.buf
      result.data.add(tnl)
    of '\0': break
    else: nil
    if buf[pos] == section[0]:
      var s = 0
      while buf[pos+1] == section[s+1]:
        inc s
        inc pos
      if section[s] != '\0':
        # reset:
        dec pos, s
      else:
        break
    result.data.add(buf[pos])
    inc pos
  L.bufpos = pos
  result.length = result.data.len

proc readKey(L: var TBaseLexer): string =
  var pos = L.bufpos
  var buf = L.buf
  while buf[pos] in IdentChars:
    result.add(buf[pos])
    inc pos
  if buf[pos] != ':': internalError("ccgmerge: ':' expected")
  L.bufpos = pos + 1 # skip ':'

proc NewFakeType(id: int): PType = 
  new(result)
  result.id = id

proc readTypeCache(L: var TBaseLexer, result: var TIdTable) =
  if ^L.bufpos != '{': internalError("ccgmerge: '{' expected")
  inc L.bufpos
  while ^L.bufpos != '}':
    skipWhite(L)
    var key = decodeVInt(L.buf, L.bufpos)
    if ^L.bufpos != ':': internalError("ccgmerge: ':' expected")
    inc L.bufpos
    var value = decodeStr(L.buf, L.bufpos)
    # XXX little hack: we create a "fake" type object with the correct Id
    # better would be to adapt the data structure to not even store the
    # object as key, but only the Id
    IdTablePut(result, newFakeType(key), value.toRope)
  inc L.bufpos

proc readIntSet(L: var TBaseLexer, result: var TIntSet) =
  if ^L.bufpos != '{': internalError("ccgmerge: '{' expected")
  inc L.bufpos
  while ^L.bufpos != '}':
    skipWhite(L)
    var key = decodeVInt(L.buf, L.bufpos)
    result.incl(key)
  inc L.bufpos

proc processMergeInfo(L: var TBaseLexer, m: BModule) =
  while true:
    skipWhite(L)
    if ^L.bufpos == '*' and ^(L.bufpos+1) == '/':
      inc(L.bufpos, 2)
      break
    var k = readKey(L)
    case k
    of "typeCache": readTypeCache(L, m.typeCache)
    of "declared":  readIntSet(L, m.declaredThings)
    of "typeInfo":  readIntSet(L, m.typeInfoMarker)
    of "labels":    m.labels = decodeVInt(L.buf, L.bufpos)
    else: InternalError("ccgmerge: unkown key: " & k)
  
proc readMergeInfo*(cfilename: string, m: BModule) =
  ## reads the merge information into `m`.
  var s = LLStreamOpen(cfilename, fmRead)
  if s == nil: return
  var L: TBaseLexer
  openBaseLexer(L, s)
  while true:
    skipUntilCmd(L)
    if ^L.bufpos == '\0': break
    var k = readKey(L)
    if k == "NIM_merge_INFO":   
      processMergeInfo(L, m)
    elif ^L.bufpos == '*' and ^(L.bufpos+1) == '/':
      inc(L.bufpos, 2)
      # read back into section
      skipWhite(L)
      var verbatim = readVerbatimSection(L)
      skipWhite(L)
      var sectionA = CFileSectionNames.find(k)
      if sectionA > 0 and sectionA <= high(TCFileSection).int:
        m.s[TCFileSection(sectionA)] = verbatim
      else:
        var sectionB = CProcSectionNames.find(k)
        if sectionB >= 0 and sectionB <= high(TCProcSection).int:
          m.initProc.s[TCProcSection(sectionB)] = verbatim
        else:
          InternalError("ccgmerge: unknown section: " & k)
    else:
      InternalError("ccgmerge: */ expected")
  closeBaseLexer(L)

