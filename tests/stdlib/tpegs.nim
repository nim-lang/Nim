discard """
  output: '''this
is
an
example
d
e
f
('keyvalue' 'key'*)'''
"""
# PEGs module turned out to be a good test to detect memory management bugs.

include "system/inclrtl"

const
  useUnicode = true ## change this to deactivate proper UTF-8 support

import
  strutils

when useUnicode:
  import unicode

const
  InlineThreshold = 5  ## number of leaves; -1 to disable inlining
  MaxSubpatterns* = 10 ## defines the maximum number of subpatterns that
                       ## can be captured. More subpatterns cannot be captured!

type
  TPegKind = enum
    pkEmpty,
    pkAny,              ## any character (.)
    pkAnyRune,          ## any Unicode character (_)
    pkNewLine,          ## CR-LF, LF, CR
    pkLetter,           ## Unicode letter
    pkLower,            ## Unicode lower case letter
    pkUpper,            ## Unicode upper case letter
    pkTitle,            ## Unicode title character
    pkWhitespace,       ## Unicode whitespace character
    pkTerminal,
    pkTerminalIgnoreCase,
    pkTerminalIgnoreStyle,
    pkChar,             ## single character to match
    pkCharChoice,
    pkNonTerminal,
    pkSequence,         ## a b c ... --> Internal DSL: peg(a, b, c)
    pkOrderedChoice,    ## a / b / ... --> Internal DSL: a / b or /[a, b, c]
    pkGreedyRep,        ## a*     --> Internal DSL: *a
                        ## a+     --> (a a*)
    pkGreedyRepChar,    ## x* where x is a single character (superop)
    pkGreedyRepSet,     ## [set]* (superop)
    pkGreedyAny,        ## .* or _* (superop)
    pkOption,           ## a?     --> Internal DSL: ?a
    pkAndPredicate,     ## &a     --> Internal DSL: &a
    pkNotPredicate,     ## !a     --> Internal DSL: !a
    pkCapture,          ## {a}    --> Internal DSL: capture(a)
    pkBackRef,          ## $i     --> Internal DSL: backref(i)
    pkBackRefIgnoreCase,
    pkBackRefIgnoreStyle,
    pkSearch,           ## @a     --> Internal DSL: !*a
    pkCapturedSearch,   ## {@} a  --> Internal DSL: !*\a
    pkRule,             ## a <- b
    pkList,             ## a, b
    pkStartAnchor       ## ^      --> Internal DSL: startAnchor()
  TNonTerminalFlag = enum
    ntDeclared, ntUsed
  TNonTerminal {.final.} = object ## represents a non terminal symbol
    name: string                  ## the name of the symbol
    line: int                     ## line the symbol has been declared/used in
    col: int                      ## column the symbol has been declared/used in
    flags: set[TNonTerminalFlag]  ## the nonterminal's flags
    rule: TNode                   ## the rule that the symbol refers to
  TNode {.final, shallow.} = object
    case kind: TPegKind
    of pkEmpty..pkWhitespace: nil
    of pkTerminal, pkTerminalIgnoreCase, pkTerminalIgnoreStyle: term: string
    of pkChar, pkGreedyRepChar: ch: char
    of pkCharChoice, pkGreedyRepSet: charChoice: ref set[char]
    of pkNonTerminal: nt: PNonTerminal
    of pkBackRef..pkBackRefIgnoreStyle: index: range[0..MaxSubpatterns]
    else: sons: seq[TNode]
  PNonTerminal* = ref TNonTerminal

  TPeg* = TNode ## type that represents a PEG

proc term*(t: string): TPeg {.rtl, extern: "npegs$1Str".} =
  ## constructs a PEG from a terminal string
  if t.len != 1:
    result.kind = pkTerminal
    result.term = t
  else:
    result.kind = pkChar
    result.ch = t[0]

proc termIgnoreCase*(t: string): TPeg {.
  rtl, extern: "npegs$1".} =
  ## constructs a PEG from a terminal string; ignore case for matching
  result.kind = pkTerminalIgnoreCase
  result.term = t

proc termIgnoreStyle*(t: string): TPeg {.
  rtl, extern: "npegs$1".} =
  ## constructs a PEG from a terminal string; ignore style for matching
  result.kind = pkTerminalIgnoreStyle
  result.term = t

proc term*(t: char): TPeg {.rtl, extern: "npegs$1Char".} =
  ## constructs a PEG from a terminal char
  assert t != '\0'
  result.kind = pkChar
  result.ch = t

proc charSet*(s: set[char]): TPeg {.rtl, extern: "npegs$1".} =
  ## constructs a PEG from a character set `s`
  assert '\0' notin s
  result.kind = pkCharChoice
  new(result.charChoice)
  result.charChoice[] = s

proc len(a: TPeg): int {.inline.} = return a.sons.len
proc add(d: var TPeg, s: TPeg) {.inline.} = add(d.sons, s)

proc copyPeg(a: TPeg): TPeg =
  result.kind = a.kind
  case a.kind
  of pkEmpty..pkWhitespace: discard
  of pkTerminal, pkTerminalIgnoreCase, pkTerminalIgnoreStyle:
    result.term = a.term
  of pkChar, pkGreedyRepChar:
    result.ch = a.ch
  of pkCharChoice, pkGreedyRepSet:
    new(result.charChoice)
    result.charChoice[] = a.charChoice[]
  of pkNonTerminal: result.nt = a.nt
  of pkBackRef..pkBackRefIgnoreStyle:
    result.index = a.index
  else:
    result.sons = a.sons

proc addChoice(dest: var TPeg, elem: TPeg) =
  var L = dest.len-1
  if L >= 0 and dest.sons[L].kind == pkCharChoice:
    # caution! Do not introduce false aliasing here!
    case elem.kind
    of pkCharChoice:
      dest.sons[L] = charSet(dest.sons[L].charChoice[] + elem.charChoice[])
    of pkChar:
      dest.sons[L] = charSet(dest.sons[L].charChoice[] + {elem.ch})
    else: add(dest, elem)
  else: add(dest, elem)

template multipleOp(k: TPegKind, localOpt: expr) =
  result.kind = k
  result.sons = @[]
  for x in items(a):
    if x.kind == k:
      for y in items(x.sons):
        localOpt(result, y)
    else:
      localOpt(result, x)
  if result.len == 1:
    result = result.sons[0]

proc `/`*(a: varargs[TPeg]): TPeg {.
  rtl, extern: "npegsOrderedChoice".} =
  ## constructs an ordered choice with the PEGs in `a`
  multipleOp(pkOrderedChoice, addChoice)

proc addSequence(dest: var TPeg, elem: TPeg) =
  var L = dest.len-1
  if L >= 0 and dest.sons[L].kind == pkTerminal:
    # caution! Do not introduce false aliasing here!
    case elem.kind
    of pkTerminal:
      dest.sons[L] = term(dest.sons[L].term & elem.term)
    of pkChar:
      dest.sons[L] = term(dest.sons[L].term & elem.ch)
    else: add(dest, elem)
  else: add(dest, elem)

proc sequence*(a: varargs[TPeg]): TPeg {.
  rtl, extern: "npegs$1".} =
  ## constructs a sequence with all the PEGs from `a`
  multipleOp(pkSequence, addSequence)

proc `?`*(a: TPeg): TPeg {.rtl, extern: "npegsOptional".} =
  ## constructs an optional for the PEG `a`
  if a.kind in {pkOption, pkGreedyRep, pkGreedyAny, pkGreedyRepChar,
                pkGreedyRepSet}:
    # a* ?  --> a*
    # a? ?  --> a?
    result = a
  else:
    result.kind = pkOption
    result.sons = @[a]

