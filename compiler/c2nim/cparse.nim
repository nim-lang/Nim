#
#
#      c2nim - C to Nimrod source converter
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements an Ansi C parser.
## It translates a C source file into a Nimrod AST. Then the renderer can be
## used to convert the AST to its text representation.

# TODO
# - document 'cpp' mode
# - implement handling of '::': function declarations
# - C++'s "operator" still needs some love
# - support '#if' in classes

import 
  os, llstream, renderer, clex, idents, strutils, pegs, ast, astalgo, msgs,
  options, strtabs

type 
  TParserFlag = enum
    pfRefs,             ## use "ref" instead of "ptr" for C's typ*
    pfCDecl,            ## annotate procs with cdecl
    pfStdCall,          ## annotate procs with stdcall
    pfSkipInclude,      ## skip all ``#include``
    pfTypePrefixes,     ## all generated types start with 'T' or 'P'
    pfSkipComments,     ## do not generate comments
    pfCpp,              ## process C++
    pfIgnoreRValueRefs, ## transform C++'s 'T&&' to 'T'
    pfKeepBodies        ## do not skip C++ method bodies
  
  TMacro = object
    name: string
    params: int           # number of parameters
    body: seq[ref TToken] # can contain pxMacroParam tokens
  
  TParserOptions = object
    flags: set[TParserFlag]
    prefixes, suffixes: seq[string]
    mangleRules: seq[tuple[pattern: TPeg, frmt: string]]
    privateRules: seq[TPeg]
    dynlibSym, header: string
    macros: seq[TMacro]
    toMangle: PStringTable
    classes: PStringTable
  PParserOptions* = ref TParserOptions
  
  TParser* = object
    lex: TLexer
    tok: ref TToken       # current token
    options: PParserOptions
    backtrack: seq[ref TToken]
    inTypeDef: int
    scopeCounter: int
    hasDeadCodeElimPragma: bool
    currentClass: PNode   # type that needs to be added as 'this' parameter
  
  TReplaceTuple* = array[0..1, string]

  ERetryParsing = object of ESynch

proc newParserOptions*(): PParserOptions = 
  new(result)
  result.prefixes = @[]
  result.suffixes = @[]
  result.macros = @[]
  result.mangleRules = @[]
  result.privateRules = @[]
  result.flags = {}
  result.dynlibSym = ""
  result.header = ""
  result.toMangle = newStringTable(modeCaseSensitive)
  result.classes = newStringTable(modeCaseSensitive)

proc setOption*(parserOptions: PParserOptions, key: string, val=""): bool = 
  result = true
  case key.normalize
  of "ref": incl(parserOptions.flags, pfRefs)
  of "dynlib": parserOptions.dynlibSym = val
  of "header": parserOptions.header = val
  of "cdecl": incl(parserOptions.flags, pfCdecl)
  of "stdcall": incl(parserOptions.flags, pfStdCall)
  of "prefix": parserOptions.prefixes.add(val)
  of "suffix": parserOptions.suffixes.add(val)
  of "skipinclude": incl(parserOptions.flags, pfSkipInclude)
  of "typeprefixes": incl(parserOptions.flags, pfTypePrefixes)
  of "skipcomments": incl(parserOptions.flags, pfSkipComments)
  of "cpp": incl(parserOptions.flags, pfCpp)
  of "keepbodies": incl(parserOptions.flags, pfKeepBodies)
  of "ignorervaluerefs": incl(parserOptions.flags, pfIgnoreRValueRefs)
  of "class": parserOptions.classes[val] = "true"
  else: result = false

proc parseUnit*(p: var TParser): PNode
proc openParser*(p: var TParser, filename: string, inputStream: PLLStream,
                 options = newParserOptions())
proc closeParser*(p: var TParser)

# implementation

proc openParser(p: var TParser, filename: string, 
                inputStream: PLLStream, options = newParserOptions()) = 
  openLexer(p.lex, filename, inputStream)
  p.options = options
  p.backtrack = @[]
  new(p.tok)

proc parMessage(p: TParser, msg: TMsgKind, arg = "") = 
  #assert false
  lexMessage(p.lex, msg, arg)

proc closeParser(p: var TParser) = closeLexer(p.lex)
proc saveContext(p: var TParser) = p.backtrack.add(p.tok)
proc closeContext(p: var TParser) = discard p.backtrack.pop()
proc backtrackContext(p: var TParser) = p.tok = p.backtrack.pop()

proc rawGetTok(p: var TParser) = 
  if p.tok.next != nil:
    p.tok = p.tok.next
  elif p.backtrack.len == 0: 
    p.tok.next = nil
    getTok(p.lex, p.tok[])
  else: 
    # We need the next token and must be able to backtrack. So we need to 
    # allocate a new token.
    var t: ref TToken
    new(t)
    getTok(p.lex, t[])
    p.tok.next = t
    p.tok = t

proc insertAngleRi(currentToken: ref TToken) = 
  var t: ref TToken
  new(t)
  t.xkind = pxAngleRi
  t.next = currentToken.next
  currentToken.next = t

proc findMacro(p: TParser): int =
  for i in 0..high(p.options.macros):
    if p.tok.s == p.options.macros[i].name: return i
  return -1

proc rawEat(p: var TParser, xkind: TTokKind) = 
  if p.tok.xkind == xkind: rawGetTok(p)
  else: parMessage(p, errTokenExpected, tokKindToStr(xkind))

proc parseMacroArguments(p: var TParser): seq[seq[ref TToken]] = 
  result = @[]
  result.add(@[])
  var i: array[pxParLe..pxCurlyLe, int]
  var L = 0
  saveContext(p)
  while true:
    var kind = p.tok.xkind
    case kind
    of pxEof: rawEat(p, pxParRi)
    of pxParLe, pxBracketLe, pxCurlyLe: 
      inc(i[kind])
      result[L].add(p.tok)
    of pxParRi:
      # end of arguments?
      if i[pxParLe] == 0 and i[pxBracketLe] == 0 and i[pxCurlyLe] == 0: break
      if i[pxParLe] > 0: dec(i[pxParLe])
      result[L].add(p.tok)
    of pxBracketRi, pxCurlyRi:
      kind = pred(kind, 3)
      if i[kind] > 0: dec(i[kind])
      result[L].add(p.tok)
    of pxComma: 
      if i[pxParLe] == 0 and i[pxBracketLe] == 0 and i[pxCurlyLe] == 0:
        # next argument: comma is not part of the argument
        result.add(@[])
        inc(L)
      else: 
        # comma does not separate different arguments:
        result[L].add(p.tok)
    else:
      result[L].add(p.tok)
    rawGetTok(p)
  closeContext(p)

proc expandMacro(p: var TParser, m: TMacro) = 
  rawGetTok(p) # skip macro name
  var arguments: seq[seq[ref TToken]]
  if m.params > 0:
    rawEat(p, pxParLe)
    arguments = parseMacroArguments(p)
    if arguments.len != m.params: parMessage(p, errWrongNumberOfArguments)
    rawEat(p, pxParRi)
  # insert into the token list:
  if m.body.len > 0:
    var newList: ref TToken
    new(newList)
    var lastTok = newList
    for tok in items(m.body): 
      if tok.xkind == pxMacroParam: 
        for t in items(arguments[int(tok.iNumber)]):
          #echo "t: ", t^
          lastTok.next = t
          lastTok = t
      else:
        #echo "tok: ", tok^
        lastTok.next = tok
        lastTok = tok
    lastTok.next = p.tok
    p.tok = newList.next

proc getTok(p: var TParser) = 
  rawGetTok(p)
  if p.tok.xkind == pxSymbol:
    var idx = findMacro(p)
    if idx >= 0: 
      expandMacro(p, p.options.macros[idx])

proc parLineInfo(p: TParser): TLineInfo = 
  result = getLineInfo(p.lex)

proc skipComAux(p: var TParser, n: PNode) =
  if n != nil and n.kind != nkEmpty: 
    if pfSkipComments notin p.options.flags:
      if n.comment == nil: n.comment = p.tok.s
      else: add(n.comment, "\n" & p.tok.s)
  else: 
    parMessage(p, warnCommentXIgnored, p.tok.s)
  getTok(p)

proc skipCom(p: var TParser, n: PNode) = 
  while p.tok.xkind in {pxLineComment, pxStarComment}: skipComAux(p, n)

proc skipStarCom(p: var TParser, n: PNode) = 
  while p.tok.xkind == pxStarComment: skipComAux(p, n)

proc getTok(p: var TParser, n: PNode) =
  getTok(p)
  skipCom(p, n)

proc expectIdent(p: TParser) = 
  if p.tok.xkind != pxSymbol: parMessage(p, errIdentifierExpected, $(p.tok[]))
  
