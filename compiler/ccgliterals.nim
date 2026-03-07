#
#
#           The Nim Compiler
#        (c) Copyright 2018 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# included from cgen.nim

## This include file contains the logic to produce constant string
## and seq literals. The code here is responsible that
## ``const x = ["a", "b"]`` works without hidden runtime creation code.
## The price is that seqs and strings are not purely a library
## implementation.

template detectVersion(field, corename) =
  if m.g.config.selectedGC in {gcArc, gcOrc, gcYrc, gcAtomicArc, gcHooks}:
    result = 2
  else:
    result = 1

proc detectStrVersion(m: BModule): int =
  if m.g.config.isDefined("nimsso") and
      m.g.config.selectedGC in {gcArc, gcOrc, gcYrc, gcAtomicArc, gcHooks}:
    result = 3
  else:
    detectVersion(strVersion, "nimStrVersion")

proc detectSeqVersion(m: BModule): int =
  detectVersion(seqVersion, "nimSeqVersion")

# ----- Version 1: GC'ed strings and seqs --------------------------------

proc genStringLiteralDataOnlyV1(m: BModule, s: string; result: var Rope) =
  cgsym(m, "TGenericSeq")
  let tmp = getTempName(m)
  result.add tmp
  var res = newBuilder("")
  res.addVarWithTypeAndInitializer(AlwaysConst, name = tmp):
    res.addSimpleStruct(m, name = "", baseType = ""):
      res.addField(name = "Sup", typ = "TGenericSeq")
      res.addArrayField(name = "data", elementType = NimChar, len = s.len + 1)
  do:
    var strInit: StructInitializer
    res.addStructInitializer(strInit, kind = siOrderedStruct):
      res.addField(strInit, name = "Sup"):
        var seqInit: StructInitializer
        res.addStructInitializer(seqInit, kind = siOrderedStruct):
          res.addField(seqInit, name = "len"):
            res.addIntValue(s.len)
          res.addField(seqInit, name = "reserved"):
            res.add(cCast(NimInt, cOp(BitOr, NimUint, cCast(NimUint, cIntValue(s.len)), NimStrlitFlag)))
      res.addField(strInit, name = "data"):
        res.add(makeCString(s))
  m.s[cfsStrData].add(extract(res))

proc genStringLiteralV1(m: BModule; n: PNode; result: var Builder) =
  if s.isNil:
    result.add(cCast(ptrType(cgsymValue(m, "NimStringDesc")), NimNil))
  else:
    let id = nodeTableTestOrSet(m.dataCache, n, m.labels)
    var name: string = ""
    if id == m.labels:
      # string literal not found in the cache:
      genStringLiteralDataOnlyV1(m, n.strVal, name)
    else:
      name = m.tmpBase & $id
    result.add(cCast(ptrType(cgsymValue(m, "NimStringDesc")), cAddr(name)))

# ------ Version 2: destructor based strings and seqs -----------------------

proc genStringLiteralDataOnlyV2(m: BModule, s: string; result: Rope; isConst: bool) =
  var res = newBuilder("")
  res.addVarWithTypeAndInitializer(
      if isConst: AlwaysConst else: Global,
      name = result):
    res.addSimpleStruct(m, name = "", baseType = ""):
      res.addField(name = "cap", typ = NimInt)
      res.addArrayField(name = "data", elementType = NimChar, len = s.len + 1)
  do:
    var structInit: StructInitializer
    res.addStructInitializer(structInit, kind = siOrderedStruct):
      res.addField(structInit, name = "cap"):
        res.add(cOp(BitOr, NimInt, cIntValue(s.len), NimStrlitFlag))
      res.addField(structInit, name = "data"):
        res.add(makeCString(s))
  m.s[cfsStrData].add(extract(res))

proc genStringLiteralV2(m: BModule; n: PNode; isConst: bool; result: var Builder) =
  let id = nodeTableTestOrSet(m.dataCache, n, m.labels)
  var litName: string
  if id == m.labels:
    cgsym(m, "NimStrPayload")
    cgsym(m, "NimStringV2")
    # string literal not found in the cache:
    litName = getTempName(m)
    genStringLiteralDataOnlyV2(m, n.strVal, litName, isConst)
  else:
    litName = m.tmpBase & $id
  let tmp = getTempName(m)
  result.add tmp
  var res = newBuilder("")
  res.addVarWithInitializer(
      if isConst: AlwaysConst else: Global,
      name = tmp,
      typ = "NimStringV2"):
    var strInit: StructInitializer
    res.addStructInitializer(strInit, kind = siOrderedStruct):
      res.addField(strInit, name = "len"):
        res.addIntValue(n.strVal.len)
      res.addField(strInit, name = "p"):
        res.add(cCast(ptrType("NimStrPayload"), cAddr(litName)))
  m.s[cfsStrData].add(extract(res))