proc `*`*(a: TPeg): TPeg {.rtl, extern: "npegsGreedyRep".} =
  ## constructs a "greedy repetition" for the PEG `a`
  case a.kind
  of pkGreedyRep, pkGreedyRepChar, pkGreedyRepSet, pkGreedyAny, pkOption:
    assert false
    # produces endless loop!
  of pkChar:
    result.kind = pkGreedyRepChar
    result.ch = a.ch
  of pkCharChoice:
    result.kind = pkGreedyRepSet
    result.charChoice = a.charChoice # copying a reference suffices!
  of pkAny, pkAnyRune:
    result.kind = pkGreedyAny
  else:
    result.kind = pkGreedyRep
    result.sons = @[a]

proc `!*`*(a: TPeg): TPeg {.rtl, extern: "npegsSearch".} =
  ## constructs a "search" for the PEG `a`
  result.kind = pkSearch
  result.sons = @[a]

proc `!*\`*(a: TPeg): TPeg {.rtl,
                             extern: "npgegsCapturedSearch".} =
  ## constructs a "captured search" for the PEG `a`
  result.kind = pkCapturedSearch
  result.sons = @[a]

when false:
  proc contains(a: TPeg, k: TPegKind): bool =
    if a.kind == k: return true
    case a.kind
    of pkEmpty, pkAny, pkAnyRune, pkGreedyAny, pkNewLine, pkTerminal,
       pkTerminalIgnoreCase, pkTerminalIgnoreStyle, pkChar, pkGreedyRepChar,
       pkCharChoice, pkGreedyRepSet: discard
    of pkNonTerminal: return true
    else:
      for i in 0..a.sons.len-1:
        if contains(a.sons[i], k): return true

proc `+`*(a: TPeg): TPeg {.rtl, extern: "npegsGreedyPosRep".} =
  ## constructs a "greedy positive repetition" with the PEG `a`
  return sequence(a, *a)

proc `&`*(a: TPeg): TPeg {.rtl, extern: "npegsAndPredicate".} =
  ## constructs an "and predicate" with the PEG `a`
  result.kind = pkAndPredicate
  result.sons = @[a]

proc `!`*(a: TPeg): TPeg {.rtl, extern: "npegsNotPredicate".} =
  ## constructs a "not predicate" with the PEG `a`
  result.kind = pkNotPredicate
  result.sons = @[a]

proc any*: TPeg {.inline.} =
  ## constructs the PEG `any character`:idx: (``.``)
  result.kind = pkAny

proc anyRune*: TPeg {.inline.} =
  ## constructs the PEG `any rune`:idx: (``_``)
  result.kind = pkAnyRune

proc newLine*: TPeg {.inline.} =
  ## constructs the PEG `newline`:idx: (``\n``)
  result.kind = pkNewline

proc UnicodeLetter*: TPeg {.inline.} =
  ## constructs the PEG ``\letter`` which matches any Unicode letter.
  result.kind = pkLetter

proc UnicodeLower*: TPeg {.inline.} =
  ## constructs the PEG ``\lower`` which matches any Unicode lowercase letter.
  result.kind = pkLower

proc UnicodeUpper*: TPeg {.inline.} =
  ## constructs the PEG ``\upper`` which matches any Unicode lowercase letter.
  result.kind = pkUpper

proc UnicodeTitle*: TPeg {.inline.} =
  ## constructs the PEG ``\title`` which matches any Unicode title letter.
  result.kind = pkTitle

proc UnicodeWhitespace*: TPeg {.inline.} =
  ## constructs the PEG ``\white`` which matches any Unicode
  ## whitespace character.
  result.kind = pkWhitespace

proc startAnchor*: TPeg {.inline.} =
  ## constructs the PEG ``^`` which matches the start of the input.
  result.kind = pkStartAnchor

proc endAnchor*: TPeg {.inline.} =
  ## constructs the PEG ``$`` which matches the end of the input.
  result = !any()

proc capture*(a: TPeg): TPeg {.rtl, extern: "npegsCapture".} =
  ## constructs a capture with the PEG `a`
  result.kind = pkCapture
  result.sons = @[a]

proc backref*(index: range[1..MaxSubPatterns]): TPeg {.
  rtl, extern: "npegs$1".} =
  ## constructs a back reference of the given `index`. `index` starts counting
  ## from 1.
  result.kind = pkBackRef
  result.index = index-1

proc backrefIgnoreCase*(index: range[1..MaxSubPatterns]): TPeg {.
  rtl, extern: "npegs$1".} =
  ## constructs a back reference of the given `index`. `index` starts counting
  ## from 1. Ignores case for matching.
  result.kind = pkBackRefIgnoreCase
  result.index = index-1

proc backrefIgnoreStyle*(index: range[1..MaxSubPatterns]): TPeg {.
  rtl, extern: "npegs$1".}=
  ## constructs a back reference of the given `index`. `index` starts counting
  ## from 1. Ignores style for matching.
  result.kind = pkBackRefIgnoreStyle
  result.index = index-1

proc spaceCost(n: TPeg): int =
  case n.kind
  of pkEmpty: discard
  of pkTerminal, pkTerminalIgnoreCase, pkTerminalIgnoreStyle, pkChar,
     pkGreedyRepChar, pkCharChoice, pkGreedyRepSet,
     pkAny..pkWhitespace, pkGreedyAny:
    result = 1
  of pkNonTerminal:
    # we cannot inline a rule with a non-terminal
    result = InlineThreshold+1
  else:
    for i in 0..n.len-1:
      inc(result, spaceCost(n.sons[i]))
      if result >= InlineThreshold: break

proc nonterminal*(n: PNonTerminal): TPeg {.
  rtl, extern: "npegs$1".} =
  ## constructs a PEG that consists of the nonterminal symbol
  assert n != nil
  if ntDeclared in n.flags and spaceCost(n.rule) < InlineThreshold:
    when false: echo "inlining symbol: ", n.name
    result = n.rule # inlining of rule enables better optimizations
  else:
    result.kind = pkNonTerminal
    result.nt = n

proc newNonTerminal*(name: string, line, column: int): PNonTerminal {.
  rtl, extern: "npegs$1".} =
  ## constructs a nonterminal symbol
  new(result)
  result.name = name
  result.line = line
  result.col = column

template letters*: expr =
  ## expands to ``charset({'A'..'Z', 'a'..'z'})``
  charset({'A'..'Z', 'a'..'z'})

template digits*: expr =
  ## expands to ``charset({'0'..'9'})``
  charset({'0'..'9'})

template whitespace*: expr =
  ## expands to ``charset({' ', '\9'..'\13'})``
  charset({' ', '\9'..'\13'})

template identChars*: expr =
  ## expands to ``charset({'a'..'z', 'A'..'Z', '0'..'9', '_'})``
  charset({'a'..'z', 'A'..'Z', '0'..'9', '_'})

template identStartChars*: expr =
  ## expands to ``charset({'A'..'Z', 'a'..'z', '_'})``
  charset({'a'..'z', 'A'..'Z', '_'})

template ident*: expr =
  ## same as ``[a-zA-Z_][a-zA-z_0-9]*``; standard identifier
  sequence(charset({'a'..'z', 'A'..'Z', '_'}),
           *charset({'a'..'z', 'A'..'Z', '0'..'9', '_'}))

template natural*: expr =
  ## same as ``\d+``
  +digits

# ------------------------- debugging -----------------------------------------

proc esc(c: char, reserved = {'\0'..'\255'}): string =
  case c
  of '\b': result = "\\b"
  of '\t': result = "\\t"
  of '\c': result = "\\c"
  of '\L': result = "\\l"
  of '\v': result = "\\v"
  of '\f': result = "\\f"
  of '\e': result = "\\e"
  of '\a': result = "\\a"
  of '\\': result = "\\\\"
  of 'a'..'z', 'A'..'Z', '0'..'9', '_': result = $c
  elif c < ' ' or c >= '\128': result = '\\' & $ord(c)
  elif c in reserved: result = '\\' & c
  else: result = $c

proc singleQuoteEsc(c: char): string = return "'" & esc(c, {'\''}) & "'"

proc singleQuoteEsc(str: string): string =
  result = "'"
  for c in items(str): add result, esc(c, {'\''})
  add result, '\''

proc charSetEscAux(cc: set[char]): string =
  const reserved = {'^', '-', ']'}
  result = ""
  var c1 = 0
  while c1 <= 0xff:
    if chr(c1) in cc:
      var c2 = c1
      while c2 < 0xff and chr(succ(c2)) in cc: inc(c2)
      if c1 == c2:
        add result, esc(chr(c1), reserved)
      elif c2 == succ(c1):
        add result, esc(chr(c1), reserved) & esc(chr(c2), reserved)
      else:
        add result, esc(chr(c1), reserved) & '-' & esc(chr(c2), reserved)
      c1 = c2
    inc(c1)

proc charSetEsc(cc: set[char]): string =
  if card(cc) >= 128+64:
    result = "[^" & charSetEscAux({'\1'..'\xFF'} - cc) & ']'
  else:
    result = '[' & charSetEscAux(cc) & ']'

proc toStrAux(r: TPeg, res: var string) =
  case r.kind
  of pkEmpty: add(res, "()")
  of pkAny: add(res, '.')
  of pkAnyRune: add(res, '_')
  of pkLetter: add(res, "\\letter")
  of pkLower: add(res, "\\lower")
  of pkUpper: add(res, "\\upper")
  of pkTitle: add(res, "\\title")
  of pkWhitespace: add(res, "\\white")

  of pkNewline: add(res, "\\n")
  of pkTerminal: add(res, singleQuoteEsc(r.term))
  of pkTerminalIgnoreCase:
    add(res, 'i')
    add(res, singleQuoteEsc(r.term))
  of pkTerminalIgnoreStyle:
    add(res, 'y')
    add(res, singleQuoteEsc(r.term))
  of pkChar: add(res, singleQuoteEsc(r.ch))
  of pkCharChoice: add(res, charSetEsc(r.charChoice[]))
  of pkNonTerminal: add(res, r.nt.name)
  of pkSequence:
    add(res, '(')
    toStrAux(r.sons[0], res)
    for i in 1 .. high(r.sons):
      add(res, ' ')
      toStrAux(r.sons[i], res)
    add(res, ')')
  of pkOrderedChoice:
    add(res, '(')
    toStrAux(r.sons[0], res)
    for i in 1 .. high(r.sons):
      add(res, " / ")
      toStrAux(r.sons[i], res)
    add(res, ')')
  of pkGreedyRep:
    toStrAux(r.sons[0], res)
    add(res, '*')
  of pkGreedyRepChar:
    add(res, singleQuoteEsc(r.ch))
    add(res, '*')
  of pkGreedyRepSet:
    add(res, charSetEsc(r.charChoice[]))
    add(res, '*')
  of pkGreedyAny:
    add(res, ".*")
  of pkOption:
    toStrAux(r.sons[0], res)
    add(res, '?')
  of pkAndPredicate:
    add(res, '&')
    toStrAux(r.sons[0], res)
  of pkNotPredicate:
    add(res, '!')
    toStrAux(r.sons[0], res)
  of pkSearch:
    add(res, '@')
    toStrAux(r.sons[0], res)
  of pkCapturedSearch:
    add(res, "{@}")
    toStrAux(r.sons[0], res)
  of pkCapture:
    add(res, '{')
    toStrAux(r.sons[0], res)
    add(res, '}')
  of pkBackRef:
    add(res, '$')
    add(res, $r.index)
  of pkBackRefIgnoreCase:
    add(res, "i$")
    add(res, $r.index)
  of pkBackRefIgnoreStyle:
    add(res, "y$")
    add(res, $r.index)
  of pkRule:
    toStrAux(r.sons[0], res)
    add(res, " <- ")
    toStrAux(r.sons[1], res)
  of pkList:
    for i in 0 .. high(r.sons):
      toStrAux(r.sons[i], res)
      add(res, "\n")
  of pkStartAnchor:
    add(res, '^')

proc `$` *(r: TPeg): string {.rtl, extern: "npegsToString".} =
  ## converts a PEG to its string representation
  result = ""
  toStrAux(r, result)

# --------------------- core engine -------------------------------------------

type
  TCaptures* {.final.} = object ## contains the captured substrings.
    matches: array[0..MaxSubpatterns-1, tuple[first, last: int]]
    ml: int
    origStart: int

proc bounds*(c: TCaptures,
             i: range[0..MaxSubpatterns-1]): tuple[first, last: int] =
  ## returns the bounds ``[first..last]`` of the `i`'th capture.
  result = c.matches[i]

when not useUnicode:
  type
    Rune = char
  template fastRuneAt(s, i, ch: expr) =
    ch = s[i]
    inc(i)
  template runeLenAt(s, i: expr): expr = 1

  proc isAlpha(a: char): bool {.inline.} = return a in {'a'..'z','A'..'Z'}
  proc isUpper(a: char): bool {.inline.} = return a in {'A'..'Z'}
  proc isLower(a: char): bool {.inline.} = return a in {'a'..'z'}
  proc isTitle(a: char): bool {.inline.} = return false
  proc isWhiteSpace(a: char): bool {.inline.} = return a in {' ', '\9'..'\13'}

proc rawMatch*(s: string, p: TPeg, start: int, c: var TCaptures): int {.
               rtl, extern: "npegs$1".} =
  ## low-level matching proc that implements the PEG interpreter. Use this
  ## for maximum efficiency (every other PEG operation ends up calling this
  ## proc).
  ## Returns -1 if it does not match, else the length of the match
  case p.kind
  of pkEmpty: result = 0 # match of length 0
  of pkAny:
    if s[start] != '\0': result = 1
    else: result = -1
  of pkAnyRune:
    if s[start] != '\0':
      result = runeLenAt(s, start)
    else:
      result = -1
  of pkLetter:
    if s[start] != '\0':
      var a: Rune
      result = start
      fastRuneAt(s, result, a)
      if isAlpha(a): dec(result, start)
      else: result = -1
    else:
      result = -1
  of pkLower:
    if s[start] != '\0':
      var a: Rune
      result = start
      fastRuneAt(s, result, a)
      if isLower(a): dec(result, start)
      else: result = -1
    else:
      result = -1
  of pkUpper:
    if s[start] != '\0':
      var a: Rune
      result = start
      fastRuneAt(s, result, a)
      if isUpper(a): dec(result, start)
      else: result = -1
    else:
      result = -1
  of pkTitle:
    if s[start] != '\0':
      var a: Rune
      result = start
      fastRuneAt(s, result, a)
      if isTitle(a): dec(result, start)
      else: result = -1
    else:
      result = -1
  of pkWhitespace:
    if s[start] != '\0':
      var a: Rune
      result = start
      fastRuneAt(s, result, a)
      if isWhitespace(a): dec(result, start)
      else: result = -1
    else:
      result = -1
  of pkGreedyAny:
    result = len(s) - start
  of pkNewLine:
    if s[start] == '\L': result = 1
    elif s[start] == '\C':
      if s[start+1] == '\L': result = 2
      else: result = 1
    else: result = -1
  of pkTerminal:
    result = len(p.term)
    for i in 0..result-1:
      if p.term[i] != s[start+i]:
        result = -1
        break
  of pkTerminalIgnoreCase:
    var
      i = 0
      a, b: Rune
    result = start
    while i < len(p.term):
      fastRuneAt(p.term, i, a)
      fastRuneAt(s, result, b)
      if toLower(a) != toLower(b):
        result = -1
        break
    dec(result, start)
  of pkTerminalIgnoreStyle:
    var
      i = 0
      a, b: Rune
    result = start
    while i < len(p.term):
      while true:
        fastRuneAt(p.term, i, a)
        if a != Rune('_'): break
      while true:
        fastRuneAt(s, result, b)
        if b != Rune('_'): break
      if toLower(a) != toLower(b):
        result = -1
        break
    dec(result, start)
  of pkChar:
    if p.ch == s[start]: result = 1
    else: result = -1
  of pkCharChoice:
    if contains(p.charChoice[], s[start]): result = 1
    else: result = -1
  of pkNonTerminal:
    var oldMl = c.ml
    when false: echo "enter: ", p.nt.name
    result = rawMatch(s, p.nt.rule, start, c)
    when false: echo "leave: ", p.nt.name
    if result < 0: c.ml = oldMl
  of pkSequence:
    var oldMl = c.ml
    result = 0
    assert(not isNil(p.sons))
    for i in 0..high(p.sons):
      var x = rawMatch(s, p.sons[i], start+result, c)
      if x < 0:
        c.ml = oldMl
        result = -1
        break
      else: inc(result, x)
  of pkOrderedChoice:
    var oldMl = c.ml
    for i in 0..high(p.sons):
      result = rawMatch(s, p.sons[i], start, c)
      if result >= 0: break
      c.ml = oldMl
  of pkSearch:
    var oldMl = c.ml
    result = 0
    while start+result < s.len:
      var x = rawMatch(s, p.sons[0], start+result, c)
      if x >= 0:
        inc(result, x)
        return
      inc(result)
    result = -1
    c.ml = oldMl
  of pkCapturedSearch:
    var idx = c.ml # reserve a slot for the subpattern
    inc(c.ml)
    result = 0
    while start+result < s.len:
      var x = rawMatch(s, p.sons[0], start+result, c)
      if x >= 0:
        if idx < MaxSubpatterns:
          c.matches[idx] = (start, start+result-1)
        #else: silently ignore the capture
        inc(result, x)
        return
      inc(result)
    result = -1
    c.ml = idx
  of pkGreedyRep:
    result = 0
    while true:
      var x = rawMatch(s, p.sons[0], start+result, c)
      # if x == 0, we have an endless loop; so the correct behaviour would be
      # not to break. But endless loops can be easily introduced:
      # ``(comment / \w*)*`` is such an example. Breaking for x == 0 does the
      # expected thing in this case.
      if x <= 0: break
      inc(result, x)
  of pkGreedyRepChar:
    result = 0
    var ch = p.ch
    while ch == s[start+result]: inc(result)
  of pkGreedyRepSet:
    result = 0
    while contains(p.charChoice[], s[start+result]): inc(result)
  of pkOption:
    result = max(0, rawMatch(s, p.sons[0], start, c))
  of pkAndPredicate:
    var oldMl = c.ml
    result = rawMatch(s, p.sons[0], start, c)
    if result >= 0: result = 0 # do not consume anything
    else: c.ml = oldMl
  of pkNotPredicate:
    var oldMl = c.ml
    result = rawMatch(s, p.sons[0], start, c)
    if result < 0: result = 0
    else:
      c.ml = oldMl
      result = -1
  of pkCapture:
    var idx = c.ml # reserve a slot for the subpattern
    inc(c.ml)
    result = rawMatch(s, p.sons[0], start, c)
    if result >= 0:
      if idx < MaxSubpatterns:
        c.matches[idx] = (start, start+result-1)
      #else: silently ignore the capture
    else:
      c.ml = idx
  of pkBackRef..pkBackRefIgnoreStyle:
    if p.index >= c.ml: return -1
    var (a, b) = c.matches[p.index]
    var n: TPeg
    n.kind = succ(pkTerminal, ord(p.kind)-ord(pkBackRef))
    n.term = s.substr(a, b)
    result = rawMatch(s, n, start, c)
  of pkStartAnchor:
    if c.origStart == start: result = 0
    else: result = -1
  of pkRule, pkList: assert false

proc match*(s: string, pattern: TPeg, matches: var openarray[string],
            start = 0): bool {.rtl, extern: "npegs$1Capture".} =
  ## returns ``true`` if ``s[start..]`` matches the ``pattern`` and
  ## the captured substrings in the array ``matches``. If it does not
  ## match, nothing is written into ``matches`` and ``false`` is
  ## returned.
  var c: TCaptures
  c.origStart = start
  result = rawMatch(s, pattern, start, c) == len(s)-start
  if result:
    for i in 0..c.ml-1:
      matches[i] = substr(s, c.matches[i][0], c.matches[i][1])

proc match*(s: string, pattern: TPeg,
            start = 0): bool {.rtl, extern: "npegs$1".} =
  ## returns ``true`` if ``s`` matches the ``pattern`` beginning from ``start``.
  var c: TCaptures
  c.origStart = start
  result = rawMatch(s, pattern, start, c) == len(s)-start

proc matchLen*(s: string, pattern: TPeg, matches: var openarray[string],
               start = 0): int {.rtl, extern: "npegs$1Capture".} =
  ## the same as ``match``, but it returns the length of the match,
  ## if there is no match, -1 is returned. Note that a match length
  ## of zero can happen. It's possible that a suffix of `s` remains
  ## that does not belong to the match.
  var c: TCaptures
  c.origStart = start
  result = rawMatch(s, pattern, start, c)
  if result >= 0:
    for i in 0..c.ml-1:
      matches[i] = substr(s, c.matches[i][0], c.matches[i][1])

proc matchLen*(s: string, pattern: TPeg,
               start = 0): int {.rtl, extern: "npegs$1".} =
  ## the same as ``match``, but it returns the length of the match,
  ## if there is no match, -1 is returned. Note that a match length
  ## of zero can happen. It's possible that a suffix of `s` remains
  ## that does not belong to the match.
  var c: TCaptures
  c.origStart = start
  result = rawMatch(s, pattern, start, c)

proc find*(s: string, pattern: TPeg, matches: var openarray[string],
           start = 0): int {.rtl, extern: "npegs$1Capture".} =
  ## returns the starting position of ``pattern`` in ``s`` and the captured
  ## substrings in the array ``matches``. If it does not match, nothing
  ## is written into ``matches`` and -1 is returned.
  for i in start .. s.len-1:
    if matchLen(s, pattern, matches, i) >= 0: return i
  return -1
  # could also use the pattern here: (!P .)* P

proc findBounds*(s: string, pattern: TPeg, matches: var openarray[string],
                 start = 0): tuple[first, last: int] {.
                 rtl, extern: "npegs$1Capture".} =
  ## returns the starting position and end position of ``pattern`` in ``s``
  ## and the captured
  ## substrings in the array ``matches``. If it does not match, nothing
  ## is written into ``matches`` and (-1,0) is returned.
  for i in start .. s.len-1:
    var L = matchLen(s, pattern, matches, i)
    if L >= 0: return (i, i+L-1)
  return (-1, 0)

proc find*(s: string, pattern: TPeg,
           start = 0): int {.rtl, extern: "npegs$1".} =
  ## returns the starting position of ``pattern`` in ``s``. If it does not
  ## match, -1 is returned.
  for i in start .. s.len-1:
    if matchLen(s, pattern, i) >= 0: return i
  return -1

iterator findAll*(s: string, pattern: TPeg, start = 0): string =
  ## yields all matching captures of pattern in `s`.
  var matches: array[0..MaxSubpatterns-1, string]
  var i = start
  while i < s.len:
    var L = matchLen(s, pattern, matches, i)
    if L < 0: break
    for k in 0..MaxSubPatterns-1:
      if isNil(matches[k]): break
      yield matches[k]
    inc(i, L)

proc findAll*(s: string, pattern: TPeg, start = 0): seq[string] {.
  rtl, extern: "npegs$1".} =
  ## returns all matching captures of pattern in `s`.
  ## If it does not match, @[] is returned.
  accumulateResult(findAll(s, pattern, start))

template `=~`*(s: string, pattern: TPeg): expr =
  ## This calls ``match`` with an implicit declared ``matches`` array that
  ## can be used in the scope of the ``=~`` call:
  ##
  ## .. code-block:: nim
  ##
  ##   if line =~ peg"\s* {\w+} \s* '=' \s* {\w+}":
  ##     # matches a key=value pair:
  ##     echo("Key: ", matches[0])
  ##     echo("Value: ", matches[1])
  ##   elif line =~ peg"\s*{'#'.*}":
  ##     # matches a comment
  ##     # note that the implicit ``matches`` array is different from the
  ##     # ``matches`` array of the first branch
  ##     echo("comment: ", matches[0])
  ##   else:
  ##     echo("syntax error")
  ##
  when not declaredInScope(matches):
    var matches {.inject.}: array[0..MaxSubpatterns-1, string]
  match(s, pattern, matches)

# ------------------------- more string handling ------------------------------

proc contains*(s: string, pattern: TPeg, start = 0): bool {.
  rtl, extern: "npegs$1".} =
  ## same as ``find(s, pattern, start) >= 0``
  return find(s, pattern, start) >= 0

proc contains*(s: string, pattern: TPeg, matches: var openArray[string],
              start = 0): bool {.rtl, extern: "npegs$1Capture".} =
  ## same as ``find(s, pattern, matches, start) >= 0``
  return find(s, pattern, matches, start) >= 0

proc startsWith*(s: string, prefix: TPeg, start = 0): bool {.
  rtl, extern: "npegs$1".} =
  ## returns true if `s` starts with the pattern `prefix`
  result = matchLen(s, prefix, start) >= 0

proc endsWith*(s: string, suffix: TPeg, start = 0): bool {.
  rtl, extern: "npegs$1".} =
  ## returns true if `s` ends with the pattern `prefix`
  for i in start .. s.len-1:
    if matchLen(s, suffix, i) == s.len - i: return true

proc replacef*(s: string, sub: TPeg, by: string): string {.
  rtl, extern: "npegs$1".} =
  ## Replaces `sub` in `s` by the string `by`. Captures can be accessed in `by`
  ## with the notation ``$i`` and ``$#`` (see strutils.`%`). Examples:
  ##
  ## .. code-block:: nim
  ##   "var1=key; var2=key2".replace(peg"{\ident}'='{\ident}", "$1<-$2$2")
  ##
  ## Results in:
  ##
  ## .. code-block:: nim
  ##
  ##   "var1<-keykey; val2<-key2key2"
  result = ""
  var i = 0
  var caps: array[0..MaxSubpatterns-1, string]
  while i < s.len:
    var x = matchLen(s, sub, caps, i)
    if x <= 0:
      add(result, s[i])
      inc(i)
    else:
      addf(result, by, caps)
      inc(i, x)
  add(result, substr(s, i))

proc replace*(s: string, sub: TPeg, by = ""): string {.
  rtl, extern: "npegs$1".} =
  ## Replaces `sub` in `s` by the string `by`. Captures cannot be accessed
  ## in `by`.
  result = ""
  var i = 0
  var caps: array[0..MaxSubpatterns-1, string]
  while i < s.len:
    var x = matchLen(s, sub, caps, i)
    if x <= 0:
      add(result, s[i])
      inc(i)
    else:
      addf(result, by, caps)
      inc(i, x)
  add(result, substr(s, i))

proc parallelReplace*(s: string, subs: varargs[
                      tuple[pattern: TPeg, repl: string]]): string {.
                      rtl, extern: "npegs$1".} =
  ## Returns a modified copy of `s` with the substitutions in `subs`
  ## applied in parallel.
  result = ""
  var i = 0
  var caps: array[0..MaxSubpatterns-1, string]
  while i < s.len:
    block searchSubs:
      for j in 0..high(subs):
        var x = matchLen(s, subs[j][0], caps, i)
        if x > 0:
          addf(result, subs[j][1], caps)
          inc(i, x)
          break searchSubs
      add(result, s[i])
      inc(i)
  # copy the rest:
  add(result, substr(s, i))

proc transformFile*(infile, outfile: string,
                    subs: varargs[tuple[pattern: TPeg, repl: string]]) {.
                    rtl, extern: "npegs$1".} =
  ## reads in the file `infile`, performs a parallel replacement (calls
  ## `parallelReplace`) and writes back to `outfile`. Calls ``quit`` if an
  ## error occurs. This is supposed to be used for quick scripting.
  var x = readFile(infile)
  if not isNil(x):
    var f: File
    if open(f, outfile, fmWrite):
      write(f, x.parallelReplace(subs))
      close(f)
    else:
      quit("cannot open for writing: " & outfile)
  else:
    quit("cannot open for reading: " & infile)

iterator split*(s: string, sep: TPeg): string =
  ## Splits the string `s` into substrings.
  ##
  ## Substrings are separated by the PEG `sep`.
  ## Examples:
  ##
  ## .. code-block:: nim
  ##   for word in split("00232this02939is39an22example111", peg"\d+"):
  ##     writeLine(stdout, word)
  ##
  ## Results in:
  ##
  ## .. code-block:: nim
  ##   "this"
  ##   "is"
  ##   "an"
  ##   "example"
  ##
  var
    first = 0
    last = 0
  while last < len(s):
    var x = matchLen(s, sep, last)
    if x > 0: inc(last, x)
    first = last
    while last < len(s):
      inc(last)
      x = matchLen(s, sep, last)
      if x > 0: break
    if first < last:
      yield substr(s, first, last-1)

proc split*(s: string, sep: TPeg): seq[string] {.
  rtl, extern: "npegs$1".} =
  ## Splits the string `s` into substrings.
  accumulateResult(split(s, sep))

# ------------------- scanner -------------------------------------------------

type
  TModifier = enum
    modNone,
    modVerbatim,
    modIgnoreCase,
    modIgnoreStyle
  TTokKind = enum       ## enumeration of all tokens
    tkInvalid,          ## invalid token
    tkEof,              ## end of file reached
    tkAny,              ## .
    tkAnyRune,          ## _
    tkIdentifier,       ## abc
    tkStringLit,        ## "abc" or 'abc'
    tkCharSet,          ## [^A-Z]
    tkParLe,            ## '('
    tkParRi,            ## ')'
    tkCurlyLe,          ## '{'
    tkCurlyRi,          ## '}'
    tkCurlyAt,          ## '{@}'
    tkArrow,            ## '<-'
    tkBar,              ## '/'
    tkStar,             ## '*'
    tkPlus,             ## '+'
    tkAmp,              ## '&'
    tkNot,              ## '!'
    tkOption,           ## '?'
    tkAt,               ## '@'
    tkBuiltin,          ## \identifier
    tkEscaped,          ## \\
    tkBackref,          ## '$'
    tkDollar,           ## '$'
    tkHat               ## '^'

  TToken {.final.} = object  ## a token
    kind: TTokKind           ## the type of the token
    modifier: TModifier
    literal: string          ## the parsed (string) literal
    charset: set[char]       ## if kind == tkCharSet
    index: int               ## if kind == tkBackref

  TPegLexer {.inheritable.} = object          ## the lexer object.
    bufpos: int               ## the current position within the buffer
    buf: cstring              ## the buffer itself
    lineNumber: int           ## the current line number
    lineStart: int            ## index of last line start in buffer
    colOffset: int            ## column to add
    filename: string

const
  tokKindToStr: array[TTokKind, string] = [
    "invalid", "[EOF]", ".", "_", "identifier", "string literal",
    "character set", "(", ")", "{", "}", "{@}",
    "<-", "/", "*", "+", "&", "!", "?",
    "@", "built-in", "escaped", "$", "$", "^"
  ]

proc HandleCR(L: var TPegLexer, pos: int): int =
  assert(L.buf[pos] == '\c')
  inc(L.linenumber)
  result = pos+1
  if L.buf[result] == '\L': inc(result)
  L.lineStart = result

proc HandleLF(L: var TPegLexer, pos: int): int =
  assert(L.buf[pos] == '\L')
  inc(L.linenumber)
  result = pos+1
  L.lineStart = result

proc init(L: var TPegLexer, input, filename: string, line = 1, col = 0) =
  L.buf = input
  L.bufpos = 0
  L.lineNumber = line
  L.colOffset = col
  L.lineStart = 0
  L.filename = filename

proc getColumn(L: TPegLexer): int {.inline.} =
  result = abs(L.bufpos - L.lineStart) + L.colOffset

proc getLine(L: TPegLexer): int {.inline.} =
  result = L.linenumber

proc errorStr(L: TPegLexer, msg: string, line = -1, col = -1): string =
  var line = if line < 0: getLine(L) else: line
  var col = if col < 0: getColumn(L) else: col
  result = "$1($2, $3) Error: $4" % [L.filename, $line, $col, msg]

proc handleHexChar(c: var TPegLexer, xi: var int) =
  case c.buf[c.bufpos]
  of '0'..'9':
    xi = (xi shl 4) or (ord(c.buf[c.bufpos]) - ord('0'))
    inc(c.bufpos)
  of 'a'..'f':
    xi = (xi shl 4) or (ord(c.buf[c.bufpos]) - ord('a') + 10)
    inc(c.bufpos)
  of 'A'..'F':
    xi = (xi shl 4) or (ord(c.buf[c.bufpos]) - ord('A') + 10)
    inc(c.bufpos)
  else: discard

proc getEscapedChar(c: var TPegLexer, tok: var TToken) =
  inc(c.bufpos)
  case c.buf[c.bufpos]
  of 'r', 'R', 'c', 'C':
    add(tok.literal, '\c')
    inc(c.bufpos)
  of 'l', 'L':
    add(tok.literal, '\L')
    inc(c.bufpos)
  of 'f', 'F':
    add(tok.literal, '\f')
    inc(c.bufpos)
  of 'e', 'E':
    add(tok.literal, '\e')
    inc(c.bufpos)
  of 'a', 'A':
    add(tok.literal, '\a')
    inc(c.bufpos)
  of 'b', 'B':
    add(tok.literal, '\b')
    inc(c.bufpos)
  of 'v', 'V':
    add(tok.literal, '\v')
    inc(c.bufpos)
  of 't', 'T':
    add(tok.literal, '\t')
    inc(c.bufpos)
  of 'x', 'X':
    inc(c.bufpos)
    var xi = 0
    handleHexChar(c, xi)
    handleHexChar(c, xi)
    if xi == 0: tok.kind = tkInvalid
    else: add(tok.literal, chr(xi))
  of '0'..'9':
    var val = ord(c.buf[c.bufpos]) - ord('0')
    inc(c.bufpos)
    var i = 1
    while (i <= 3) and (c.buf[c.bufpos] in {'0'..'9'}):
      val = val * 10 + ord(c.buf[c.bufpos]) - ord('0')
      inc(c.bufpos)
      inc(i)
    if val > 0 and val <= 255: add(tok.literal, chr(val))
    else: tok.kind = tkInvalid
  of '\0'..'\31':
    tok.kind = tkInvalid
  elif c.buf[c.bufpos] in strutils.Letters:
    tok.kind = tkInvalid
  else:
    add(tok.literal, c.buf[c.bufpos])
    inc(c.bufpos)

proc skip(c: var TPegLexer) =
  var pos = c.bufpos
  var buf = c.buf
  while true:
    case buf[pos]
    of ' ', '\t':
      inc(pos)
    of '#':
      while not (buf[pos] in {'\c', '\L', '\0'}): inc(pos)
    of '\c':
      pos = HandleCR(c, pos)
      buf = c.buf
    of '\L':
      pos = HandleLF(c, pos)
      buf = c.buf
    else:
      break                   # EndOfFile also leaves the loop
  c.bufpos = pos

proc getString(c: var TPegLexer, tok: var TToken) =
  tok.kind = tkStringLit
  var pos = c.bufPos + 1
  var buf = c.buf
  var quote = buf[pos-1]
  while true:
    case buf[pos]
    of '\\':
      c.bufpos = pos
      getEscapedChar(c, tok)
      pos = c.bufpos
    of '\c', '\L', '\0':
      tok.kind = tkInvalid
      break
    elif buf[pos] == quote:
      inc(pos)
      break
    else:
      add(tok.literal, buf[pos])
      inc(pos)
  c.bufpos = pos

proc getDollar(c: var TPegLexer, tok: var TToken) =
  var pos = c.bufPos + 1
  var buf = c.buf
  if buf[pos] in {'0'..'9'}:
    tok.kind = tkBackref
    tok.index = 0
    while buf[pos] in {'0'..'9'}:
      tok.index = tok.index * 10 + ord(buf[pos]) - ord('0')
      inc(pos)
  else:
    tok.kind = tkDollar
  c.bufpos = pos

proc getCharSet(c: var TPegLexer, tok: var TToken) =
  tok.kind = tkCharSet
  tok.charset = {}
  var pos = c.bufPos + 1
  var buf = c.buf
  var caret = false
  if buf[pos] == '^':
    inc(pos)
    caret = true
  while true:
    var ch: char
    case buf[pos]
    of ']':
      inc(pos)
      break
    of '\\':
      c.bufpos = pos
      getEscapedChar(c, tok)
      pos = c.bufpos
      ch = tok.literal[tok.literal.len-1]
    of '\C', '\L', '\0':
      tok.kind = tkInvalid
      break
    else:
      ch = buf[pos]
      inc(pos)
    incl(tok.charset, ch)
    if buf[pos] == '-':
      if buf[pos+1] == ']':
        incl(tok.charset, '-')
        inc(pos)
      else:
        inc(pos)
        var ch2: char
        case buf[pos]
        of '\\':
          c.bufpos = pos
          getEscapedChar(c, tok)
          pos = c.bufpos
          ch2 = tok.literal[tok.literal.len-1]
        of '\C', '\L', '\0':
          tok.kind = tkInvalid
          break
        else:
          ch2 = buf[pos]
          inc(pos)
        for i in ord(ch)+1 .. ord(ch2):
          incl(tok.charset, chr(i))
  c.bufpos = pos
  if caret: tok.charset = {'\1'..'\xFF'} - tok.charset

proc getSymbol(c: var TPegLexer, tok: var TToken) =
  var pos = c.bufpos
  var buf = c.buf
  while true:
    add(tok.literal, buf[pos])
    inc(pos)
    if buf[pos] notin strutils.IdentChars: break
  c.bufpos = pos
  tok.kind = tkIdentifier

proc getBuiltin(c: var TPegLexer, tok: var TToken) =
  if c.buf[c.bufpos+1] in strutils.Letters:
    inc(c.bufpos)
    getSymbol(c, tok)
    tok.kind = tkBuiltin
  else:
    tok.kind = tkEscaped
    getEscapedChar(c, tok) # may set tok.kind to tkInvalid

proc getTok(c: var TPegLexer, tok: var TToken) =
  tok.kind = tkInvalid
  tok.modifier = modNone
  setlen(tok.literal, 0)
  skip(c)
  case c.buf[c.bufpos]
  of '{':
    inc(c.bufpos)
    if c.buf[c.bufpos] == '@' and c.buf[c.bufpos+1] == '}':
      tok.kind = tkCurlyAt
      inc(c.bufpos, 2)
      add(tok.literal, "{@}")
    else:
      tok.kind = tkCurlyLe
      add(tok.literal, '{')
  of '}':
    tok.kind = tkCurlyRi
    inc(c.bufpos)
    add(tok.literal, '}')
  of '[':
    getCharset(c, tok)
  of '(':
    tok.kind = tkParLe
    inc(c.bufpos)
    add(tok.literal, '(')
  of ')':
    tok.kind = tkParRi
    inc(c.bufpos)
    add(tok.literal, ')')
  of '.':
    tok.kind = tkAny
    inc(c.bufpos)
    add(tok.literal, '.')
  of '_':
    tok.kind = tkAnyRune
    inc(c.bufpos)
    add(tok.literal, '_')
  of '\\':
    getBuiltin(c, tok)
  of '\'', '"': getString(c, tok)
  of '$': getDollar(c, tok)
  of '\0':
    tok.kind = tkEof
    tok.literal = "[EOF]"
  of 'a'..'z', 'A'..'Z', '\128'..'\255':
    getSymbol(c, tok)
    if c.buf[c.bufpos] in {'\'', '"'} or
        c.buf[c.bufpos] == '$' and c.buf[c.bufpos+1] in {'0'..'9'}:
      case tok.literal
      of "i": tok.modifier = modIgnoreCase
      of "y": tok.modifier = modIgnoreStyle
      of "v": tok.modifier = modVerbatim
      else: discard
      setLen(tok.literal, 0)
      if c.buf[c.bufpos] == '$':
        getDollar(c, tok)
      else:
        getString(c, tok)
      if tok.modifier == modNone: tok.kind = tkInvalid
  of '+':
    tok.kind = tkPlus
    inc(c.bufpos)
    add(tok.literal, '+')
  of '*':
    tok.kind = tkStar
    inc(c.bufpos)
    add(tok.literal, '+')
  of '<':
    if c.buf[c.bufpos+1] == '-':
      inc(c.bufpos, 2)
      tok.kind = tkArrow
      add(tok.literal, "<-")
    else:
      add(tok.literal, '<')
  of '/':
    tok.kind = tkBar
    inc(c.bufpos)
    add(tok.literal, '/')
  of '?':
    tok.kind = tkOption
    inc(c.bufpos)
    add(tok.literal, '?')
  of '!':
    tok.kind = tkNot
    inc(c.bufpos)
    add(tok.literal, '!')
  of '&':
    tok.kind = tkAmp
    inc(c.bufpos)
    add(tok.literal, '!')
  of '@':
    tok.kind = tkAt
    inc(c.bufpos)
    add(tok.literal, '@')
    if c.buf[c.bufpos] == '@':
      tok.kind = tkCurlyAt
      inc(c.bufpos)
      add(tok.literal, '@')
  of '^':
    tok.kind = tkHat
    inc(c.bufpos)
    add(tok.literal, '^')
  else:
    add(tok.literal, c.buf[c.bufpos])
    inc(c.bufpos)

proc arrowIsNextTok(c: TPegLexer): bool =
  # the only look ahead we need
  var pos = c.bufpos
  while c.buf[pos] in {'\t', ' '}: inc(pos)
  result = c.buf[pos] == '<' and c.buf[pos+1] == '-'

# ----------------------------- parser ----------------------------------------

type
  EInvalidPeg* = object of ValueError ## raised if an invalid
                                      ## PEG has been detected
  TPegParser = object of TPegLexer ## the PEG parser object
    tok: TToken
    nonterms: seq[PNonTerminal]
    modifier: TModifier
    captures: int
    identIsVerbatim: bool
    skip: TPeg

proc pegError(p: TPegParser, msg: string, line = -1, col = -1) =
  var e: ref EInvalidPeg
  new(e)
  e.msg = errorStr(p, msg, line, col)
  raise e

proc getTok(p: var TPegParser) =
  getTok(p, p.tok)
  if p.tok.kind == tkInvalid: pegError(p, "invalid token")

proc eat(p: var TPegParser, kind: TTokKind) =
  if p.tok.kind == kind: getTok(p)
  else: pegError(p, tokKindToStr[kind] & " expected")

proc parseExpr(p: var TPegParser): TPeg

proc getNonTerminal(p: var TPegParser, name: string): PNonTerminal =
  for i in 0..high(p.nonterms):
    result = p.nonterms[i]
    if cmpIgnoreStyle(result.name, name) == 0: return
  # forward reference:
  result = newNonTerminal(name, getLine(p), getColumn(p))
  add(p.nonterms, result)

proc modifiedTerm(s: string, m: TModifier): TPeg =
  case m
  of modNone, modVerbatim: result = term(s)
  of modIgnoreCase: result = termIgnoreCase(s)
  of modIgnoreStyle: result = termIgnoreStyle(s)

proc modifiedBackref(s: int, m: TModifier): TPeg =
  case m
  of modNone, modVerbatim: result = backRef(s)
  of modIgnoreCase: result = backRefIgnoreCase(s)
  of modIgnoreStyle: result = backRefIgnoreStyle(s)

proc builtin(p: var TPegParser): TPeg =
  # do not use "y", "skip" or "i" as these would be ambiguous
  case p.tok.literal
  of "n": result = newLine()
  of "d": result = charset({'0'..'9'})
  of "D": result = charset({'\1'..'\xff'} - {'0'..'9'})
  of "s": result = charset({' ', '\9'..'\13'})
  of "S": result = charset({'\1'..'\xff'} - {' ', '\9'..'\13'})
  of "w": result = charset({'a'..'z', 'A'..'Z', '_', '0'..'9'})
  of "W": result = charset({'\1'..'\xff'} - {'a'..'z','A'..'Z','_','0'..'9'})
  of "a": result = charset({'a'..'z', 'A'..'Z'})
  of "A": result = charset({'\1'..'\xff'} - {'a'..'z', 'A'..'Z'})
  of "ident": result = tpegs.ident
  of "letter": result = UnicodeLetter()
  of "upper": result = UnicodeUpper()
  of "lower": result = UnicodeLower()
  of "title": result = UnicodeTitle()
  of "white": result = UnicodeWhitespace()
  else: pegError(p, "unknown built-in: " & p.tok.literal)

proc token(terminal: TPeg, p: TPegParser): TPeg =
  if p.skip.kind == pkEmpty: result = terminal
  else: result = sequence(p.skip, terminal)

proc primary(p: var TPegParser): TPeg =
  case p.tok.kind
  of tkAmp:
    getTok(p)
    return &primary(p)
  of tkNot:
    getTok(p)
    return !primary(p)
  of tkAt:
    getTok(p)
    return !*primary(p)
  of tkCurlyAt:
    getTok(p)
    return !*\primary(p).token(p)
  else: discard
  case p.tok.kind
  of tkIdentifier:
    if p.identIsVerbatim:
      var m = p.tok.modifier
      if m == modNone: m = p.modifier
      result = modifiedTerm(p.tok.literal, m).token(p)
      getTok(p)
    elif not arrowIsNextTok(p):
      var nt = getNonTerminal(p, p.tok.literal)
      incl(nt.flags, ntUsed)
      result = nonTerminal(nt).token(p)
      getTok(p)
    else:
      pegError(p, "expression expected, but found: " & p.tok.literal)
  of tkStringLit:
    var m = p.tok.modifier
    if m == modNone: m = p.modifier
    result = modifiedTerm(p.tok.literal, m).token(p)
    getTok(p)
  of tkCharSet:
    if '\0' in p.tok.charset:
      pegError(p, "binary zero ('\\0') not allowed in character class")
    result = charset(p.tok.charset).token(p)
    getTok(p)
  of tkParLe:
    getTok(p)
    result = parseExpr(p)
    eat(p, tkParRi)
  of tkCurlyLe:
    getTok(p)
    result = capture(parseExpr(p)).token(p)
    eat(p, tkCurlyRi)
    inc(p.captures)
  of tkAny:
    result = any().token(p)
    getTok(p)
  of tkAnyRune:
    result = anyRune().token(p)
    getTok(p)
  of tkBuiltin:
    result = builtin(p).token(p)
    getTok(p)
  of tkEscaped:
    result = term(p.tok.literal[0]).token(p)
    getTok(p)
  of tkDollar:
    result = endAnchor()
    getTok(p)
  of tkHat:
    result = startAnchor()
    getTok(p)
  of tkBackref:
    var m = p.tok.modifier
    if m == modNone: m = p.modifier
    result = modifiedBackRef(p.tok.index, m).token(p)
    if p.tok.index < 0 or p.tok.index > p.captures:
      pegError(p, "invalid back reference index: " & $p.tok.index)
    getTok(p)
  else:
    pegError(p, "expression expected, but found: " & p.tok.literal)
    getTok(p) # we must consume a token here to prevent endless loops!
  while true:
    case p.tok.kind
    of tkOption:
      result = ?result
      getTok(p)
    of tkStar:
      result = *result
      getTok(p)
    of tkPlus:
      result = +result
      getTok(p)
    else: break

proc seqExpr(p: var TPegParser): TPeg =
  result = primary(p)
  while true:
    case p.tok.kind
    of tkAmp, tkNot, tkAt, tkStringLit, tkCharset, tkParLe, tkCurlyLe,
       tkAny, tkAnyRune, tkBuiltin, tkEscaped, tkDollar, tkBackref,
       tkHat, tkCurlyAt:
      result = sequence(result, primary(p))
    of tkIdentifier:
      if not arrowIsNextTok(p):
        result = sequence(result, primary(p))
      else: break
    else: break

proc parseExpr(p: var TPegParser): TPeg =
  result = seqExpr(p)
  while p.tok.kind == tkBar:
    getTok(p)
    result = result / seqExpr(p)

proc parseRule(p: var TPegParser): PNonTerminal =
  if p.tok.kind == tkIdentifier and arrowIsNextTok(p):
    result = getNonTerminal(p, p.tok.literal)
    if ntDeclared in result.flags:
      pegError(p, "attempt to redefine: " & result.name)
    result.line = getLine(p)
    result.col = getColumn(p)
    getTok(p)
    eat(p, tkArrow)
    result.rule = parseExpr(p)
    incl(result.flags, ntDeclared) # NOW inlining may be attempted
  else:
    pegError(p, "rule expected, but found: " & p.tok.literal)

proc rawParse(p: var TPegParser): TPeg =
  ## parses a rule or a PEG expression
  while p.tok.kind == tkBuiltin:
    case p.tok.literal
    of "i":
      p.modifier = modIgnoreCase
      getTok(p)
    of "y":
      p.modifier = modIgnoreStyle
      getTok(p)
    of "skip":
      getTok(p)
      p.skip = ?primary(p)
    else: break
  if p.tok.kind == tkIdentifier and arrowIsNextTok(p):
    result = parseRule(p).rule
    while p.tok.kind != tkEof:
      discard parseRule(p)
  else:
    p.identIsVerbatim = true
    result = parseExpr(p)
  if p.tok.kind != tkEof:
    pegError(p, "EOF expected, but found: " & p.tok.literal)
  for i in 0..high(p.nonterms):
    var nt = p.nonterms[i]
    if ntDeclared notin nt.flags:
      pegError(p, "undeclared identifier: " & nt.name, nt.line, nt.col)
    elif ntUsed notin nt.flags and i > 0:
      pegError(p, "unused rule: " & nt.name, nt.line, nt.col)

proc parsePeg*(pattern: string, filename = "pattern", line = 1, col = 0): TPeg =
  ## constructs a TPeg object from `pattern`. `filename`, `line`, `col` are
  ## used for error messages, but they only provide start offsets. `parsePeg`
  ## keeps track of line and column numbers within `pattern`.
  var p: TPegParser
  init(TPegLexer(p), pattern, filename, line, col)
  p.tok.kind = tkInvalid
  p.tok.modifier = modNone
  p.tok.literal = ""
  p.tok.charset = {}
  p.nonterms = @[]
  p.identIsVerbatim = false
  getTok(p)
  result = rawParse(p)

proc peg*(pattern: string): TPeg =
  ## constructs a TPeg object from the `pattern`. The short name has been
  ## chosen to encourage its use as a raw string modifier::
  ##
  ##   peg"{\ident} \s* '=' \s* {.*}"
  result = parsePeg(pattern, "pattern")

proc escapePeg*(s: string): string =
  ## escapes `s` so that it is matched verbatim when used as a peg.
  result = ""
  var inQuote = false
  for c in items(s):
    case c
    of '\0'..'\31', '\'', '"', '\\':
      if inQuote:
        result.add('\'')
        inQuote = false
      result.add("\\x")
      result.add(toHex(ord(c), 2))
    else:
      if not inQuote:
        result.add('\'')
        inQuote = true
      result.add(c)
  if inQuote: result.add('\'')

when isMainModule:
  doAssert escapePeg("abc''def'") == r"'abc'\x27\x27'def'\x27"
  #doAssert match("(a b c)", peg"'(' @ ')'")
  doAssert match("W_HI_Le", peg"\y 'while'")
  doAssert(not match("W_HI_L", peg"\y 'while'"))
  doAssert(not match("W_HI_Le", peg"\y v'while'"))
  doAssert match("W_HI_Le", peg"y'while'")

  doAssert($ +digits == $peg"\d+")
  doAssert "0158787".match(peg"\d+")
  doAssert "ABC 0232".match(peg"\w+\s+\d+")
  doAssert "ABC".match(peg"\d+ / \w+")

  for word in split("00232this02939is39an22example111", peg"\d+"):
    writeLine(stdout, word)

  doAssert matchLen("key", ident) == 3

  var pattern = sequence(ident, *whitespace, term('='), *whitespace, ident)
  doAssert matchLen("key1=  cal9", pattern) == 11

  var ws = newNonTerminal("ws", 1, 1)
  ws.rule = *whitespace

  var expr = newNonTerminal("expr", 1, 1)
  expr.rule = sequence(capture(ident), *sequence(
                nonterminal(ws), term('+'), nonterminal(ws), nonterminal(expr)))

  var c: TCaptures
  var s = "a+b +  c +d+e+f"
  doAssert rawMatch(s, expr.rule, 0, c) == len(s)
  var a = ""
  for i in 0..c.ml-1:
    a.add(substr(s, c.matches[i][0], c.matches[i][1]))
  doAssert a == "abcdef"
  #echo expr.rule

  #const filename = "lib/devel/peg/grammar.txt"
  #var grammar = parsePeg(newFileStream(filename, fmRead), filename)
  #echo "a <- [abc]*?".match(grammar)
  doAssert find("_____abc_______", term("abc"), 2) == 5
  doAssert match("_______ana", peg"A <- 'ana' / . A")
  doAssert match("abcs%%%", peg"A <- ..A / .A / '%'")

  if "abc" =~ peg"{'a'}'bc' 'xyz' / {\ident}":
    doAssert matches[0] == "abc"
  else:
    doAssert false

  var g2 = peg"""S <- A B / C D
                 A <- 'a'+
                 B <- 'b'+
                 C <- 'c'+
                 D <- 'd'+
              """
  doAssert($g2 == "((A B) / (C D))")
  doAssert match("cccccdddddd", g2)
  doAssert("var1=key; var2=key2".replacef(peg"{\ident}'='{\ident}", "$1<-$2$2") ==
         "var1<-keykey; var2<-key2key2")
  doAssert "var1=key; var2=key2".endsWith(peg"{\ident}'='{\ident}")

  if "aaaaaa" =~ peg"'aa' !. / ({'a'})+":
    doAssert matches[0] == "a"
  else:
    doAssert false

  block:
    var matches: array[0..2, string]
    if match("abcdefg", peg"c {d} ef {g}", matches, 2):
      doAssert matches[0] == "d"
      doAssert matches[1] == "g"
    else:
      doAssert false

  for x in findAll("abcdef", peg"{.}", 3):
    echo x

  if "f(a, b)" =~ peg"{[0-9]+} / ({\ident} '(' {@} ')')":
    doAssert matches[0] == "f"
    doAssert matches[1] == "a, b"
  else:
    doAssert false

  doAssert match("eine übersicht und außerdem", peg"(\letter \white*)+")
  # ß is not a lower cased letter?!
  doAssert match("eine übersicht und auerdem", peg"(\lower \white*)+")
  doAssert match("EINE ÜBERSICHT UND AUSSERDEM", peg"(\upper \white*)+")
  doAssert(not match("456678", peg"(\letter)+"))

  doAssert("var1 = key; var2 = key2".replacef(
    peg"\skip(\s*) {\ident}'='{\ident}", "$1<-$2$2") ==
         "var1<-keykey;var2<-key2key2")

  doAssert match("prefix/start", peg"^start$", 7)

  # tricky test to check for false aliasing:
  block:
    var a = term"key"
    echo($sequence(sequence(a, term"value"), *a))

