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

proc genStringLiteralDataOnlyV1(m: BModule, s: string; name: Rope) =
  ## define the string literal using the string and its name
  discard cgsym(m, "TGenericSeq")
  m.s[cfsData].addf("STRING_LITERAL($1, $2, $3);$n",
                    [name, makeCString(s), rope(s.len)])

proc genStringLiteralDataOnlyV1(m: BModule, s: string): Rope =
  ## all we have to work with is a string, so just grab a rando name
  ## and insert it into the data section.  lame, i know.
  result = getTempName(m)
  genStringLiteralDataOnlyV1(m, s, result)

proc genStringLiteralV1(m: BModule; n: PNode): Rope =
  ## what we're doing here is basically generating the cast of a string
  ## literal that may not be in the data section yet.
  if s.isNil:
    # nil literals are really easy to handle; i love that about them
    result = ropecg(m, "((#NimStringDesc*) NIM_NIL)", [])
  else:
    var name: Rope
    # fetch a temp name from cache, if possible, else it'll be fresh
    if getTempName(m, n, name):
      # it's new; add it to the data section using the literal and name
      genStringLiteralDataOnlyV1(m, n.strVal, name)
    # here we simply provide the cast with the name of the literal
    result = ropecg(m, "((#NimStringDesc*) &$1)", [name])

# ------ Version 2: destructor based strings and seqs -----------------------

proc genStringLiteralDataOnlyV2(m: BModule, s: string; name: Rope;
                                isConst: bool) =
  ## stuff a string literal into the data section using a string and
  ## the name to give the literal.  that is all.
  const codef = "static $4 struct {$n NI cap; NIM_CHAR data[$2+1];$n} " &
                "$1 = { $2 | NIM_STRLIT_FLAG, $3 };$n"
  m.s[cfsData].addf(codef, [name, rope(s.len), makeCString(s),
                            rope(if isConst: "const" else: "")])

proc genStringLiteralV2(m: BModule; n: PNode; isConst: bool): Rope =
  ## what we're doing here is basically generating the cast of a string
  ## literal that may not be in the data section yet.
  var name: Rope
  # fetch a temp name from cache, if possible, else it'll be fresh
  if getTempName(m, n, name):
    # it's new; add it to the data section using the literal and name
    genStringLiteralDataOnlyV2(m, n.strVal, name, isConst)
    discard cgsym(m, "NimStrPayload")
    discard cgsym(m, "NimStringV2")

  # in contrast to V1, we only cache the raw literal and not the name
  # from the data section itself; our result is that wrapped name
  result = getTempName(m)
  # here we are adding the wrapped literal into the data section
  const codef = "static $4 NimStringV2 $1 = {$2, (NimStrPayload*)&$3};$n"
  m.s[cfsData].addf(codef, [result, rope(n.strVal.len), name,
                            rope(if isConst: "const" else: "")])

proc genStringLiteralV2Const(m: BModule; n: PNode; isConst: bool): Rope =
  ## this is a special lightweight version of genStringLiteralV2()
  ## that is used for optSeqDestructors; we don't bother to retain
  ## the wrapped symbol in the data section.
  var name: Rope
  # fetch a temp name from cache, if possible, else it'll be fresh
  if getTempName(m, n, name):
    discard cgsym(m, "NimStrPayload")
    discard cgsym(m, "NimStringV2")
    # it's new; add it to the data section using the literal and name
    genStringLiteralDataOnlyV2(m, n.strVal, name, isConst)
  # here we simply provide the cast with the name(s) of the literal
  result = "{$1, (NimStrPayload*)&$2}" % [rope(n.strVal.len), name]

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
