#
#
#      c2nim - C to Nimrod source converter
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements an Ansi C parser.
# It transfers a C source file into a Nimrod AST. Then the renderer can be
# used to convert the AST to its text representation.

# XXX standalone structs and unions!
# XXX header pragma for struct and union fields!
# XXX rewrite symbol export handling!

import 
  os, llstream, rnimsyn, clex, idents, strutils, pegs, ast, astalgo, msgs,
  options, strtabs

type 
  TParserFlag* = enum
    pfRefs,             ## use "ref" instead of "ptr" for C's typ*
    pfCDecl,            ## annotate procs with cdecl
    pfStdCall           ## annotate procs with stdcall
  
  TParserOptions {.final.} = object
    flags: set[TParserFlag]
    prefixes, suffixes, skipWords: seq[string]
    mangleRules: seq[tuple[pattern: TPeg, frmt: string]]
    dynlibSym, header: string
  PParserOptions* = ref TParserOptions
  
  TParser* {.final.} = object
    lex: TLexer
    tok: ref TToken       # current token
    options: PParserOptions
    backtrack: seq[ref TToken]
    inTypeDef: int
    scopeCounter: int
  
  TReplaceTuple* = array[0..1, string]

proc newParserOptions*(): PParserOptions = 
  new(result)
  result.prefixes = @[]
  result.suffixes = @[]
  result.skipWords = @[]
  result.mangleRules = @[]
  result.flags = {}
  result.dynlibSym = ""
  result.header = ""

proc setOption*(parserOptions: PParserOptions, key: string, val=""): bool = 
  result = true
  case key
  of "ref": incl(parserOptions.flags, pfRefs)
  of "dynlib": parserOptions.dynlibSym = val
  of "header": parserOptions.header = val
  of "cdecl": incl(parserOptions.flags, pfCdecl)
  of "stdcall": incl(parserOptions.flags, pfStdCall)
  of "prefix": parserOptions.prefixes.add(val)
  of "suffix": parserOptions.suffixes.add(val)
  of "skip": parserOptions.skipWords.add(val)
  else: result = false

proc ParseUnit*(p: var TParser): PNode
proc openParser*(p: var TParser, filename: string, inputStream: PLLStream,
                 options = newParserOptions())
proc closeParser*(p: var TParser)
proc exSymbol*(n: var PNode)
proc fixRecordDef*(n: var PNode)
  # XXX: move these two to an auxiliary module

# implementation

proc OpenParser(p: var TParser, filename: string, 
                inputStream: PLLStream, options = newParserOptions()) = 
  OpenLexer(p.lex, filename, inputStream)
  p.options = options
  p.backtrack = @[]
  new(p.tok)
  
proc CloseParser(p: var TParser) = CloseLexer(p.lex)
proc safeContext(p: var TParser) = p.backtrack.add(p.tok)
proc closeContext(p: var TParser) = discard p.backtrack.pop()
proc backtrackContext(p: var TParser) = p.tok = p.backtrack.pop()

proc rawGetTok(p: var TParser) = 
  if p.tok.next != nil:
    p.tok = p.tok.next
  elif p.backtrack.len == 0: 
    p.tok.next = nil
    getTok(p.lex, p.tok^)
  else: 
    # We need the next token and must be able to backtrack. So we need to 
    # allocate a new token.
    var t: ref TToken
    new(t)
    getTok(p.lex, t^)
    p.tok.next = t
    p.tok = t

proc isSkipWord(p: TParser): bool =
  for s in items(p.options.skipWords):
    if p.tok.s == s: return true

proc getTok(p: var TParser) = 
  while true:
    rawGetTok(p)
    if p.tok.xkind != pxSymbol or not isSkipWord(p): break

proc parMessage(p: TParser, msg: TMsgKind, arg = "") = 
  #assert false
  lexMessage(p.lex, msg, arg)

proc parLineInfo(p: TParser): TLineInfo = 
  result = getLineInfo(p.lex)

proc skipCom(p: var TParser, n: PNode) = 
  while p.tok.xkind in {pxLineComment, pxStarComment}: 
    if (n != nil): 
      if n.comment == nil: n.comment = p.tok.s
      else: add(n.comment, "\n" & p.tok.s)
    else: 
      parMessage(p, warnCommentXIgnored, p.tok.s)
    getTok(p)

proc skipStarCom(p: var TParser, n: PNode) = 
  while p.tok.xkind == pxStarComment: 
    if (n != nil): 
      if n.comment == nil: n.comment = p.tok.s
      else: add(n.comment, "\n" & p.tok.s)
    else: 
      parMessage(p, warnCommentXIgnored, p.tok.s)
    getTok(p)

proc getTok(p: var TParser, n: PNode) =
  getTok(p)
  skipCom(p, n)

proc ExpectIdent(p: TParser) = 
  if p.tok.xkind != pxSymbol: 
    parMessage(p, errIdentifierExpected, $(p.tok^))
  
proc Eat(p: var TParser, xkind: TTokKind, n: PNode) = 
  if p.tok.xkind == xkind: getTok(p, n)
  else: parMessage(p, errTokenExpected, TokKindToStr(xkind))
  
proc Eat(p: var TParser, xkind: TTokKind) = 
  if p.tok.xkind == xkind: getTok(p)
  else: parMessage(p, errTokenExpected, TokKindToStr(xkind))
  
proc Eat(p: var TParser, tok: string, n: PNode) = 
  if p.tok.s == tok: getTok(p, n)
  else: parMessage(p, errTokenExpected, tok)
  
proc Opt(p: var TParser, xkind: TTokKind, n: PNode) = 
  if p.tok.xkind == xkind: getTok(p, n)
  
proc addSon(father, a, b: PNode) = 
  addSon(father, a)
  addSon(father, b)

proc addSon(father, a, b, c: PNode) = 
  addSon(father, a)
  addSon(father, b)
  addSon(father, c)
  
proc newNodeP(kind: TNodeKind, p: TParser): PNode = 
  result = newNodeI(kind, getLineInfo(p.lex))

proc newIntNodeP(kind: TNodeKind, intVal: BiggestInt, p: TParser): PNode = 
  result = newNodeP(kind, p)
  result.intVal = intVal

proc newFloatNodeP(kind: TNodeKind, floatVal: BiggestFloat, 
                   p: TParser): PNode = 
  result = newNodeP(kind, p)
  result.floatVal = floatVal

proc newStrNodeP(kind: TNodeKind, strVal: string, p: TParser): PNode = 
  result = newNodeP(kind, p)
  result.strVal = strVal

proc newIdentNodeP(ident: PIdent, p: TParser): PNode = 
  result = newNodeP(nkIdent, p)
  result.ident = ident

