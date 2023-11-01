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
    Colon = ":"
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
    WhileKeyword = "while ("
    IfKeyword = "if ("
    ElseKeyword = "else "
    SwitchKeyword = "switch ("
    CaseKeyword = "case "
    DefaultKeyword = "default:"
    BreakKeyword = "break"
    NullPtr = "nullptr"
    IfNot = "if (!("
    ReturnKeyword = "return "
    TypedefStruct = "typedef struct "

proc fillTokenTable(tab: var BiTable[string]) =
  for e in EmptyToken..high(PredefinedToken):
    let id = tab.getOrIncl $e
    assert id == LitId(e), $(id, " ", ord(e))

type
  GeneratedCode* = object
    code: seq[LitId]
    tokens: BiTable[string]

proc initGeneratedCode*(): GeneratedCode =
  result = GeneratedCode(code: @[], tokens: initBiTable[string]())
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
    if not containsOrIncl(c.lookedAt, obj.int):
      traverseObject(types, lit, c, obj)
    if viaPointer:
      c.forwardedDecls.add obj
    else:
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
  of IntVal, SizeVal, AlignVal, OffsetVal, AnnotationVal, FieldDecl, ObjectDecl, UnionDecl:
    raiseAssert "did not expect: " & $types[t].kind

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

proc main(f: string) =
  let m = load(f)
  var c = TypeOrder()
  traverseTypes(m.types, m.lit, c)

  var g = initGeneratedCode()
  generateTypes(g, m.types, m.lit, c)

  var f = CppFile(f: stdout)
  writeTokenSeq f, g.code, g

import std / os
main paramStr(1)
