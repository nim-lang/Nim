#
#
#           The Nimrod Compiler
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements a FreePascal scanner. This is a adaption from
# the scanner module.

import 
  nhashes, options, msgs, strutils, platform, idents, lexbase, wordrecg, scanner

const 
  MaxLineLength* = 80         # lines longer than this lead to a warning
  numChars*: TCharSet = {'0'..'9', 'a'..'z', 'A'..'Z'} # we support up to base 36
  SymChars*: TCharSet = {'a'..'z', 'A'..'Z', '0'..'9', '\x80'..'\xFF'}
  SymStartChars*: TCharSet = {'a'..'z', 'A'..'Z', '\x80'..'\xFF'}
  OpChars*: TCharSet = {'+', '-', '*', '/', '<', '>', '!', '?', '^', '.', '|', 
    '=', ':', '%', '&', '$', '@', '~', '\x80'..'\xFF'}

type                          # order is important for TPasTokKind
  TPasTokKind* = enum 
    pxInvalid, pxEof,         # keywords:
                              #[[[cog
                              #from string import capitalize
                              #keywords = eval(open("data/pas_keyw.yml").read())
                              #idents = ""
                              #strings = ""
                              #i = 1
                              #for k in keywords:
                              #  idents = idents + "px" + capitalize(k) + ", "
                              #  strings = strings + "'" + k + "', "
                              #  if i % 4 == 0:
                              #    idents = idents + "\n"
                              #    strings = strings + "\n"
                              #  i = i + 1
                              #cog.out(idents)
                              #]]]
    pxAnd, pxArray, pxAs, pxAsm, pxBegin, pxCase, pxClass, pxConst, 
    pxConstructor, pxDestructor, pxDiv, pxDo, pxDownto, pxElse, pxEnd, pxExcept, 
    pxExports, pxFinalization, pxFinally, pxFor, pxFunction, pxGoto, pxIf, 
    pxImplementation, pxIn, pxInherited, pxInitialization, pxInline, 
    pxInterface, pxIs, pxLabel, pxLibrary, pxMod, pxNil, pxNot, pxObject, pxOf, 
    pxOr, pxOut, pxPacked, pxProcedure, pxProgram, pxProperty, pxRaise, 
    pxRecord, pxRepeat, pxResourcestring, pxSet, pxShl, pxShr, pxThen, 
    pxThreadvar, pxTo, pxTry, pxType, pxUnit, pxUntil, pxUses, pxVar, pxWhile, 
    pxWith, pxXor,            #[[[end]]]
    pxComment,                # ordinary comment
    pxCommand,                # {@}
    pxAmp,                    # {&}
    pxPer,                    # {%}
    pxStrLit, pxSymbol,       # a symbol
    pxIntLit, pxInt64Lit,     # long constant like 0x00000070fffffff or out of int range
    pxFloatLit, pxParLe, pxParRi, pxBracketLe, pxBracketRi, pxComma, 
    pxSemiColon, pxColon,     # operators
    pxAsgn, pxEquals, pxDot, pxDotDot, pxHat, pxPlus, pxMinus, pxStar, pxSlash, 
    pxLe, pxLt, pxGe, pxGt, pxNeq, pxAt, pxStarDirLe, pxStarDirRi, pxCurlyDirLe, 
    pxCurlyDirRi
  TPasTokKinds* = set[TPasTokKind]