proc newIdentNodeP(ident: string, p: TParser): PNode =
  result = newIdentNodeP(getIdent(ident), p)

proc mangleName(s: string, p: TParser): string = 
  for pattern, frmt in items(p.options.mangleRules):
    if s.match(pattern):
      return s.replace(pattern, frmt)
  block prefixes:
    for prefix in items(p.options.prefixes): 
      if s.startsWith(prefix): 
        result = s.copy(prefix.len)
        break prefixes
    result = s
  for suffix in items(p.options.suffixes):
    if result.endsWith(suffix):
      setLen(result, result.len - suffix.len)
      break

proc mangledIdent(ident: string, p: TParser): PNode = 
  result = newNodeP(nkIdent, p)
  result.ident = getIdent(mangleName(ident, p))

proc newIdentPair(a, b: string, p: TParser): PNode = 
  result = newNodeP(nkExprColonExpr, p)
  addSon(result, newIdentNodeP(a, p))
  addSon(result, newIdentNodeP(b, p))

proc newIdentStrLitPair(a, b: string, p: TParser): PNode =
  result = newNodeP(nkExprColonExpr, p)
  addSon(result, newIdentNodeP(a, p))
  addSon(result, newStrNodeP(nkStrLit, b, p))

proc addImportToPragma(pragmas: PNode, ident: string, p: TParser) =
  addSon(pragmas, newIdentStrLitPair("importc", ident, p))
  if p.options.dynlibSym.len > 0:
    addSon(pragmas, newIdentPair("dynlib", p.options.dynlibSym, p))
  else:
    addSon(pragmas, newIdentStrLitPair("header", p.options.header, p))

proc mangledIdentAndImport(ident: string, p: TParser): PNode = 
  result = mangledIdent(ident, p)
  if p.scopeCounter > 0: return
  if p.options.dynlibSym.len > 0 or p.options.header.len > 0: 
    var a = result
    result = newNodeP(nkPragmaExpr, p)
    var pragmas = newNodeP(nkPragma, p)
    addSon(result, a)
    addSon(result, pragmas)
    addImportToPragma(pragmas, ident, p)

proc DoImport(ident: string, pragmas: PNode, p: TParser) = 
  if p.options.dynlibSym.len > 0 or p.options.header.len > 0: 
    addImportToPragma(pragmas, ident, p)

proc newBinary(opr: string, a, b: PNode, p: TParser): PNode =
  result = newNodeP(nkInfix, p)
  addSon(result, newIdentNodeP(getIdent(opr), p))
  addSon(result, a)
  addSon(result, b)
  
# --------------- symbol exporter --------------------------------------------

proc identVis(p: var TParser): PNode = 
  # identifier with visability
  var a = mangledIdent(p.tok.s, p)
  result = newNodeP(nkPostfix, p)
  addSon(result, newIdentNodeP("*", p))
  addSon(result, a)
  getTok(p)

proc exSymbol(n: var PNode) = 
  case n.kind
  of nkPostfix: 
    nil
  of nkPragmaExpr: 
    exSymbol(n.sons[0])
  of nkIdent, nkAccQuoted: 
    var a = newNodeI(nkPostFix, n.info)
    addSon(a, newIdentNode(getIdent("*"), n.info))
    addSon(a, n)
    n = a
  else: internalError(n.info, "exSymbol(): " & $n.kind)
  
proc fixRecordDef(n: var PNode) = 
  if n == nil: return 
  case n.kind
  of nkRecCase: 
    fixRecordDef(n.sons[0])
    for i in countup(1, sonsLen(n) - 1): 
      var length = sonsLen(n.sons[i])
      fixRecordDef(n.sons[i].sons[length - 1])
  of nkRecList, nkRecWhen, nkElse, nkOfBranch, nkElifBranch, nkObjectTy: 
    for i in countup(0, sonsLen(n) - 1): fixRecordDef(n.sons[i])
  of nkIdentDefs: 
    for i in countup(0, sonsLen(n) - 3): exSymbol(n.sons[i])
  of nkNilLit: nil
  else: internalError(n.info, "fixRecordDef(): " & $n.kind)
  
proc addPragmaToIdent(ident: var PNode, pragma: PNode) = 
  var pragmasNode: PNode
  if ident.kind != nkPragmaExpr: 
    pragmasNode = newNodeI(nkPragma, ident.info)
    var e = newNodeI(nkPragmaExpr, ident.info)
    addSon(e, ident)
    addSon(e, pragmasNode)
    ident = e
  else: 
    pragmasNode = ident.sons[1]
    if pragmasNode.kind != nkPragma: 
      InternalError(ident.info, "addPragmaToIdent")
  addSon(pragmasNode, pragma)
  
proc exSymbols(n: PNode) = 
  if n == nil: return 
  case n.kind
  of nkEmpty..nkNilLit: nil
  of nkProcDef..nkIteratorDef: exSymbol(n.sons[namePos])
  of nkWhenStmt:
    for i in countup(0, sonsLen(n) - 1): exSymbols(lastSon(n.sons[i]))
  of nkStmtList: 
    for i in countup(0, sonsLen(n) - 1): exSymbols(n.sons[i])
  of nkVarSection, nkConstSection: 
    for i in countup(0, sonsLen(n) - 1): exSymbol(n.sons[i].sons[0])
  of nkTypeSection: 
    for i in countup(0, sonsLen(n) - 1): 
      exSymbol(n.sons[i].sons[0])
      if (n.sons[i].sons[2] != nil) and
          (n.sons[i].sons[2].kind == nkObjectTy): 
        fixRecordDef(n.sons[i].sons[2])
  else: nil
  
# --------------- parser -----------------------------------------------------
# We use this parsing rule: If it looks like a declaration, it is one. This
# avoids to build a symbol table, which can't be done reliably anyway for our
# purposes.

proc expression(p: var TParser): PNode
proc constantExpression(p: var TParser): PNode
proc assignmentExpression(p: var TParser): PNode
proc compoundStatement(p: var TParser): PNode
proc statement(p: var TParser): PNode

proc declKeyword(s: string): bool = 
  # returns true if it is a keyword that introduces a declaration
  case s
  of  "extern", "static", "auto", "register", "const", "volatile", "restrict",
      "inline", "__inline", "__cdecl", "__stdcall", "__syscall", "__fastcall",
      "__safecall", "void", "struct", "union", "enum", "typedef",
      "short", "int", "long", "float", "double", "signed", "unsigned", "char": 
    result = true

proc stmtKeyword(s: string): bool =
  case s
  of  "if", "for", "while", "do", "switch", "break", "continue", "return",
      "goto":
    result = true

# ------------------- type desc -----------------------------------------------

proc skipIdent(p: var TParser): PNode = 
  expectIdent(p)
  result = mangledIdent(p.tok.s, p)
  getTok(p, result)

