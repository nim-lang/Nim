#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module handles the reading of the config file.

import
  llstream, nversion, commands, os, strutils, msgs, platform, condsyms, lexer,
  options, idents, wordrecg, strtabs, lineinfos

# ---------------- configuration file parser -----------------------------
# we use Nim's scanner here to save space and work

proc ppGetTok(L: var TLexer, tok: var TToken) =
  # simple filter
  rawGetTok(L, tok)
  while tok.tokType in {tkComment}: rawGetTok(L, tok)

proc parseExpr(L: var TLexer, tok: var TToken; config: ConfigRef): bool
proc parseAtom(L: var TLexer, tok: var TToken; config: ConfigRef): bool =
  if tok.tokType == tkParLe:
    ppGetTok(L, tok)
    result = parseExpr(L, tok, config)
    if tok.tokType == tkParRi: ppGetTok(L, tok)
    else: lexMessage(L, errGenerated, "expected closing ')'")
  elif tok.ident.id == ord(wNot):
    ppGetTok(L, tok)
    result = not parseAtom(L, tok, config)
  else:
    result = isDefined(config, tok.ident.s)
    ppGetTok(L, tok)

proc parseAndExpr(L: var TLexer, tok: var TToken; config: ConfigRef): bool =
  result = parseAtom(L, tok, config)
  while tok.ident.id == ord(wAnd):
    ppGetTok(L, tok)          # skip "and"
    var b = parseAtom(L, tok, config)
    result = result and b

proc parseExpr(L: var TLexer, tok: var TToken; config: ConfigRef): bool =
  result = parseAndExpr(L, tok, config)
  while tok.ident.id == ord(wOr):
    ppGetTok(L, tok)          # skip "or"
    var b = parseAndExpr(L, tok, config)
    result = result or b

proc evalppIf(L: var TLexer, tok: var TToken; config: ConfigRef): bool =
  ppGetTok(L, tok)            # skip 'if' or 'elif'
  result = parseExpr(L, tok, config)
  if tok.tokType == tkColon: ppGetTok(L, tok)
  else: lexMessage(L, errGenerated, "expected ':'")

#var condStack: seq[bool] = @[]

proc doEnd(L: var TLexer, tok: var TToken; condStack: var seq[bool]) =
  if high(condStack) < 0: lexMessage(L, errGenerated, "expected @if")
  ppGetTok(L, tok)            # skip 'end'
  setLen(condStack, high(condStack))

type
  TJumpDest = enum
    jdEndif, jdElseEndif

proc jumpToDirective(L: var TLexer, tok: var TToken, dest: TJumpDest; config: ConfigRef;
                     condStack: var seq[bool])
proc doElse(L: var TLexer, tok: var TToken; config: ConfigRef; condStack: var seq[bool]) =
  if high(condStack) < 0: lexMessage(L, errGenerated, "expected @if")
  ppGetTok(L, tok)
  if tok.tokType == tkColon: ppGetTok(L, tok)
  if condStack[high(condStack)]: jumpToDirective(L, tok, jdEndif, config, condStack)

proc doElif(L: var TLexer, tok: var TToken; config: ConfigRef; condStack: var seq[bool]) =
  if high(condStack) < 0: lexMessage(L, errGenerated, "expected @if")
  var res = evalppIf(L, tok, config)
  if condStack[high(condStack)] or not res: jumpToDirective(L, tok, jdElseEndif, config, condStack)
  else: condStack[high(condStack)] = true

proc jumpToDirective(L: var TLexer, tok: var TToken, dest: TJumpDest; config: ConfigRef;
                     condStack: var seq[bool]) =
  var nestedIfs = 0
  while true:
    if tok.ident != nil and tok.ident.s == "@":
      ppGetTok(L, tok)
      case whichKeyword(tok.ident)
      of wIf:
        inc(nestedIfs)
      of wElse:
        if dest == jdElseEndif and nestedIfs == 0:
          doElse(L, tok, config, condStack)
          break
      of wElif:
        if dest == jdElseEndif and nestedIfs == 0:
          doElif(L, tok, config, condStack)
          break
      of wEnd:
        if nestedIfs == 0:
          doEnd(L, tok, condStack)
          break
        if nestedIfs > 0: dec(nestedIfs)
      else:
        discard
      ppGetTok(L, tok)
    elif tok.tokType == tkEof:
      lexMessage(L, errGenerated, "expected @end")
    else:
      ppGetTok(L, tok)

proc parseDirective(L: var TLexer, tok: var TToken; config: ConfigRef; condStack: var seq[bool]) =
  ppGetTok(L, tok)            # skip @
  case whichKeyword(tok.ident)
  of wIf:
    setLen(condStack, len(condStack) + 1)
    let res = evalppIf(L, tok, config)
    condStack[high(condStack)] = res
    if not res: jumpToDirective(L, tok, jdElseEndif, config, condStack)
  of wElif: doElif(L, tok, config, condStack)
  of wElse: doElse(L, tok, config, condStack)
  of wEnd: doEnd(L, tok, condStack)
  of wWrite:
    ppGetTok(L, tok)
    msgs.msgWriteln(config, strtabs.`%`(tokToStr(tok), config.configVars,
                                {useEnvironment, useKey}))
    ppGetTok(L, tok)
  else:
    case tok.ident.s.normalize
    of "putenv":
      ppGetTok(L, tok)
      var key = tokToStr(tok)
      ppGetTok(L, tok)
      os.putEnv(key, tokToStr(tok))
      ppGetTok(L, tok)
    of "prependenv":
      ppGetTok(L, tok)
      var key = tokToStr(tok)
      ppGetTok(L, tok)
      os.putEnv(key, tokToStr(tok) & os.getEnv(key))
      ppGetTok(L, tok)
    of "appendenv":
      ppGetTok(L, tok)
      var key = tokToStr(tok)
      ppGetTok(L, tok)
      os.putEnv(key, os.getEnv(key) & tokToStr(tok))
      ppGetTok(L, tok)
    else:
      lexMessage(L, errGenerated, "invalid directive: '$1'" % tokToStr(tok))

