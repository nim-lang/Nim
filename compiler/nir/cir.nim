#
#
#           The Nim Compiler
#        (c) Copyright 2023 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# We produce C code as a list of tokens.

import std / [assertions, syncio, tables, intsets]
from std / strutils import toOctal
import .. / ic / [bitabs, rodfiles]
import nirtypes, nirinsts, nirfiles

type
  Token = LitId # indexing into the tokens BiTable[string]

  PredefinedToken = enum
    IgnoreMe = "<unused>"
    EmptyToken = ""
    CurlyLe = "{"
    CurlyRi = "}"
    ParLe = "("
    ParRi = ")"
    BracketLe = "["
    BracketRi = "]"
    NewLine = "\n"
    Semicolon = ";"
    Comma = ", "
    Space = " "
    Colon = ": "
    Dot = "."
    Arrow = "->"
    Star = "*"
    Amp = "&"
    AsgnOpr = " = "
    ScopeOpr = "::"
    ConstKeyword = "const "
    StaticKeyword = "static "
    NimString = "NimString"
    StrLitPrefix = "(NimChar*)"
    StrLitNamePrefix = "Qstr"
    LoopKeyword = "while (true) "
    WhileKeyword = "while "
    IfKeyword = "if ("
    ElseKeyword = "else "
    SwitchKeyword = "switch "
    CaseKeyword = "case "
    DefaultKeyword = "default:"
    BreakKeyword = "break"
    NullPtr = "nullptr"
    IfNot = "if (!("
    ReturnKeyword = "return "
    TypedefStruct = "typedef struct "
    IncludeKeyword = "#include "

proc fillTokenTable(tab: var BiTable[string]) =
  for e in EmptyToken..high(PredefinedToken):
    let id = tab.getOrIncl $e
    assert id == LitId(e), $(id, " ", ord(e))

type
  GeneratedCode* = object
    m: NirModule
    includes: seq[LitId]
    includedHeaders: IntSet
    data: seq[LitId]
    protos: seq[LitId]
    code: seq[LitId]
    tokens: BiTable[string]
    emittedStrings: IntSet

proc initGeneratedCode*(m: sink NirModule): GeneratedCode =
  result = GeneratedCode(m: m, code: @[], tokens: initBiTable[string]())
  fillTokenTable(result.tokens)

proc add*(g: var GeneratedCode; t: PredefinedToken) {.inline.} =
  g.code.add Token(t)

proc add*(g: var GeneratedCode; s: string) {.inline.} =
  g.code.add g.tokens.getOrIncl(s)

type
  CppFile = object
    f: File

proc write(f: var CppFile; s: string) = write(f.f, s)
proc write(f: var CppFile; c: char) = write(f.f, c)

proc writeTokenSeq(f: var CppFile; s: seq[Token]; c: GeneratedCode) =
  var indent = 0
  for i in 0..<s.len:
    let x = s[i]
    case x
    of Token(CurlyLe):
      inc indent
      write f, c.tokens[x]
      write f, "\n"
      for i in 1..indent*2: write f, ' '
    of Token(CurlyRi):
      dec indent
      write f, c.tokens[x]
      if i+1 < s.len and s[i+1] == Token(CurlyRi):
        discard
      else:
        write f, "\n"
        for i in 1..indent*2: write f, ' '
    of Token(Semicolon):
      write f, c.tokens[x]
      if i+1 < s.len and s[i+1] == Token(CurlyRi):
        discard "no newline before }"
      else:
        write f, "\n"
        for i in 1..indent*2: write f, ' '
    of Token(NewLine):
      write f, c.tokens[x]
      for i in 1..indent*2: write f, ' '
    else:
      write f, c.tokens[x]


# Type graph

type
  TypeList = object
    processed: IntSet
    s: seq[TypeId]

proc add(dest: var TypeList; elem: TypeId) =
  if not containsOrIncl(dest.processed, int(elem)):
    dest.s.add elem