proc eat(p: var TParser, xkind: TTokKind, n: PNode) = 
  if p.tok.xkind == xkind: getTok(p, n)
  else: parMessage(p, errTokenExpected, tokKindToStr(xkind))
  
proc eat(p: var TParser, xkind: TTokKind) = 
  if p.tok.xkind == xkind: getTok(p)
  else: parMessage(p, errTokenExpected, tokKindToStr(xkind))
  
proc eat(p: var TParser, tok: string, n: PNode) = 
  if p.tok.s == tok: getTok(p, n)
  else: parMessage(p, errTokenExpected, tok)
  
proc opt(p: var TParser, xkind: TTokKind, n: PNode) = 
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

proc mangleRules(s: string, p: TParser): string = 
  block mangle:
    for pattern, frmt in items(p.options.mangleRules):
      if s.match(pattern):
        result = s.replacef(pattern, frmt)
        break mangle
    block prefixes:
      for prefix in items(p.options.prefixes): 
        if s.startsWith(prefix): 
          result = s.substr(prefix.len)
          break prefixes
      result = s
    block suffixes:
      for suffix in items(p.options.suffixes):
        if result.endsWith(suffix):
          setLen(result, result.len - suffix.len)
          break suffixes

proc mangleName(s: string, p: TParser): string = 
  if p.options.toMangle.hasKey(s): result = p.options.toMangle[s]
  else: result = mangleRules(s, p)

proc isPrivate(s: string, p: TParser): bool = 
  for pattern in items(p.options.privateRules): 
    if s.match(pattern): return true

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

proc exportSym(p: TParser, i: PNode, origName: string): PNode = 
  assert i.kind == nkIdent
  if p.scopeCounter == 0 and not isPrivate(origName, p):
    result = newNodeI(nkPostfix, i.info)
    addSon(result, newIdentNode(getIdent("*"), i.info), i)
  else:
    result = i

proc varIdent(ident: string, p: TParser): PNode = 
  result = exportSym(p, mangledIdent(ident, p), ident)
  if p.scopeCounter > 0: return
  if p.options.dynlibSym.len > 0 or p.options.header.len > 0: 
    var a = result
    result = newNodeP(nkPragmaExpr, p)
    var pragmas = newNodeP(nkPragma, p)
    addSon(result, a)
    addSon(result, pragmas)
    addImportToPragma(pragmas, ident, p)

proc fieldIdent(ident: string, p: TParser): PNode = 
  result = exportSym(p, mangledIdent(ident, p), ident)
  if p.scopeCounter > 0: return
  if p.options.header.len > 0: 
    var a = result
    result = newNodeP(nkPragmaExpr, p)
    var pragmas = newNodeP(nkPragma, p)
    addSon(result, a)
    addSon(result, pragmas)
    addSon(pragmas, newIdentStrLitPair("importc", ident, p))

proc doImport(ident: string, pragmas: PNode, p: TParser) = 
  if p.options.dynlibSym.len > 0 or p.options.header.len > 0: 
    addImportToPragma(pragmas, ident, p)

proc doImportCpp(ident: string, pragmas: PNode, p: TParser) = 
  if p.options.dynlibSym.len > 0 or p.options.header.len > 0:
    addSon(pragmas, newIdentStrLitPair("importcpp", ident, p))
    if p.options.dynlibSym.len > 0:
      addSon(pragmas, newIdentPair("dynlib", p.options.dynlibSym, p))
    else:
      addSon(pragmas, newIdentStrLitPair("header", p.options.header, p))

proc newBinary(opr: string, a, b: PNode, p: TParser): PNode =
  result = newNodeP(nkInfix, p)
  addSon(result, newIdentNodeP(getIdent(opr), p))
  addSon(result, a)
  addSon(result, b)

proc skipIdent(p: var TParser): PNode = 
  expectIdent(p)
  result = mangledIdent(p.tok.s, p)
  getTok(p, result)

proc skipIdentExport(p: var TParser): PNode = 
  expectIdent(p)
  result = exportSym(p, mangledIdent(p.tok.s, p), p.tok.s)
  getTok(p, result)

proc skipTypeIdentExport(p: var TParser, prefix='T'): PNode = 
  expectIdent(p)
  var n = prefix & mangleName(p.tok.s, p)
  p.options.toMangle[p.tok.s] = n
  var i = newNodeP(nkIdent, p)
  i.ident = getIdent(n)
  result = exportSym(p, i, p.tok.s)
  getTok(p, result)

proc markTypeIdent(p: var TParser, typ: PNode) = 
  if pfTypePrefixes in p.options.flags:
    var prefix = ""
    if typ == nil or typ.kind == nkEmpty: 
      prefix = "T"
    else: 
      var t = typ
      while t != nil and t.kind in {nkVarTy, nkPtrTy, nkRefTy}: 
        prefix.add('P')
        t = t.sons[0]
      if prefix.len == 0: prefix.add('T')
    expectIdent(p)
    p.options.toMangle[p.tok.s] = prefix & mangleRules(p.tok.s, p)
  
# --------------- parser -----------------------------------------------------
# We use this parsing rule: If it looks like a declaration, it is one. This
# avoids to build a symbol table, which can't be done reliably anyway for our
# purposes.

proc expression(p: var TParser, rbp: int = 0): PNode
proc constantExpression(p: var TParser): PNode = expression(p, 40)
proc assignmentExpression(p: var TParser): PNode = expression(p, 30)
proc compoundStatement(p: var TParser): PNode
proc statement(p: var TParser): PNode

proc declKeyword(p: TParser, s: string): bool = 
  # returns true if it is a keyword that introduces a declaration
  case s
  of  "extern", "static", "auto", "register", "const", "volatile", "restrict",
      "inline", "__inline", "__cdecl", "__stdcall", "__syscall", "__fastcall",
      "__safecall", "void", "struct", "union", "enum", "typedef",
      "short", "int", "long", "float", "double", "signed", "unsigned", "char": 
    result = true
  of "class":
    result = p.options.flags.contains(pfCpp)

proc stmtKeyword(s: string): bool =
  case s
  of  "if", "for", "while", "do", "switch", "break", "continue", "return",
      "goto":
    result = true

# ------------------- type desc -----------------------------------------------

proc isIntType(s: string): bool =
  case s
  of "short", "int", "long", "float", "double", "signed", "unsigned":
    result = true

proc skipConst(p: var TParser) = 
  while p.tok.xkind == pxSymbol and
      (p.tok.s == "const" or p.tok.s == "volatile" or p.tok.s == "restrict"): 
    getTok(p, nil)

proc isTemplateAngleBracket(p: var TParser): bool =
  if pfCpp notin p.options.flags: return false
  saveContext(p)
  getTok(p, nil) # skip "<"
  var i: array[pxParLe..pxCurlyLe, int]
  var angles = 0
  while true:
    let kind = p.tok.xkind
    case kind
    of pxEof: break
    of pxParLe, pxBracketLe, pxCurlyLe: inc(i[kind])
    of pxGt, pxAngleRi:
      # end of arguments?
      if i[pxParLe] == 0 and i[pxBracketLe] == 0 and i[pxCurlyLe] == 0 and
          angles == 0:
        # mark as end token:
        p.tok.xkind = pxAngleRi
        result = true; 
        break
      if angles > 0: dec(angles)
    of pxShr:
      # >> can end a template too:
      if i[pxParLe] == 0 and i[pxBracketLe] == 0 and i[pxCurlyLe] == 0 and
          angles == 1:
        p.tok.xkind = pxAngleRi
        insertAngleRi(p.tok)
        result = true
        break
      if angles > 1: dec(angles, 2)
    of pxLt: inc(angles)
    of pxParRi, pxBracketRi, pxCurlyRi:
      let kind = pred(kind, 3)
      if i[kind] > 0: dec(i[kind])
      else: break
    of pxSemicolon: break
    else: discard
    getTok(p, nil)
  backtrackContext(p)

proc optAngle(p: var TParser, n: PNode): PNode =
  if p.tok.xkind == pxLt and isTemplateAngleBracket(p):
    getTok(p)
    result = newNodeP(nkBracketExpr, p)
    result.add(n)
    while true:
      let a = assignmentExpression(p)
      if not a.isNil: result.add(a)
      if p.tok.xkind != pxComma: break
      getTok(p)
    eat(p, pxAngleRi)
  else:
    result = n

proc optScope(p: var TParser, n: PNode): PNode =
  result = n
  if pfCpp in p.options.flags:
    while p.tok.xkind == pxScope:
      let a = result
      result = newNodeP(nkDotExpr, p)
      result.add(a)
      getTok(p, result)
      expectIdent(p)
      result.add(mangledIdent(p.tok.s, p))
      getTok(p, result)