proc isIntType(s: string): bool =
  case s
  of "short", "int", "long", "float", "double", "signed", "unsigned":
    result = true

proc skipConst(p: var TParser) = 
  while p.tok.xkind == pxSymbol and
      (p.tok.s == "const" or p.tok.s == "volatile" or p.tok.s == "restrict"): 
    getTok(p, nil)

proc typeAtom(p: var TParser): PNode = 
  if p.tok.xkind != pxSymbol: return nil
  skipConst(p)
  ExpectIdent(p)
  case p.tok.s
  of "void": 
    result = newNodeP(nkNilLit, p) # little hack
    getTok(p, nil)
  of "struct", "union", "enum": 
    getTok(p, nil)
    result = skipIdent(p)
  elif isIntType(p.tok.s):
    var x = "c" & p.tok.s
    getTok(p, nil)
    while p.tok.xkind == pxSymbol and (isIntType(p.tok.s) or p.tok.s == "char"):
      add(x, p.tok.s)
      getTok(p, nil)
    result = newIdentNodeP(x, p)
  else: 
    result = newIdentNodeP(p.tok.s, p)
    getTok(p, result)
    
proc newPointerTy(p: TParser, typ: PNode): PNode =
  if pfRefs in p.options.flags: 
    result = newNodeP(nkRefTy, p)
  else:
    result = newNodeP(nkPtrTy, p)
  result.addSon(typ)
  
proc pointer(p: var TParser, a: PNode): PNode = 
  result = a
  var i = 0
  skipConst(p)
  while p.tok.xkind == pxStar:
    inc(i)
    getTok(p, result)
    skipConst(p)
    result = newPointerTy(p, result)
  if a.kind == nkIdent and a.ident.s == "char": 
    if i >= 2: 
      result = newIdentNodeP("cstringArray", p)
      for j in 1..i-2: result = newPointerTy(p, result)
    elif i == 1: result = newIdentNodeP("cstring", p)
  elif a.kind == nkNilLit and i > 0:
    result = newIdentNodeP("pointer", p)
    for j in 1..i-1: result = newPointerTy(p, result)

proc parseTypeSuffix(p: var TParser, typ: PNode): PNode = 
  result = typ
  while p.tok.xkind == pxBracketLe:
    getTok(p, result)
    skipConst(p) # POSIX contains: ``int [restrict]``
    if p.tok.xkind != pxBracketRi:
      var tmp = result
      var index = expression(p)
      # array type:
      result = newNodeP(nkBracketExpr, p)
      addSon(result, newIdentNodeP("array", p))
      var r = newNodeP(nkRange, p)
      addSon(r, newIntNodeP(nkIntLit, 0, p))
      addSon(r, newBinary("-", index, newIntNodeP(nkIntLit, 1, p), p))
      addSon(result, r)
      addSon(result, tmp)
    else:
      # pointer type:
      var tmp = result
      if pfRefs in p.options.flags: 
        result = newNodeP(nkRefTy, p)
      else:
        result = newNodeP(nkPtrTy, p)
      result.addSon(tmp)
    eat(p, pxBracketRi, result)

proc typeDesc(p: var TParser): PNode = 
  result = typeAtom(p)
  if result != nil:
    result = pointer(p, result)

proc parseStructBody(p: var TParser): PNode = 
  result = newNodeP(nkRecList, p)
  eat(p, pxCurlyLe, result)
  while p.tok.xkind notin {pxEof, pxCurlyRi}:
    var baseTyp = typeAtom(p)
    while true:
      var def = newNodeP(nkIdentDefs, p)
      var t = pointer(p, baseTyp)
      var i = skipIdent(p)
      t = parseTypeSuffix(p, t)
      addSon(def, i, t, nil)
      addSon(result, def)
      if p.tok.xkind != pxComma: break
      getTok(p, def)
    eat(p, pxSemicolon, lastSon(result))
  eat(p, pxCurlyRi, result)

proc structPragmas(p: TParser, name: PNode): PNode = 
  result = newNodeP(nkPragmaExpr, p)
  addson(result, name)
  var pragmas = newNodep(nkPragma, p)
  addSon(pragmas, newIdentNodeP("pure", p))
  addSon(pragmas, newIdentNodeP("final", p))
  addSon(result, pragmas)

proc enumPragmas(p: TParser, name: PNode): PNode =
  result = newNodeP(nkPragmaExpr, p)
  addson(result, name)
  var pragmas = newNodep(nkPragma, p)
  var e = newNodeP(nkExprColonExpr, p)
  addSon(e, newIdentNodeP("size", p))
  addSon(e, newIntNodeP(nkIntLit, 4, p))
  addSon(pragmas, e)
  addSon(result, pragmas)

proc parseStruct(p: var TParser): PNode = 
  result = newNodeP(nkObjectTy, p)
  addSon(result, nil) # no pragmas
  addSon(result, nil) # no inheritance
  if p.tok.xkind == pxCurlyLe:
    addSon(result, parseStructBody(p))
  else: 
    addSon(result, newNodeP(nkRecList, p))

proc parseParam(p: var TParser, params: PNode) = 
  var typ = typeDesc(p)
  # support for ``(void)`` parameter list: 
  if typ.kind == nkNilLit and p.tok.xkind == pxParRi: return
  var name: PNode
  if p.tok.xkind == pxSymbol: 
    name = skipIdent(p)
  else:
    # generate a name for the formal parameter:
    var idx = sonsLen(params)+1
    name = newIdentNodeP("a" & $idx, p)
  typ = parseTypeSuffix(p, typ)
  var x = newNodeP(nkIdentDefs, p)
  addSon(x, name)
  addSon(x, typ)
  if p.tok.xkind == pxAsgn: 
    # we support default parameters for C++:
    getTok(p, x)
    addSon(x, assignmentExpression(p))
  else:
    addSon(x, nil)
  addSon(params, x)

proc parseFormalParams(p: var TParser, params, pragmas: PNode) = 
  eat(p, pxParLe, params)
  while p.tok.xkind notin {pxEof, pxParRi}:
    if p.tok.xkind == pxDotDotDot:  
      addSon(pragmas, newIdentNodeP("varargs", p))
      getTok(p, pragmas)
      break
    parseParam(p, params)
    if p.tok.xkind != pxComma: break
    getTok(p, params)
  eat(p, pxParRi, params)

proc parseCallConv(p: var TParser, pragmas: PNode) = 
  while p.tok.xkind == pxSymbol:
    case p.tok.s
    of "inline", "__inline": addSon(pragmas, newIdentNodeP("inline", p))
    of "__cdecl": addSon(pragmas, newIdentNodeP("cdecl", p))
    of "__stdcall": addSon(pragmas, newIdentNodeP("stdcall", p))
    of "__syscall": addSon(pragmas, newIdentNodeP("syscall", p))
    of "__fastcall": addSon(pragmas, newIdentNodeP("fastcall", p))
    of "__safecall": addSon(pragmas, newIdentNodeP("safecall", p))
    else: break
    getTok(p, nil)