type
  TypeOrder = object
    forwardedDecls, ordered: TypeList
    typeImpls: Table[string, TypeId]
    lookedAt: IntSet

proc traverseObject(types: TypeGraph; lit: Literals; c: var TypeOrder; t: TypeId)

proc recordDependency(types: TypeGraph; lit: Literals; c: var TypeOrder; parent, child: TypeId) =
  var ch = child
  var viaPointer = false
  while true:
    case types[ch].kind
    of APtrTy, UPtrTy, AArrayPtrTy, UArrayPtrTy:
      viaPointer = true
      ch = elementType(types, ch)
    of ArrayTy, LastArrayTy:
      ch = elementType(types, ch)
    else:
      break

  case types[ch].kind
  of ObjectTy, UnionTy:
    let obj = c.typeImpls.getOrDefault(lit.strings[types[ch].litId])
    if viaPointer:
      c.forwardedDecls.add obj
    else:
      if not containsOrIncl(c.lookedAt, obj.int):
        traverseObject(types, lit, c, obj)
      c.ordered.add obj
  else:
    discard "uninteresting type as we only focus on the required struct declarations"

proc traverseObject(types: TypeGraph; lit: Literals; c: var TypeOrder; t: TypeId) =
  for x in sons(types, t):
    case types[x].kind
    of FieldDecl:
      recordDependency types, lit, c, t, x.firstSon
    of ObjectTy:
      # inheritance
      recordDependency types, lit, c, t, x
    else: discard

proc traverseTypes(types: TypeGraph; lit: Literals; c: var TypeOrder) =
  for t in allTypes(types):
    if types[t].kind in {ObjectDecl, UnionDecl}:
      assert types[t.firstSon].kind == NameVal
      c.typeImpls[lit.strings[types[t.firstSon].litId]] = t

  for t in allTypes(types):
    if types[t].kind in {ObjectDecl, UnionDecl}:
      assert types[t.firstSon].kind == NameVal
      traverseObject types, lit, c, t
      c.ordered.add t

when false:
  template emitType(s: string) = c.types.add c.tokens.getOrIncl(s)
  template emitType(t: Token) = c.types.add t
  template emitType(t: PredefinedToken) = c.types.add Token(t)

proc genType(g: var GeneratedCode; types: TypeGraph; lit: Literals; t: TypeId) =
  case types[t].kind
  of VoidTy: g.add "void"
  of IntTy: g.add "NI" & $types[t].integralBits
  of UIntTy: g.add "NU" & $types[t].integralBits
  of FloatTy: g.add "NF" & $types[t].integralBits
  of BoolTy: g.add "NB" & $types[t].integralBits
  of CharTy: g.add "NC" & $types[t].integralBits
  of ObjectTy, UnionTy, NameVal:
    g.add lit.strings[types[t].litId]
  of VarargsTy:
    g.add "..."
  of APtrTy, UPtrTy, AArrayPtrTy, UArrayPtrTy:
    genType g, types, lit, elementType(types, t)
    g.add Star
  of ArrayTy:
    genType g, types, lit, elementType(types, t)
    g.add BracketLe
    g.add $arrayLen(types, t)
    g.add BracketRi
  of LastArrayTy:
    genType g, types, lit, elementType(types, t)
    g.add BracketLe
    g.add BracketRi
  of ProcTy:
    g.add "(*)"
    g.add ParLe
    var i = 0
    for ch in sons(types, t):
      if i > 0: g.add Comma
      genType g, types, lit, ch
      inc i
    g.add ParRi
  of ObjectDecl, UnionDecl:
    g.add lit.strings[types[t.firstSon].litId]
  of IntVal, SizeVal, AlignVal, OffsetVal, AnnotationVal, FieldDecl:
    #raiseAssert "did not expect: " & $types[t].kind
    g.add "BUG "
    g.add $types[t].kind