proc typeAtom(p: var TParser): PNode = 
  skipConst(p)
  expectIdent(p)
  case p.tok.s
  of "void": 
    result = newNodeP(nkNilLit, p) # little hack
    getTok(p, nil)
  of "struct", "union", "enum": 
    getTok(p, nil)
    result = skipIdent(p)
  elif isIntType(p.tok.s):
    var x = ""
    #getTok(p, nil)
    var isUnsigned = false
    while p.tok.xkind == pxSymbol and (isIntType(p.tok.s) or p.tok.s == "char"):
      if p.tok.s == "unsigned":
        isUnsigned = true
      elif p.tok.s == "signed" or p.tok.s == "int":
        discard
      else:
        add(x, p.tok.s)
      getTok(p, nil)
    if x.len == 0: x = "int"
    let xx = if isUnsigned: "cu" & x else: "c" & x
    result = mangledIdent(xx, p)
  else:
    result = mangledIdent(p.tok.s, p)
    getTok(p, result)
    result = optScope(p, result)
    result = optAngle(p, result)
    
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
  while true:
    if p.tok.xkind == pxStar:
      inc(i)
      getTok(p, result)
      skipConst(p)
      result = newPointerTy(p, result)
    elif p.tok.xkind == pxAmp and pfCpp in p.options.flags:
      getTok(p, result)
      skipConst(p)
      let b = result
      result = newNodeP(nkVarTy, p)
      result.add(b)
    elif p.tok.xkind == pxAmpAmp and pfCpp in p.options.flags:
      getTok(p, result)
      skipConst(p)
      if pfIgnoreRvalueRefs notin p.options.flags:
        let b = result
        result = newNodeP(nkVarTy, p)
        result.add(b)
    else: break
  if a.kind == nkIdent and a.ident.s == "char": 
    if i >= 2: 
      result = newIdentNodeP("cstringArray", p)
      for j in 1..i-2: result = newPointerTy(p, result)
    elif i == 1: result = newIdentNodeP("cstring", p)
  elif a.kind == nkNilLit and i > 0:
    result = newIdentNodeP("pointer", p)
    for j in 1..i-1: result = newPointerTy(p, result)

proc newProcPragmas(p: TParser): PNode =
  result = newNodeP(nkPragma, p)
  if pfCDecl in p.options.flags: 
    addSon(result, newIdentNodeP("cdecl", p))
  elif pfStdCall in p.options.flags:
    addSon(result, newIdentNodeP("stdcall", p))

proc addPragmas(father, pragmas: PNode) =
  if sonsLen(pragmas) > 0: addSon(father, pragmas)
  else: addSon(father, ast.emptyNode)

proc addReturnType(params, rettyp: PNode) =
  if rettyp == nil: addSon(params, ast.emptyNode)
  elif rettyp.kind != nkNilLit: addSon(params, rettyp)
  else: addSon(params, ast.emptyNode)

proc parseFormalParams(p: var TParser, params, pragmas: PNode)

proc parseTypeSuffix(p: var TParser, typ: PNode): PNode = 
  result = typ
  while true:
    case p.tok.xkind 
    of pxBracketLe:
      getTok(p, result)
      skipConst(p) # POSIX contains: ``int [restrict]``
      if p.tok.xkind != pxBracketRi:
        var tmp = result
        var index = expression(p)
        # array type:
        result = newNodeP(nkBracketExpr, p)
        addSon(result, newIdentNodeP("array", p))
        #var r = newNodeP(nkRange, p)
        #addSon(r, newIntNodeP(nkIntLit, 0, p))
        #addSon(r, newBinary("-", index, newIntNodeP(nkIntLit, 1, p), p))
        #addSon(result, r)
        addSon(result, index)
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
    of pxParLe:
      # function pointer:
      var procType = newNodeP(nkProcTy, p)
      var pragmas = newProcPragmas(p)
      var params = newNodeP(nkFormalParams, p)
      addReturnType(params, result)
      parseFormalParams(p, params, pragmas)
      addSon(procType, params)
      addPragmas(procType, pragmas)
      result = procType
    else: break

proc typeDesc(p: var TParser): PNode = 
  result = pointer(p, typeAtom(p))

proc abstractDeclarator(p: var TParser, a: PNode): PNode

proc directAbstractDeclarator(p: var TParser, a: PNode): PNode =
  if p.tok.xkind == pxParLe:
    getTok(p, a)
    if p.tok.xkind in {pxStar, pxAmp, pxAmpAmp}:
      result = abstractDeclarator(p, a)
      eat(p, pxParRi, result)
  return parseTypeSuffix(p, a)

proc abstractDeclarator(p: var TParser, a: PNode): PNode =
  return directAbstractDeclarator(p, pointer(p, a))

proc typeName(p: var TParser): PNode =
  return abstractDeclarator(p, typeAtom(p))

proc parseField(p: var TParser, kind: TNodeKind): PNode =
  if p.tok.xkind == pxParLe: 
    getTok(p, nil)
    while p.tok.xkind == pxStar: getTok(p, nil)
    result = parseField(p, kind)
    eat(p, pxParRi, result)
  else: 
    expectIdent(p)
    if kind == nkRecList: result = fieldIdent(p.tok.s, p) 
    else: result = mangledIdent(p.tok.s, p)
    getTok(p, result)

proc parseStructBody(p: var TParser, isUnion: bool,
                     kind: TNodeKind = nkRecList): PNode =
  result = newNodeP(kind, p)
  eat(p, pxCurlyLe, result)
  while p.tok.xkind notin {pxEof, pxCurlyRi}:
    var baseTyp = typeAtom(p)
    while true:
      var def = newNodeP(nkIdentDefs, p)
      var t = pointer(p, baseTyp)
      var i = parseField(p, kind)
      t = parseTypeSuffix(p, t)
      addSon(def, i, t, ast.emptyNode)
      addSon(result, def)
      if p.tok.xkind != pxComma: break
      getTok(p, def)
    eat(p, pxSemicolon, lastSon(result))
  eat(p, pxCurlyRi, result)

proc structPragmas(p: TParser, name: PNode, origName: string): PNode = 
  assert name.kind == nkIdent
  result = newNodeP(nkPragmaExpr, p)
  addSon(result, exportSym(p, name, origName))
  var pragmas = newNodeP(nkPragma, p)
  #addSon(pragmas, newIdentNodeP("pure", p), newIdentNodeP("final", p))
  if p.options.header.len > 0:
    addSon(pragmas, newIdentStrLitPair("importc", origName, p),
                    newIdentStrLitPair("header", p.options.header, p))
  if pragmas.len > 0: addSon(result, pragmas)
  else: addSon(result, ast.emptyNode)

proc enumPragmas(p: TParser, name: PNode): PNode =
  result = newNodeP(nkPragmaExpr, p)
  addSon(result, name)
  var pragmas = newNodeP(nkPragma, p)
  var e = newNodeP(nkExprColonExpr, p)
  # HACK: sizeof(cint) should be constructed as AST
  addSon(e, newIdentNodeP("size", p), newIdentNodeP("sizeof(cint)", p))
  addSon(pragmas, e)
  addSon(result, pragmas)

proc parseStruct(p: var TParser, isUnion: bool): PNode =
  result = newNodeP(nkObjectTy, p)
  var pragmas = ast.emptyNode
  if isUnion:
    pragmas = newNodeP(nkPragma, p)
    addSon(pragmas, newIdentNodeP("union", p))
  addSon(result, pragmas, ast.emptyNode) # no inheritance 
  if p.tok.xkind == pxCurlyLe:
    addSon(result, parseStructBody(p, isUnion))
  else: 
    addSon(result, newNodeP(nkRecList, p))

proc declarator(p: var TParser, a: PNode, ident: ptr PNode): PNode

proc directDeclarator(p: var TParser, a: PNode, ident: ptr PNode): PNode =
  case p.tok.xkind
  of pxSymbol:
    ident[] = skipIdent(p)
  of pxParLe:
    getTok(p, a)
    if p.tok.xkind in {pxStar, pxAmp, pxAmpAmp, pxSymbol}:
      result = declarator(p, a, ident)
      eat(p, pxParRi, result)
  else:
    discard
  return parseTypeSuffix(p, a)

proc declarator(p: var TParser, a: PNode, ident: ptr PNode): PNode =
  return directDeclarator(p, pointer(p, a), ident)