proc genStringLiteralV2Const(m: BModule; n: PNode; isConst: bool; result: var Builder) =
  let id = nodeTableTestOrSet(m.dataCache, n, m.labels)
  var pureLit: Rope
  if id == m.labels:
    pureLit = getTempName(m)
    cgsym(m, "NimStrPayload")
    cgsym(m, "NimStringV2")
    # string literal not found in the cache:
    genStringLiteralDataOnlyV2(m, n.strVal, pureLit, isConst)
  else:
    pureLit = m.tmpBase & rope(id)
  var strInit: StructInitializer
  result.addStructInitializer(strInit, kind = siOrderedStruct):
    result.addField(strInit, name = "len"):
      result.addIntValue(n.strVal.len)
    result.addField(strInit, name = "p"):
      result.add(cCast(ptrType("NimStrPayload"), cAddr(pureLit)))

proc ssoCharLit(ch: char): string =
  ## Return a C char literal for ch, with proper escaping.
  const hexDigits = "0123456789abcdef"
  result = "'"
  case ch
  of '\'': result.add("\\'")
  of '\\': result.add("\\\\")
  of '\0': result.add("\\0")
  of '\n': result.add("\\n")
  of '\r': result.add("\\r")
  of '\t': result.add("\\t")
  elif ch.ord < 32 or ch.ord == 127:
    result.add("\\x")
    result.add(hexDigits[ch.ord shr 4])
    result.add(hexDigits[ch.ord and 0xf])
  else:
    result.add(ch)
  result.add('\'')

proc ssoPayloadLit(src: string; maxLen: int): string =
  const AlwaysAvail = 7
  result = "{"
  for i in 0..<AlwaysAvail:
    if i > 0: result.add(',')
    let ch = if i < maxLen: src[i] else: '\0'
    result.add(ssoCharLit(ch))
  result.add('}')

proc genStringLiteralV3Const(m: BModule; n: PNode; isConst: bool; result: var Builder) =
  # Inline SmallString struct initializer for use inside const aggregate types.
  # Short strings (<=7 chars) embed all chars directly. Long strings reference
  # a static LongString block emitted separately into cfsStrData.
  const AlwaysAvail = 7
  let s = n.strVal

  cgsym(m, "SmallString")
  cgsym(m, "LongString")

  var si: StructInitializer
  result.addStructInitializer(si, kind = siOrderedStruct):
    if s.len <= AlwaysAvail:
      result.addField(si, name = "slen"):
        result.addIntValue(s.len)
      result.addField(si, name = "payload"):
        result.add(ssoPayloadLit(s, s.len))
      result.addField(si, name = "more"):
        result.add(NimNil)
    else:
      # Emit the LongString block into cfsStrData and reference it inline.
      let dataName = getTempName(m)
      var res = newBuilder("")
      res.addVarWithTypeAndInitializer(
          if isConst: AlwaysConst else: Global,
          name = dataName):
        res.addSimpleStruct(m, name = "", baseType = ""):
          res.addField(name = "rc", typ = NimInt)
          res.addField(name = "fullLen", typ = NimInt)
          res.addField(name = "capImpl", typ = NimInt)
          res.addArrayField(name = "data", elementType = NimChar, len = s.len + 1)
      do:
        var di: StructInitializer
        res.addStructInitializer(di, kind = siOrderedStruct):
          res.addField(di, name = "rc"):
            res.addIntValue(1)
          res.addField(di, name = "fullLen"):
            res.addIntValue(s.len)
          res.addField(di, name = "capImpl"):
            res.addIntValue(0)  # static, never freed
          res.addField(di, name = "data"):
            res.add(makeCString(s))
      m.s[cfsStrData].add(extract(res))
      result.addField(si, name = "slen"):
        result.addIntValue(255)
      result.addField(si, name = "payload"):
        result.add(ssoPayloadLit(s, AlwaysAvail))
      result.addField(si, name = "more"):
        result.add(cCast(ptrType("LongString"), cAddr(dataName)))