proc parseFunctionPointerDecl(p: var TParser, rettyp: PNode): PNode = 
  var procType = newNodeP(nkProcTy, p)
  var pragmas = newNodeP(nkPragma, p)
  if pfCDecl in p.options.flags: 
    addSon(pragmas, newIdentNodeP("cdecl", p))
  elif pfStdCall in p.options.flags:
    addSon(pragmas, newIdentNodeP("stdcall", p))
  var params = newNodeP(nkFormalParams, p)
  eat(p, pxParLe, params)
  addSon(params, rettyp)
  parseCallConv(p, pragmas)
  if p.tok.xkind == pxStar: getTok(p, params)
  else: parMessage(p, errTokenExpected, "*")
  var name = skipIdent(p)
  eat(p, pxParRi, name)
  parseFormalParams(p, params, pragmas)
  addSon(procType, params)
  addSon(procType, pragmas)
  
  if p.inTypeDef == 0:
    result = newNodeP(nkVarSection, p)
    var def = newNodeP(nkIdentDefs, p)
    addSon(def, name)
    addSon(def, procType)
    addSon(def, nil)
    addSon(result, def)    
  else:
    result = newNodeP(nkTypeDef, p)
    addSon(result, name)
    addSon(result, nil) # no generics
    addSon(result, procType)
  
proc addTypeDef(section, name, t: PNode) = 
  var def = newNodeI(nkTypeDef, name.info)
  addSon(def, name, nil, t)
  addSon(section, def)
  
proc otherTypeDef(p: var TParser, section, typ: PNode) = 
  var name, t: PNode
  case p.tok.xkind
  of pxParLe: 
    # function pointer: typedef typ (*name)();
    getTok(p, nil)
    var x = parseFunctionPointerDecl(p, typ)
    name = x[0]
    t = x[2]
  of pxStar:
    # typedef typ *b;
    t = pointer(p, typ)
    name = skipIdent(p)
  else: 
    # typedef typ name;
    t = typ
    name = skipIdent(p)
  t = parseTypeSuffix(p, t)
  addTypeDef(section, name, t)

proc parseTrailingDefinedTypes(p: var TParser, section, typ: PNode) = 
  while p.tok.xkind == pxComma:
    getTok(p, nil)
    var newTyp = pointer(p, typ)
    var newName = skipIdent(p)
    newTyp = parseTypeSuffix(p, newTyp)
    addTypeDef(section, newName, newTyp)

proc enumFields(p: var TParser): PNode = 
  result = newNodeP(nkEnumTy, p)
  addSon(result, nil) # enum does not inherit from anything
  while true:
    var e = skipIdent(p)
    if p.tok.xkind == pxAsgn: 
      getTok(p, e)
      var c = constantExpression(p)
      var a = e
      e = newNodeP(nkEnumFieldDef, p)
      addSon(e, a)
      addSon(e, c)
      skipCom(p, e)
    
    addSon(result, e)
    if p.tok.xkind != pxComma: break
    getTok(p, e)

proc parseTypeDef(p: var TParser): PNode =  
  result = newNodeP(nkTypeSection, p)
  while p.tok.xkind == pxSymbol and p.tok.s == "typedef":
    getTok(p, result)
    inc(p.inTypeDef)
    expectIdent(p)
    case p.tok.s
    of "struct", "union": 
      getTok(p, result)
      if p.tok.xkind == pxCurlyLe:
        var t = parseStruct(p)
        var name = skipIdent(p)
        addTypeDef(result, structPragmas(p, name), t)
        parseTrailingDefinedTypes(p, result, name)
      elif p.tok.xkind == pxSymbol: 
        # name to be defined or type "struct a", we don't know yet:
        var nameOrType = skipIdent(p)
        case p.tok.xkind 
        of pxCurlyLe:
          var t = parseStruct(p)
          if p.tok.xkind == pxSymbol: 
            # typedef struct tagABC {} abc, *pabc;
            # --> abc is a better type name than tagABC!
            var name = skipIdent(p)
            addTypeDef(result, structPragmas(p, name), t)
            parseTrailingDefinedTypes(p, result, name)
          else:
            addTypeDef(result, structPragmas(p, nameOrType), t)
        of pxSymbol: 
          # typedef struct a a?
          if mangleName(p.tok.s, p) == nameOrType.ident.s:
            # ignore the declaration:
            getTok(p, nil)
          else:
            # typedef struct a b; or typedef struct a b[45];
            otherTypeDef(p, result, nameOrType)
        else: 
          otherTypeDef(p, result, nameOrType)
      else:
        expectIdent(p)
    of "enum": 
      getTok(p, result)
      if p.tok.xkind == pxCurlyLe:
        getTok(p, result)
        var t = enumFields(p)
        eat(p, pxCurlyRi, t)
        var name = skipIdent(p)
        addTypeDef(result, enumPragmas(p, name), t)
        parseTrailingDefinedTypes(p, result, name)
      elif p.tok.xkind == pxSymbol: 
        # name to be defined or type "enum a", we don't know yet:
        var nameOrType = skipIdent(p)
        case p.tok.xkind 
        of pxCurlyLe:
          getTok(p, result)
          var t = enumFields(p)
          eat(p, pxCurlyRi, t)
          if p.tok.xkind == pxSymbol: 
            # typedef enum tagABC {} abc, *pabc;
            # --> abc is a better type name than tagABC!
            var name = skipIdent(p)
            addTypeDef(result, enumPragmas(p, name), t)
            parseTrailingDefinedTypes(p, result, name)
          else:
            addTypeDef(result, enumPragmas(p, nameOrType), t)
        of pxSymbol: 
          # typedef enum a a?
          if mangleName(p.tok.s, p) == nameOrType.ident.s:
            # ignore the declaration:
            getTok(p, nil)
          else:
            # typedef enum a b; or typedef enum a b[45];
            otherTypeDef(p, result, nameOrType)
        else: 
          otherTypeDef(p, result, nameOrType)
      else:
        expectIdent(p)
    else: 
      var t = typeAtom(p)
      otherTypeDef(p, result, t)
    
    eat(p, pxSemicolon)
    dec(p.inTypeDef)
    
proc skipDeclarationSpecifiers(p: var TParser) =
  while p.tok.xkind == pxSymbol:
    case p.tok.s
    of "extern", "static", "auto", "register", "const", "volatile": 
      getTok(p, nil)
    else: break