# parameter-declaration
#   declaration-specifiers declarator
#   declaration-specifiers asbtract-declarator(opt)
proc parseParam(p: var TParser, params: PNode) = 
  var typ = typeDesc(p)
  # support for ``(void)`` parameter list: 
  if typ.kind == nkNilLit and p.tok.xkind == pxParRi: return
  var name: PNode
  typ = declarator(p, typ, addr name)
  if name == nil:
    var idx = sonsLen(params)+1
    name = newIdentNodeP("a" & $idx, p)
  var x = newNodeP(nkIdentDefs, p)
  addSon(x, name, typ)
  if p.tok.xkind == pxAsgn: 
    # we support default parameters for C++:
    getTok(p, x)
    addSon(x, assignmentExpression(p))
  else:
    addSon(x, ast.emptyNode)
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
  var pragmas = newProcPragmas(p)
  var params = newNodeP(nkFormalParams, p)
  eat(p, pxParLe, params)
  addReturnType(params, rettyp)
  parseCallConv(p, pragmas)
  if p.tok.xkind == pxStar: getTok(p, params)
  else: parMessage(p, errTokenExpected, "*")
  if p.inTypeDef > 0: markTypeIdent(p, nil)
  var name = skipIdentExport(p)
  eat(p, pxParRi, name)
  parseFormalParams(p, params, pragmas)
  addSon(procType, params)
  addPragmas(procType, pragmas)
  
  if p.inTypeDef == 0:
    result = newNodeP(nkVarSection, p)
    var def = newNodeP(nkIdentDefs, p)
    addSon(def, name, procType, ast.emptyNode)
    addSon(result, def)    
  else:
    result = newNodeP(nkTypeDef, p)
    addSon(result, name, ast.emptyNode, procType)
  assert result != nil
  
proc addTypeDef(section, name, t: PNode) = 
  var def = newNodeI(nkTypeDef, name.info)
  addSon(def, name, ast.emptyNode, t)
  addSon(section, def)
  
proc otherTypeDef(p: var TParser, section, typ: PNode) = 
  var name: PNode
  var t = typ
  if p.tok.xkind in {pxStar, pxAmp, pxAmpAmp}:
    t = pointer(p, t)
  if p.tok.xkind == pxParLe: 
    # function pointer: typedef typ (*name)();
    var x = parseFunctionPointerDecl(p, t)
    name = x[0]
    t = x[2]
  else: 
    # typedef typ name;
    markTypeIdent(p, t)
    name = skipIdentExport(p)
  t = parseTypeSuffix(p, t)
  addTypeDef(section, name, t)

proc parseTrailingDefinedTypes(p: var TParser, section, typ: PNode) = 
  while p.tok.xkind == pxComma:
    getTok(p, nil)
    var newTyp = pointer(p, typ)
    markTypeIdent(p, newTyp)
    var newName = skipIdentExport(p)
    newTyp = parseTypeSuffix(p, newTyp)
    addTypeDef(section, newName, newTyp)

proc enumFields(p: var TParser): PNode = 
  result = newNodeP(nkEnumTy, p)
  addSon(result, ast.emptyNode) # enum does not inherit from anything
  while true:
    var e = skipIdent(p)
    if p.tok.xkind == pxAsgn: 
      getTok(p, e)
      var c = constantExpression(p)
      var a = e
      e = newNodeP(nkEnumFieldDef, p)
      addSon(e, a, c)
      skipCom(p, e)
    
    addSon(result, e)
    if p.tok.xkind != pxComma: break
    getTok(p, e)
    # allow trailing comma:
    if p.tok.xkind == pxCurlyRi: break

proc parseTypedefStruct(p: var TParser, result: PNode, isUnion: bool) = 
  getTok(p, result)
  if p.tok.xkind == pxCurlyLe:
    var t = parseStruct(p, isUnion)
    var origName = p.tok.s
    markTypeIdent(p, nil)
    var name = skipIdent(p)
    addTypeDef(result, structPragmas(p, name, origName), t)
    parseTrailingDefinedTypes(p, result, name)
  elif p.tok.xkind == pxSymbol: 
    # name to be defined or type "struct a", we don't know yet:
    markTypeIdent(p, nil)
    var origName = p.tok.s
    var nameOrType = skipIdent(p)
    case p.tok.xkind 
    of pxCurlyLe:
      var t = parseStruct(p, isUnion)
      if p.tok.xkind == pxSymbol: 
        # typedef struct tagABC {} abc, *pabc;
        # --> abc is a better type name than tagABC!
        markTypeIdent(p, nil)
        var origName = p.tok.s
        var name = skipIdent(p)
        addTypeDef(result, structPragmas(p, name, origName), t)
        parseTrailingDefinedTypes(p, result, name)
      else:
        addTypeDef(result, structPragmas(p, nameOrType, origName), t)
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

proc parseTypedefEnum(p: var TParser, result: PNode) = 
  getTok(p, result)
  if p.tok.xkind == pxCurlyLe:
    getTok(p, result)
    var t = enumFields(p)
    eat(p, pxCurlyRi, t)
    var origName = p.tok.s
    markTypeIdent(p, nil)
    var name = skipIdent(p)
    addTypeDef(result, enumPragmas(p, exportSym(p, name, origName)), t)
    parseTrailingDefinedTypes(p, result, name)
  elif p.tok.xkind == pxSymbol: 
    # name to be defined or type "enum a", we don't know yet:
    markTypeIdent(p, nil)
    var origName = p.tok.s
    var nameOrType = skipIdent(p)
    case p.tok.xkind 
    of pxCurlyLe:
      getTok(p, result)
      var t = enumFields(p)
      eat(p, pxCurlyRi, t)
      if p.tok.xkind == pxSymbol: 
        # typedef enum tagABC {} abc, *pabc;
        # --> abc is a better type name than tagABC!
        markTypeIdent(p, nil)
        var origName = p.tok.s
        var name = skipIdent(p)
        addTypeDef(result, enumPragmas(p, exportSym(p, name, origName)), t)
        parseTrailingDefinedTypes(p, result, name)
      else:
        addTypeDef(result, 
                   enumPragmas(p, exportSym(p, nameOrType, origName)), t)
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

proc parseTypeDef(p: var TParser): PNode =  
  result = newNodeP(nkTypeSection, p)
  while p.tok.xkind == pxSymbol and p.tok.s == "typedef":
    getTok(p, result)
    inc(p.inTypeDef)
    expectIdent(p)
    case p.tok.s
    of "struct": parseTypedefStruct(p, result, isUnion=false)
    of "union": parseTypedefStruct(p, result, isUnion=true)
    of "enum": parseTypedefEnum(p, result)
    of "class":
      if pfCpp in p.options.flags:
        parseTypedefStruct(p, result, isUnion=false)
      else:
        var t = typeAtom(p)
        otherTypeDef(p, result, t)
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
    addSon(def, ast.emptyNode)  

proc parseVarDecl(p: var TParser, baseTyp, typ: PNode, 
                  origName: string): PNode =  
  result = newNodeP(nkVarSection, p)
  var def = newNodeP(nkIdentDefs, p)
  addSon(def, varIdent(origName, p))
  addSon(def, parseTypeSuffix(p, typ))
  addInitializer(p, def)
  addSon(result, def)
    
  while p.tok.xkind == pxComma: 
    getTok(p, def)
    var t = pointer(p, baseTyp)
    expectIdent(p)
    def = newNodeP(nkIdentDefs, p)
    addSon(def, varIdent(p.tok.s, p))
    getTok(p, def)
    addSon(def, parseTypeSuffix(p, t))
    addInitializer(p, def)
    addSon(result, def)
  eat(p, pxSemicolon)

proc declarationName(p: var TParser): string =
  expectIdent(p)
  result = p.tok.s
  getTok(p) # skip identifier
  while p.tok.xkind == pxScope and pfCpp in p.options.flags:
    getTok(p) # skip "::"
    expectIdent(p)
    result.add("::")
    result.add(p.tok.s)
    getTok(p)

proc declaration(p: var TParser): PNode = 
  result = newNodeP(nkProcDef, p)
  var pragmas = newNodeP(nkPragma, p)
  
  skipDeclarationSpecifiers(p)
  parseCallConv(p, pragmas)
  skipDeclarationSpecifiers(p)
  expectIdent(p)
  var baseTyp = typeAtom(p)
  var rettyp = pointer(p, baseTyp)
  skipDeclarationSpecifiers(p)
  parseCallConv(p, pragmas)
  skipDeclarationSpecifiers(p)
  
  if p.tok.xkind == pxParLe: 
    # Function pointer declaration: This is of course only a heuristic, but the
    # best we can do here.
    result = parseFunctionPointerDecl(p, rettyp)
    eat(p, pxSemicolon)
    return
  var origName = declarationName(p)
  case p.tok.xkind
  of pxParLe:
    # really a function!
    var name = mangledIdent(origName, p)
    var params = newNodeP(nkFormalParams, p)
    addReturnType(params, rettyp)
    parseFormalParams(p, params, pragmas)
    if pfCpp in p.options.flags and p.tok.xkind == pxSymbol and
        p.tok.s == "const":
      addSon(pragmas, newIdentNodeP("noSideEffect", p))
      getTok(p)
    if pfCDecl in p.options.flags:
      addSon(pragmas, newIdentNodeP("cdecl", p))
    elif pfStdcall in p.options.flags:
      addSon(pragmas, newIdentNodeP("stdcall", p))
    # no pattern, no exceptions:
    addSon(result, exportSym(p, name, origName), ast.emptyNode, ast.emptyNode)
    addSon(result, params, pragmas, ast.emptyNode) # no exceptions
    case p.tok.xkind 
    of pxSemicolon: 
      getTok(p)
      addSon(result, ast.emptyNode) # nobody
      if p.scopeCounter == 0: doImport(origName, pragmas, p)
    of pxCurlyLe:
      addSon(result, compoundStatement(p))
    else:
      parMessage(p, errTokenExpected, ";")
    if sonsLen(result.sons[pragmasPos]) == 0: 
      result.sons[pragmasPos] = ast.emptyNode
  else:
    result = parseVarDecl(p, baseTyp, rettyp, origName)
  assert result != nil