proc generateTypes(g: var GeneratedCode; types: TypeGraph; lit: Literals; c: TypeOrder) =
  for t in c.forwardedDecls.s:
    let s {.cursor.} = lit.strings[types[t.firstSon].litId]
    g.add TypedefStruct
    g.add s
    g.add Space
    g.add s
    g.add Semicolon

  for t in c.ordered.s:
    let s {.cursor.} = lit.strings[types[t.firstSon].litId]
    g.add TypedefStruct
    g.add CurlyLe

    for x in sons(types, t):
      case types[x].kind
      of FieldDecl:
        genType g, types, lit, x.firstSon
        g.add Semicolon
      of ObjectTy:
        genType g, types, lit, x
        g.add Semicolon
      else: discard

    g.add CurlyRi
    g.add Space
    g.add s
    g.add Semicolon

# Procs

proc toCChar*(c: char; result: var string) {.inline.} =
  case c
  of '\0'..'\x1F', '\x7F'..'\xFF':
    result.add '\\'
    result.add toOctal(c)
  of '\'', '\"', '\\', '?':
    result.add '\\'
    result.add c
  else:
    result.add c

proc makeCString(s: string): string =
  result = newStringOfCap(s.len + 10)
  result.add('"')
  for c in s: toCChar(c, result)
  result.add('"')

template emitData(s: string) = c.data.add c.tokens.getOrIncl(s)
template emitData(t: Token) = c.data.add t
template emitData(t: PredefinedToken) = c.data.add Token(t)

proc genStrLit(c: var GeneratedCode; lit: Literals; litId: LitId): Token =
  result = Token(c.tokens.getOrIncl "QStr" & $litId)
  if not containsOrIncl(c.emittedStrings, int(litId)):
    let s {.cursor.} = lit.strings[litId]
    emitData "static const struct "
    emitData CurlyLe
    emitData "  NI cap"
    emitData Semicolon
    emitData "NIM_CHAR data"
    emitData BracketLe
    emitData $s.len
    emitData "+1"
    emitData BracketRi
    emitData Semicolon
    emitData CurlyRi
    emitData result
    emitData AsgnOpr
    emitData CurlyLe
    emitData $s.len
    emitData " | NIM_STRLIT_FLAG"
    emitData Comma
    emitData makeCString(s)
    emitData CurlyRi
    emitData Semicolon

proc genIntLit(c: var GeneratedCode; lit: Literals; litId: LitId) =
  let i = lit.numbers[litId]
  if i > low(int32) and i <= high(int32):
    c.add $i
  elif i == low(int32):
    # Nim has the same bug for the same reasons :-)
    c.add "(-2147483647 -1)"
  elif i > low(int64):
    c.add "IL64("
    c.add $i
    c.add ")"
  else:
    c.add "(IL64(-9223372036854775807) - IL64(1))"

proc gen(c: var GeneratedCode; t: Tree; n: NodePos)

proc genProcDecl(c: var GeneratedCode; t: Tree; n: NodePos) =
  let signatureBegin = c.code.len
  let name = n.firstSon

  var prc = n.firstSon
  next t, prc

  while true:
    case t[prc].kind
    of PragmaPair:
      let (x, y) = sons2(t, prc)
      let key = cast[PragmaKey](t[x].rawOperand)
      case key
      of HeaderImport:
        let lit = t[y].litId
        let headerAsStr {.cursor.} = c.m.lit.strings[lit]
        let header = c.tokens.getOrIncl(headerAsStr)
        # headerAsStr can be empty, this has the semantics of the `nodecl` pragma:
        if headerAsStr.len > 0 and not c.includedHeaders.containsOrIncl(int header):
          if headerAsStr[0] == '#':
            discard "skip the #include"
          else:
            c.includes.add Token(IncludeKeyword)
          c.includes.add header
          c.includes.add Token NewLine
        # do not generate code for importc'ed procs:
        return
      of DllImport:
        let lit = t[y].litId
        raiseAssert "cannot eval: " & c.m.lit.strings[lit]
      else: discard
    of PragmaId: discard
    else: break
    next t, prc

  if t[prc].kind == SummonResult:
    gen c, t, prc.firstSon
    next t, prc
  else:
    c.add "void"
  c.add Space
  gen c, t, name
  c.add ParLe
  var params = 0
  while t[prc].kind == SummonParam:
    if params > 0: c.add Comma
    let (typ, sym) = sons2(t, prc)
    gen c, t, typ
    c.add Space
    gen c, t, sym
    next t, prc
    inc params
  if params == 0:
    c.add "void"
  c.add ParRi

  for i in signatureBegin ..< c.code.len:
    c.protos.add c.code[i]
  c.protos.add Token Semicolon

  c.add CurlyLe
  for ch in sonsRest(t, n, prc):
    assert t[ch].kind != ProcDecl
    gen c, t, ch
  c.add CurlyRi