proc parseInitializer(p: var TParser): PNode = 
  if p.tok.xkind == pxCurlyLe: 
    result = newNodeP(nkBracket, p)
    getTok(p, result)
    while p.tok.xkind notin {pxEof, pxCurlyRi}: 
      addSon(result, parseInitializer(p))
      opt(p, pxComma, nil)
    eat(p, pxCurlyRi, result)
  else:
    result = assignmentExpression(p)

proc addInitializer(p: var TParser, def: PNode) = 
  if p.tok.xkind == pxAsgn:
    getTok(p, def)
    addSon(def, parseInitializer(p))
  else:
    addSon(def, nil)  

proc parseVarDecl(p: var TParser, baseTyp, typ: PNode, 
                  origName: string): PNode =  
  result = newNodeP(nkVarSection, p)
  var def = newNodeP(nkIdentDefs, p)
  addSon(def, mangledIdentAndImport(origName, p))
  addSon(def, parseTypeSuffix(p, typ))
  addInitializer(p, def)
  addSon(result, def)
    
  while p.tok.xkind == pxComma: 
    getTok(p, def)
    var t = pointer(p, baseTyp)
    expectIdent(p)
    def = newNodeP(nkIdentDefs, p)
    addSon(def, mangledIdentAndImport(p.tok.s, p))
    getTok(p, def)
    addSon(def, parseTypeSuffix(p, t))
    addInitializer(p, def)
    addSon(result, def)
  eat(p, pxSemicolon, result)

proc declaration(p: var TParser): PNode = 
  result = newNodeP(nkProcDef, p)
  var pragmas = newNodeP(nkPragma, p)
  
  skipDeclarationSpecifiers(p)
  parseCallConv(p, pragmas)
  skipDeclarationSpecifiers(p)
  expectIdent(p)
  var baseTyp = typeAtom(p)
  var rettyp = pointer(p, baseTyp)
  if rettyp != nil and rettyp.kind == nkNilLit: rettyp = nil
  skipDeclarationSpecifiers(p)
  parseCallConv(p, pragmas)
  skipDeclarationSpecifiers(p)
  
  if p.tok.xkind == pxParLe: 
    # Function pointer declaration: This is of course only a heuristic, but the
    # best we can do here.
    result = parseFunctionPointerDecl(p, rettyp)
    eat(p, pxSemicolon, result)
    return
  ExpectIdent(p)
  var origName = p.tok.s
  getTok(p) # skip identifier
  case p.tok.xkind 
  of pxParLe: 
    # really a function!
    var name = mangledIdent(origName, p)
    var params = newNodeP(nkFormalParams, p)
    addSon(params, rettyp)
    parseFormalParams(p, params, pragmas)
    
    if pfCDecl in p.options.flags:
      addSon(pragmas, newIdentNodeP("cdecl", p))
    elif pfStdcall in p.options.flags:
      addSon(pragmas, newIdentNodeP("stdcall", p))
    addSon(result, name)
    addSon(result, nil) # no generics
    addSon(result, params)
    addSon(result, pragmas)
    case p.tok.xkind 
    of pxSemicolon: 
      getTok(p)
      addSon(result, nil) # nobody
      if p.scopeCounter == 0: DoImport(origName, pragmas, p)
    of pxCurlyLe:
      addSon(result, compoundStatement(p))
    else:
      parMessage(p, errTokenExpected, ";")
    if sonsLen(result.sons[pragmasPos]) == 0: result.sons[pragmasPos] = nil
  of pxAsgn, pxSemicolon, pxComma:
    result = parseVarDecl(p, baseTyp, rettyp, origName)
  else:
    parMessage(p, errTokenExpected, ";")

proc createConst(name, typ, val: PNode, p: TParser): PNode =
  result = newNodeP(nkConstDef, p)
  addSon(result, name, typ, val)

proc enumSpecifier(p: var TParser): PNode =  
  getTok(p, nil) # skip "enum"
  case p.tok.xkind
  of pxCurlyLe: 
    # make a const section out of it:
    result = newNodeP(nkConstSection, p)
    getTok(p, result)
    var i = 0
    while true:
      var name = skipIdent(p)
      var val: PNode
      if p.tok.xkind == pxAsgn: 
        getTok(p, name)
        val = constantExpression(p)
        if val.kind == nkIntLit: i = int(val.intVal)+1
        else: parMessage(p, errXExpected, "int literal")
      else:
        val = newIntNodeP(nkIntLit, i, p)
        inc(i)
      var c = createConst(name, nil, val, p)
      addSon(result, c)
      if p.tok.xkind != pxComma: break
      getTok(p, c)
    eat(p, pxCurlyRi, result)
    eat(p, pxSemicolon)
  of pxSymbol: 
    result = skipIdent(p)
    if p.tok.xkind == pxCurlyLe: 
      var name = result
      # create a type section containing the enum
      result = newNodeP(nkTypeSection, p)
      var t = newNodeP(nkTypeDef, p)
      getTok(p, t)
      var e = enumFields(p)
      addSon(t, name, nil, e) # nil for generic params
      addSon(result, t)
  else:
    parMessage(p, errTokenExpected, "{")
    
# Expressions

proc setBaseFlags(n: PNode, base: TNumericalBase) = 
  case base
  of base10: nil
  of base2: incl(n.flags, nfBase2)
  of base8: incl(n.flags, nfBase8)
  of base16: incl(n.flags, nfBase16)
  
proc primaryExpression(p: var TParser): PNode = 
  case p.tok.xkind
  of pxSymbol: 
    if p.tok.s == "NULL": 
      result = newNodeP(nkNilLit, p)
    else: 
      result = mangledIdent(p.tok.s, p)
    getTok(p, result)
  of pxIntLit: 
    result = newIntNodeP(nkIntLit, p.tok.iNumber, p)
    setBaseFlags(result, p.tok.base)
    getTok(p, result)
  of pxInt64Lit: 
    result = newIntNodeP(nkInt64Lit, p.tok.iNumber, p)
    setBaseFlags(result, p.tok.base)
    getTok(p, result)
  of pxFloatLit: 
    result = newFloatNodeP(nkFloatLit, p.tok.fNumber, p)
    setBaseFlags(result, p.tok.base)
    getTok(p, result)
  of pxStrLit: 
    # Ansi C allows implicit string literal concatenations:
    result = newStrNodeP(nkStrLit, p.tok.s, p)
    getTok(p, result)
    while p.tok.xkind == pxStrLit:
      add(result.strVal, p.tok.s)
      getTok(p, result)
  of pxCharLit:
    result = newIntNodeP(nkCharLit, ord(p.tok.s[0]), p)
    getTok(p, result)
  of pxParLe:
    result = newNodeP(nkPar, p)
    getTok(p, result)
    addSon(result, expression(p))
    eat(p, pxParRi, result)
  else:
    result = nil

