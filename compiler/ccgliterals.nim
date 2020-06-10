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
      m.g.field = toInt(ast.getInt(core.ast))
  result = m.g.field

proc detectStrVersion(m: BModule): int =
  detectVersion(strVersion, "nimStrVersion")

proc detectSeqVersion(m: BModule): int =
  detectVersion(seqVersion, "nimSeqVersion")

# ----- Version 1: GC'ed strings and seqs --------------------------------

proc genStringLiteralDataOnlyV1(m: BModule, s: string; pureLit: Rope) =
  discard cgsym(m, "TGenericSeq")
  m.s[cfsData].addf("STRING_LITERAL($1, $2, $3);$n",
                    [pureLit, makeCString(s), rope(s.len)])

proc genStringLiteralDataOnlyV1(m: BModule, s: string): Rope =
  result = getTempName(m)
  genStringLiteralDataOnlyV1(m, s, result)

proc genStringLiteralV1(m: BModule; n: PNode): Rope =
  if s.isNil:
    result = ropecg(m, "((#NimStringDesc*) NIM_NIL)", [])
  else:
    # i'm telling you, it's super subtle
    # (or maybe not, but i got bit twice)
    if hasTempName(m, n):
      var name = getTempName(m, n)
      result = ropecg(m, "((#NimStringDesc*) &$1)", [name])
    else:
      # string literal not found in the cache:
      result = ropecg(m, "((#NimStringDesc*) &$1)",
                      [genStringLiteralDataOnlyV1(m, n.strVal)])

# ------ Version 2: destructor based strings and seqs -----------------------

proc genStringLiteralDataOnlyV2(m: BModule, s: string; pureLit: Rope;
                                isConst: bool) =
  const codef = "static $4 struct {$n NI cap; NIM_CHAR data[$2+1];$n} " &
                "$1 = { $2 | NIM_STRLIT_FLAG, $3 };$n"
  m.s[cfsData].addf(codef, [pureLit, rope(s.len), makeCString(s),
                            rope(if isConst: "const" else: "")])

proc genStringLiteralV2(m: BModule; n: PNode; isConst: bool): Rope =
  const codef = "static $4 NimStringV2 $1 = {$2, (NimStrPayload*)&$3};$n"
  var pureLit: Rope
  # another very subtle one...  watch out!
  if hasTempName(m, n):
    pureLit = getTempName(m, n)
  else:
    pureLit = getTempName(m)
    genStringLiteralDataOnlyV2(m, n.strVal, pureLit, isConst)
    discard cgsym(m, "NimStrPayload")
    discard cgsym(m, "NimStringV2")
  result = getTempName(m)
  m.s[cfsData].addf(codef, [result, rope(n.strVal.len), pureLit,
                            rope(if isConst: "const" else: "")])

proc genStringLiteralV2Const(m: BModule; n: PNode; isConst: bool): Rope =
  var pureLit: Rope
  # and yet another creepy case...
  if hasTempName(m, n):
    pureLit = getTempName(m, n)
  else:
    pureLit = getTempName(m)
    discard cgsym(m, "NimStrPayload")
    discard cgsym(m, "NimStringV2")
    genStringLiteralDataOnlyV2(m, n.strVal, pureLit, isConst)
  result = "{$1, (NimStrPayload*)&$2}" % [rope(n.strVal.len), pureLit]

# ------ Version selector ---------------------------------------------------

proc genStringLiteralDataOnly(m: BModule; s: string; info: TLineInfo;
                              isConst: bool): Rope =
  case detectStrVersion(m)
  of 0, 1: result = genStringLiteralDataOnlyV1(m, s)
  of 2:
    result = getTempName(m)
    genStringLiteralDataOnlyV2(m, s, result, isConst)
  else:
    localError(m.config, info, "cannot determine how to produce code for string literal")

proc genNilStringLiteral(m: BModule; info: TLineInfo): Rope =
  result = ropecg(m, "((#NimStringDesc*) NIM_NIL)", [])

proc genStringLiteral(m: BModule; n: PNode): Rope =
  case detectStrVersion(m)
  of 0, 1: result = genStringLiteralV1(m, n)
  of 2: result = genStringLiteralV2(m, n, isConst = true)
  else:
    localError(m.config, n.info, "cannot determine how to produce code for string literal")