template triop(opr) =
  let (typ, a, b) = sons3(t, n)
  c.add ParLe
  c.add ParLe
  gen c, t, typ
  c.add ParRi
  gen c, t, a
  c.add opr
  gen c, t, b
  c.add ParRi

template cmpop(opr) =
  let (_, a, b) = sons3(t, n)
  c.add ParLe
  gen c, t, a
  c.add opr
  gen c, t, b
  c.add ParRi

template binaryop(opr) =
  let (typ, a) = sons2(t, n)
  c.add ParLe
  c.add ParLe
  gen c, t, typ
  c.add ParRi
  c.add opr
  gen c, t, a
  c.add ParRi

template checkedBinaryop(opr) =
  let (typ, labIdx, a, b) = sons4(t, n)
  let bits = integralBits(c.m.types[t[typ].typeId])
  let lab = t[labIdx].label

  c.add (opr & $bits)
  c.add ParLe
  c.gen t, a
  c.add Comma
  c.gen t, b
  c.add Comma
  c.add "L" & $lab.int
  c.add ParRi

template moveToDataSection(body: untyped) =
  let oldLen = c.code.len
  body
  for i in oldLen ..< c.code.len:
    c.data.add c.code[i]
  setLen c.code, oldLen

proc gen(c: var GeneratedCode; t: Tree; n: NodePos) =
  case t[n].kind
  of Nop:
    discard "nothing to emit"
  of ImmediateVal:
    c.add "BUG: " & $t[n].kind
  of IntVal:
    genIntLit c, c.m.lit, t[n].litId
  of StrVal:
    c.code.add genStrLit(c, c.m.lit, t[n].litId)
  of Typed:
    genType c, c.m.types, c.m.lit, t[n].typeId
  of SymDef, SymUse:
    let s = t[n].symId
    # XXX Use proper names here
    c.add "Q"
    c.add $s

  of ModuleSymUse:
    when false:
      let (x, y) = sons2(t, n)
      let unit = c.u.unitNames.getOrDefault(bc.m.lit.strings[t[x].litId], -1)
      let s = t[y].symId
      if c.u.units[unit].procs.hasKey(s):
        bc.add info, LoadProcM, uint32 c.u.units[unit].procs[s]
      elif bc.globals.hasKey(s):
        maybeDeref(WantAddr notin flags):
          build bc, info, LoadGlobalM:
            bc.add info, ImmediateValM, uint32 unit
            bc.add info, LoadLocalM, uint32 s
      else:
        raiseAssert "don't understand ModuleSymUse ID"

    #raiseAssert "don't understand ModuleSymUse ID"
    c.add "NOT IMPLEMENTED YET"
  of NilVal:
    c.add NullPtr
  of LoopLabel:
    c.add WhileKeyword
    c.add ParLe
    c.add "1"
    c.add ParRi
    c.add CurlyLe
  of GotoLoop:
    c.add CurlyRi
  of Label:
    let lab = t[n].label
    c.add "L"
    c.add $lab.int
    c.add Colon
    c.add Semicolon
  of Goto:
    let lab = t[n].label
    c.add "goto L"
    c.add $lab.int
    c.add Semicolon
  of CheckedGoto:
    discard "XXX todo"
  of ArrayConstr:
    c.add CurlyLe
    var i = 0
    for ch in sonsFrom1(t, n):
      if i > 0: c.add Comma
      c.gen t, ch
      inc i
    c.add CurlyRi
  of ObjConstr:
    c.add CurlyLe
    var i = 0
    for ch in sonsFrom1(t, n):
      if i mod 2 == 0:
        if i > 0: c.add Comma
        c.add ".F" & $t[ch].immediateVal
        c.add AsgnOpr
      else:
        c.gen t, ch
      inc i
    c.add CurlyRi
  of Ret:
    c.add ReturnKeyword
    c.gen t, n.firstSon
    c.add Semicolon
  of Select:
    c.add SwitchKeyword
    c.add ParLe
    let (_, selector) = sons2(t, n)
    c.gen t, selector
    c.add ParRi
    c.add CurlyLe
    for ch in sonsFromN(t, n, 2):
      c.gen t, ch
    c.add CurlyRi
  of SelectPair:
    let (le, ri) = sons2(t, n)
    c.gen t, le
    c.gen t, ri
  of SelectList:
    for ch in sons(t, n):
      c.gen t, ch
  of SelectValue:
    c.add CaseKeyword
    c.gen t, n.firstSon
    c.add Colon
  of SelectRange:
    let (le, ri) = sons2(t, n)
    c.add CaseKeyword
    c.gen t, le
    c.add " ... "
    c.gen t, ri
    c.add Colon
  of SummonGlobal:
    moveToDataSection:
      let (typ, sym) = sons2(t, n)
      c.gen t, typ
      c.add Space
      c.gen t, sym
      c.add Semicolon
  of SummonThreadLocal:
    moveToDataSection:
      let (typ, sym) = sons2(t, n)
      c.add "__thread "
      c.gen t, typ
      c.add Space
      c.gen t, sym
      c.add Semicolon
  of SummonConst:
    moveToDataSection:
      let (typ, sym) = sons2(t, n)
      c.add ConstKeyword
      c.gen t, typ
      c.add Space
      c.gen t, sym
      c.add Semicolon
  of Summon:
    let (typ, sym) = sons2(t, n)
    c.gen t, typ
    c.add Space
    c.gen t, sym
    c.add Semicolon

  of SummonParam, SummonResult:
    raiseAssert "SummonParam, SummonResult should have been handled in genProc"
  of Kill:
    discard "we don't care about Kill instructions"
  of AddrOf:
    let (_, arg) = sons2(t, n)
    c.add "&"
    gen c, t, arg
  of DerefArrayAt, ArrayAt:
    let (_, a, i) = sons3(t, n)
    gen c, t, a
    c.add BracketLe
    gen c, t, i
    c.add BracketRi
  of FieldAt:
    let (_, a, b) = sons3(t, n)
    gen c, t, a
    let field = t[b].immediateVal
    c.add Dot
    c.add "F" & $field
  of DerefFieldAt:
    let (_, a, b) = sons3(t, n)
    gen c, t, a
    let field = t[b].immediateVal
    c.add Arrow
    c.add "F" & $field
  of Load:
    let (_, arg) = sons2(t, n)
    c.add ParLe
    c.add "*"
    gen c, t, arg
    c.add ParRi
  of Store:
    raiseAssert "Assumption was that Store is unused!"
  of Asgn:
    let (_, dest, src) = sons3(t, n)
    gen c, t, dest
    c.add AsgnOpr
    gen c, t, src
    c.add Semicolon
  of CheckedRange:
    c.add "nimCheckRange"
    c.add ParLe
    let (_, x, a, b) = sons4(t, n)
    gen c, t, x
    c.add Comma
    gen c, t, a
    c.add Comma
    gen c, t, b
    c.add ParRi
  of CheckedIndex:
    c.add "nimCheckIndex"
    c.add ParLe
    let (_, x, a) = sons3(t, n)
    gen c, t, x
    c.add Comma
    gen c, t, a
    c.add ParRi
  of Call, IndirectCall:
    let (typ, fn) = sons2(t, n)
    gen c, t, fn
    c.add ParLe
    for ch in sonsFromN(t, n, 2): gen c, t, ch
    c.add ParRi
    if c.m.types[t[typ].typeId].kind == VoidTy:
      c.add Semicolon
  of CheckedCall, CheckedIndirectCall:
    let (typ, gotoInstr, fn) = sons3(t, n)
    gen c, t, fn
    c.add ParLe
    for ch in sonsFromN(t, n, 3): gen c, t, ch
    c.add ParRi
    if c.m.types[t[typ].typeId].kind == VoidTy:
      c.add Semicolon

  of CheckedAdd: checkedBinaryop "nimAddInt"
  of CheckedSub: checkedBinaryop "nimSubInt"
  of CheckedMul: checkedBinaryop "nimMulInt"
  of CheckedDiv: checkedBinaryop "nimDivInt"
  of CheckedMod: checkedBinaryop "nimModInt"
  of Add: triop " + "
  of Sub: triop " - "
  of Mul: triop " * "
  of Div: triop " / "
  of Mod: triop " % "
  of BitShl: triop " << "
  of BitShr: triop " >> "
  of BitAnd: triop " & "
  of BitOr: triop " | "
  of BitXor: triop " ^ "
  of BitNot: binaryop " ~ "
  of BoolNot: binaryop " !"
  of Eq: cmpop " == "
  of Le: cmpop " <= "
  of Lt: cmpop " < "
  of Cast: binaryop ""
  of NumberConv: binaryop ""
  of CheckedObjConv: binaryop ""
  of ObjConv: binaryop ""
  of Emit: raiseAssert "cannot interpret: Emit"
  of ProcDecl: genProcDecl c, t, n
  of PragmaPair, PragmaId, TestOf, Yld, SetExc, TestExc:
    c.add "cannot interpret: " & $t[n].kind