proc createConst(name, typ, val: PNode, p: TParser): PNode =
  result = newNodeP(nkConstDef, p)
  addSon(result, name, typ, val)

proc enumSpecifier(p: var TParser): PNode =  
  saveContext(p)
  getTok(p, nil) # skip "enum"
  case p.tok.xkind
  of pxCurlyLe: 
    closeContext(p)
    # make a const section out of it:
    result = newNodeP(nkConstSection, p)
    getTok(p, result)
    var i = 0
    var hasUnknown = false
    while true:
      var name = skipIdentExport(p)
      var val: PNode
      if p.tok.xkind == pxAsgn: 
        getTok(p, name)
        val = constantExpression(p)
        if val.kind == nkIntLit:  
          i = int(val.intVal)+1
          hasUnknown = false
        else:
          hasUnknown = true
      else:
        if hasUnknown:
          parMessage(p, warnUser, "computed const value may be wrong: " &
            name.renderTree)
        val = newIntNodeP(nkIntLit, i, p)
        inc(i)
      var c = createConst(name, ast.emptyNode, val, p)
      addSon(result, c)
      if p.tok.xkind != pxComma: break
      getTok(p, c)
      # allow trailing comma:
      if p.tok.xkind == pxCurlyRi: break
    eat(p, pxCurlyRi, result)
    eat(p, pxSemicolon)
  of pxSymbol: 
    var origName = p.tok.s
    markTypeIdent(p, nil)
    result = skipIdent(p)
    case p.tok.xkind 
    of pxCurlyLe: 
      closeContext(p)
      var name = result
      # create a type section containing the enum
      result = newNodeP(nkTypeSection, p)
      var t = newNodeP(nkTypeDef, p)
      getTok(p, t)
      var e = enumFields(p)
      addSon(t, exportSym(p, name, origName), ast.emptyNode, e)
      addSon(result, t)
      eat(p, pxCurlyRi, result)
      eat(p, pxSemicolon)
    of pxSemicolon:
      # just ignore ``enum X;`` for now.
      closeContext(p)
      getTok(p, nil)
    else: 
      backtrackContext(p)
      result = declaration(p)
  else:
    closeContext(p)
    parMessage(p, errTokenExpected, "{")
    result = ast.emptyNode
    
# Expressions

proc setBaseFlags(n: PNode, base: TNumericalBase) = 
  case base
  of base10: discard
  of base2: incl(n.flags, nfBase2)
  of base8: incl(n.flags, nfBase8)
  of base16: incl(n.flags, nfBase16)

proc startExpression(p : var TParser, tok : TToken) : PNode =
  #echo "nud ", $tok
  case tok.xkind:
  of pxSymbol:
    if tok.s == "NULL":
      result = newNodeP(nkNilLit, p)
    elif tok.s == "sizeof":
      result = newNodeP(nkCall, p)
      addSon(result, newIdentNodeP("sizeof", p))
      saveContext(p)
      try:
        addSon(result, expression(p, 139))
        closeContext(p)
      except ERetryParsing:
        backtrackContext(p)
        eat(p, pxParLe)
        addSon(result, typeName(p))
        eat(p, pxParRi)
    elif (tok.s == "new" or tok.s == "delete") and pfCpp in p.options.flags:
      var opr = tok.s
      result = newNodeP(nkCall, p)
      if p.tok.xkind == pxBracketLe:
        getTok(p)
        eat(p, pxBracketRi)
        opr.add("Array")
      addSon(result, newIdentNodeP(opr, p))
      if p.tok.xkind == pxParLe:
        getTok(p, result)
        addSon(result, typeDesc(p))
        eat(p, pxParRi, result)
      else:
        addSon(result, expression(p, 139))
    else:
      result = mangledIdent(tok.s, p)
      result = optScope(p, result)
      result = optAngle(p, result)
  of pxIntLit: 
    result = newIntNodeP(nkIntLit, tok.iNumber, p)
    setBaseFlags(result, tok.base)
  of pxInt64Lit: 
    result = newIntNodeP(nkInt64Lit, tok.iNumber, p)
    setBaseFlags(result, tok.base)
  of pxFloatLit: 
    result = newFloatNodeP(nkFloatLit, tok.fNumber, p)
    setBaseFlags(result, tok.base)
  of pxStrLit: 
    result = newStrNodeP(nkStrLit, tok.s, p)
    while p.tok.xkind == pxStrLit:
      add(result.strVal, p.tok.s)
      getTok(p, result)
  of pxCharLit:
    result = newIntNodeP(nkCharLit, ord(tok.s[0]), p)
  of pxParLe:
    try:
      saveContext(p)
      result = newNodeP(nkPar, p)
      addSon(result, expression(p, 0))
      if p.tok.xkind != pxParRi:
        raise newException(ERetryParsing, "expected a ')'")
      getTok(p, result)
      if p.tok.xkind in {pxSymbol, pxIntLit, pxFloatLit, pxStrLit, pxCharLit}:
        raise newException(ERetryParsing, "expected a non literal token")
      closeContext(p)
    except ERetryParsing:
      backtrackContext(p)
      result = newNodeP(nkCast, p)
      addSon(result, typeName(p))
      eat(p, pxParRi, result)
      addSon(result, expression(p, 139))
  of pxPlusPlus:
    result = newNodeP(nkCall, p)
    addSon(result, newIdentNodeP("inc", p))
    addSon(result, expression(p, 139))
  of pxMinusMinus:
    result = newNodeP(nkCall, p)
    addSon(result, newIdentNodeP("dec", p))
    addSon(result, expression(p, 139))
  of pxAmp:
    result = newNodeP(nkAddr, p)
    addSon(result, expression(p, 139))
  of pxStar:
    result = newNodeP(nkBracketExpr, p)
    addSon(result, expression(p, 139))
  of pxPlus:
    result = newNodeP(nkPrefix, p)
    addSon(result, newIdentNodeP("+", p))
    addSon(result, expression(p, 139))
  of pxMinus:
    result = newNodeP(nkPrefix, p)
    addSon(result, newIdentNodeP("-", p))
    addSon(result, expression(p, 139))
  of pxTilde:
    result = newNodeP(nkPrefix, p)
    addSon(result, newIdentNodeP("not", p))
    addSon(result, expression(p, 139))
  of pxNot:
    result = newNodeP(nkPrefix, p)
    addSon(result, newIdentNodeP("not", p))
    addSon(result, expression(p, 139))
  else:
    # probably from a failed sub expression attempt, try a type cast
    raise newException(ERetryParsing, "did not expect " & $tok)

proc leftBindingPower(p : var TParser, tok : ref TToken) : int =
  #echo "lbp ", $tok[]
  case tok.xkind:
  of pxComma:
    return 10
    # throw == 20
  of pxAsgn, pxPlusAsgn, pxMinusAsgn, pxStarAsgn, pxSlashAsgn, pxModAsgn, pxShlAsgn, pxShrAsgn, pxAmpAsgn, pxHatAsgn, pxBarAsgn:
    return 30
  of pxConditional:
    return 40
  of pxBarBar:
    return 50
  of pxAmpAmp:
    return 60
  of pxBar:
    return 70
  of pxHat:
    return 80
  of pxAmp:
    return 90
  of pxEquals, pxNeq:
    return 100
  of pxLt, pxLe, pxGt, pxGe:
    return 110
  of pxShl, pxShr:
    return 120
  of pxPlus, pxMinus:
    return 130
  of pxStar, pxSlash, pxMod:
    return 140
    # .* ->* == 150
  of pxPlusPlus, pxMinusMinus, pxParLe, pxDot, pxArrow, pxBracketLe:
    return 160
    # :: == 170
  else:
    return 0

proc buildStmtList(a: PNode): PNode