proc confTok(L: var TLexer, tok: var TToken; config: ConfigRef; condStack: var seq[bool]) =
  ppGetTok(L, tok)
  while tok.ident != nil and tok.ident.s == "@":
    parseDirective(L, tok, config, condStack)    # else: give the token to the parser

proc checkSymbol(L: TLexer, tok: TToken) =
  if tok.tokType notin {tkSymbol..tkInt64Lit, tkStrLit..tkTripleStrLit}:
    lexMessage(L, errGenerated, "expected identifier, but got: " & tokToStr(tok))

proc parseAssignment(L: var TLexer, tok: var TToken;
                     config: ConfigRef; condStack: var seq[bool]) =
  if tok.ident.s == "-" or tok.ident.s == "--":
    confTok(L, tok, config, condStack)           # skip unnecessary prefix
  var info = getLineInfo(L, tok) # save for later in case of an error
  checkSymbol(L, tok)
  var s = tokToStr(tok)
  confTok(L, tok, config, condStack)             # skip symbol
  var val = ""
  while tok.tokType == tkDot:
    add(s, '.')
    confTok(L, tok, config, condStack)
    checkSymbol(L, tok)
    add(s, tokToStr(tok))
    confTok(L, tok, config, condStack)
  if tok.tokType == tkBracketLe:
    # BUGFIX: val, not s!
    # BUGFIX: do not copy '['!
    confTok(L, tok, config, condStack)
    checkSymbol(L, tok)
    add(val, tokToStr(tok))
    confTok(L, tok, config, condStack)
    if tok.tokType == tkBracketRi: confTok(L, tok, config, condStack)
    else: lexMessage(L, errGenerated, "expected closing ']'")
    add(val, ']')
  let percent = tok.ident != nil and tok.ident.s == "%="
  if tok.tokType in {tkColon, tkEquals} or percent:
    if len(val) > 0: add(val, ':')
    confTok(L, tok, config, condStack)           # skip ':' or '=' or '%'
    checkSymbol(L, tok)
    add(val, tokToStr(tok))
    confTok(L, tok, config, condStack)           # skip symbol
    while tok.ident != nil and tok.ident.s == "&":
      confTok(L, tok, config, condStack)
      checkSymbol(L, tok)
      add(val, tokToStr(tok))
      confTok(L, tok, config, condStack)
  if percent:
    processSwitch(s, strtabs.`%`(val, config.configVars,
                                {useEnvironment, useEmpty}), passPP, info, config)
  else:
    processSwitch(s, val, passPP, info, config)

proc readConfigFile(
    filename: string; cache: IdentCache; config: ConfigRef): bool =
  var
    L: TLexer
    tok: TToken
    stream: PLLStream
  stream = llStreamOpen(filename, fmRead)
  if stream != nil:
    initToken(tok)
    openLexer(L, filename, stream, cache, config)
    tok.tokType = tkEof       # to avoid a pointless warning
    var condStack: seq[bool] = @[]
    confTok(L, tok, config, condStack)           # read in the first token
    while tok.tokType != tkEof: parseAssignment(L, tok, config, condStack)
    if len(condStack) > 0: lexMessage(L, errGenerated, "expected @end")
    closeLexer(L)
    return true

proc getUserConfigPath(filename: string): string =
  result = joinPath(getConfigDir(), filename)

proc getSystemConfigPath(conf: ConfigRef; filename: string): string =
  # try standard configuration file (installation did not distribute files
  # the UNIX way)
  let p = getPrefixDir(conf)
  result = joinPath([p, "config", filename])
  when defined(unix):
    if not existsFile(result): result = joinPath([p, "etc", filename])
    if not existsFile(result): result = "/etc/" & filename

proc loadConfigs*(cfg: string; cache: IdentCache; conf: ConfigRef) =
  setDefaultLibpath(conf)

  var configFiles = newSeq[string]()

  template readConfigFile(path: string) =
    let configPath = path
    if readConfigFile(configPath, cache, conf):
      add(configFiles, configPath)

  if optSkipConfigFile notin conf.globalOptions:
    readConfigFile(getSystemConfigPath(conf, cfg))

  if optSkipUserConfigFile notin conf.globalOptions:
    readConfigFile(getUserConfigPath(cfg))

  let pd = if conf.projectPath.len > 0: conf.projectPath else: getCurrentDir()
  if optSkipParentConfigFiles notin conf.globalOptions:
    for dir in parentDirs(pd, fromRoot=true, inclusive=false):
      readConfigFile(dir / cfg)

  if optSkipProjConfigFile notin conf.globalOptions:
    readConfigFile(pd / cfg)

    if conf.projectName.len != 0:
      # new project wide config file:
      var projectConfig = changeFileExt(conf.projectFull, "nimcfg")
      if not fileExists(projectConfig):
        projectConfig = changeFileExt(conf.projectFull, "nim.cfg")
      readConfigFile(projectConfig)

  for filename in configFiles:
    rawMessage(conf, hintConf, filename)
