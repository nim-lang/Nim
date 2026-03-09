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

proc ssoBytesLit(m: BModule; s: string; slen: int): string =
  ## Compute the `bytes` field value for the new SmallString layout.
  ## byte 0 = slen, bytes 1-7 = inline chars 0-6 (zero-padded).
  ## On LE: slen in bits 0-7, char[i] in bits (i+1)*8..(i+1)*8+7.
  ## On BE: slen in bits 56-63, char[i] in bits (6-i)*8..(6-i)*8+7.
  const AlwaysAvail = 7
  var val: uint64
  if CPU[m.g.config.target.targetCPU].endian == littleEndian:
    val = uint64(slen)
    for i in 0..<min(s.len, AlwaysAvail):
      val = val or (uint64(s[i]) shl (uint(i + 1) * 8))
  else:
    val = uint64(slen) shl 56
    for i in 0..<min(s.len, AlwaysAvail):
      val = val or (uint64(s[i]) shl (uint(AlwaysAvail - 1 - i) * 8))
  # Cast to NU (C name for Nim's uint, = NU64 on 64-bit). NU64 = uint64_t.
  result = cCast("NU", $val & "ULL")

proc ssoMoreLit(m: BModule; s: string): string =
  ## For medium string literals (AlwaysAvail < len <= PayloadSize), encode
  ## chars[AlwaysAvail..ptrSize-1] in the 'more' pointer field bit-pattern.
  ## The last pointer byte is always '\0' (null terminator), guaranteed by
  ## PayloadSize = AlwaysAvail + ptrSize - 1.  slen <= PayloadSize guards
  ## prevent any code from dereferencing this as an actual pointer.
  const AlwaysAvail = 7
  let ptrSize = m.g.config.target.ptrSize
  var val: uint64 = 0
  for i in 0..<ptrSize:
    let ch: uint64 = if AlwaysAvail + i < s.len: uint64(s[AlwaysAvail + i]) else: 0
    if CPU[m.g.config.target.targetCPU].endian == littleEndian:
      val = val or (ch shl (uint(i) * 8))
    else:
      val = val or (ch shl (uint(ptrSize - 1 - i) * 8))
  result = cCast(ptrType("LongString"), "(uintptr_t)" & $val)

proc genStringLiteralV3Const(m: BModule; n: PNode; isConst: bool; result: var Builder) =
  # Inline SmallString struct initializer for use inside const aggregate types.
  # Layout: {bytes: NimUint, more: ptr LongString}
  # bytes = slen (low byte) | char[0]<<8 | char[1]<<16 | ... | char[6]<<56
  const AlwaysAvail = 7
  let s = n.strVal

  cgsym(m, "SmallString")
  cgsym(m, "LongString")

  let payloadSize = AlwaysAvail + m.g.config.target.ptrSize - 1
  var si: StructInitializer
  result.addStructInitializer(si, kind = siOrderedStruct):
    if s.len <= AlwaysAvail:
      result.addField(si, name = "bytes"):
        result.add(ssoBytesLit(m, s, s.len))
      result.addField(si, name = "more"):
        result.add(NimNil)
    elif s.len <= payloadSize:
      # Medium string: bytes holds slen + chars 0-6; more holds chars 7..PayloadSize-1.
      result.addField(si, name = "bytes"):
        result.add(ssoBytesLit(m, s, s.len))
      result.addField(si, name = "more"):
        result.add(ssoMoreLit(m, s))
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
      # Sentinel slen = 255 (> PayloadSize on all platforms), hot prefix in bytes 1-7.
      result.addField(si, name = "bytes"):
        result.add(ssoBytesLit(m, s, 255))
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

  let payloadSize = AlwaysAvail + m.g.config.target.ptrSize - 1
  var res = newBuilder("")
  if s.len <= AlwaysAvail:
    # Short: bytes holds slen + all chars (zero-padded), more = NULL.
    res.addVarWithInitializer(
        if isConst: AlwaysConst else: Global,
        name = tmp, typ = "SmallString"):
      var si: StructInitializer
      res.addStructInitializer(si, kind = siOrderedStruct):
        res.addField(si, name = "bytes"):
          res.add(ssoBytesLit(m, s, s.len))
        res.addField(si, name = "more"):
          res.add(NimNil)
  elif s.len <= payloadSize:
    # Medium: bytes holds slen + chars 0-6; more holds chars 7..PayloadSize-1 as raw bits.
    res.addVarWithInitializer(
        if isConst: AlwaysConst else: Global,
        name = tmp, typ = "SmallString"):
      var si: StructInitializer
      res.addStructInitializer(si, kind = siOrderedStruct):
        res.addField(si, name = "bytes"):
          res.add(ssoBytesLit(m, s, s.len))
        res.addField(si, name = "more"):
          res.add(ssoMoreLit(m, s))
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
    # bytes: sentinel slen=255 (> PayloadSize on all platforms) + hot prefix in bytes 1-7.
    res.addVarWithInitializer(
        if isConst: AlwaysConst else: Global,
        name = tmp, typ = "SmallString"):
      var si: StructInitializer
      res.addStructInitializer(si, kind = siOrderedStruct):
        res.addField(si, name = "bytes"):
          res.add(ssoBytesLit(m, s, 255))
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