const 
  PasTokKindToStr*: array[TPasTokKind, string] = ["pxInvalid", "[EOF]", #[[[cog
                                                                        #cog.out(strings)
                                                                        #]]]
    "and", "array", "as", "asm", "begin", "case", "class", "const", 
    "constructor", "destructor", "div", "do", "downto", "else", "end", "except", 
    "exports", "finalization", "finally", "for", "function", "goto", "if", 
    "implementation", "in", "inherited", "initialization", "inline", 
    "interface", "is", "label", "library", "mod", "nil", "not", "object", "of", 
    "or", "out", "packed", "procedure", "program", "property", "raise", 
    "record", "repeat", "resourcestring", "set", "shl", "shr", "then", 
    "threadvar", "to", "try", "type", "unit", "until", "uses", "var", "while", 
    "with", "xor",            #[[[end]]]
    "pxComment", "pxCommand", "{&}", "{%}", "pxStrLit", "[IDENTIFIER]", 
    "pxIntLit", "pxInt64Lit", "pxFloatLit", "(", ")", "[", "]", ",", ";", ":", 
    ":=", "=", ".", "..", "^", "+", "-", "*", "/", "<=", "<", ">=", ">", "<>", 
    "@", "(*$", "*)", "{$", "}"]

type 
  TPasTok* = object of TToken # a Pascal token
    xkind*: TPasTokKind       # the type of the token
  
  TPasLex* = object of TLexer

proc getPasTok*(L: var TPasLex, tok: var TPasTok)
proc PrintPasTok*(tok: TPasTok)
proc pasTokToStr*(tok: TPasTok): string
# implementation

proc pastokToStr(tok: TPasTok): string = 
  case tok.xkind
  of pxIntLit, pxInt64Lit: result = $(tok.iNumber)
  of pxFloatLit: result = $(tok.fNumber)
  of pxInvalid, pxComment..pxStrLit: result = tok.literal
  else: 
    if (tok.ident.s != ""): result = tok.ident.s
    else: result = pasTokKindToStr[tok.xkind]
  
proc PrintPasTok(tok: TPasTok) = 
  write(stdout, pasTokKindToStr[tok.xkind])
  write(stdout, ' ')
  writeln(stdout, pastokToStr(tok))

proc setKeyword(L: var TPasLex, tok: var TPasTok) = 
  case tok.ident.id #[[[cog
                    #for k in keywords:
                    #  m = capitalize(k)
                    #  cog.outl("ord(w%s):%s tok.xkind := px%s;" % (m, ' '*(18-len(m)), m))
                    #]]]
  of ord(wAnd): 
    tok.xkind = pxAnd
  of ord(wArray): 
    tok.xkind = pxArray
  of ord(wAs): 
    tok.xkind = pxAs
  of ord(wAsm): 
    tok.xkind = pxAsm
  of ord(wBegin): 
    tok.xkind = pxBegin
  of ord(wCase): 
    tok.xkind = pxCase
  of ord(wClass): 
    tok.xkind = pxClass
  of ord(wConst): 
    tok.xkind = pxConst
  of ord(wConstructor): 
    tok.xkind = pxConstructor
  of ord(wDestructor): 
    tok.xkind = pxDestructor
  of ord(wDiv): 
    tok.xkind = pxDiv
  of ord(wDo): 
    tok.xkind = pxDo
  of ord(wDownto): 
    tok.xkind = pxDownto
  of ord(wElse): 
    tok.xkind = pxElse
  of ord(wEnd): 
    tok.xkind = pxEnd
  of ord(wExcept): 
    tok.xkind = pxExcept
  of ord(wExports): 
    tok.xkind = pxExports
  of ord(wFinalization): 
    tok.xkind = pxFinalization
  of ord(wFinally): 
    tok.xkind = pxFinally
  of ord(wFor): 
    tok.xkind = pxFor
  of ord(wFunction): 
    tok.xkind = pxFunction
  of ord(wGoto): 
    tok.xkind = pxGoto
  of ord(wIf): 
    tok.xkind = pxIf
  of ord(wImplementation): 
    tok.xkind = pxImplementation
  of ord(wIn): 
    tok.xkind = pxIn
  of ord(wInherited): 
    tok.xkind = pxInherited
  of ord(wInitialization): 
    tok.xkind = pxInitialization
  of ord(wInline): 
    tok.xkind = pxInline
  of ord(wInterface): 
    tok.xkind = pxInterface
  of ord(wIs): 
    tok.xkind = pxIs
  of ord(wLabel): 
    tok.xkind = pxLabel
  of ord(wLibrary): 
    tok.xkind = pxLibrary
  of ord(wMod): 
    tok.xkind = pxMod
  of ord(wNil): 
    tok.xkind = pxNil
  of ord(wNot): 
    tok.xkind = pxNot
  of ord(wObject): 
    tok.xkind = pxObject
  of ord(wOf): 
    tok.xkind = pxOf
  of ord(wOr): 
    tok.xkind = pxOr
  of ord(wOut): 
    tok.xkind = pxOut
  of ord(wPacked): 
    tok.xkind = pxPacked
  of ord(wProcedure): 
    tok.xkind = pxProcedure
  of ord(wProgram): 
    tok.xkind = pxProgram
  of ord(wProperty): 
    tok.xkind = pxProperty
  of ord(wRaise): 
    tok.xkind = pxRaise
  of ord(wRecord): 
    tok.xkind = pxRecord
  of ord(wRepeat): 
    tok.xkind = pxRepeat
  of ord(wResourcestring): 
    tok.xkind = pxResourcestring
  of ord(wSet): 
    tok.xkind = pxSet
  of ord(wShl): 
    tok.xkind = pxShl
  of ord(wShr): 
    tok.xkind = pxShr
  of ord(wThen): 
    tok.xkind = pxThen
  of ord(wThreadvar): 
    tok.xkind = pxThreadvar
  of ord(wTo): 
    tok.xkind = pxTo
  of ord(wTry): 
    tok.xkind = pxTry
  of ord(wType): 
    tok.xkind = pxType
  of ord(wUnit): 
    tok.xkind = pxUnit
  of ord(wUntil): 
    tok.xkind = pxUntil
  of ord(wUses): 
    tok.xkind = pxUses
  of ord(wVar): 
    tok.xkind = pxVar
  of ord(wWhile): 
    tok.xkind = pxWhile
  of ord(wWith): 
    tok.xkind = pxWith
  of ord(wXor): 
    tok.xkind = pxXor         #[[[end]]]
  else: tok.xkind = pxSymbol
  
