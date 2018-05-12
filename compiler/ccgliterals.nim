#
#
#           The Nim Compiler
#        (c) Copyright 2018 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

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
      m.g.field = int ast.getInt(core.ast)
  result = m.g.field

proc detectStrVersion(m: BModule): int =
  detectVersion(strVersion, "nimStrVersion")

proc detectSeqVersion(m: BModule): int =
  detectVersion(seqVersion, "nimSeqVersion")

# ----- Version 1: GC'ed strings and seqs --------------------------------

proc genStringLiteralDataOnlyV1(m: BModule, s: string): Rope =
  discard cgsym(m, "TGenericSeq")
  result = getTempName(m)
  addf(m.s[cfsData], "STRING_LITERAL($1, $2, $3);$n",
       [result, makeCString(s), rope(len(s))])

proc genStringLiteralV1(m: BModule; n: PNode): Rope =
  if s.isNil:
    result = ropecg(m, "((#NimStringDesc*) NIM_NIL)", [])
  else:
    let id = nodeTableTestOrSet(m.dataCache, n, m.labels)
    if id == m.labels:
      # string literal not found in the cache:
      result = ropecg(m, "((#NimStringDesc*) &$1)",
                      [genStringLiteralDataOnlyV1(m, n.strVal)])
    else:
      result = ropecg(m, "((#NimStringDesc*) &$1$2)",
                      [m.tmpBase, rope(id)])

# ------ Version 2: destructor based strings and seqs -----------------------

proc genStringLiteralDataOnlyV2(m: BModule, s: string): Rope =
  result = getTempName(m)
  addf(m.s[cfsData], " static const NIM_CHAR $1[$2] = $3;$n",
       [result, rope(len(s)+1), makeCString(s)])

proc genStringLiteralV2(m: BModule; n: PNode): Rope =
  let id = nodeTableTestOrSet(m.dataCache, n, m.labels)
  if id == m.labels:
    # string literal not found in the cache:
    let pureLit = genStringLiteralDataOnlyV2(m, n.strVal)
    result = getTempName(m)
    addf(m.s[cfsData], "static const #NimStringV2 $1 = {$2, $2, $3};$n",
        [result, rope(len(n.strVal)+1), pureLit])
  else:
    result = m.tmpBase & rope(id)

# ------ Version selector ---------------------------------------------------

proc genStringLiteralDataOnly(m: BModule; s: string; info: TLineInfo): Rope =
  case detectStrVersion(m)
  of 0, 1: result = genStringLiteralDataOnlyV1(m, s)
  of 2: result = genStringLiteralDataOnlyV2(m, s)
  else:
    localError(m.config, info, "cannot determine how to produce code for string literal")

proc genStringLiteralFromData(m: BModule; data: Rope; info: TLineInfo): Rope =
  result = ropecg(m, "((#NimStringDesc*) &$1)",
                [data])

proc genNilStringLiteral(m: BModule; info: TLineInfo): Rope =
  result = ropecg(m, "((#NimStringDesc*) NIM_NIL)", [])

proc genStringLiteral(m: BModule; n: PNode): Rope =
  case detectStrVersion(m)
  of 0, 1: result = genStringLiteralV1(m, n)
  of 2: result = genStringLiteralV2(m, n)
  else:
    localError(m.config, n.info, "cannot determine how to produce code for string literal")