const
  Prelude = """
/* GENERATED CODE. DO NOT EDIT. */

#define nimAddInt64(a, b, L) ({long long int res; if(__builtin_saddll_overflow(a, b, &res)) goto L; res})
#define nimSubInt64(a, b, L) ({long long int res; if(__builtin_ssubll_overflow(a, b, &res) goto L; res})
#define nimMulInt64(a, b, L) ({long long int res; if(__builtin_smulll_overflow(a, b, &res) goto L; res})

#define nimAddInt32(a, b, L) ({long int res; if(__builtin_sadd_overflow(a, b, &res) goto L; res})
#define nimSubInt32(a, b, L) ({long int res; if(__builtin_ssub_overflow(a, b, &res) goto L; res})
#define nimMulInt32(a, b, L) ({long int res; if(__builtin_smul_overflow(a, b, &res) goto L; res})

#define nimCheckRange(x, a, b, L) ({if (x < a || x > b) goto L; x})
#define nimCheckIndex(x, a, L) ({if (x >= a) goto L; x})

"""

proc main(f: string) =
  var c = initGeneratedCode(load(f))

  var co = TypeOrder()
  traverseTypes(c.m.types, c.m.lit, co)

  generateTypes(c, c.m.types, c.m.lit, co)
  let typeDecls = move c.code

  var i = NodePos(0)
  while i.int < c.m.code.len:
    gen c, c.m.code, NodePos(i)
    next c.m.code, i

  var f = CppFile(f: stdout)
  f.write Prelude
  writeTokenSeq f, c.includes, c
  writeTokenSeq f, typeDecls, c
  writeTokenSeq f, c.data, c
  writeTokenSeq f, c.protos, c
  writeTokenSeq f, c.code, c

import std / os
main paramStr(1)