proc matchUnderscoreChars(L: var TPasLex, tok: var TPasTok, chars: TCharSet) = 
  # matches ([chars]_)*
  var 
    pos: int
    buf: cstring
  pos = L.bufpos              # use registers for pos, buf
  buf = L.buf
  while true: 
    if buf[pos] in chars: 
      add(tok.literal, buf[pos])
      Inc(pos)
    else: 
      break 
    if buf[pos] == '_': 
      add(tok.literal, '_')
      Inc(pos)
  L.bufPos = pos

proc isFloatLiteral(s: string): bool = 
  for i in countup(0, len(s) + 0 - 1): 
    if s[i] in {'.', 'e', 'E'}: 
      return true
  result = false

proc getNumber2(L: var TPasLex, tok: var TPasTok) = 
  var 
    pos, bits: int
    xi: biggestInt
  pos = L.bufpos + 1          # skip %
  if not (L.buf[pos] in {'0'..'1'}): 
    # BUGFIX for %date%
    tok.xkind = pxInvalid
    add(tok.literal, '%')
    inc(L.bufpos)
    return 
  tok.base = base2
  xi = 0
  bits = 0
  while true: 
    case L.buf[pos]
    of 'A'..'Z', 'a'..'z', '2'..'9', '.': 
      lexMessage(L, errInvalidNumber)
      inc(pos)
    of '_': 
      inc(pos)
    of '0', '1': 
      xi = `shl`(xi, 1) or (ord(L.buf[pos]) - ord('0'))
      inc(pos)
      inc(bits)
    else: break 
  tok.iNumber = xi
  if (bits > 32): 
    tok.xkind = pxInt64Lit
  else: 
    tok.xkind = pxIntLit
  L.bufpos = pos

