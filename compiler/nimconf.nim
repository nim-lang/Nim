#
#
#           The Nimrod Compiler
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module handles the reading of the config file.

import 
  llstream, nversion, commands, os, strutils, msgs, platform, condsyms, scanner, 
  options, idents, wordrecg

# ---------------- configuration file parser -----------------------------
# we use Nimrod's scanner here to safe space and work

proc ppGetTok(L: var TLexer, tok: PToken) = 
  # simple filter
  rawGetTok(L, tok[])
  while tok.tokType in {tkInd, tkSad, tkDed, tkComment}: rawGetTok(L, tok[])
  
proc parseExpr(L: var TLexer, tok: PToken): bool
proc parseAtom(L: var TLexer, tok: PToken): bool = 
  if tok.tokType == tkParLe: 
    ppGetTok(L, tok)
    result = parseExpr(L, tok)
    if tok.tokType == tkParRi: ppGetTok(L, tok)
    else: lexMessage(L, errTokenExpected, "\')\'")
  elif tok.ident.id == ord(wNot): 
    ppGetTok(L, tok)
    result = not parseAtom(L, tok)
  else:
    result = isDefined(tok.ident)
    ppGetTok(L, tok)

proc parseAndExpr(L: var TLexer, tok: PToken): bool = 
  result = parseAtom(L, tok)
  while tok.ident.id == ord(wAnd): 
    ppGetTok(L, tok)          # skip "and"
    var b = parseAtom(L, tok)
    result = result and b

proc parseExpr(L: var TLexer, tok: PToken): bool = 
  result = parseAndExpr(L, tok)
  while tok.ident.id == ord(wOr): 
    ppGetTok(L, tok)          # skip "or"
    var b = parseAndExpr(L, tok)
    result = result or b

proc EvalppIf(L: var TLexer, tok: PToken): bool = 
  ppGetTok(L, tok)            # skip 'if' or 'elif'
  result = parseExpr(L, tok)
  if tok.tokType == tkColon: ppGetTok(L, tok)
  else: lexMessage(L, errTokenExpected, "\':\'")
  
var condStack: seq[bool] = @[]

proc doEnd(L: var TLexer, tok: PToken) = 
  if high(condStack) < 0: lexMessage(L, errTokenExpected, "@if")
  ppGetTok(L, tok)            # skip 'end'
  setlen(condStack, high(condStack))

type 
  TJumpDest = enum 
    jdEndif, jdElseEndif

proc jumpToDirective(L: var TLexer, tok: PToken, dest: TJumpDest)
proc doElse(L: var TLexer, tok: PToken) = 
  if high(condStack) < 0: lexMessage(L, errTokenExpected, "@if")
  ppGetTok(L, tok)
  if tok.tokType == tkColon: ppGetTok(L, tok)
  if condStack[high(condStack)]: jumpToDirective(L, tok, jdEndif)
  
proc doElif(L: var TLexer, tok: PToken) = 
  if high(condStack) < 0: lexMessage(L, errTokenExpected, "@if")
  var res = EvalppIf(L, tok)
  if condStack[high(condStack)] or not res: jumpToDirective(L, tok, jdElseEndif)
  else: condStack[high(condStack)] = true
  
proc jumpToDirective(L: var TLexer, tok: PToken, dest: TJumpDest) = 
  var nestedIfs = 0
  while True: 
    if (tok.ident != nil) and (tok.ident.s == "@"): 
      ppGetTok(L, tok)
      case whichKeyword(tok.ident)
      of wIf: 
        Inc(nestedIfs)
      of wElse: 
        if (dest == jdElseEndif) and (nestedIfs == 0): 
          doElse(L, tok)
          break 
      of wElif: 
        if (dest == jdElseEndif) and (nestedIfs == 0): 
          doElif(L, tok)
          break 
      of wEnd: 
        if nestedIfs == 0: 
          doEnd(L, tok)
          break 
        if nestedIfs > 0: Dec(nestedIfs)
      else: 
        nil
      ppGetTok(L, tok)
    elif tok.tokType == tkEof: 
      lexMessage(L, errTokenExpected, "@end")
    else: 
      ppGetTok(L, tok)
  