proc unaryExpression(p: var TParser): PNode
proc castExpression(p: var TParser): PNode = 
  if p.tok.xkind == pxParLe: 
    SafeContext(p)
    result = newNodeP(nkCast, p)
    getTok(p, result)
    var a = typeDesc(p)
    if a != nil and p.tok.xkind == pxParRi: 
      closeContext(p)
      eat(p, pxParRi, result)
      addSon(result, a)
      addSon(result, castExpression(p))
    else: 
      backtrackContext(p)
      result = unaryExpression(p)
  else:
    result = unaryExpression(p)

proc multiplicativeExpression(p: var TParser): PNode = 
  result = castExpression(p)
  while true:
    case p.tok.xkind
    of pxStar:
      var a = result
      result = newNodeP(nkInfix, p)
      addSon(result, newIdentNodeP("*", p), a)
      getTok(p, result)
      var b = castExpression(p)
      addSon(result, b)
    of pxSlash:
      var a = result
      result = newNodeP(nkInfix, p)
      addSon(result, newIdentNodeP("div", p), a)
      getTok(p, result)
      var b = castExpression(p)
      addSon(result, b)
    of pxMod:
      var a = result
      result = newNodeP(nkInfix, p)
      addSon(result, newIdentNodeP("mod", p), a)
      getTok(p, result)
      var b = castExpression(p)
      addSon(result, b)
    else: break 

proc additiveExpression(p: var TParser): PNode = 
  result = multiplicativeExpression(p)
  while true:
    case p.tok.xkind
    of pxPlus:
      var a = result
      result = newNodeP(nkInfix, p)
      addSon(result, newIdentNodeP("+", p), a)
      getTok(p, result)
      var b = multiplicativeExpression(p)
      addSon(result, b)
    of pxMinus:
      var a = result
      result = newNodeP(nkInfix, p)
      addSon(result, newIdentNodeP("-", p), a)
      getTok(p, result)
      var b = multiplicativeExpression(p)
      addSon(result, b)
    else: break 
  
proc incdec(p: var TParser, opr: string): PNode = 
  result = newNodeP(nkCall, p)
  addSon(result, newIdentNodeP(opr, p))
  gettok(p, result)
  addSon(result, unaryExpression(p))

proc unaryOp(p: var TParser, kind: TNodeKind): PNode = 
  result = newNodeP(kind, p)
  getTok(p, result)
  addSon(result, castExpression(p))

proc prefixCall(p: var TParser, opr: string): PNode = 
  result = newNodeP(nkPrefix, p)
  addSon(result, newIdentNodeP(opr, p))
  gettok(p, result)
  addSon(result, castExpression(p))

proc postfixExpression(p: var TParser): PNode = 
  result = primaryExpression(p)
  while true:
    case p.tok.xkind
    of pxBracketLe:
      var a = result
      result = newNodeP(nkBracketExpr, p)
      addSon(result, a)
      getTok(p, result)
      var b = expression(p)
      addSon(result, b)
      eat(p, pxBracketRi, result)
    of pxParLe:
      var a = result
      result = newNodeP(nkCall, p)
      addSon(result, a)
      getTok(p, result)
      if p.tok.xkind != pxParRi:
        a = assignmentExpression(p)
        addSon(result, a)
        while p.tok.xkind == pxComma:
          getTok(p, a)
          a = assignmentExpression(p)
          addSon(result, a)
      eat(p, pxParRi, result)
    of pxDot, pxArrow:
      var a = result
      result = newNodeP(nkDotExpr, p)
      addSon(result, a)
      getTok(p, result)
      addSon(result, skipIdent(p))
    of pxPlusPlus:
      var a = result
      result = newNodeP(nkCall, p)
      addSon(result, newIdentNodeP("inc", p))
      gettok(p, result)
      addSon(result, a)
    of pxMinusMinus:
      var a = result
      result = newNodeP(nkCall, p)
      addSon(result, newIdentNodeP("dec", p))
      gettok(p, result)
      addSon(result, a)
    else: break

proc unaryExpression(p: var TParser): PNode =
  case p.tok.xkind
  of pxPlusPlus: result = incdec(p, "inc")
  of pxMinusMinus: result = incdec(p, "dec")
  of pxAmp: result = unaryOp(p, nkAddr)
  of pxStar: result = unaryOp(p, nkDerefExpr)
  of pxPlus: result = prefixCall(p, "+")
  of pxMinus: result = prefixCall(p, "-")
  of pxTilde: result = prefixCall(p, "not")
  of pxNot: result = prefixCall(p, "not")
  of pxSymbol:
    if p.tok.s == "sizeof": 
      result = newNodeP(nkCall, p)
      addSon(result, newIdentNodeP("sizeof", p))
      getTok(p, result)
      if p.tok.xkind == pxParLe: 
        getTok(p, result)
        addson(result, typeDesc(p))
        eat(p, pxParRi, result)
      else:
        addSon(result, unaryExpression(p))
    else:
      result = postfixExpression(p)
  else: result = postfixExpression(p)

proc expression(p: var TParser): PNode = 
  # we cannot support C's ``,`` operator
  result = assignmentExpression(p)
  if p.tok.xkind == pxComma:
    getTok(p, result)
    parMessage(p, errOperatorExpected, ",")
    
proc conditionalExpression(p: var TParser): PNode

proc constantExpression(p: var TParser): PNode = 
  result = conditionalExpression(p)

proc lvalue(p: var TParser): PNode = 
  result = unaryExpression(p)

proc asgnExpr(p: var TParser, opr: string, a: PNode): PNode = 
  closeContext(p)
  getTok(p, a)
  var b = assignmentExpression(p)
  result = newNodeP(nkAsgn, p)
  addSon(result, a)
  addSon(result, newBinary(opr, copyTree(a), b, p))
  
proc incdec(p: var TParser, opr: string, a: PNode): PNode =
  closeContext(p)
  getTok(p, a)
  var b = assignmentExpression(p)
  result = newNodeP(nkCall, p)
  addSon(result, newIdentNodeP(getIdent(opr), p))
  addSon(result, a)
  addSon(result, b)
  
proc assignmentExpression(p: var TParser): PNode = 
  safeContext(p)
  var a = lvalue(p)
  case p.tok.xkind 
  of pxAsgn:
    closeContext(p)
    getTok(p, a)
    var b = assignmentExpression(p)
    result = newNodeP(nkAsgn, p)
    addSon(result, a)
    addSon(result, b)
  of pxPlusAsgn: result = incDec(p, "inc", a)    
  of pxMinusAsgn: result = incDec(p, "dec", a)
  of pxStarAsgn: result = asgnExpr(p, "*", a)
  of pxSlashAsgn: result = asgnExpr(p, "/", a)
  of pxModAsgn: result = asgnExpr(p, "mod", a)
  of pxShlAsgn: result = asgnExpr(p, "shl", a)
  of pxShrAsgn: result = asgnExpr(p, "shr", a)
  of pxAmpAsgn: result = asgnExpr(p, "and", a)
  of pxHatAsgn: result = asgnExpr(p, "xor", a)
  of pxBarAsgn: result = asgnExpr(p, "or", a)
  else:
    backtrackContext(p)
    result = conditionalExpression(p)
  
