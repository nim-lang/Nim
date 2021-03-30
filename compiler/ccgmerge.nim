#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the merge operation of 2 different C files. This
## is needed for incremental compilation.

import
  ast, ropes, options, strutils, nimlexbase, cgendata, rodutils,
  intsets, llstream, tables, modulegraphs, pathutils

# Careful! Section marks need to contain a tabulator so that they cannot
# be part of C string literals.

const
  CFileSectionNames: array[TCFileSection, string] = [
    cfsMergeInfo: "",
    cfsHeaders: "NIM_merge_HEADERS",
    cfsFrameDefines: "NIM_merge_FRAME_DEFINES",
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
    cfsDatInitProc: "NIM_merge_DATINIT_PROC",
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
  NimMergeEndMark = "/*\tNIM_merge_END:*/"

proc genSectionStart*(fs: TCFileSection; conf: ConfigRef): Rope =
  # useful for debugging and only adds at most a few lines in each file
  result.add("\n/* section: ")
  result.add(CFileSectionNames[fs])
  result.add(" */\n")
  if compilationCachePresent(conf):
    result = nil
    result.add("\n/*\t")
    result.add(CFileSectionNames[fs])
    result.add(":*/\n")

proc genSectionEnd*(fs: TCFileSection; conf: ConfigRef): Rope =
  if compilationCachePresent(conf):
    result = rope(NimMergeEndMark & "\n")

proc genSectionStart*(ps: TCProcSection; conf: ConfigRef): Rope =
  if compilationCachePresent(conf):
    result = rope("")
    result.add("\n/*\t")
    result.add(CProcSectionNames[ps])
    result.add(":*/\n")

proc genSectionEnd*(ps: TCProcSection; conf: ConfigRef): Rope =
  if compilationCachePresent(conf):
    result = rope(NimMergeEndMark & "\n")

proc writeTypeCache(a: TypeCache, s: var string) =
  var i = 0
  for id, value in pairs(a):
    if i == 10:
      i = 0
      s.add('\L')
    else:
      s.add(' ')
    encodeStr($id, s)
    s.add(':')
    encodeStr($value, s)
    inc i
  s.add('}')

proc writeIntSet(a: IntSet, s: var string) =
  var i = 0
  for x in items(a):
    if i == 10:
      i = 0
      s.add('\L')
    else:
      s.add(' ')
    encodeVInt(x, s)
    inc i
  s.add('}')

proc genMergeInfo*(m: BModule): Rope =
  if not compilationCachePresent(m.config): return nil
  var s = "/*\tNIM_merge_INFO:\n"
  s.add("typeCache:{")
  writeTypeCache(m.typeCache, s)
  s.add("declared:{")
  writeIntSet(m.declaredThings, s)
  when false:
    s.add("typeInfo:{")
    writeIntSet(m.typeInfoMarker, s)
  s.add("labels:")
  encodeVInt(m.labels, s)
  s.add(" flags:")
  encodeVInt(cast[int](m.flags), s)
  s.add("\n*/")
  result = s.rope

template `^`(pos: int): untyped = L.buf[pos]

proc skipWhite(L: var TBaseLexer) =
  var pos = L.bufpos
  while true:
    case ^pos
    of CR: pos = nimlexbase.handleCR(L, pos)
    of LF: pos = nimlexbase.handleLF(L, pos)
    of ' ': inc pos
    else: break
  L.bufpos = pos

proc skipUntilCmd(L: var TBaseLexer) =
  var pos = L.bufpos
  while true:
    case ^pos
    of CR: pos = nimlexbase.handleCR(L, pos)
    of LF: pos = nimlexbase.handleLF(L, pos)
    of '\0': break
    of '/':
      if ^(pos+1) == '*' and ^(pos+2) == '\t':
        inc pos, 3
        break
      inc pos
    else: inc pos
  L.bufpos = pos

proc atEndMark(buf: cstring, pos: int): bool =
  var s = 0
  while s < NimMergeEndMark.len and buf[pos+s] == NimMergeEndMark[s]: inc s
  result = s == NimMergeEndMark.len

proc readVerbatimSection(L: var TBaseLexer): Rope =
  var pos = L.bufpos
  var r = newStringOfCap(30_000)
  while true:
    case L.buf[pos]
    of CR:
      pos = nimlexbase.handleCR(L, pos)
      r.add('\L')
    of LF:
      pos = nimlexbase.handleLF(L, pos)
      r.add('\L')
    of '\0':
      doAssert(false, "ccgmerge: expected: " & NimMergeEndMark)
      break
    else:
      if atEndMark(L.buf, pos):
        inc pos, NimMergeEndMark.len
        break
      r.add(L.buf[pos])
      inc pos
  L.bufpos = pos
  result = r.rope

proc readKey(L: var TBaseLexer, result: var string) =
  var pos = L.bufpos
  setLen(result, 0)
  while L.buf[pos] in IdentChars:
    result.add(L.buf[pos])
    inc pos
  if L.buf[pos] != ':': doAssert(false, "ccgmerge: ':' expected")
  L.bufpos = pos + 1 # skip ':'

proc readTypeCache(L: var TBaseLexer, result: var TypeCache) =
  if ^L.bufpos != '{': doAssert(false, "ccgmerge: '{' expected")
  inc L.bufpos
  while ^L.bufpos != '}':
    skipWhite(L)
    var key = decodeStr(L.buf, L.bufpos)
    if ^L.bufpos != ':': doAssert(false, "ccgmerge: ':' expected")
    inc L.bufpos
    discard decodeStr(L.buf, L.bufpos)
  inc L.bufpos

proc readIntSet(L: var TBaseLexer, result: var IntSet) =
  if ^L.bufpos != '{': doAssert(false, "ccgmerge: '{' expected")
  inc L.bufpos
  while ^L.bufpos != '}':
    skipWhite(L)
    var key = decodeVInt(L.buf, L.bufpos)
    result.incl(key)
  inc L.bufpos

proc processMergeInfo(L: var TBaseLexer, m: BModule) =
  var k = newStringOfCap("typeCache".len)
  while true:
    skipWhite(L)
    if ^L.bufpos == '*' and ^(L.bufpos+1) == '/':
      inc(L.bufpos, 2)
      break
    readKey(L, k)
    case k
    of "typeCache": readTypeCache(L, m.typeCache)
    of "declared":  readIntSet(L, m.declaredThings)
    of "typeInfo":
      when false: readIntSet(L, m.typeInfoMarker)
    of "labels":    m.labels = decodeVInt(L.buf, L.bufpos)
    of "flags":
      m.flags = cast[set[CodegenFlag]](decodeVInt(L.buf, L.bufpos) != 0)
    else: doAssert(false, "ccgmerge: unknown key: " & k)

template withCFile(cfilename: AbsoluteFile, body: untyped) =
  var s = llStreamOpen(cfilename, fmRead)
  if s == nil: return
  var L {.inject.}: TBaseLexer
  openBaseLexer(L, s)
  var k {.inject.} = newStringOfCap("NIM_merge_FORWARD_TYPES".len)
  while true:
    skipUntilCmd(L)
    if ^L.bufpos == '\0': break
    body
  closeBaseLexer(L)

proc readMergeInfo*(cfilename: AbsoluteFile, m: BModule) =
  ## reads the merge meta information into `m`.
  withCFile(cfilename):
    readKey(L, k)
    if k == "NIM_merge_INFO":
      processMergeInfo(L, m)
      break

type
  TMergeSections = object
    f: TCFileSections
    p: TCProcSections

proc readMergeSections(cfilename: AbsoluteFile, m: var TMergeSections) =
  ## reads the merge sections into `m`.
  withCFile(cfilename):
    readKey(L, k)
    if k == "NIM_merge_INFO":
      discard
    elif ^L.bufpos == '*' and ^(L.bufpos+1) == '/':
      inc(L.bufpos, 2)
      # read back into section
      skipWhite(L)
      var verbatim = readVerbatimSection(L)
      skipWhite(L)
      var sectionA = CFileSectionNames.find(k)
      if sectionA > 0 and sectionA <= high(TCFileSection).int:
        m.f[TCFileSection(sectionA)] = verbatim
      else:
        var sectionB = CProcSectionNames.find(k)
        if sectionB >= 0 and sectionB <= high(TCProcSection).int:
          m.p[TCProcSection(sectionB)] = verbatim
        else:
          doAssert(false, "ccgmerge: unknown section: " & k)
    else:
      doAssert(false, "ccgmerge: '*/' expected")

proc mergeRequired*(m: BModule): bool =
  for i in cfsHeaders..cfsProcs:
    if m.s[i] != nil:
      #echo "not empty: ", i, " ", m.s[i]
      return true
  for i in TCProcSection:
    if m.initProc.s(i) != nil:
      #echo "not empty: ", i, " ", m.initProc.s[i]
      return true

proc mergeFiles*(cfilename: AbsoluteFile, m: BModule) =
  ## merges the C file with the old version on hard disc.
  var old: TMergeSections
  readMergeSections(cfilename, old)
  # do the merge; old section before new section:
  for i in TCFileSection:
    m.s[i] = old.f[i] & m.s[i]
  for i in TCProcSection:
    m.initProc.s(i) = old.p[i] & m.initProc.s(i)
