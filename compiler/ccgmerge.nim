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
  ast, astalgo, ropes, options, strutils, nimlexbase, msgs, cgendata, rodutils,
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
  NimMergeEndMark = "/*\tNIM_merge_END:*/"

proc genSectionStart*(fs: TCFileSection): PRope =
  if compilationCachePresent:
    result = toRope(tnl)
    app(result, "/*\t")
    app(result, CFileSectionNames[fs])
    app(result, ":*/")
    app(result, tnl)

proc genSectionEnd*(fs: TCFileSection): PRope =
  if compilationCachePresent:
    result = toRope(NimMergeEndMark & tnl)

proc genSectionStart*(ps: TCProcSection): PRope =
  if compilationCachePresent:
    result = toRope(tnl)
    app(result, "/*\t")
    app(result, CProcSectionNames[ps])
    app(result, ":*/")
    app(result, tnl)

proc genSectionEnd*(ps: TCProcSection): PRope =
  if compilationCachePresent:
    result = toRope(NimMergeEndMark & tnl)

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

proc writeIntSet(a: IntSet, s: var string) =
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
  s.add(" hasframe:")
  encodeVInt(ord(m.frameDeclared), s)
  s.add(tnl)
  s.add("*/")
  result = s.toRope

template `^`(pos: expr): expr = L.buf[pos]

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

proc readVerbatimSection(L: var TBaseLexer): PRope = 
  var pos = L.bufpos
  var buf = L.buf
  var r = newStringOfCap(30_000)
  while true:
    case buf[pos]
    of CR:
      pos = nimlexbase.handleCR(L, pos)
      buf = L.buf
      r.add(tnl)
    of LF:
      pos = nimlexbase.handleLF(L, pos)
      buf = L.buf
      r.add(tnl)
    of '\0':
      internalError("ccgmerge: expected: " & NimMergeEndMark)
      break
    else: 
      if atEndMark(buf, pos):
        inc pos, NimMergeEndMark.len
        break
      r.add(buf[pos])
      inc pos
  L.bufpos = pos
  result = r.toRope

proc readKey(L: var TBaseLexer, result: var string) =
  var pos = L.bufpos
  var buf = L.buf
  setLen(result, 0)
  while buf[pos] in IdentChars:
    result.add(buf[pos])
    inc pos
  if buf[pos] != ':': internalError("ccgmerge: ':' expected")
  L.bufpos = pos + 1 # skip ':'

proc newFakeType(id: int): PType = 
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
    idTablePut(result, newFakeType(key), value.toRope)
  inc L.bufpos

proc readIntSet(L: var TBaseLexer, result: var IntSet) =
  if ^L.bufpos != '{': internalError("ccgmerge: '{' expected")
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
    of "typeInfo":  readIntSet(L, m.typeInfoMarker)
    of "labels":    m.labels = decodeVInt(L.buf, L.bufpos)
    of "hasframe":  m.frameDeclared = decodeVInt(L.buf, L.bufpos) != 0
    else: internalError("ccgmerge: unknown key: " & k)

when not defined(nimhygiene):
  {.pragma: inject.}
  
template withCFile(cfilename: string, body: stmt) {.immediate.} = 
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
  
proc readMergeInfo*(cfilename: string, m: BModule) =
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

proc readMergeSections(cfilename: string, m: var TMergeSections) =
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
          internalError("ccgmerge: unknown section: " & k)
    else:
      internalError("ccgmerge: '*/' expected")

proc mergeRequired*(m: BModule): bool =
  for i in cfsHeaders..cfsProcs:
    if m.s[i] != nil:
      #echo "not empty: ", i, " ", ropeToStr(m.s[i])
      return true
  for i in low(TCProcSection)..high(TCProcSection):
    if m.initProc.s(i) != nil: 
      #echo "not empty: ", i, " ", ropeToStr(m.initProc.s[i])
      return true

proc mergeFiles*(cfilename: string, m: BModule) =
  ## merges the C file with the old version on hard disc.
  var old: TMergeSections
  readMergeSections(cfilename, old)
  # do the merge; old section before new section:    
  for i in low(TCFileSection)..high(TCFileSection):
    m.s[i] = con(old.f[i], m.s[i])
  for i in low(TCProcSection)..high(TCProcSection):
    m.initProc.s(i) = con(old.p[i], m.initProc.s(i))