proc shiftExpression(p: var TParser): PNode = 
  result = additiveExpression(p)
  while p.tok.xkind in {pxShl, pxShr}:
    var op = if p.tok.xkind == pxShl: "shl" else: "shr"
    getTok(p, result)
    var a = result 
    var b = additiveExpression(p)
    result = newBinary(op, a, b, p)

proc relationalExpression(p: var TParser): PNode = 
  result = shiftExpression(p)
  # Nimrod uses ``<`` and ``<=``, etc. too:
  while p.tok.xkind in {pxLt, pxLe, pxGt, pxGe}:
    var op = TokKindToStr(p.tok.xkind)
    getTok(p, result)
    var a = result 
    var b = shiftExpression(p)
    result = newBinary(op, a, b, p)

proc equalityExpression(p: var TParser): PNode =
  result = relationalExpression(p)
  # Nimrod uses ``==`` and ``!=`` too:
  while p.tok.xkind in {pxEquals, pxNeq}:
    var op = TokKindToStr(p.tok.xkind)
    getTok(p, result)
    var a = result 
    var b = relationalExpression(p)
    result = newBinary(op, a, b, p)

proc andExpression(p: var TParser): PNode =
  result = equalityExpression(p)
  while p.tok.xkind == pxAmp:
    getTok(p, result)
    var a = result 
    var b = equalityExpression(p)
    result = newBinary("&", a, b, p)

proc exclusiveOrExpression(p: var TParser): PNode = 
  result = andExpression(p)
  while p.tok.xkind == pxHat:
    getTok(p, result)
    var a = result 
    var b = andExpression(p)
    result = newBinary("^", a, b, p)

proc inclusiveOrExpression(p: var TParser): PNode = 
  result = exclusiveOrExpression(p)
  while p.tok.xkind == pxBar:
    getTok(p, result)
    var a = result 
    var b = exclusiveOrExpression(p)
    result = newBinary("or", a, b, p)
  
proc logicalAndExpression(p: var TParser): PNode = 
  result = inclusiveOrExpression(p)
  while p.tok.xkind == pxAmpAmp:
    getTok(p, result)
    var a = result
    var b = inclusiveOrExpression(p)
    result = newBinary("and", a, b, p)

proc logicalOrExpression(p: var TParser): PNode = 
  result = logicalAndExpression(p)
  while p.tok.xkind == pxBarBar:
    getTok(p, result)
    var a = result
    var b = logicalAndExpression(p)
    result = newBinary("or", a, b, p)
  
proc conditionalExpression(p: var TParser): PNode =  
  result = logicalOrExpression(p)
  if p.tok.xkind == pxConditional: 
    getTok(p, result) # skip '?'
    var a = result
    var b = expression(p)
    eat(p, pxColon, b)
    var c = conditionalExpression(p)
    result = newNodeP(nkIfExpr, p)
    var branch = newNodeP(nkElifExpr, p)
    addSon(branch, a)
    addSon(branch, b)
    addSon(result, branch)
    branch = newNodeP(nkElseExpr, p)
    addSon(branch, c)
    addSon(result, branch)
    
# Statements

proc buildStmtList(a: PNode): PNode = 
  if a.kind == nkStmtList: result = a
  else:
    result = newNodeI(nkStmtList, a.info)
    addSon(result, a)

proc nestedStatement(p: var TParser): PNode =
  # careful: We need to translate:
  # if (x) if (y) stmt;
  # into:
  # if x:
  #   if x:
  #     stmt
  # 
  # Nimrod requires complex statements to be nested in whitespace!
  const
    complexStmt = {nkProcDef, nkMethodDef, nkConverterDef, nkMacroDef,
      nkTemplateDef, nkIteratorDef, nkMacroStmt, nkIfStmt,
      nkWhenStmt, nkForStmt, nkWhileStmt, nkCaseStmt, nkVarSection, 
      nkConstSection, nkTypeSection, nkTryStmt, nkBlockStmt, nkStmtList,
      nkCommentStmt, nkStmtListExpr, nkBlockExpr, nkStmtListType, nkBlockType}
  result = statement(p)
  if result.kind in complexStmt:
    result = buildStmtList(result)

proc expressionStatement(p: var TParser): PNode = 
  # do not skip the comment after a semicolon to make a new nkCommentStmt
  if p.tok.xkind == pxSemicolon: 
    getTok(p)
  else:
    result = expression(p)
    if p.tok.xkind == pxSemicolon: getTok(p)
    else: parMessage(p, errTokenExpected, ";")

proc parseIf(p: var TParser): PNode = 
  # we parse additional "else if"s too here for better Nimrod code
  result = newNodeP(nkIfStmt, p)
  while true: 
    getTok(p) # skip ``if``
    var branch = newNodeP(nkElifBranch, p)
    skipCom(p, branch)
    eat(p, pxParLe, branch)
    addSon(branch, expression(p))
    eat(p, pxParRi, branch)
    addSon(branch, nestedStatement(p))
    addSon(result, branch)
    if p.tok.s == "else": 
      getTok(p, result)
      if p.tok.s != "if": 
        # ordinary else part:
        branch = newNodeP(nkElse, p)
        addSon(branch, nestedStatement(p))
        addSon(result, branch)
        break 
    else: 
      break 
  
proc parseWhile(p: var TParser): PNode = 
  result = newNodeP(nkWhileStmt, p)
  getTok(p, result)
  eat(p, pxParLe, result)
  addSon(result, expression(p))
  eat(p, pxParRi, result)
  addSon(result, nestedStatement(p))

proc parseDoWhile(p: var TParser): PNode =  
  # we only support ``do stmt while (0)`` as an idiom for 
  # ``block: stmt``
  result = newNodeP(nkBlockStmt, p)
  getTok(p, result) # skip "do"
  addSon(result, nil, nestedStatement(p))
  eat(p, "while", result)
  eat(p, pxParLe, result)
  if p.tok.xkind == pxIntLit and p.tok.iNumber == 0: getTok(p, result)
  else: parMessage(p, errTokenExpected, "0")
  eat(p, pxParRi, result)
  if p.tok.xkind == pxSemicolon: getTok(p)