# ------ Version 3: SmallString (SSO) strings --------------------------------

proc genStringLiteralV3(m: BModule; n: PNode; isConst: bool; result: var Builder) =
  # SmallString literal. Always generate a fresh SmallString variable (like v2
  # always generates a fresh outer NimStringV2). For long strings, cache the
  # LongString payload to avoid duplicates within a module.
  const AlwaysAvail = 7  # must match strs_v3.nim
  let s = n.strVal
  let tmp = getTempName(m)
  result.add tmp

  cgsym(m, "SmallString")
  cgsym(m, "LongString")

  var res = newBuilder("")
  if s.len <= AlwaysAvail:
    # Short: all chars fit in payload, more = NULL.
    res.addVarWithInitializer(
        if isConst: AlwaysConst else: Global,
        name = tmp, typ = "SmallString"):
      var si: StructInitializer
      res.addStructInitializer(si, kind = siOrderedStruct):
        res.addField(si, name = "slen"):
          res.addIntValue(s.len)
        res.addField(si, name = "payload"):
          res.add(ssoPayloadLit(s, s.len))
        res.addField(si, name = "more"):
          res.add(NimNil)
  else:
    # Long: cache the LongString block to emit it only once per module per string.
    # Always generate a fresh SmallString pointing at the (possibly cached) block.
    let id = nodeTableTestOrSet(m.dataCache, n, m.labels)
    var dataName: string
    if id == m.labels:
      dataName = getTempName(m)
      res.addVarWithTypeAndInitializer(
          if isConst: AlwaysConst else: Global,
          name = dataName):
        res.addSimpleStruct(m, name = "", baseType = ""):
          res.addField(name = "rc", typ = NimInt)
          res.addField(name = "fullLen", typ = NimInt)
          res.addField(name = "capImpl", typ = NimInt)
          res.addArrayField(name = "data", elementType = NimChar, len = s.len + 1)
      do:
        var di: StructInitializer
        res.addStructInitializer(di, kind = siOrderedStruct):
          res.addField(di, name = "rc"):
            res.addIntValue(1)
          res.addField(di, name = "fullLen"):
            res.addIntValue(s.len)
          res.addField(di, name = "capImpl"):
            res.addIntValue(0)  # bit 0 = 0: static, never freed
          res.addField(di, name = "data"):
            res.add(makeCString(s))
    else:
      dataName = m.tmpBase & $id
    # PayloadSize = AlwaysAvail + sizeof(pointer) - 1; sentinel slen = PayloadSize+1
    # We just use a large value (255) that is guaranteed > PayloadSize on all platforms.
    res.addVarWithInitializer(
        if isConst: AlwaysConst else: Global,
        name = tmp, typ = "SmallString"):
      var si: StructInitializer
      res.addStructInitializer(si, kind = siOrderedStruct):
        res.addField(si, name = "slen"):
          res.addIntValue(255)  # > PayloadSize on all platforms => long sentinel
        res.addField(si, name = "payload"):
          res.add(ssoPayloadLit(s, AlwaysAvail))
        res.addField(si, name = "more"):
          res.add(cCast(ptrType("LongString"), cAddr(dataName)))
  m.s[cfsStrData].add(extract(res))

# ------ Version selector ---------------------------------------------------

proc genStringLiteralDataOnly(m: BModule; s: string; info: TLineInfo;
                              isConst: bool; result: var Rope) =
  case detectStrVersion(m)
  of 0, 1: genStringLiteralDataOnlyV1(m, s, result)
  of 2:
    let tmp = getTempName(m)
    genStringLiteralDataOnlyV2(m, s, tmp, isConst)
    result.add tmp
  of 3:
    localError(m.config, info, "genStringLiteralDataOnly not supported for SmallString (nimsso)")
  else:
    localError(m.config, info, "cannot determine how to produce code for string literal")

proc genNilStringLiteral(m: BModule; info: TLineInfo; result: var Builder) =
  result.add(cCast(ptrType(cgsymValue(m, "NimStringDesc")), NimNil))

proc genStringLiteral(m: BModule; n: PNode; result: var Builder) =
  case detectStrVersion(m)
  of 0, 1: genStringLiteralV1(m, n, result)
  of 2: genStringLiteralV2(m, n, isConst = true, result)
  of 3: genStringLiteralV3(m, n, isConst = true, result)
  else:
    localError(m.config, n.info, "cannot determine how to produce code for string literal")