proc getNumber16(L: var TPasLex, tok: var TPasTok) = 
  var 
    pos, bits: int
    xi: biggestInt
  pos = L.bufpos + 1          # skip $
  tok.base = base16
  xi = 0
  bits = 0
  while true: 
    case L.buf[pos]
    of 'G'..'Z', 'g'..'z', '.': 
      lexMessage(L, errInvalidNumber)
      inc(pos)
    of '_': 
      inc(pos)
    of '0'..'9': 
      xi = `shl`(xi, 4) or (ord(L.buf[pos]) - ord('0'))
      inc(pos)
      inc(bits, 4)
    of 'a'..'f': 
      xi = `shl`(xi, 4) or (ord(L.buf[pos]) - ord('a') + 10)
      inc(pos)
      inc(bits, 4)
    of 'A'..'F': 
      xi = `shl`(xi, 4) or (ord(L.buf[pos]) - ord('A') + 10)
      inc(pos)
      inc(bits, 4)
    else: break 
  tok.iNumber = xi
  if (bits > 32): 
    tok.xkind = pxInt64Lit
  else: 
    tok.xkind = pxIntLit
  L.bufpos = pos

proc getNumber10(L: var TPasLex, tok: var TPasTok) = 
  tok.base = base10
  matchUnderscoreChars(L, tok, {'0'..'9'})
  if (L.buf[L.bufpos] == '.') and (L.buf[L.bufpos + 1] in {'0'..'9'}): 
    add(tok.literal, '.')
    inc(L.bufpos)
    matchUnderscoreChars(L, tok, {'e', 'E', '+', '-', '0'..'9'})
  try: 
    if isFloatLiteral(tok.literal): 
      tok.fnumber = parseFloat(tok.literal)
      tok.xkind = pxFloatLit
    else: 
      tok.iNumber = ParseInt(tok.literal)
      if (tok.iNumber < low(int32)) or (tok.iNumber > high(int32)): 
        tok.xkind = pxInt64Lit
      else: 
        tok.xkind = pxIntLit
  except EInvalidValue: 
    lexMessage(L, errInvalidNumber, tok.literal)
  except EOverflow: 
    lexMessage(L, errNumberOutOfRange, tok.literal)
  
proc HandleCRLF(L: var TLexer, pos: int): int = 
  case L.buf[pos]
  of CR: result = lexbase.HandleCR(L, pos)
  of LF: result = lexbase.HandleLF(L, pos)
  else: result = pos
  
proc getString(L: var TPasLex, tok: var TPasTok) = 
  var 
    pos, xi: int
    buf: cstring
  pos = L.bufPos
  buf = L.buf
  while true: 
    if buf[pos] == '\'': 
      inc(pos)
      while true: 
        case buf[pos]
        of CR, LF, lexbase.EndOfFile: 
          lexMessage(L, errClosingQuoteExpected)
          break 
        of '\'': 
          inc(pos)
          if buf[pos] == '\'': 
            inc(pos)
            add(tok.literal, '\'')
          else: 
            break 
        else: 
          add(tok.literal, buf[pos])
          inc(pos)
    elif buf[pos] == '#': 
      inc(pos)
      xi = 0
      case buf[pos]
      of '$': 
        inc(pos)
        xi = 0
        while true: 
          case buf[pos]
          of '0'..'9': xi = (xi shl 4) or (ord(buf[pos]) - ord('0'))
          of 'a'..'f': xi = (xi shl 4) or (ord(buf[pos]) - ord('a') + 10)
          of 'A'..'F': xi = (xi shl 4) or (ord(buf[pos]) - ord('A') + 10)
          else: break 
          inc(pos)
      of '0'..'9': 
        xi = 0
        while buf[pos] in {'0'..'9'}: 
          xi = (xi * 10) + (ord(buf[pos]) - ord('0'))
          inc(pos)
      else: lexMessage(L, errInvalidCharacterConstant)
      if (xi <= 255): add(tok.literal, Chr(xi))
      else: lexMessage(L, errInvalidCharacterConstant)
    else: 
      break 
  tok.xkind = pxStrLit
  L.bufpos = pos