proc leftExpression(p : var TParser, tok : TToken, left : PNode) : PNode =
  #echo "led ", $tok
  case tok.xkind:
  of pxComma: # 10
    # not supported as an expression, turns into a statement list
    result = buildStmtList(left)
    addSon(result, expression(p, 0))
    # throw == 20
  of pxAsgn: # 30
    result = newNodeP(nkAsgn, p)
    addSon(result, left, expression(p, 29))
  of pxPlusAsgn: # 30
    result = newNodeP(nkCall, p)
    addSon(result, newIdentNodeP(getIdent("inc"), p), left, expression(p, 29))
  of pxMinusAsgn: # 30
    result = newNodeP(nkCall, p)
    addSon(result, newIdentNodeP(getIdent("dec"), p), left, expression(p, 29))
  of pxStarAsgn: # 30
    result = newNodeP(nkAsgn, p)
    var right = expression(p, 29)
    addSon(result, left, newBinary("*", copyTree(left), right, p))
  of pxSlashAsgn: # 30
    result = newNodeP(nkAsgn, p)
    var right = expression(p, 29)
    addSon(result, left, newBinary("/", copyTree(left), right, p))
  of pxModAsgn: # 30
    result = newNodeP(nkAsgn, p)
    var right = expression(p, 29)
    addSon(result, left, newBinary("mod", copyTree(left), right, p))
  of pxShlAsgn: # 30
    result = newNodeP(nkAsgn, p)
    var right = expression(p, 29)
    addSon(result, left, newBinary("shl", copyTree(left), right, p))
  of pxShrAsgn: # 30
    result = newNodeP(nkAsgn, p)
    var right = expression(p, 29)
    addSon(result, left, newBinary("shr", copyTree(left), right, p))
  of pxAmpAsgn: # 30
    result = newNodeP(nkAsgn, p)
    var right = expression(p, 29)
    addSon(result, left, newBinary("and", copyTree(left), right, p))
  of pxHatAsgn: # 30
    result = newNodeP(nkAsgn, p)
    var right = expression(p, 29)
    addSon(result, left, newBinary("xor", copyTree(left), right, p))
  of pxBarAsgn: # 30
    result = newNodeP(nkAsgn, p)
    var right = expression(p, 29)
    addSon(result, left, newBinary("or", copyTree(left), right, p))
  of pxConditional: # 40
    var a = expression(p, 0)
    eat(p, pxColon, a)
    var b = expression(p, 39)
    result = newNodeP(nkIfExpr, p)
    var branch = newNodeP(nkElifExpr, p)
    addSon(branch, left, a)
    addSon(result, branch)
    branch = newNodeP(nkElseExpr, p)
    addSon(branch, b)
    addSon(result, branch)
  of pxBarBar: # 50
    result = newBinary("or", left, expression(p, 50), p)
  of pxAmpAmp: # 60
    result = newBinary("and", left, expression(p, 60), p)
  of pxBar: # 70
    result = newBinary("or", left, expression(p, 70), p)
  of pxHat: # 80
    result = newBinary("^", left, expression(p, 80), p)
  of pxAmp: # 90
    result = newBinary("and", left, expression(p, 90), p)
  of pxEquals: # 100
    result = newBinary("==", left, expression(p, 100), p)
  of pxNeq: # 100
    result = newBinary("!=", left, expression(p, 100), p)
  of pxLt: # 110
    result = newBinary("<", left, expression(p, 110), p)
  of pxLe: # 110
    result = newBinary("<=", left, expression(p, 110), p)
  of pxGt: # 110
    result = newBinary(">", left, expression(p, 110), p)
  of pxGe: # 110
    result = newBinary(">=", left, expression(p, 110), p)
  of pxShl: # 120
    result = newBinary("shl", left, expression(p, 120), p)
  of pxShr: # 120
    result = newBinary("shr", left, expression(p, 120), p)
  of pxPlus: # 130
    result = newNodeP(nkInfix, p)
    addSon(result, newIdentNodeP("+", p), left)
    addSon(result, expression(p, 130))
  of pxMinus: # 130
    result = newNodeP(nkInfix, p)
    addSon(result, newIdentNodeP("+", p), left)
    addSon(result, expression(p, 130))
  of pxStar: # 140
    result = newNodeP(nkInfix, p)
    addSon(result, newIdentNodeP("*", p), left)
    addSon(result, expression(p, 140))
  of pxSlash: # 140
    result = newNodeP(nkInfix, p)
    addSon(result, newIdentNodeP("div", p), left)
    addSon(result, expression(p, 140))
  of pxMod: # 140
    result = newNodeP(nkInfix, p)
    addSon(result, newIdentNodeP("mod", p), left)
    addSon(result, expression(p, 140))
    # .* ->* == 150
  of pxPlusPlus: # 160
    result = newNodeP(nkCall, p)
    addSon(result, newIdentNodeP("inc", p), left)
  of pxMinusMinus: # 160
    result = newNodeP(nkCall, p)
    addSon(result, newIdentNodeP("dec", p), left)
  of pxParLe: # 160
    result = newNodeP(nkCall, p)
    addSon(result, left)
    while p.tok.xkind != pxParRi:
      var a = expression(p, 29)
      addSon(result, a)
      while p.tok.xkind == pxComma:
        getTok(p, a)
        a = expression(p, 29)
        addSon(result, a)
    eat(p, pxParRi, result)
  of pxDot: # 160
    result = newNodeP(nkDotExpr, p)
    addSon(result, left)
    addSon(result, skipIdent(p))
  of pxArrow: # 160
    result = newNodeP(nkDotExpr, p)
    addSon(result, left)
    addSon(result, skipIdent(p))
  of pxBracketLe: # 160
    result = newNodeP(nkBracketExpr, p)
    addSon(result, left, expression(p))
    eat(p, pxBracketRi, result)
    # :: == 170
  else:
    result = left

proc expression*(p : var TParser, rbp : int = 0) : PNode =
  var tok : TToken

  tok = p.tok[]
  getTok(p, result)

  result = startExpression(p, tok)

  while rbp < leftBindingPower(p, p.tok):
    tok = p.tok[]
    getTok(p, result)
    result = leftExpression(p, tok, result)
    
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
      nkTemplateDef, nkIteratorDef, nkIfStmt,
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
    result = ast.emptyNode
  else:
    result = expression(p)
    if p.tok.xkind == pxSemicolon: getTok(p)
    else: parMessage(p, errTokenExpected, ";")
  assert result != nil

proc parseIf(p: var TParser): PNode = 
  # we parse additional "else if"s too here for better Nimrod code
  result = newNodeP(nkIfStmt, p)
  while true: 
    getTok(p) # skip ``if``
    var branch = newNodeP(nkElifBranch, p)
    eat(p, pxParLe, branch)
    addSon(branch, expression(p))
    eat(p, pxParRi, branch)
    addSon(branch, nestedStatement(p))
    addSon(result, branch)
    skipCom(p, branch)
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

proc embedStmts(sl, a: PNode)

proc parseDoWhile(p: var TParser): PNode =  
  # parsing
  result = newNodeP(nkWhileStmt, p)
  getTok(p, result)
  var stm = nestedStatement(p)
  eat(p, "while", result)
  eat(p, pxParLe, result)
  var exp = expression(p)
  eat(p, pxParRi, result)
  if p.tok.xkind == pxSemicolon: getTok(p)

  # while true:
  #   stmt
  #   if not expr:
  #     break
  addSon(result, newIdentNodeP("true", p))

  stm = buildStmtList(stm)

  # get the last exp if it is a stmtlist
  var cleanedExp = exp
  if exp.kind == nkStmtList:
    cleanedExp = exp.sons[exp.len-1]
    exp.sons = exp.sons[0..exp.len-2]
    embedStmts(stm, exp)

  var notExp = newNodeP(nkPrefix, p)
  addSon(notExp, newIdentNodeP("not", p))
  addSon(notExp, cleanedExp)

  var brkStm = newNodeP(nkBreakStmt, p)
  addSon(brkStm, ast.emptyNode)

  var ifStm = newNodeP(nkIfStmt, p)
  var ifBranch = newNodeP(nkElifBranch, p)
  addSon(ifBranch, notExp)
  addSon(ifBranch, brkStm)
  addSon(ifStm, ifBranch)

  embedStmts(stm, ifStm)

  addSon(result, stm)

proc declarationOrStatement(p: var TParser): PNode = 
  if p.tok.xkind != pxSymbol:
    result = expressionStatement(p)
  elif declKeyword(p, p.tok.s): 
    result = declaration(p)
  else:
    # ordinary identifier:
    saveContext(p)
    getTok(p) # skip identifier to look ahead
    case p.tok.xkind
    of pxSymbol, pxStar, pxLt, pxAmp, pxAmpAmp:
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
  assert result != nil

proc parseTuple(p: var TParser, isUnion: bool): PNode = 
  result = parseStructBody(p, isUnion, nkTupleTy)

