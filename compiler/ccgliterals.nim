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
  if m.g.field == 0:
    let core = getCompilerProc(m.g.graph, corename)
    if core == nil or core.kind != skConst:
      m.g.field = 1
    else:
      m.g.field = toInt(ast.getInt(core.astdef))
  result = m.g.field

proc detectStrVersion(m: BModule): int =
  detectVersion(strVersion, "nimStrVersion")

proc detectSeqVersion(m: BModule): int =
  detectVersion(seqVersion, "nimSeqVersion")

# ----- Version 1: GC'ed strings and seqs --------------------------------

proc genStringLiteralDataOnlyV1(m: BModule, s: string; result: var Rope) =
  cgsym(m, "TGenericSeq")
  let tmp = getTempName(m)
  result.add tmp
  m.s[cfsStrData].addf("STRING_LITERAL($1, $2, $3);$n",
       [tmp, makeCString(s), rope(s.len)])

proc genStringLiteralV1(m: BModule; n: PNode; result: var Rope) =
  if s.isNil:
    appcg(m, result, "((#NimStringDesc*) NIM_NIL)", [])
  else:
    let id = nodeTableTestOrSet(m.dataCache, n, m.labels)
    if id == m.labels:
      # string literal not found in the cache:
      appcg(m, result, "((#NimStringDesc*) &", [])
      genStringLiteralDataOnlyV1(m, n.strVal, result)
      result.add ")"
    else:
      appcg(m, result, "((#NimStringDesc*) &$1$2)",
                      [m.tmpBase, id])

# ------ Version 2: destructor based strings and seqs -----------------------

proc genStringLiteralDataOnlyV2(m: BModule, s: string; result: Rope; isConst: bool) =
  m.s[cfsStrData].addf("static $4 struct {$n" &
       "  NI cap; NIM_CHAR data[$2+1];$n" &
       "} $1 = { $2 | NIM_STRLIT_FLAG, $3 };$n",
       [result, rope(s.len), makeCString(s),
       rope(if isConst: "const" else: "")])

proc genStringLiteralV2(m: BModule; n: PNode; isConst: bool; result: var Rope) =
  let id = nodeTableTestOrSet(m.dataCache, n, m.labels)
  if id == m.labels:
    let pureLit = getTempName(m)
    genStringLiteralDataOnlyV2(m, n.strVal, pureLit, isConst)
    let tmp = getTempName(m)
    result.add tmp
    cgsym(m, "NimStrPayload")
    cgsym(m, "NimStringV2")
    # string literal not found in the cache:
    m.s[cfsStrData].addf("static $4 NimStringV2 $1 = {$2, (NimStrPayload*)&$3};$n",
          [tmp, rope(n.strVal.len), pureLit, rope(if isConst: "const" else: "")])
  else:
    let tmp = getTempName(m)
    result.add tmp
    m.s[cfsStrData].addf("static $4 NimStringV2 $1 = {$2, (NimStrPayload*)&$3};$n",
          [tmp, rope(n.strVal.len), m.tmpBase & rope(id),
          rope(if isConst: "const" else: "")])

proc genStringLiteralV2Const(m: BModule; n: PNode; isConst: bool; result: var Rope) =
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
  result.addf "{$1, (NimStrPayload*)&$2}", [rope(n.strVal.len), pureLit]

# ------ Version selector ---------------------------------------------------

proc genStringLiteralDataOnly(m: BModule; s: string; info: TLineInfo;
                              isConst: bool; result: var Rope) =
  case detectStrVersion(m)
  of 0, 1: genStringLiteralDataOnlyV1(m, s, result)
  of 2:
    let tmp = getTempName(m)
    genStringLiteralDataOnlyV2(m, s, tmp, isConst)
    result.add tmp
  else:
    localError(m.config, info, "cannot determine how to produce code for string literal")

proc genNilStringLiteral(m: BModule; info: TLineInfo; result: var Rope) =
  appcg(m, result, "((#NimStringDesc*) NIM_NIL)", [])

proc genStringLiteral(m: BModule; n: PNode; result: var Rope) =
  case detectStrVersion(m)
  of 0, 1: genStringLiteralV1(m, n, result)
  of 2: genStringLiteralV2(m, n, isConst = true, result)
  else:
    localError(m.config, n.info, "cannot determine how to produce code for string literal")