proc getSymbol(L: var TPasLex, tok: var TPasTok) = 
  var 
    pos: int
    c: Char
    buf: cstring
    h: THash                  # hashing algorithm inlined
  h = 0
  pos = L.bufpos
  buf = L.buf
  while true: 
    c = buf[pos]
    case c
    of 'a'..'z', '0'..'9', '\x80'..'\xFF': 
      h = h +% Ord(c)
      h = h +% h shl 10
      h = h xor (h shr 6)
    of 'A'..'Z': 
      c = chr(ord(c) + (ord('a') - ord('A'))) # toLower()
      h = h +% Ord(c)
      h = h +% h shl 10
      h = h xor (h shr 6)
    of '_': 
      nil
    else: break 
    Inc(pos)
  h = h +% h shl 3
  h = h xor (h shr 11)
  h = h +% h shl 15
  tok.ident = getIdent(addr(L.buf[L.bufpos]), pos - L.bufpos, h)
  L.bufpos = pos
  setKeyword(L, tok)

proc scanLineComment(L: var TPasLex, tok: var TPasTok) = 
  var 
    buf: cstring
    pos, col: int
    indent: int
  pos = L.bufpos
  buf = L.buf # a comment ends if the next line does not start with the // on the same
              # column after only whitespace
  tok.xkind = pxComment
  col = getColNumber(L, pos)
  while true: 
    inc(pos, 2)               # skip //
    add(tok.literal, '#')
    while not (buf[pos] in {CR, LF, lexbase.EndOfFile}): 
      add(tok.literal, buf[pos])
      inc(pos)
    pos = handleCRLF(L, pos)
    buf = L.buf
    indent = 0
    while buf[pos] == ' ': 
      inc(pos)
      inc(indent)
    if (col == indent) and (buf[pos] == '/') and (buf[pos + 1] == '/'): 
      tok.literal = tok.literal & "\n"
    else: 
      break 
  L.bufpos = pos

proc scanCurlyComment(L: var TPasLex, tok: var TPasTok) = 
  var 
    buf: cstring
    pos: int
  pos = L.bufpos
  buf = L.buf
  tok.literal = "#"
  tok.xkind = pxComment
  while true: 
    case buf[pos]
    of CR, LF: 
      pos = HandleCRLF(L, pos)
      buf = L.buf
      tok.literal = tok.literal & "\n" & '#'
    of '}': 
      inc(pos)
      break 
    of lexbase.EndOfFile: 
      lexMessage(L, errTokenExpected, "}")
    else: 
      add(tok.literal, buf[pos])
      inc(pos)
  L.bufpos = pos

proc scanStarComment(L: var TPasLex, tok: var TPasTok) = 
  var 
    buf: cstring
    pos: int
  pos = L.bufpos
  buf = L.buf
  tok.literal = "#"
  tok.xkind = pxComment
  while true: 
    case buf[pos]
    of CR, LF: 
      pos = HandleCRLF(L, pos)
      buf = L.buf
      tok.literal = tok.literal & "\n" & '#'
    of '*': 
      inc(pos)
      if buf[pos] == ')': 
        inc(pos)
        break 
      else: 
        add(tok.literal, '*')
    of lexbase.EndOfFile: 
      lexMessage(L, errTokenExpected, "*)")
    else: 
      add(tok.literal, buf[pos])
      inc(pos)
  L.bufpos = pos

proc skip(L: var TPasLex, tok: var TPasTok) = 
  var 
    buf: cstring
    pos: int
  pos = L.bufpos
  buf = L.buf
  while true: 
    case buf[pos]
    of ' ', Tabulator: 
      Inc(pos)                # newline is special:
    of CR, LF: 
      pos = HandleCRLF(L, pos)
      buf = L.buf
    else: 
      break                   # EndOfFile also leaves the loop
  L.bufpos = pos