proc parseTrailingDefinedIdents(p: var TParser, result, baseTyp: PNode) =
  var varSection = newNodeP(nkVarSection, p)
  while p.tok.xkind notin {pxEof, pxSemicolon}:
    var t = pointer(p, baseTyp)
    expectIdent(p)
    var def = newNodeP(nkIdentDefs, p)
    addSon(def, varIdent(p.tok.s, p))
    getTok(p, def)
    addSon(def, parseTypeSuffix(p, t))
    addInitializer(p, def)
    addSon(varSection, def)
    if p.tok.xkind != pxComma: break
    getTok(p, def)
  eat(p, pxSemicolon)
  if sonsLen(varSection) > 0:
    addSon(result, varSection)

proc parseStandaloneStruct(p: var TParser, isUnion: bool): PNode =
  result = newNodeP(nkStmtList, p)
  saveContext(p)
  getTok(p, result) # skip "struct" or "union"
  var origName = ""
  if p.tok.xkind == pxSymbol: 
    markTypeIdent(p, nil)
    origName = p.tok.s
    getTok(p, result)
  if p.tok.xkind in {pxCurlyLe, pxSemiColon}:
    if origName.len > 0: 
      var name = mangledIdent(origName, p)
      var t = parseStruct(p, isUnion)
      var typeSection = newNodeP(nkTypeSection, p)
      addTypeDef(typeSection, structPragmas(p, name, origName), t)
      addSon(result, typeSection)
      parseTrailingDefinedIdents(p, result, name)
    else:
      var t = parseTuple(p, isUnion)
      parseTrailingDefinedIdents(p, result, t)
  else:
    backtrackContext(p)
    result = declaration(p)

proc parseFor(p: var TParser, result: PNode) = 
  # 'for' '(' expression_statement expression_statement expression? ')'
  #   statement
  getTok(p, result)
  eat(p, pxParLe, result)
  var initStmt = declarationOrStatement(p)
  if initStmt.kind != nkEmpty:
    embedStmts(result, initStmt)
  var w = newNodeP(nkWhileStmt, p)
  var condition = expressionStatement(p)
  if condition.kind == nkEmpty: condition = newIdentNodeP("true", p)
  addSon(w, condition)
  var step = if p.tok.xkind != pxParRi: expression(p) else: ast.emptyNode
  eat(p, pxParRi, step)
  var loopBody = nestedStatement(p)
  if step.kind != nkEmpty:
    loopBody = buildStmtList(loopBody)
    embedStmts(loopBody, step)
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
    else: discard
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

proc addStmt(sl, a: PNode) = 
  # merge type sections if possible:
  if a.kind != nkTypeSection or sonsLen(sl) == 0 or
      lastSon(sl).kind != nkTypeSection:
    addSon(sl, a)
  else:
    var ts = lastSon(sl)
    for i in 0..sonsLen(a)-1: addSon(ts, a.sons[i])

proc embedStmts(sl, a: PNode) = 
  if a.kind != nkStmtList:
    addStmt(sl, a)
  else:
    for i in 0..sonsLen(a)-1: 
      if a[i].kind != nkEmpty: addStmt(sl, a[i])

proc compoundStatement(p: var TParser): PNode = 
  result = newNodeP(nkStmtList, p)
  eat(p, pxCurlyLe)
  inc(p.scopeCounter)
  while p.tok.xkind notin {pxEof, pxCurlyRi}: 
    var a = statement(p)
    if a.kind == nkEmpty: break
    embedStmts(result, a)
  if sonsLen(result) == 0:
    # translate ``{}`` to Nimrod's ``discard`` statement
    result = newNodeP(nkDiscardStmt, p)
    result.add(ast.emptyNode)
  dec(p.scopeCounter)
  eat(p, pxCurlyRi)

proc skipInheritKeyw(p: var TParser) =
  if p.tok.xkind == pxSymbol and (p.tok.s == "private" or 
                                  p.tok.s == "protected" or
                                  p.tok.s == "public"):
    getTok(p)

proc parseConstructor(p: var TParser, pragmas: PNode, 
                      isDestructor=false): PNode =
  var origName = p.tok.s
  getTok(p)
  
  result = newNodeP(nkProcDef, p)
  var rettyp = if isDestructor: newNodeP(nkNilLit, p)
               else: mangledIdent(origName, p)
  
  let oname = if isDestructor: "destroy" & origName
              else: "construct" & origName
  var name = mangledIdent(oname, p)
  var params = newNodeP(nkFormalParams, p)
  addReturnType(params, rettyp)
  if p.tok.xkind == pxParLe:
    parseFormalParams(p, params, pragmas)
  if p.tok.xkind == pxSymbol and p.tok.s == "const":
    addSon(pragmas, newIdentNodeP("noSideEffect", p))
  if pfCDecl in p.options.flags:
    addSon(pragmas, newIdentNodeP("cdecl", p))
  elif pfStdcall in p.options.flags:
    addSon(pragmas, newIdentNodeP("stdcall", p))
  if p.tok.xkind == pxColon:
    # skip initializer list:
    while true:
      getTok(p)
      discard expression(p)
      if p.tok.xkind != pxComma: break
  # no pattern, no exceptions:
  addSon(result, exportSym(p, name, origName), ast.emptyNode, ast.emptyNode)
  addSon(result, params, pragmas, ast.emptyNode) # no exceptions
  addSon(result, ast.emptyNode) # no body
  case p.tok.xkind 
  of pxSemicolon: getTok(p)
  of pxCurlyLe:
    let body = compoundStatement(p)
    if pfKeepBodies in p.options.flags:
      result.sons[bodyPos] = body
  else:
    parMessage(p, errTokenExpected, ";")
  if result.sons[bodyPos].kind == nkEmpty:
    doImport((if isDestructor: "~" else: "") & origName, pragmas, p)
  elif isDestructor:
    addSon(pragmas, newIdentNodeP("destructor", p))
  if sonsLen(result.sons[pragmasPos]) == 0:
    result.sons[pragmasPos] = ast.emptyNode

proc parseMethod(p: var TParser, origName: string, rettyp, pragmas: PNode,
                 isStatic: bool): PNode =
  result = newNodeP(nkProcDef, p)
  var params = newNodeP(nkFormalParams, p)
  addReturnType(params, rettyp)
  var thisDef = newNodeP(nkIdentDefs, p)
  if not isStatic:
    # declare 'this':
    var t = newNodeP(nkVarTy, p)
    t.add(p.currentClass)
    addSon(thisDef, newIdentNodeP("this", p), t, ast.emptyNode)
    params.add(thisDef)
  parseFormalParams(p, params, pragmas)
  if p.tok.xkind == pxSymbol and p.tok.s == "const":
    addSon(pragmas, newIdentNodeP("noSideEffect", p))
    getTok(p, result)
    if not isStatic:
      # fix the type of the 'this' parameter:
      thisDef.sons[1] = thisDef.sons[1].sons[0]
  if pfCDecl in p.options.flags:
    addSon(pragmas, newIdentNodeP("cdecl", p))
  elif pfStdcall in p.options.flags:
    addSon(pragmas, newIdentNodeP("stdcall", p))
  # no pattern, no exceptions:
  let methodName = newIdentNodeP(origName, p)
  addSon(result, exportSym(p, methodName, origName),
         ast.emptyNode, ast.emptyNode)
  addSon(result, params, pragmas, ast.emptyNode) # no exceptions
  addSon(result, ast.emptyNode) # no body
  case p.tok.xkind
  of pxSemicolon: getTok(p)
  of pxCurlyLe:
    let body = compoundStatement(p)
    if pfKeepBodies in p.options.flags:
      result.sons[bodyPos] = body
  else:
    parMessage(p, errTokenExpected, ";")
  if result.sons[bodyPos].kind == nkEmpty:
    if isStatic: doImport(origName, pragmas, p)
    else: doImportCpp(origName, pragmas, p)
  if sonsLen(result.sons[pragmasPos]) == 0:
    result.sons[pragmasPos] = ast.emptyNode

proc parseStandaloneClass(p: var TParser, isStruct: bool): PNode

proc followedByParLe(p: var TParser): bool =
  saveContext(p)
  getTok(p) # skip Identifier
  result = p.tok.xkind == pxParLe
  backtrackContext(p)