proc declarationOrStatement(p: var TParser): PNode = 
  if p.tok.xkind != pxSymbol:
    result = expressionStatement(p)
  elif declKeyword(p.tok.s): 
    result = declaration(p)
  else:
    # ordinary identifier:
    safeContext(p)
    getTok(p) # skip identifier to look ahead
    case p.tok.xkind 
    of pxSymbol, pxStar: 
      # we parse 
      # a b
      # a * b
      # always as declarations! This is of course not correct, but good
      # enough for most real world C code out there.
      backtrackContext(p)
      result = declaration(p)
    of pxColon: 
      # it is only a label:
      closeContext(p)
      getTok(p)
      result = statement(p)
    else: 
      backtrackContext(p)
      result = expressionStatement(p)

proc parseFor(p: var TParser, result: PNode) = 
  # 'for' '(' expression_statement expression_statement expression? ')'
  #   statement
  getTok(p, result)
  eat(p, pxParLe, result)
  var initStmt = declarationOrStatement(p)
  addSonIfNotNil(result, initStmt)
  var w = newNodeP(nkWhileStmt, p)
  var condition = expressionStatement(p)
  if condition == nil: condition = newIdentNodeP("true", p)
  addSon(w, condition)
  var step = if p.tok.xkind != pxParRi: expression(p) else: nil
  eat(p, pxParRi, step)
  var loopBody = nestedStatement(p)
  if step != nil:
    loopBody = buildStmtList(loopBody)
    addSon(loopBody, step)
  addSon(w, loopBody)
  addSon(result, w)
  
proc switchStatement(p: var TParser): PNode = 
  result = newNodeP(nkStmtList, p)
  while true:
    if p.tok.xkind in {pxEof, pxCurlyRi}: break
    case p.tok.s 
    of "break":
      getTok(p, result)
      eat(p, pxSemicolon, result)
      break
    of "return", "continue", "goto": 
      addSon(result, statement(p))
      break
    of "case", "default":
      break
    else: nil
    addSon(result, statement(p))
  if sonsLen(result) == 0:
    # translate empty statement list to Nimrod's ``nil`` statement
    result = newNodeP(nkNilLit, p)

proc rangeExpression(p: var TParser): PNode =
  # We support GCC's extension: ``case expr...expr:`` 
  result = constantExpression(p)
  if p.tok.xkind == pxDotDotDot:
    getTok(p, result)
    var a = result
    var b = constantExpression(p)
    result = newNodeP(nkRange, p)
    addSon(result, a)
    addSon(result, b)

proc parseSwitch(p: var TParser): PNode = 
  # We cannot support Duff's device or C's crazy switch syntax. We just support
  # sane usages of switch. ;-)
  result = newNodeP(nkCaseStmt, p)
  getTok(p, result)
  eat(p, pxParLe, result)
  addSon(result, expression(p))
  eat(p, pxParRi, result)
  eat(p, pxCurlyLe, result)
  var b: PNode
  while (p.tok.xkind != pxCurlyRi) and (p.tok.xkind != pxEof): 
    case p.tok.s 
    of "default": 
      b = newNodeP(nkElse, p)
      getTok(p, b)
      eat(p, pxColon, b)
    of "case": 
      b = newNodeP(nkOfBranch, p)
      while p.tok.xkind == pxSymbol and p.tok.s == "case":
        getTok(p, b)
        addSon(b, rangeExpression(p))
        eat(p, pxColon, b)
    else:
      parMessage(p, errXExpected, "case")
    addSon(b, switchStatement(p))
    addSon(result, b)
    if b.kind == nkElse: break 
  eat(p, pxCurlyRi)

proc embedStmts(sl, a: PNode) = 
  if a.kind != nkStmtList:
    addSon(sl, a)
  else:
    for i in 0..sonsLen(a)-1: addSon(sl, a[i])

proc compoundStatement(p: var TParser): PNode = 
  result = newNodeP(nkStmtList, p)
  eat(p, pxCurlyLe)
  inc(p.scopeCounter)
  while p.tok.xkind notin {pxEof, pxCurlyRi}: 
    var a = statement(p)
    if a == nil: break
    embedStmts(result, a)
  if sonsLen(result) == 0:
    # translate ``{}`` to Nimrod's ``nil`` statement
    result = newNodeP(nkNilLit, p)
  dec(p.scopeCounter)
  eat(p, pxCurlyRi)

include cpp

proc statement(p: var TParser): PNode = 
  case p.tok.xkind 
  of pxSymbol: 
    case p.tok.s
    of "if": result = parseIf(p)
    of "switch": result = parseSwitch(p)
    of "while": result = parseWhile(p)
    of "do": result = parseDoWhile(p)
    of "for": 
      result = newNodeP(nkStmtList, p)
      parseFor(p, result)
    of "goto": 
      # we cannot support "goto"; in hand-written C, "goto" is most often used
      # to break a block, so we convert it to a break statement with label.
      result = newNodeP(nkBreakStmt, p)
      getTok(p)
      addSon(result, skipIdent(p))
      eat(p, pxSemicolon)
    of "continue":
      result = newNodeP(nkContinueStmt, p)
      getTok(p)
      eat(p, pxSemicolon)
      addSon(result, nil)
    of "break":
      result = newNodeP(nkBreakStmt, p)
      getTok(p)
      eat(p, pxSemicolon)
      addSon(result, nil)
    of "return":
      result = newNodeP(nkReturnStmt, p)
      getTok(p)
      # special case for ``return (expr)`` because I hate the redundant
      # parenthesis ;-)
      if p.tok.xkind == pxParLe:
        getTok(p, result)
        addSon(result, expression(p))
        eat(p, pxParRi, result)
      elif p.tok.xkind != pxSemicolon:
        addSon(result, expression(p))
      else:
        addSon(result, nil)
      eat(p, pxSemicolon)
    of "enum":
      result = enumSpecifier(p)
    of "typedef": 
      result = parseTypeDef(p)
    else: 
      result = declarationOrStatement(p)
  of pxCurlyLe:
    result = compoundStatement(p)
  of pxDirective, pxDirectiveParLe:
    result = parseDir(p)
  of pxLineComment, pxStarComment: 
    result = newNodeP(nkCommentStmt, p)
    skipCom(p, result)
  of pxSemicolon:
    # empty statement:
    getTok(p)
    if p.tok.xkind in {pxLineComment, pxStarComment}:
      result = newNodeP(nkCommentStmt, p)
      skipCom(p, result)
    else:
      result = newNodeP(nkNilLit, p)
  else:
    result = expressionStatement(p)
    #parMessage(p, errStmtExpected)

proc parseUnit(p: var TParser): PNode = 
  result = newNodeP(nkStmtList, p)
  getTok(p) # read first token
  while p.tok.xkind != pxEof: 
    var s = statement(p)
    if s != nil: embedStmts(result, s)
  exSymbols(result)