proc getPasTok(L: var TPasLex, tok: var TPasTok) = 
  var c: Char
  tok.xkind = pxInvalid
  fillToken(tok)
  skip(L, tok)
  c = L.buf[L.bufpos]
  if c in SymStartChars: 
    getSymbol(L, tok)
  elif c in {'0'..'9'}: 
    getNumber10(L, tok)
  else: 
    case c
    of ';': 
      tok.xkind = pxSemicolon
      Inc(L.bufpos)
    of '/': 
      if L.buf[L.bufpos + 1] == '/': 
        scanLineComment(L, tok)
      else: 
        tok.xkind = pxSlash
        inc(L.bufpos)
    of ',': 
      tok.xkind = pxComma
      Inc(L.bufpos)
    of '(': 
      Inc(L.bufpos)
      if (L.buf[L.bufPos] == '*'): 
        if (L.buf[L.bufPos + 1] == '$'): 
          Inc(L.bufpos, 2)
          skip(L, tok)
          getSymbol(L, tok)
          tok.xkind = pxStarDirLe
        else: 
          inc(L.bufpos)
          scanStarComment(L, tok)
      else: 
        tok.xkind = pxParLe
    of '*': 
      inc(L.bufpos)
      if L.buf[L.bufpos] == ')': 
        inc(L.bufpos)
        tok.xkind = pxStarDirRi
      else: 
        tok.xkind = pxStar
    of ')': 
      tok.xkind = pxParRi
      Inc(L.bufpos)
    of '[': 
      Inc(L.bufpos)
      tok.xkind = pxBracketLe
    of ']': 
      Inc(L.bufpos)
      tok.xkind = pxBracketRi
    of '.': 
      inc(L.bufpos)
      if L.buf[L.bufpos] == '.': 
        tok.xkind = pxDotDot
        inc(L.bufpos)
      else: 
        tok.xkind = pxDot
    of '{': 
      Inc(L.bufpos)
      case L.buf[L.bufpos]
      of '$': 
        Inc(L.bufpos)
        skip(L, tok)
        getSymbol(L, tok)
        tok.xkind = pxCurlyDirLe
      of '&': 
        Inc(L.bufpos)
        tok.xkind = pxAmp
      of '%': 
        Inc(L.bufpos)
        tok.xkind = pxPer
      of '@': 
        Inc(L.bufpos)
        tok.xkind = pxCommand
      else: scanCurlyComment(L, tok)
    of '+': 
      tok.xkind = pxPlus
      inc(L.bufpos)
    of '-': 
      tok.xkind = pxMinus
      inc(L.bufpos)
    of ':': 
      inc(L.bufpos)
      if L.buf[L.bufpos] == '=': 
        inc(L.bufpos)
        tok.xkind = pxAsgn
      else: 
        tok.xkind = pxColon
    of '<': 
      inc(L.bufpos)
      if L.buf[L.bufpos] == '>': 
        inc(L.bufpos)
        tok.xkind = pxNeq
      elif L.buf[L.bufpos] == '=': 
        inc(L.bufpos)
        tok.xkind = pxLe
      else: 
        tok.xkind = pxLt
    of '>': 
      inc(L.bufpos)
      if L.buf[L.bufpos] == '=': 
        inc(L.bufpos)
        tok.xkind = pxGe
      else: 
        tok.xkind = pxGt
    of '=': 
      tok.xkind = pxEquals
      inc(L.bufpos)
    of '@': 
      tok.xkind = pxAt
      inc(L.bufpos)
    of '^': 
      tok.xkind = pxHat
      inc(L.bufpos)
    of '}': 
      tok.xkind = pxCurlyDirRi
      Inc(L.bufpos)
    of '\'', '#': 
      getString(L, tok)
    of '$': 
      getNumber16(L, tok)
    of '%': 
      getNumber2(L, tok)
    of lexbase.EndOfFile: 
      tok.xkind = pxEof
    else: 
      tok.literal = c & ""
      tok.xkind = pxInvalid
      lexMessage(L, errInvalidToken, c & " (\\" & $(ord(c)) & ')')
      Inc(L.bufpos)