proc parseDirective(L: var TLexer, tok: PToken) = 
  ppGetTok(L, tok)            # skip @
  case whichKeyword(tok.ident)
  of wIf: 
    setlen(condStack, len(condStack) + 1)
    var res = EvalppIf(L, tok)
    condStack[high(condStack)] = res
    if not res: jumpToDirective(L, tok, jdElseEndif)
  of wElif: doElif(L, tok)
  of wElse: doElse(L, tok)
  of wEnd: doEnd(L, tok)
  of wWrite: 
    ppGetTok(L, tok)
    msgs.MsgWriteln(tokToStr(tok))
    ppGetTok(L, tok)
  of wPutEnv: 
    ppGetTok(L, tok)
    var key = tokToStr(tok)
    ppGetTok(L, tok)
    os.putEnv(key, tokToStr(tok))
    ppGetTok(L, tok)
  of wPrependEnv: 
    ppGetTok(L, tok)
    var key = tokToStr(tok)
    ppGetTok(L, tok)
    os.putEnv(key, tokToStr(tok) & os.getenv(key))
    ppGetTok(L, tok)
  of wAppendenv: 
    ppGetTok(L, tok)
    var key = tokToStr(tok)
    ppGetTok(L, tok)
    os.putEnv(key, os.getenv(key) & tokToStr(tok))
    ppGetTok(L, tok)
  else: lexMessage(L, errInvalidDirectiveX, tokToStr(tok))
  
proc confTok(L: var TLexer, tok: PToken) = 
  ppGetTok(L, tok)
  while tok.ident != nil and tok.ident.s == "@": 
    parseDirective(L, tok)    # else: give the token to the parser
  
proc checkSymbol(L: TLexer, tok: PToken) = 
  if tok.tokType notin {tkSymbol..pred(tkIntLit), tkStrLit..tkTripleStrLit}: 
    lexMessage(L, errIdentifierExpected, tokToStr(tok))
  
proc parseAssignment(L: var TLexer, tok: PToken) = 
  if tok.ident.id == getIdent("-").id or tok.ident.id == getIdent("--").id:
    confTok(L, tok)           # skip unnecessary prefix
  var info = getLineInfo(L)   # safe for later in case of an error
  checkSymbol(L, tok)
  var s = tokToStr(tok)
  confTok(L, tok)             # skip symbol
  var val = ""
  while tok.tokType == tkDot: 
    add(s, '.')
    confTok(L, tok)
    checkSymbol(L, tok)
    add(s, tokToStr(tok))
    confTok(L, tok)
  if tok.tokType == tkBracketLe: 
    # BUGFIX: val, not s!
    # BUGFIX: do not copy '['!
    confTok(L, tok)
    checkSymbol(L, tok)
    add(val, tokToStr(tok))
    confTok(L, tok)
    if tok.tokType == tkBracketRi: confTok(L, tok)
    else: lexMessage(L, errTokenExpected, "\']\'")
    add(val, ']')
  if tok.tokType in {tkColon, tkEquals}: 
    if len(val) > 0: add(val, ':')
    confTok(L, tok)           # skip ':' or '='
    checkSymbol(L, tok)
    add(val, tokToStr(tok))
    confTok(L, tok)           # skip symbol
    while tok.ident != nil and tok.ident.id == getIdent("&").id:
      confTok(L, tok)
      checkSymbol(L, tok)
      add(val, tokToStr(tok))
      confTok(L, tok)
  processSwitch(s, val, passPP, info)

proc readConfigFile(filename: string) = 
  var 
    L: TLexer
    tok: PToken
    stream: PLLStream
  new(tok)
  stream = LLStreamOpen(filename, fmRead)
  if stream != nil: 
    openLexer(L, filename, stream)
    tok.tokType = tkEof       # to avoid a pointless warning
    confTok(L, tok)           # read in the first token
    while tok.tokType != tkEof: parseAssignment(L, tok)
    if len(condStack) > 0: lexMessage(L, errTokenExpected, "@end")
    closeLexer(L)
    if gVerbosity >= 1: rawMessage(hintConf, filename)
  
proc getConfigPath(filename: string): string = 
  # try local configuration file:
  result = joinPath(getConfigDir(), filename)
  if not ExistsFile(result): 
    # try standard configuration file (installation did not distribute files
    # the UNIX way)
    result = joinPath([getPrefixDir(), "config", filename])
    if not ExistsFile(result): result = "/etc/" & filename

proc LoadSpecialConfig*(configfilename: string) = 
  if optSkipConfigFile notin gGlobalOptions:
    readConfigFile(getConfigPath(configfilename))
  
proc LoadConfig*(project: string) = 
  # set default value (can be overwritten):
  if libpath == "": 
    # choose default libpath:
    var prefix = getPrefixDir()
    if (prefix == "/usr"): libpath = "/usr/lib/nimrod"
    elif (prefix == "/usr/local"): libpath = "/usr/local/lib/nimrod"
    else: libpath = joinPath(prefix, "lib")
  LoadSpecialConfig("nimrod.cfg") # read project config file:
  if optSkipProjConfigFile notin gGlobalOptions and project != "": 
    var conffile = changeFileExt(project, "cfg")
    if existsFile(conffile): readConfigFile(conffile)
  