proc parseOperator(p: var TParser, origName: var string): bool =
  getTok(p) # skip 'operator' keyword
  case p.tok.xkind
  of pxAmp..pxArrow:
    # ordinary operator symbol:
    origName.add(tokKindToStr(p.tok.xkind))
    getTok(p)
  of pxSymbol:
    if p.tok.s == "new" or p.tok.s == "delete":
      origName.add(p.tok.s)
      getTok(p)
      if p.tok.xkind == pxBracketLe:
        getTok(p)
        eat(p, pxBracketRi)
        origName.add("[]")
    else:
      # type converter
      let x = typeAtom(p)
      if x.kind == nkIdent:
        origName.add(x.ident.s)
      else:
        parMessage(p, errGenerated, "operator symbol expected")
      result = true
  of pxParLe:
    getTok(p)
    eat(p, pxParRi)
    origName.add("()")
  of pxBracketLe:
    getTok(p)
    eat(p, pxBracketRi)
    origName.add("[]")
  else:
    parMessage(p, errGenerated, "operator symbol expected")

proc parseClass(p: var TParser; isStruct: bool; stmtList: PNode): PNode =
  result = newNodeP(nkObjectTy, p)
  addSon(result, ast.emptyNode, ast.emptyNode) # no pragmas, no inheritance 
  
  var recList = newNodeP(nkRecList, p)
  addSon(result, recList)
  if p.tok.xkind == pxColon:
    getTok(p, result)
    skipInheritKeyw(p)
    var baseTyp = typeAtom(p)
    var inh = newNodeP(nkOfInherit, p)
    inh.add(baseTyp)
    if p.tok.xkind == pxComma:
      parMessage(p, errGenerated, "multiple inheritance is not supported")
      while p.tok.xkind == pxComma:
        getTok(p)
        skipInheritKeyw(p)
        discard typeAtom(p)
    result.sons[0] = inh
    
  eat(p, pxCurlyLe, result)
  var private = not isStruct
  var pragmas = newNodeP(nkPragma, p)
  while p.tok.xkind notin {pxEof, pxCurlyRi}:
    skipCom(p, stmtList)
    if p.tok.xkind == pxSymbol and (p.tok.s == "private" or 
                                    p.tok.s == "protected"):
      getTok(p, result)
      eat(p, pxColon, result)
      private = true
    elif p.tok.xkind == pxSymbol and p.tok.s == "public":
      getTok(p, result)
      eat(p, pxColon, result)
      private = false
    if p.tok.xkind == pxSymbol and (p.tok.s == "friend" or p.tok.s == "using"):
      # we skip friend declarations:
      while p.tok.xkind notin {pxEof, pxSemicolon}: getTok(p)
      eat(p, pxSemicolon)
    elif p.tok.xkind == pxSymbol and p.tok.s == "enum":
      let x = enumSpecifier(p)
      if not private or pfKeepBodies in p.options.flags: stmtList.add(x)
    elif p.tok.xkind == pxSymbol and p.tok.s == "typedef":
      let x = parseTypeDef(p)
      if not private or pfKeepBodies in p.options.flags: stmtList.add(x)
    elif p.tok.xkind == pxSymbol and(p.tok.s == "struct" or p.tok.s == "class"):
      let x = parseStandaloneClass(p, isStruct=p.tok.s == "struct")
      if not private or pfKeepBodies in p.options.flags: stmtList.add(x)
    elif p.tok.xkind == pxSymbol and p.tok.s == "union":
      let x = parseStandaloneStruct(p, isUnion=true)
      if not private or pfKeepBodies in p.options.flags: stmtList.add(x)
    else:
      if pragmas.len != 0: pragmas = newNodeP(nkPragma, p)
      parseCallConv(p, pragmas)
      var isStatic = false
      if p.tok.xkind == pxSymbol and p.tok.s == "virtual":
        getTok(p, stmtList)
      if p.tok.xkind == pxSymbol and p.tok.s == "explicit":
        getTok(p, stmtList)
      if p.tok.xkind == pxSymbol and p.tok.s == "static":
        getTok(p, stmtList)
        isStatic = true
      parseCallConv(p, pragmas)
      if p.tok.xkind == pxSymbol and p.tok.s == p.currentClass.ident.s and 
          followedByParLe(p):
        # constructor
        let cons = parseConstructor(p, pragmas)
        if not private or pfKeepBodies in p.options.flags: stmtList.add(cons)
      elif p.tok.xkind == pxTilde:
        # destructor
        getTok(p, stmtList)
        if p.tok.xkind == pxSymbol and p.tok.s == p.currentClass.ident.s:
          let des = parseConstructor(p, pragmas, isDestructor=true)
          if not private or pfKeepBodies in p.options.flags: stmtList.add(des)
        else:
          parMessage(p, errGenerated, "invalid destructor")
      else:
        # field declaration or method:
        var baseTyp = typeAtom(p)
        while true:
          var def = newNodeP(nkIdentDefs, p)
          var t = pointer(p, baseTyp)
          let canBeMethod = p.tok.xkind != pxParLe
          var origName: string
          if p.tok.xkind == pxSymbol:
            origName = p.tok.s
            if p.tok.s == "operator":
              var isConverter = parseOperator(p, origName)
              let meth = parseMethod(p, origName, t, pragmas, isStatic)
              if not private or pfKeepBodies in p.options.flags:
                if isConverter: meth.kind = nkConverterDef
                stmtList.add(meth)
              break
          var i = parseField(p, nkRecList)
          if canBeMethod and p.tok.xkind == pxParLe:
            let meth = parseMethod(p, origName, t, pragmas, isStatic)
            if not private or pfKeepBodies in p.options.flags:
              stmtList.add(meth)
          else:
            t = parseTypeSuffix(p, t)
            addSon(def, i, t, ast.emptyNode)
            if not isStatic: addSon(recList, def)
          if p.tok.xkind != pxComma: break
          getTok(p, def)
        if p.tok.xkind == pxSemicolon:
          getTok(p, lastSon(recList))
  eat(p, pxCurlyRi, result)

proc parseStandaloneClass(p: var TParser, isStruct: bool): PNode =
  result = newNodeP(nkStmtList, p)
  saveContext(p)
  getTok(p, result) # skip "class" or "struct"
  var origName = ""
  let oldClass = p.currentClass
  if p.tok.xkind == pxSymbol: 
    markTypeIdent(p, nil)
    origName = p.tok.s
    getTok(p, result)
    p.currentClass = mangledIdent(origName, p)
  else:
    p.currentClass = nil
  if p.tok.xkind in {pxCurlyLe, pxSemiColon, pxColon}:
    if origName.len > 0:
      p.options.classes[origName] = "true"

      var typeSection = newNodeP(nkTypeSection, p)
      addSon(result, typeSection)
      
      var name = mangledIdent(origName, p)
      var t = parseClass(p, isStruct, result)
      addTypeDef(typeSection, structPragmas(p, name, origName), t)
      parseTrailingDefinedIdents(p, result, name)
    else:
      var t = parseTuple(p, isUnion=false)
      parseTrailingDefinedIdents(p, result, t)
  else:
    backtrackContext(p)
    result = declaration(p)
  p.currentClass = oldClass

proc unwrap(a: PNode): PNode =
  if a.kind == nkPar:
    return a.sons[0]
  return a

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
      addSon(result, ast.emptyNode)
    of "break":
      result = newNodeP(nkBreakStmt, p)
      getTok(p)
      eat(p, pxSemicolon)
      addSon(result, ast.emptyNode)
    of "return":
      result = newNodeP(nkReturnStmt, p)
      getTok(p)
      if p.tok.xkind == pxSemicolon:
        addSon(result, ast.emptyNode)
      else:
        addSon(result, unwrap(expression(p)))
      eat(p, pxSemicolon)
    of "enum": result = enumSpecifier(p)
    of "typedef": result = parseTypeDef(p)
    of "union": result = parseStandaloneStruct(p, isUnion=true)
    of "struct":
      if pfCpp in p.options.flags:
        result = parseStandaloneClass(p, isStruct=true)
      else:
        result = parseStandaloneStruct(p, isUnion=false)
    of "class":
      if pfCpp in p.options.flags:
        result = parseStandaloneClass(p, isStruct=false)
      else:
        result = declarationOrStatement(p)
    of "namespace":
      if pfCpp in p.options.flags:
        while p.tok.xkind notin {pxEof, pxCurlyLe}: getTok(p)
        result = compoundStatement(p)
      else:
        result = declarationOrStatement(p)
    of "using":
      if pfCpp in p.options.flags:
        while p.tok.xkind notin {pxEof, pxSemicolon}: getTok(p)
        eat(p, pxSemicolon)
        result = newNodeP(nkNilLit, p)
      else:
        result = declarationOrStatement(p)
    else: result = declarationOrStatement(p)
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
  assert result != nil

proc parseUnit(p: var TParser): PNode =
  try:
    result = newNodeP(nkStmtList, p)
    getTok(p) # read first token
    while p.tok.xkind != pxEof:
      var s = statement(p)
      if s.kind != nkEmpty: embedStmts(result, s)
  except ERetryParsing:
    parMessage(p, errGenerated, "Uncaught parsing exception raised")

